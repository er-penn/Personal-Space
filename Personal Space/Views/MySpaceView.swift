//
//  MySpaceView.swift
//  Personal Space
//
//  Created by Penn on 2025/1/27.
//

import SwiftUI
import Combine

// MARK: - 圆角扩展
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

struct MySpaceView: View {
    @EnvironmentObject var userState: UserState
    @EnvironmentObject var partnerState: PartnerState
    @State private var showingFABMenu = false
    @State private var showingMoodSlider = false
    @State private var currentMood: Double = 5.0
    @State private var showingGestureHints = false
    @State private var batteryScale: CGFloat = 1.0
    @State private var batteryTilt: Double = 0.0
    @State private var highlightedDirection: String? = nil
    @State private var hasSwitchedFromUnplanned = false
    // 移除 showingMomentDetail 状态，改用 NavigationLink
    
    // MARK: - 定时器相关状态变量
    @State private var timer: Timer?
    
    // MARK: - 临时状态相关状态变量
    @State private var showingTimePicker = false
    @State private var selectedTemporaryStateType: TemporaryStateType? = nil
    @State private var selectedDuration: TimeInterval = 7200 // 默认2小时
    @State private var showingTemporaryStateOverlay = false

    // MARK: - FAB功能相关状态变量
    @State private var showingCollaborationInvitation = false
    @State private var showingPeacefulClosureCreate = false
    @State private var showingGiftBoxCreate = false
    @State private var showingFragmentCreate = false
    @State private var showingMomentCreate = false
    @State private var showingMyMoments = false

    // MARK: - 焦虑平复指南相关状态变量
    @State private var showingAnxietySoothingGuide = false
    @StateObject private var knowledgeActionManager = KnowledgeActionManager()
    @StateObject private var customContentManager = CustomContentManager()
    
    init() {
        // 每天第一次打开app时重置状态
        let today = Calendar.current.startOfDay(for: Date())
        let lastResetDate = UserDefaults.standard.object(forKey: "lastResetDate") as? Date ?? Date.distantPast
        if !Calendar.current.isDate(lastResetDate, inSameDayAs: today) {
            UserDefaults.standard.set(today, forKey: "lastResetDate")
            // 这里不需要设置hasSwitchedFromUnplanned，因为@State会在每次视图创建时重置
        }
    }
    
    private var knowledgeActionContent: String {
        let todayActions = knowledgeActionManager.getTodayActions()
        let completed = todayActions.filter { $0.isCompleted }.count
        let total = todayActions.count
        let firstLine = "今日打卡：\(completed)/\(total) 已完成"
        let consecutiveDays = knowledgeActionManager.getConsecutiveCompletionDays()
        let flame = consecutiveDays >= 3 ? " 🔥" : ""
        let secondLine = "持续打卡：\(consecutiveDays)天\(flame)"
        return firstLine + "\n" + secondLine
    }
    
    private var anxietyGuideCard: FunctionCard {
        let contents = customContentManager.contents.sorted { $0.lastAccessed > $1.lastAccessed }
        if contents.isEmpty {
            let preview = "暂无自定义内容\n点击添加你的平复工具"
            return FunctionCard(title: "焦虑平复指南", icon: "cross.case.fill", color: .orange, content: preview, action: {
                showingAnxietySoothingGuide = true
            })
        } else if contents.count == 1 {
            let first = contents[0].title
            let preview = "自定义：\(first)\n点击进入查看更多"
            return FunctionCard(title: "焦虑平复指南", icon: "cross.case.fill", color: .orange, content: preview, action: {
                showingAnxietySoothingGuide = true
            })
        } else {
            let first = contents[0].title
            let second = contents[1].title
            let moreCount = contents.count - 2
            let moreText = moreCount > 0 ? "还有 \(moreCount) 个内容待探索" : "点击查看全部自定义内容"
            let preview = "自定义：\(first) · \(second)\n\(moreText)"
            return FunctionCard(title: "焦虑平复指南", icon: "cross.case.fill", color: .orange, content: preview, action: {
                showingAnxietySoothingGuide = true
            })
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景渐变
                AppGradient.background
                    .ignoresSafeArea()
                
                ScrollView(.vertical, showsIndicators: true) {
                    LazyVStack(spacing: AppTheme.Spacing.xxl) {
                        // 顶部状态区
                        statusSection
                        
                        // 能量预规划
                        EnergyProgressView()
                            .environmentObject(userState)
                        
                        // 心情记录
                        MoodChartView()
                            .environmentObject(userState)
                        
                        // 知行合一卡片
                        NavigationLink(destination: KnowledgeActionUnityView()) {
                            HStack(spacing: AppTheme.Spacing.lg) {
                                // 左侧图标区域
                                VStack {
                                    Image(systemName: "target")
                                        .font(.system(size: 32))
                                        .foregroundColor(.green)
                                        .shadow(color: .green.opacity(0.3), radius: 4, x: 0, y: 2)
                                        .frame(width: 60, height: 60)
                                        .background(.green.opacity(0.1))
                                        .clipShape(Circle())
                                }

                                // 中间内容区域
                                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                                    Text("知行合一")
                                        .font(.system(size: AppTheme.FontSize.headline, weight: .semibold))
                                        .foregroundColor(AppTheme.Colors.text)

                                    Text(knowledgeActionContent)
                                        .font(.system(size: AppTheme.FontSize.caption))
                                        .foregroundColor(AppTheme.Colors.textSecondary)
                                        .lineLimit(2)
                                }

                                Spacer()
                            }
                            .padding(AppTheme.Spacing.lg)
                            .background(Color(.systemBackground))
                            .cornerRadius(AppTheme.Radius.medium)
                            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // 我的动态内容部分
                        MyMomentSection(onTap: { showingMyMoments = true })
                            .environmentObject(userState)
                        
                        // 焦虑平复指南卡片（放在最后）
                        FunctionCardView(card: anxietyGuideCard)
                        
                        Spacer(minLength: 120) // 为FAB留出更多空间
                    }
                    .padding(.horizontal, AppTheme.Spacing.lg)
                    .padding(.top, AppTheme.Spacing.lg)
                }
                
                // 悬浮按钮 (FAB)
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        FABMenuView(
                            isShowing: $showingFABMenu,
                            onAction: handleFABAction,
                            hasPartner: partnerState.hasPartner
                        )
                    }
                    .padding(.trailing, AppTheme.Spacing.xl)
                    .padding(.bottom, AppTheme.Spacing.xl)
                }
                
                // 时间选择器 - 底部弹出
                if showingTimePicker, let stateType = selectedTemporaryStateType {
                    ZStack {
                        // 半透明背景遮罩
                        Color.black.opacity(0.3)
                            .ignoresSafeArea(.all)
                            .onTapGesture {
                                showingTimePicker = false
                                selectedTemporaryStateType = nil
                            }
                        
                        // 弹窗内容 - 从底部弹出，露出"已选择"部分
                        VStack {
                            Spacer()
                            
                            TemporaryStateTimePicker(
                                selectedDuration: $selectedDuration,
                                isPresented: $showingTimePicker,
                                maxDuration: userState.getTodayRemainingTimeRoundedTo15Minutes(),
                                onConfirm: { duration in
                                    // 启动临时状态
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        userState.startTemporaryState(type: stateType, duration: duration)
                                        showingTemporaryStateOverlay = true
                                        showingTimePicker = false
                                        
                                        // 同步到后端
                                        Task {
                                            await userState.createTemporaryStateToBackend(type: stateType, durationMinutes: Int(duration / 60))
                                        }
                                    }
                                },
                                onCancel: {
                                    showingTimePicker = false
                                    selectedTemporaryStateType = nil
                                }
                            )
                            .background(Color(.systemBackground))
                            .cornerRadius(16, corners: [.topLeft, .topRight])
                            .shadow(radius: 10)
                            .padding(.bottom, 0) // 移除底部间距，让弹窗完全贴底
                        }
                        .ignoresSafeArea(.all) // 确保覆盖所有安全区域
                        .zIndex(1000) // 确保在最上层
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                        .animation(.easeInOut(duration: 0.3), value: showingTimePicker)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            startTimer()

            // 从后端加载能量数据
            Task {
                await userState.loadCurrentEnergyStatus()
                await userState.loadEnergyRecords()
            }

            // 加载示例安心确认数据（仅DEBUG模式）
            #if DEBUG
            if userState.peacefulClosures.isEmpty {
                userState.loadSamplePeacefulClosures()
            }
            #endif

            // 更新待处理列表
            userState.updatePendingClosures()
        }
        .onDisappear {
            stopTimer()
            
            // 页面切换时同步基础状态记录到后端
            Task {
                await userState.syncBaseEnergyRecordsToBackend()
            }
        }
        .sheet(isPresented: $showingCollaborationInvitation) {
            CollaborationInvitationView()
        }
        .sheet(isPresented: $showingPeacefulClosureCreate) {
            PeacefulClosureCreateView()
                .environmentObject(userState)
        }
        .sheet(isPresented: $showingGiftBoxCreate) {
            GiftBoxCreateView()
                .environmentObject(userState)
        }
        .sheet(isPresented: $showingFragmentCreate) {
            FragmentCreateView()
                .environmentObject(userState)
        }
        .sheet(isPresented: $showingMomentCreate) {
            MomentCreateView()
                .environmentObject(userState)
        }
        .sheet(isPresented: $showingMyMoments) {
            MyMomentsView()
                .environmentObject(userState)
        }
        .sheet(isPresented: $showingAnxietySoothingGuide) {
            AnxietySoothingGuideView()
                .environmentObject(customContentManager)
        }
    }
    
    // MARK: - 定时器管理（全局状态管理）
    private func startTimer() {
        // 每分钟更新一次，确保能量状态能够及时切换
        timer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { _ in
            // 🎯 全局状态管理：统一负责所有状态更新
            // 1. 更新全局当前时间（所有组件自动响应）
            userState.currentTime = Date()

            // 2. 检查是否跨天，如果是则重置基础状态为"未规划"
            userState.checkAndResetDailyState()

            // 3. 每分钟检查并追加基础状态时间段
            userState.checkAndAppendBaseStateTimeSlot()

            // 4. 检查并更新预规划状态
            userState.checkAndUpdatePlannedState()

            // 5. 🎯 新增：分钟级倒计时更新
            userState.updateMinuteCountdowns()

            // 6. 检查过期的安心确认
            userState.checkExpiredClosures()
            // 7. 检查过期的心意盒
            userState.checkExpiredGiftBoxes()
            // 8. 触发UI更新，让所有子组件自动响应状态变化
            userState.objectWillChange.send()
        }

        // 立即执行一次检查
        userState.checkAndResetDailyState()
        userState.checkAndUpdatePlannedState()
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    // MARK: - 顶部状态区
    private var statusSection: some View {
        ZStack {
            // 主卡片区域 - 固定高度
            VStack(spacing: AppTheme.Spacing.lg) {
                // 顶部：能量状态 + 快速操作
                HStack(spacing: AppTheme.Spacing.lg) {
                    // 左侧空白区域
                    Spacer()
                        .frame(width: 40)
                    
                    // 能量状态（电池图标设计）
                    VStack(spacing: AppTheme.Spacing.sm) {
                        ZStack {
                            // 背景圆形渐变 - 根据预规划状态动态变化
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            userState.getCurrentPlannedEnergyColor().opacity(0.2),
                                            userState.getCurrentPlannedEnergyColor().opacity(0.1)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 80, height: 80)
                            
                            // 电池图标
                            BatteryIconView(energyLevel: hasSwitchedFromUnplanned ? userState.displayEnergyLevel : (userState.displayEnergyLevel == .unplanned ? .unplanned : userState.displayEnergyLevel))
                                .scaleEffect(0.7)
                            
                            // 手势引导提示 - 围绕电池图标
                            if showingGestureHints {
                                // 上箭头 - 高能量
                                VStack {
                                    VStack(spacing: 2) {
                                        SmallBatteryIconView(energyLevel: .high)
                                            .scaleEffect(0.5)
                                        Image(systemName: "arrowtriangle.up.fill")
                                            .font(.system(size: 6, weight: .bold))
                                            .foregroundColor(highlightedDirection == "up" ? .green : .gray.opacity(0.6))
                                    }
                                    .padding(4)
                                    .background(
                                        Circle()
                                            .fill(highlightedDirection == "up" ? Color.green.opacity(0.15) : Color.gray.opacity(0.1))
                                    )
                                    Spacer()
                                }
                                .frame(width: 80, height: 80)
                                .offset(y: -40)
                                
                                // 下箭头 - 低能量
                                VStack {
                                    Spacer()
                                    VStack(spacing: 2) {
                                        Image(systemName: "arrowtriangle.down.fill")
                                            .font(.system(size: 6, weight: .bold))
                                            .foregroundColor(highlightedDirection == "down" ? .red : .gray.opacity(0.6))
                                        SmallBatteryIconView(energyLevel: .low)
                                            .scaleEffect(0.5)
                                    }
                                    .padding(4)
                                    .background(
                                        Circle()
                                            .fill(highlightedDirection == "down" ? Color.red.opacity(0.15) : Color.gray.opacity(0.1))
                                    )
                                }
                                .frame(width: 80, height: 80)
                                .offset(y: 40)
                                
                                // 左箭头 - 中能量
                                HStack {
                                    VStack(spacing: 2) {
                                        SmallBatteryIconView(energyLevel: .medium)
                                            .scaleEffect(0.5)
                                        Image(systemName: "arrowtriangle.left.fill")
                                            .font(.system(size: 6, weight: .bold))
                                            .foregroundColor(highlightedDirection == "left" ? .blue : .gray.opacity(0.6))
                                    }
                                    .padding(4)
                                    .background(
                                        Circle()
                                            .fill(highlightedDirection == "left" ? Color.blue.opacity(0.15) : Color.gray.opacity(0.1))
                                    )
                                    Spacer()
                                }
                                .frame(width: 80, height: 80)
                                .offset(x: -40)
                                
                                // 右箭头 - 中能量
                                HStack {
                                    Spacer()
                                    VStack(spacing: 2) {
                                        SmallBatteryIconView(energyLevel: .medium)
                                            .scaleEffect(0.5)
                                        Image(systemName: "arrowtriangle.right.fill")
                                            .font(.system(size: 6, weight: .bold))
                                            .foregroundColor(highlightedDirection == "right" ? .blue : .gray.opacity(0.6))
                                    }
                                    .padding(4)
                                    .background(
                                        Circle()
                                            .fill(highlightedDirection == "right" ? Color.blue.opacity(0.15) : Color.gray.opacity(0.1))
                                    )
                                }
                                .frame(width: 80, height: 80)
                                .offset(x: 40)
                            }
                        }
                        .scaleEffect(batteryScale)
                        .rotationEffect(.degrees(batteryTilt))
                        .offset(x: showingGestureHints ? 0 : -27, y: showingGestureHints ? 0 : 10) // 静态时向左下移动
                        
                        if !showingGestureHints {
                            let displayLevel = hasSwitchedFromUnplanned ? userState.displayEnergyLevel : (userState.displayEnergyLevel == .unplanned ? .unplanned : userState.displayEnergyLevel)
                            Text(displayLevel.description)
                                .font(.system(size: AppTheme.FontSize.subheadline, weight: .semibold))
                                .foregroundColor(displayLevel.color)
                                .multilineTextAlignment(.center)
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                                .offset(x: -27, y: 10) // 向右上移动，与电池图标中心对齐
                                .transition(.opacity.combined(with: .scale))
                        }
                    }
                    .onTapGesture {
                        // 短按：循环切换能量状态
                        // 时段规则：0:00-6:59 允许切回"未规划"，7:00-23:59 不允许
                        withAnimation(.easeInOut(duration: 0.3)) {
                            let calendar = Calendar.current
                            let currentHour = calendar.component(.hour, from: Date())
                            let isEarlyMorning = currentHour >= 0 && currentHour < 7
                            
                            let newLevel: EnergyLevel
                            
                            if isEarlyMorning {
                                // 凌晨时段（0:00-6:59）：允许切回"未规划"
                                switch userState.currentBaseEnergyLevel {
                                case .high:
                                    newLevel = .medium
                                case .medium:
                                    newLevel = .low
                                case .low:
                                    newLevel = .unplanned  // ✓ 可以切回未规划
                                case .unplanned:
                                    newLevel = .high
                                }
                            } else {
                                // 白天时段（7:00-23:59）：不允许切回"未规划"
                                switch userState.currentBaseEnergyLevel {
                                case .high:
                                    newLevel = .medium
                                case .medium:
                                    newLevel = .low
                                case .low:
                                    newLevel = .high       // ✓ 跳过未规划，直接回到高
                                case .unplanned:
                                    newLevel = .high       // ✓ 单向切换
                                }
                            }

                            // 更新状态并记录状态切换历史（使用新的实时截断策略）
                            userState.updateCurrentBaseEnergyLevel(to: newLevel)
                            userState.recordEnergyLevelChange(to: newLevel)
                            
                            // 同步到后端（包括能量等级和基础状态记录）
                            Task {
                                await userState.syncCurrentEnergyLevelToBackend()
                                await userState.syncBaseEnergyRecordsToBackend()
                            }
                            
                            // 更新 hasSwitchedFromUnplanned 标记
                            if newLevel != .unplanned {
                                hasSwitchedFromUnplanned = true
                            } else {
                                // 切回未规划时重置标记
                                hasSwitchedFromUnplanned = false
                            }
                        }
                    }
                    .onLongPressGesture {
                        showGestureHints()
                    }
                    .simultaneousGesture(
                        DragGesture()
                            .onChanged { value in
                                updateGestureFeedback(translation: value.translation)
                            }
                            .onEnded { value in
                                handleGestureEnd(translation: value.translation)
                            }
                    )
                    
                    Spacer()
                    
                    // 右侧：快速操作按钮组 - 2x2网格布局
                    VStack(spacing: AppTheme.Spacing.md) {
                        // 第一行：平复和TA
                        HStack(spacing: AppTheme.Spacing.lg) {
                            // 平复按钮 - 可点击，向右偏移与快充按钮对齐
                            VStack(spacing: 4) {
                                Button(action: {
                                    showingAnxietySoothingGuide = true
                                }) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.red.opacity(0.15))
                                            .frame(width: 50, height: 50)
                                        
                                        Image(systemName: "cross.case.fill")
                                            .font(.system(size: 20))
                                            .foregroundColor(.red)
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                                Text("平复")
                                    .font(.system(size: AppTheme.FontSize.caption2, weight: .medium))
                                    .foregroundColor(AppTheme.Colors.textSecondary)
                            }
                            .offset(x: 8) // 向右偏移，与快充按钮对齐
                            
                            // TA状态 - 不可点击，仅显示（有伴侣时才显示）
                            if partnerState.hasPartner {
                            VStack(spacing: 4) {
                                // 小电池图标 - 无背景圆形
                                BatteryIconView(energyLevel: partnerState.energyLevel)
                                    .scaleEffect(0.6) // 缩小到60%
                                
                                Text("TA")
                                    .font(.system(size: AppTheme.FontSize.caption2, weight: .medium))
                                    .foregroundColor(AppTheme.Colors.textSecondary)
                                }
                            }
                        }
                        
                        // 第二行：快充模式 + 低电量模式
                        HStack(spacing: AppTheme.Spacing.lg) {
                            // 快充模式按钮
                            TemporaryStateButton(
                                stateType: .fastCharge,
                                isActive: userState.currentBaseEnergyLevel == .high,
                                onShortPress: {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        userState.updateCurrentBaseEnergyLevel(to: .high)  // 使用新的实时截断策略
                                        hasSwitchedFromUnplanned = true
                                        // 同步到后端
                                        Task {
                                            await userState.syncCurrentEnergyLevelToBackend()
                                        }
                                    }
                                },
                                onLongPress: {
                                    print("快充按钮长按被触发")
                                    selectedTemporaryStateType = .fastCharge
                                    selectedDuration = min(7200, userState.getTodayRemainingTimeRoundedTo15Minutes())
                                    showingTimePicker = true
                                    print("showingTimePicker 设置为: \(showingTimePicker)")
                                }
                            )

                            // 低电量模式按钮
                            TemporaryStateButton(
                                stateType: .lowPower,
                                isActive: userState.currentBaseEnergyLevel == .low,
                                onShortPress: {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        userState.updateCurrentBaseEnergyLevel(to: .low)  // 使用新的实时截断策略
                                        hasSwitchedFromUnplanned = true
                                        // 同步到后端
                                        Task {
                                            await userState.syncCurrentEnergyLevelToBackend()
                                        }
                                    }
                                },
                                onLongPress: {
                                    print("低电量按钮长按被触发")
                                    selectedTemporaryStateType = .lowPower
                                    selectedDuration = min(7200, userState.getTodayRemainingTimeRoundedTo15Minutes())
                                    showingTimePicker = true
                                    print("showingTimePicker 设置为: \(showingTimePicker)")
                                }
                            )
                        }
                    }
                }
            }
            .frame(height: 140) // 压缩高度
            .padding(AppTheme.Spacing.xl)
            .background(
                ZStack {
                    // 主背景
                    RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                        .fill(
                            LinearGradient(
                                colors: [
                                    AppTheme.Colors.cardBg,
                                    AppTheme.Colors.cardBg.opacity(0.95)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    // 玻璃态效果
                    RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                        .fill(.ultraThinMaterial)
                        .opacity(0.3)
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                    .stroke(
                        LinearGradient(
                            colors: [
                                AppTheme.Colors.border.opacity(0.5),
                                AppTheme.Colors.border.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: AppTheme.Shadows.card.opacity(0.8),
                radius: 12,
                x: 0,
                y: 6
            )
            .shadow(
                color: AppTheme.Shadows.card.opacity(0.4),
                radius: 4,
                x: 0,
                y: 2
            )

            // 🎯 状态遮罩 - 跟随卡片一起滚动
            // 临时状态遮罩
            if showingTemporaryStateOverlay && userState.isTemporaryStateActive {
                TemporaryStateOverlay(
                    stateType: userState.currentTemporaryStateType ?? .fastCharge,
                    remainingTime: userState.getTemporaryStateRemainingTime(),
                    onEnd: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            userState.endTemporaryState()
                            showingTemporaryStateOverlay = false
                            // 同步到后端
                            Task {
                                await userState.endTemporaryStateToBackend()
                            }
                            // 🎯 手动触发一次UI刷新，让能量条立即显示新的状态
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                userState.objectWillChange.send()
                            }
                        }
                    }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.8)))
                .animation(.easeInOut(duration: 0.3), value: showingTemporaryStateOverlay)
            }

            // 预规划状态遮罩
            if !userState.isTemporaryStateActive && userState.isPlannedStateActive,
               let plannedLevel = userState.currentPlannedStateLevel {
                PlannedStateOverlay(
                    energyLevel: plannedLevel,
                    remainingTime: userState.getPlannedStateRemainingTime(),
                    onEnd: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            userState.endPlannedStateManually()
                            // 🎯 手动触发一次UI刷新，让能量条立即显示新的状态
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                userState.objectWillChange.send()
                            }
                        }
                    }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.8)))
                .animation(.easeInOut(duration: 0.3), value: userState.isPlannedStateActive)
            }
        }
    }
    
    // MARK: - 手势处理方法
    private func showGestureHints() {
        withAnimation(.easeInOut(duration: 0.2)) {
            showingGestureHints = true
            batteryScale = 1.1
        }
        
        // 3秒后自动隐藏提示
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            hideGestureHints()
        }
    }
    
    private func hideGestureHints() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showingGestureHints = false
            batteryScale = 1.0
            batteryTilt = 0.0
            highlightedDirection = nil
        }
    }
    
    private func updateGestureFeedback(translation: CGSize) {
        let threshold: CGFloat = 20
        
        // 根据滑动方向更新高亮状态
        if abs(translation.height) > abs(translation.width) {
            // 垂直滑动
            if translation.height < -threshold {
                highlightedDirection = "up"
                batteryTilt = -5.0
            } else if translation.height > threshold {
                highlightedDirection = "down"
                batteryTilt = 5.0
            } else {
                highlightedDirection = nil
                batteryTilt = 0.0
            }
        } else {
            // 水平滑动
            if translation.width < -threshold {
                highlightedDirection = "left"
                batteryTilt = -3.0
            } else if translation.width > threshold {
                highlightedDirection = "right"
                batteryTilt = 3.0
            } else {
                highlightedDirection = nil
                batteryTilt = 0.0
            }
        }
    }
    
    private func handleGestureEnd(translation: CGSize) {
        let threshold: CGFloat = 30
        
        withAnimation(.easeInOut(duration: 0.3)) {
            if abs(translation.height) > threshold {
                if translation.height < 0 {
                    // 向上滑动 - 高能量
                    switchToEnergyLevel(.high)
                } else {
                    // 向下滑动 - 低能量
                    switchToEnergyLevel(.low)
                }
            } else if abs(translation.width) > threshold {
                // 左右滑动 - 中能量
                switchToEnergyLevel(.medium)
            }
            
            // 隐藏提示
            hideGestureHints()
        }
    }
    
    private func switchToEnergyLevel(_ level: EnergyLevel) {
        withAnimation(.easeInOut(duration: 0.3)) {
            userState.updateCurrentBaseEnergyLevel(to: level)  // 使用新的实时截断策略
            hasSwitchedFromUnplanned = true
            // 同步到后端
            Task {
                await userState.syncCurrentEnergyLevelToBackend()
            }
        }
    }
    
    // MARK: - FAB功能处理
    private func handleFABAction(_ action: String) {
        switch action {
        case "发起邀请":
            showingCollaborationInvitation = true
        case "安心确认":
            showingPeacefulClosureCreate = true
        case "赠送心意":
            showingGiftBoxCreate = true
        case "分享碎片":
            showingFragmentCreate = true
        case "发布瞬间":
            showingMomentCreate = true
        default:
            break
        }
    }
}

// MARK: - 我的动态部分
struct MyMomentSection: View {
    @EnvironmentObject var userState: UserState
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: AppTheme.Spacing.lg) {
                // 标题行
                HStack {
                    HStack(spacing: AppTheme.Spacing.sm) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 20))
                            .foregroundColor(AppTheme.Colors.primary)
                        
                        Text("我的动态")
                            .font(.system(size: AppTheme.FontSize.headline, weight: .semibold))
                            .foregroundColor(AppTheme.Colors.text)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Text("\(userState.myMoments.count) 条瞬间")
                            .font(.system(size: AppTheme.FontSize.caption))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: AppTheme.FontSize.caption))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                }
                
                if userState.myMoments.isEmpty {
                    // 空状态
                    Text("点击右下角"+"按钮发布你的第一条瞬间")
                        .font(.system(size: AppTheme.FontSize.body))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppTheme.Spacing.lg)
                } else {
                    // 显示最近2条
                    VStack(spacing: AppTheme.Spacing.sm) {
                        ForEach(userState.myMoments.prefix(2)) { moment in
                            HStack(spacing: AppTheme.Spacing.sm) {
                                // 缩略图
                                if !moment.images.isEmpty {
                                    RoundedRectangle(cornerRadius: AppTheme.Radius.small)
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(width: 50, height: 50)
                                        .overlay(
                                            Image(systemName: "photo")
                                                .foregroundColor(.gray.opacity(0.5))
                                        )
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(moment.content)
                                        .font(.system(size: AppTheme.FontSize.body))
                                        .foregroundColor(AppTheme.Colors.text)
                                        .lineLimit(2)
                                    
                                    HStack(spacing: AppTheme.Spacing.sm) {
                                        Text(formatDate(moment.createdAt))
                                            .font(.system(size: AppTheme.FontSize.caption))
                                            .foregroundColor(AppTheme.Colors.textSecondary)
                                        
                                        HStack(spacing: 4) {
                                            Image(systemName: "heart")
                                                .font(.system(size: 12))
                                            Text("\(moment.likes)")
                                                .font(.system(size: AppTheme.FontSize.caption))
                                        }
                                        .foregroundColor(AppTheme.Colors.textSecondary)
                                    }
                                }
                                
                                Spacer()
                            }
                            .padding(AppTheme.Spacing.sm)
                            .background(AppTheme.Colors.bgMain)
                            .cornerRadius(AppTheme.Radius.small)
                        }
                    }
                }
            }
            .padding(AppTheme.Spacing.lg)
            .background(AppTheme.Colors.cardBg)
            .cornerRadius(AppTheme.Radius.large)
            .shadow(color: AppTheme.Shadows.card, radius: 6, x: 0, y: 3)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - 瞬间条目视图
struct MomentItemView: View {
    let index: Int
    
    var body: some View {
        HStack {
            Circle()
                .fill(AppTheme.Colors.primary.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Text("\(index + 1)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppTheme.Colors.primary)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text("瞬间记录 \(index + 1)")
                    .font(.system(size: AppTheme.FontSize.body, weight: .medium))
                    .foregroundColor(AppTheme.Colors.text)
                
                Text("这是第 \(index + 1) 条瞬间记录的内容预览...")
                    .font(.system(size: AppTheme.FontSize.caption))
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Text("2小时前")
                .font(.system(size: AppTheme.FontSize.caption2))
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.cardBg)
        .cornerRadius(AppTheme.Radius.medium)
        .shadow(color: AppTheme.Shadows.card, radius: 4, x: 0, y: 2)
    }
}

// MARK: - 功能卡片视图
struct FunctionCardView: View {
    let card: FunctionCard
    
    var body: some View {
        Button(action: card.action) {
            HStack(spacing: AppTheme.Spacing.lg) {
                // 左侧图标区域
                VStack {
                    Image(systemName: card.icon)
                        .font(.system(size: 32))
                        .foregroundColor(card.color)
                        .shadow(color: card.color.opacity(0.3), radius: 4, x: 0, y: 2)
                        .frame(width: 60, height: 60)
                        .background(card.color.opacity(0.1))
                        .clipShape(Circle())
                }
                
                // 中间内容区域
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text(card.title)
                        .font(.system(size: AppTheme.FontSize.headline, weight: .semibold))
                        .foregroundColor(AppTheme.Colors.text)
                    
                    Text(card.content)
                        .font(.system(size: AppTheme.FontSize.body))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // 右侧箭头
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            .padding(AppTheme.Spacing.lg)
            .background(AppTheme.Colors.cardBg)
            .cornerRadius(AppTheme.Radius.large)
            .shadow(
                color: AppTheme.Shadows.card,
                radius: 6,
                x: 0,
                y: 3
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.large)
                    .stroke(AppTheme.Colors.border, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(1.0)
        .animation(.easeInOut(duration: 0.2), value: card.title)
    }
}

// MARK: - FAB菜单视图
struct FABMenuView: View {
    @Binding var isShowing: Bool
    let onAction: (String) -> Void
    let hasPartner: Bool
    
    private let allFabItems = [
        ("发起邀请", "envelope", Color.blue),
        ("安心确认", "checkmark.circle", Color.green),
        ("赠送心意", "gift", Color.pink),
        ("分享碎片", "photo", Color.orange),
        ("发布瞬间", "camera", Color.purple)
    ]
    
    // 根据是否有伴侣关系过滤菜单项
    private var fabItems: [(String, String, Color)] {
        if hasPartner {
            // 有伴侣时显示所有功能
            return allFabItems
        } else {
            // 没有伴侣时只显示"发布瞬间"
            return allFabItems.filter { $0.0 == "发布瞬间" }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if isShowing {
                VStack(spacing: AppTheme.Spacing.sm) {
                    ForEach(fabItems, id: \.0) { item in
                        FABMenuItem(
                            title: item.0,
                            icon: item.1,
                            color: item.2,
                            action: {
                                onAction(item.0)
                                isShowing = false
                            }
                        )
                    }
                }
                .padding(AppTheme.Spacing.lg)
                .background(AppTheme.Colors.cardBg)
                .cornerRadius(AppTheme.Radius.card)
                .shadow(
                    color: AppTheme.Shadows.cardHover,
                    radius: 16,
                    x: 0,
                    y: 8
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                        .stroke(AppTheme.Colors.border, lineWidth: 1)
                )
                .transition(.scale.combined(with: .opacity))
            }
            
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isShowing.toggle()
                }
            }) {
                Image(systemName: isShowing ? "xmark" : "plus")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 64, height: 64)
                    .background(AppGradient.primaryGradient)
                    .clipShape(Circle())
                    .shadow(
                        color: AppTheme.Shadows.floating,
                        radius: 10,
                        x: 0,
                        y: 6
                    )
            }
        }
    }
}

// MARK: - FAB菜单项视图
struct FABMenuItem: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Spacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
                    .frame(width: 36, height: 36)
                    .background(color.opacity(0.1))
                    .clipShape(Circle())
                
                Text(title)
                    .font(.system(size: AppTheme.FontSize.subheadline, weight: .medium))
                    .foregroundColor(AppTheme.Colors.text)
                
                Spacer()
            }
            .padding(.horizontal, AppTheme.Spacing.lg)
            .padding(.vertical, AppTheme.Spacing.md)
            .background(AppTheme.Colors.bgMain)
            .cornerRadius(AppTheme.Radius.medium)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 我的瞬间详情页面
struct MyMomentDetailView: View {
    @State private var moments: [Moment] = [
        Moment(
            content: "今天天气真好，心情也很棒！在公园里散步，看到了很多美丽的花朵。",
            images: ["flower1", "flower2"],
            createdAt: Calendar.current.date(byAdding: .hour, value: -2, to: Date()) ?? Date(),
            isFromMe: true,
            isTextHidden: false,
            likes: 5,
            comments: 2
        ),
        Moment(
            content: "刚刚完成了一个重要的项目，感觉很有成就感！",
            images: ["project1"],
            createdAt: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
            isFromMe: true,
            isTextHidden: false,
            likes: 8,
            comments: 3
        ),
        Moment(
            content: "和朋友一起吃饭，聊了很多有趣的话题。友谊真的很珍贵！",
            images: ["dinner1", "dinner2", "dinner3"],
            createdAt: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date(),
            isFromMe: true,
            isTextHidden: false,
            likes: 12,
            comments: 5
        ),
        Moment(
            content: "今天学会了做一道新菜，味道还不错！",
            images: ["food1"],
            createdAt: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date(),
            isFromMe: true,
            isTextHidden: false,
            likes: 6,
            comments: 1
        ),
        Moment(
            content: "看了一部很棒的电影，推荐给大家！",
            images: ["movie1"],
            createdAt: Calendar.current.date(byAdding: .day, value: -4, to: Date()) ?? Date(),
            isFromMe: true,
            isTextHidden: false,
            likes: 9,
            comments: 4
        )
    ]
    
    var body: some View {
        ZStack {
            AppGradient.background
                .ignoresSafeArea()
            
            ScrollView {
                LazyVStack(spacing: AppTheme.Spacing.lg) {
                    ForEach(moments) { moment in
                        MomentDetailCard(moment: moment)
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.lg)
                .padding(.top, AppTheme.Spacing.lg)
            }
        }
        .navigationTitle("我的瞬间")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
    }
}

// MARK: - 瞬间数据模型已在 AppModels.swift 中定义

// MARK: - 瞬间详情卡片
struct MomentDetailCard: View {
    let moment: Moment
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            // 用户信息和时间
            HStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text("我")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("SSSPenn")
                        .font(.system(size: AppTheme.FontSize.body, weight: .semibold))
                        .foregroundColor(AppTheme.Colors.text)
                    
                    Text(formatTime(moment.createdAt))
                        .font(.system(size: AppTheme.FontSize.caption))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                
                Spacer()
            }
            
            // 内容文字
            Text(moment.content)
                .font(.system(size: AppTheme.FontSize.body))
                .foregroundColor(AppTheme.Colors.text)
                .lineLimit(nil)
            
            // 图片网格
            if !moment.images.isEmpty {
                LazyVGrid(columns: getImageColumns(), spacing: AppTheme.Spacing.sm) {
                    ForEach(moment.images, id: \.self) { imageName in
                        Rectangle()
                            .fill(AppTheme.Colors.primary.opacity(0.1))
                            .aspectRatio(1, contentMode: .fit)
                            .cornerRadius(AppTheme.Radius.medium)
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.system(size: 24))
                                    .foregroundColor(AppTheme.Colors.primary.opacity(0.5))
                            )
                    }
                }
            }
        }
        .padding(AppTheme.Spacing.lg)
        .background(AppTheme.Colors.cardBg)
        .cornerRadius(AppTheme.Radius.large)
        .shadow(color: AppTheme.Shadows.card, radius: 6, x: 0, y: 3)
    }
    
    private func getImageColumns() -> [GridItem] {
        let count = moment.images.count
        if count == 1 {
            return [GridItem(.flexible())]
        } else if count == 2 {
            return [GridItem(.flexible()), GridItem(.flexible())]
        } else {
            return Array(repeating: GridItem(.flexible()), count: 3)
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM月dd日 HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - 电池图标视图
struct BatteryIconView: View {
    let energyLevel: EnergyLevel
    
    var body: some View {
        ZStack {
            // 电池外框
            RoundedRectangle(cornerRadius: 8)
                .stroke(energyLevel.color, lineWidth: 5)
                .frame(width: 70, height: 40)
            
            // 电池正极
            RoundedRectangle(cornerRadius: 4)
                .fill(energyLevel.color)
                .frame(width: 6, height: 20)
                .offset(x: 40)
            
            // 电池电量
            HStack(spacing: 4) {
                ForEach(0..<getBatterySegments(), id: \.self) { _ in
                    Rectangle()
                        .fill(energyLevel.color)
                        .frame(width: 10, height: 26)
                        .cornerRadius(2)
                }
            }
            .offset(x: -4)
            
            // 省电模式图标（黄色时显示）
            if energyLevel == .medium {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.green)
                    .offset(x: 22, y: -12)
            }
        }
    }
    
    private func getBatterySegments() -> Int {
        switch energyLevel {
        case .high:
            return 4  // 满电：4格
        case .medium:
            return 2  // 半满：2格
        case .low:
            return 1  // 低电量：1格
        case .unplanned:
            return 0  // 待规划：0格
        }
    }
}


#Preview {
    MySpaceView()
        .environmentObject(UserState())
        .environmentObject(PartnerState())
        .environmentObject(GrowthGarden())
}
