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
    @State private var currentTime = Date()
    @State private var timer: Timer?
    
    // MARK: - 临时状态相关状态变量
    @State private var showingTimePicker = false
    @State private var selectedTemporaryStateType: TemporaryStateType? = nil
    @State private var selectedDuration: TimeInterval = 7200 // 默认2小时
    @State private var showingTemporaryStateOverlay = false
    
    init() {
        // 每天第一次打开app时重置状态
        let today = Calendar.current.startOfDay(for: Date())
        let lastResetDate = UserDefaults.standard.object(forKey: "lastResetDate") as? Date ?? Date.distantPast
        if !Calendar.current.isDate(lastResetDate, inSameDayAs: today) {
            UserDefaults.standard.set(today, forKey: "lastResetDate")
            // 这里不需要设置hasSwitchedFromUnplanned，因为@State会在每次视图创建时重置
        }
    }
    
    private let functionCards = [
        FunctionCard(title: "知行合一", icon: "target", color: .green, content: "今日目标：冥想15分钟 ✓", action: { }),
        FunctionCard(title: "焦虑平复指南", icon: "cross.case.fill", color: .orange, content: "推荐：深呼吸练习", action: { })
    ]
    
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
                        FunctionCardView(card: functionCards[0])
                        
                        // 我的瞬间内容部分
                        MyMomentSection()
                        
                        // 焦虑平复指南卡片（放在最后）
                        FunctionCardView(card: functionCards[1])
                        
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
                        FABMenuView(isShowing: $showingFABMenu)
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
                
                // 临时状态遮罩 - 添加动画效果
                if showingTemporaryStateOverlay && userState.isTemporaryStateActive {
                    TemporaryStateOverlay(
                        stateType: userState.temporaryStateType ?? .fastCharge,
                        remainingTime: userState.getTemporaryStateRemainingTime(),
                        onEnd: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                userState.endTemporaryState()
                                showingTemporaryStateOverlay = false
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
                
                // 预规划状态遮罩 - 当不在临时状态且处于预规划状态时显示
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
            .navigationBarHidden(true)
        }
        .onAppear {
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
    }
    
    // MARK: - 定时器管理
    private func startTimer() {
        // 每分钟更新一次，确保能量状态能够及时切换
        timer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { _ in
            currentTime = Date()
            
            // 检查并更新预规划状态
            userState.checkAndUpdatePlannedState()
            
            // 触发UI更新，让displayEnergyLevel重新计算
            userState.objectWillChange.send()
        }
        
        // 立即执行一次检查
        userState.checkAndUpdatePlannedState()
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    // MARK: - 顶部状态区
    private var statusSection: some View {
        VStack(spacing: 0) {
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
                        // 短按：循环切换能量状态（高→中→低）
                        withAnimation(.easeInOut(duration: 0.3)) {
                            let newLevel: EnergyLevel
                            switch userState.energyLevel {
                            case .high:
                                newLevel = .medium
                            case .medium:
                                newLevel = .low
                            case .low:
                                newLevel = .high
                            case .unplanned:
                                newLevel = .high
                            }

                            // 更新状态并记录状态切换历史
                            userState.energyLevel = newLevel
                            userState.recordEnergyLevelChange(to: newLevel)
                            hasSwitchedFromUnplanned = true
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
                                    // 焦虑平复功能
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
                            
                            // TA状态 - 不可点击，仅显示
                            VStack(spacing: 4) {
                                // 小电池图标 - 无背景圆形
                                BatteryIconView(energyLevel: partnerState.energyLevel)
                                    .scaleEffect(0.6) // 缩小到60%
                                
                                Text("TA")
                                    .font(.system(size: AppTheme.FontSize.caption2, weight: .medium))
                                    .foregroundColor(AppTheme.Colors.textSecondary)
                            }
                        }
                        
                        // 第二行：快充模式 + 低电量模式
                        HStack(spacing: AppTheme.Spacing.lg) {
                            // 快充模式按钮
                            TemporaryStateButton(
                                stateType: .fastCharge,
                                isActive: userState.energyLevel == .high,
                                onShortPress: {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        userState.energyLevel = .high
                                        hasSwitchedFromUnplanned = true
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
                                isActive: userState.energyLevel == .low,
                                onShortPress: {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        userState.energyLevel = .low
                                        hasSwitchedFromUnplanned = true
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
        }
    }
    
    
    // MARK: - 功能卡片区
    private var functionCardsSection: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            ForEach(functionCards) { card in
                FunctionCardView(card: card)
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
            userState.energyLevel = level
            hasSwitchedFromUnplanned = true
        }
    }
}

// MARK: - 我的瞬间部分
struct MyMomentSection: View {
    var body: some View {
        NavigationLink(destination: MyMomentDetailView()) {
            VStack(spacing: AppTheme.Spacing.lg) {
                // 标题行
                HStack {
                    Text("我的瞬间")
                        .font(.system(size: AppTheme.FontSize.headline, weight: .semibold))
                        .foregroundColor(AppTheme.Colors.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: AppTheme.FontSize.caption))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                
                // 只展示两条数据
                VStack(spacing: AppTheme.Spacing.md) {
                    ForEach(0..<2) { index in
                        MomentItemView(index: index)
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
    
    private let fabItems = [
        ("发起邀请", "envelope", Color.blue),
        ("安心确认", "checkmark.circle", Color.green),
        ("赠送心意", "gift", Color.pink),
        ("分享碎片", "photo", Color.orange),
        ("发布瞬间", "camera", Color.purple)
    ]
    
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
                                // TODO: 实现具体功能
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
