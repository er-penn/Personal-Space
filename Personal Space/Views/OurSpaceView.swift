//
//  OurSpaceView.swift
//  Personal Space
//
//  Created by Penn on 2025/1/27.
//

import SwiftUI
import Combine

struct OurSpaceView: View {
    @EnvironmentObject var userState: UserState
    @EnvironmentObject var partnerState: PartnerState
    @EnvironmentObject var growthGarden: GrowthGarden
    @State private var showingCommonRecords = true

    // MARK: - 焦虑平复指南相关状态变量
    @State private var showingAnxietySoothingGuide = false
    @State private var showingDataDemo = false
    @State private var showingMoodReport = false // 情绪报告弹窗
    @State private var showingFragmentInbox = false // 碎片收件箱弹窗
    @State private var showingPartnerMoments = false // TA的瞬间弹窗
    
    // MARK: - Tab切换状态
    @State private var selectedTab: OurSpaceTab = .notifications
    @State private var tabContentHeight: CGFloat = 400 // 动态Tab内容高度
    
    // MARK: - 定时器相关状态变量
    @State private var timer: Timer?
    
    // Tab类型枚举
    enum OurSpaceTab: Int, CaseIterable, Identifiable {
        case notifications = 0  // 信息或提醒
        case pending = 1        // 待处理事项
        case myInitiated = 2    // 我发起的
        case partnerInfo = 3    // TA的信息
        
        var id: Int { rawValue }
        
        var title: String {
            switch self {
            case .notifications: return "信息或提醒"
            case .pending: return "待处理事项"
            case .myInitiated: return "我发起的"
            case .partnerInfo: return "TA的信息"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景渐变
                AppGradient.background
                    .ignoresSafeArea()
                
                // 外层ScrollView：整体可滚动
                ScrollView {
                    VStack(spacing: AppTheme.Spacing.lg) {
                        // 1. 顶部状态区（可滚动离开）
                        partnerStatusSection
                        
                        // 2. Tab标签栏（可滚动离开）
                        tabBarSection
                        
                        // 3. TabView内容区（固定高度，支持左右滑动）
                        tabContentSection
                        
                        // 4. 共同记录区（可滚动离开）
                        commonRecordsSection
                    }
                    .padding(.horizontal, AppTheme.Spacing.lg)
                    .padding(.top, AppTheme.Spacing.lg)
                    .padding(.bottom, AppTheme.Spacing.xl) // 底部留白
                }
                .onAppear {
                    userState.updatePendingClosures()
                    userState.cleanExpiredReminders() // 清理过期提醒
                    startTimer() // 启动定时器
                }
                .onDisappear {
                    stopTimer() // 停止定时器
                }
                
                // 调试按钮 - 仅在DEBUG模式显示
                #if DEBUG
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            showingDataDemo = true
                        }) {
                            Image(systemName: "gear")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue.opacity(0.8))
                                .clipShape(Circle())
                                .shadow(radius: 4)
                        }
                        .padding()
                    }
                }
                #endif
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingAnxietySoothingGuide) {
            AnxietySoothingGuideView()
        }
        .sheet(isPresented: $showingDataDemo) {
            ComprehensiveDataDemoView()
                .environmentObject(userState)
        }
        .sheet(isPresented: $showingMoodReport) {
            PartnerMoodReportDetailView()
        }
        .sheet(isPresented: $showingFragmentInbox) {
            FragmentInboxView()
                .environmentObject(userState)
        }
        .sheet(isPresented: $showingPartnerMoments) {
            PartnerMomentsView()
                .environmentObject(userState)
        }
    }
    
    // MARK: - 定时器管理（更新伴侣能量状态）
    private func startTimer() {
        stopTimer() // 先停止已存在的timer，避免重复创建
        
        // 每分钟更新一次，确保伴侣能量状态和能量条能够及时更新
        DispatchQueue.main.async {
            self.timer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { _ in
                // 1. 更新伴侣能量状态（触发电池图标更新）
                // 这里可以根据实际需求添加更新逻辑，目前先触发UI更新
                self.partnerState.objectWillChange.send()
                
                // 2. 触发能量条更新：通过更新partnerState来触发PartnerEnergyRecordView的onReceive
                // PartnerEnergyRecordView中的onReceive(partnerState.objectWillChange)会更新currentTime
                // 从而触发能量条重绘，更新当前时间指针位置
            }
            
            // 确保定时器在主线程的RunLoop中运行
            if let timer = self.timer {
                RunLoop.current.add(timer, forMode: .common)
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    // MARK: - 伴侣状态区（参考我的空间布局）
    private var partnerStatusSection: some View {
        VStack(spacing: AppTheme.Spacing.md) {  // ✅ lg (16px) → md (12px)
            // 主状态区域
            HStack(spacing: AppTheme.Spacing.lg) {
                // 1. 伴侣能量状态（电池图标设计 - 无背景，不可点击）
                VStack(spacing: AppTheme.Spacing.sm) {
                    // 电池图标（去掉圆形背景）
                    BatteryIconView(energyLevel: partnerState.energyLevel)
                        .scaleEffect(0.75)
                    
                    Text(partnerState.energyLevel.description)
                        .font(.system(size: AppTheme.FontSize.subheadline, weight: .semibold))
                        .foregroundColor(partnerState.energyLevel.color)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity)
                
                Spacer()
                
                // 右侧：快捷操作按钮
                HStack(spacing: AppTheme.Spacing.md) {
                    // 报告按钮
                    VStack(spacing: 4) {
                        Button(action: {
                            showingMoodReport = true
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color.pink.opacity(0.15))
                                    .frame(width: 50, height: 50)
                                
                                Image(systemName: "heart.text.square.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.pink)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        Text("报告")
                            .font(.system(size: AppTheme.FontSize.caption2, weight: .medium))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    
                    // 平复按钮
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
                }
            }
            
            // 伴侣能量记录进度条
            PartnerEnergyRecordView()
                .environmentObject(partnerState)
        }
        .frame(height: 140)  // ✅ 固定内容高度为140px（与"我的空间"一致）
        .padding(AppTheme.Spacing.xl)  // ✅ 使用xl (20px)，与"我的空间"一致
        .background(AppGradient.cardBackground)
        .cornerRadius(AppTheme.Radius.card)
        .shadow(color: AppTheme.Shadows.card, radius: 8, x: 0, y: 4)
        .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.card).stroke(AppTheme.Colors.border, lineWidth: 1))
    }
    
    // MARK: - 检查是否有伴侣能量规划
    private func hasPartnerEnergyPlan() -> Bool {
        // 模拟数据：假设伴侣有能量规划
        return true
    }
    
    // MARK: - Tab标签栏
    private var tabBarSection: some View {
        HStack(spacing: 0) {
            ForEach(OurSpaceTab.allCases) { tab in
                TabBarButton(
                    title: tab.title,
                    isSelected: selectedTab == tab,
                    action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTab = tab
                        }
                    }
                )
            }
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.sm)
        .background(Color(.systemBackground))
        .cornerRadius(AppTheme.Radius.medium)
        .shadow(color: AppTheme.Shadows.card, radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Tab内容区（动态高度，支持左右滑动）
    private var tabContentSection: some View {
        TabView(selection: $selectedTab) {
            // Tab 0: 信息或提醒
            notificationsPageView
                .tag(OurSpaceTab.notifications)
                .background(
                    GeometryReader { geo in
                        Color.clear.preference(
                            key: ViewHeightKey.self,
                            value: geo.size.height
                        )
                    }
                )
            
            // Tab 1: 待处理事项
            pendingItemsPageView
                .tag(OurSpaceTab.pending)
                .background(
                    GeometryReader { geo in
                        Color.clear.preference(
                            key: ViewHeightKey.self,
                            value: geo.size.height
                        )
                    }
                )
            
            // Tab 2: 我发起的
            myInitiatedPageView
                .tag(OurSpaceTab.myInitiated)
                .background(
                    GeometryReader { geo in
                        Color.clear.preference(
                            key: ViewHeightKey.self,
                            value: geo.size.height
                        )
                    }
                )
            
            // Tab 3: TA的信息
            partnerInfoPageView
                .tag(OurSpaceTab.partnerInfo)
                .background(
                    GeometryReader { geo in
                        Color.clear.preference(
                            key: ViewHeightKey.self,
                            value: geo.size.height
                        )
                    }
                )
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(height: tabContentHeight) // 使用动态高度
        .animation(.easeInOut(duration: 0.3), value: tabContentHeight)
        .onPreferenceChange(ViewHeightKey.self) { height in
            // 切换Tab时更新高度
            if height > 0 {
                tabContentHeight = max(height, 200) // 最小200pt
            }
        }
    }
    
    // MARK: - 页面1：信息或提醒
    private var notificationsPageView: some View {
        LazyVStack(spacing: 12) {
            if userState.notifications.isEmpty {
                Text("暂无信息或提醒")
                    .font(.system(size: AppTheme.FontSize.body))
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 500) // 占满整个高度
            } else {
                ForEach(userState.notifications) { notification in
                    NotificationInfoCard(notification: notification)
                }
            }
        }
        .padding(.vertical, AppTheme.Spacing.md)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - 页面2：待处理事项
    private var pendingItemsPageView: some View {
        LazyVStack(spacing: 12) {
            // 显示待处理的协作邀请
            ForEach(userState.invitations.filter { $0.createdBy == "partner" && $0.status == .pending }) { invitation in
                CollaborationInvitationCard(invitation: invitation)
            }

            // 显示待处理的安心确认
            ForEach(userState.pendingClosures) { closure in
                PendingPeacefulClosureCardView(closure: closure) { response in
                    userState.respondToClosure(closure, response: response)
                }
            }

            // 显示待处理的心意盒
            ForEach(userState.pendingGiftBoxes.filter { !$0.isFromMe }) { giftBox in
                PendingGiftBoxCardView(giftBox: giftBox) { response in
                    userState.respondToGiftBox(giftBox, response: response)
                }
            }
            
            // 空状态
            let partnerInvitations = userState.invitations.filter { $0.createdBy == "partner" && $0.status == .pending }
            let pendingGiftBoxesFromPartner = userState.pendingGiftBoxes.filter { !$0.isFromMe }

            if userState.pendingClosures.isEmpty && partnerInvitations.isEmpty && pendingGiftBoxesFromPartner.isEmpty {
                Text("暂无待处理事项")
                    .font(.system(size: AppTheme.FontSize.body))
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 500) // 占满整个高度
            }
        }
        .padding(.vertical, AppTheme.Spacing.md)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - 页面3：我发起的
    private var myInitiatedPageView: some View {
        LazyVStack(spacing: 12) {
            // 显示我发起的协作邀请
            ForEach(userState.myInvitations) { invitation in
                CollaborationInvitationCard(invitation: invitation)
            }

            // 显示我发起的安心确认
            ForEach(userState.myClosures.filter { $0.status != .archived && $0.status != .cancelled }) { closure in
                PeacefulClosureCardView(
                    closure: closure,
                    onTap: {
                        // 可以点击查看详情，但暂时为空
                    },
                    onCancel: { closureToCancel in
                        userState.cancelClosure(closureToCancel)
                    },
                    isMyClosure: true
                )
            }

            // 显示我发起的心意盒（按最新活动时间倒序）
            ForEach(userState.myGiftBoxes.sorted(by: { $0.lastActivityTime > $1.lastActivityTime })) { giftBox in
                MyInitiatedGiftBoxCard(giftBox: giftBox)
            }

            // 显示我分享的碎片
            ForEach(userState.fragments.filter { $0.isFromMe }) { fragment in
                FragmentCard(fragment: fragment)
            }
            
            // 空状态
            let activeMyClosures = userState.myClosures.filter { $0.status != .archived && $0.status != .cancelled }
            let myFragments = userState.fragments.filter { $0.isFromMe }

            if activeMyClosures.isEmpty && userState.myInvitations.isEmpty && userState.myGiftBoxes.isEmpty && myFragments.isEmpty {
                Text("暂无发起事项")
                    .font(.system(size: AppTheme.FontSize.body))
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 400) // 占满基本高度
            }
        }
        .padding(.vertical, AppTheme.Spacing.md)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - 页面4：TA的信息
    private var partnerInfoPageView: some View {
        VStack(spacing: 12) {
            // 情绪报告
            PartnerMoodReportCard()
            
            // 碎片收件箱
            if userState.displayEnergyLevel == .high {
                Button(action: {
                    showingFragmentInbox = true
                }) {
                    PartnerInfoCard(
                        title: "TA的分享",
                        icon: "photo.on.rectangle.angled",
                        color: .orange,
                        content: userState.receivedFragments.isEmpty ? "暂无分享" : "有\(userState.receivedFragments.count)条分享"
                    )
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                PartnerInfoCard(
                    title: "TA的分享",
                    icon: "photo.on.rectangle.angled",
                    color: .gray,
                    content: "🟢状态时可查看"
                )
                .opacity(0.6)
            }
            
            // TA的瞬间
            if userState.displayEnergyLevel != .low {
                Button(action: {
                    showingPartnerMoments = true
                }) {
                    PartnerInfoCard(
                        title: "TA的瞬间",
                        icon: "photo.on.rectangle.angled",
                        color: .purple,
                        content: userState.partnerMoments.isEmpty ? "暂无瞬间" : "有\(userState.partnerMoments.count)条瞬间"
                    )
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                PartnerInfoCard(
                    title: "TA的瞬间",
                    icon: "photo.on.rectangle.angled",
                    color: .gray,
                    content: "🔴状态时不可访问"
                )
                .opacity(0.6)
            }
            
            Spacer() // 填充剩余空间
        }
        .padding(.vertical, AppTheme.Spacing.md)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - 旧的信息列表区（已废弃，改用Tab方式）
    private var informationListSection_deprecated: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 信息或提醒模块
            if !userState.notifications.isEmpty {
                Text("信息或提醒")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                LazyVStack(spacing: 12) {
                    ForEach(userState.notifications.prefix(5)) { notification in
                        NotificationInfoCard(notification: notification)
                    }
                }
                
                Divider()
                    .padding(.vertical, 8)
            }
            
            Text("待处理事项")
                .font(.headline)
                .foregroundColor(.secondary)

            LazyVStack(spacing: 12) {
                // 显示待处理的协作邀请
                ForEach(userState.invitations.filter { $0.createdBy == "partner" }) { invitation in
                    CollaborationInvitationCard(invitation: invitation)
                }

                // 显示待处理的安心确认
                ForEach(userState.pendingClosures) { closure in
                    PendingPeacefulClosureCardView(closure: closure) { response in
                        userState.respondToClosure(closure, response: response)
                    }
                }

                // 显示待处理的心意盒
                ForEach(userState.pendingGiftBoxes.filter { !$0.isFromMe }) { giftBox in
                    PendingGiftBoxCardView(giftBox: giftBox) { response in
                        userState.respondToGiftBox(giftBox, response: response)
                    }
                }
            }

            let partnerInvitations = userState.invitations.filter { $0.createdBy == "partner" }
            let pendingGiftBoxesFromPartner = userState.pendingGiftBoxes.filter { !$0.isFromMe }

            if userState.pendingClosures.isEmpty && partnerInvitations.isEmpty && pendingGiftBoxesFromPartner.isEmpty {
                Text("暂无待处理事项")
                    .font(.system(size: AppTheme.FontSize.body))
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppTheme.Spacing.xl)
            }

            Divider()
                .padding(.vertical, 8)

            Text("我发起的")
                .font(.headline)
                .foregroundColor(.secondary)

            LazyVStack(spacing: 12) {
                // 显示我发起的协作邀请
                ForEach(userState.myInvitations) { invitation in
                    CollaborationInvitationCard(invitation: invitation)
                }

                // 显示我发起的安心确认
                ForEach(userState.myClosures.filter { $0.status != .archived && $0.status != .cancelled }) { closure in
                    PeacefulClosureCardView(
                        closure: closure,
                        onTap: {
                            // 可以点击查看详情，但暂时为空
                        },
                        onCancel: { closureToCancel in
                            userState.cancelClosure(closureToCancel)
                        },
                        isMyClosure: true
                    )
                }

                // 显示我发起的心意盒
                ForEach(userState.myGiftBoxes.prefix(3)) { giftBox in
                    MyGiftBoxCardView(giftBox: giftBox)
                }

                // 显示我分享的碎片
                ForEach(userState.fragments.filter { $0.isFromMe }.prefix(3)) { fragment in
                    FragmentCard(fragment: fragment)
                }
            }

            let activeMyClosures = userState.myClosures.filter { $0.status != .archived && $0.status != .cancelled }
            let myFragments = userState.fragments.filter { $0.isFromMe }

            if activeMyClosures.isEmpty && userState.myInvitations.isEmpty && userState.myGiftBoxes.isEmpty && myFragments.isEmpty {
                Text("暂无发起事项")
                    .font(.system(size: AppTheme.FontSize.body))
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppTheme.Spacing.xl)
            }
        }
        .padding(AppTheme.Spacing.lg)
        .background(AppGradient.cardBackground)
        .cornerRadius(AppTheme.Radius.card)
        .shadow(
            color: AppTheme.Shadows.card,
            radius: 8,
            x: 0,
            y: 4
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                .stroke(AppTheme.Colors.border, lineWidth: 1)
        )
        .onAppear {
            userState.updatePendingClosures()
            userState.cleanExpiredReminders() // 清理过期提醒
        }
    }
    
    // MARK: - 共同记录区
    private var commonRecordsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showingCommonRecords.toggle()
                }
            }) {
                HStack {
                    Text("共同记录")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Image(systemName: showingCommonRecords ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            if showingCommonRecords {
                VStack(spacing: 16) {
                    // 连接计划（协作邀请记录）
                    ConnectionPlanCard()

                    // Maybe清单
                    MaybeListCard()

                    // 成长花园
                    GrowthGardenCard()
                }
            }
        }
        .padding(AppTheme.Spacing.lg)
        .background(AppGradient.cardBackground)
        .cornerRadius(AppTheme.Radius.card)
        .shadow(
            color: AppTheme.Shadows.card,
            radius: 8,
            x: 0,
            y: 4
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                .stroke(AppTheme.Colors.border, lineWidth: 1)
        )
    }
}

// MARK: - 我的心意盒部分
struct MyGiftBoxSection: View {
    @EnvironmentObject var userState: UserState
    @State private var showingManageView = false
    @State private var isExpanded = true

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Image(systemName: "gift.fill")
                        .font(.title3)
                        .foregroundColor(.pink)

                    Text("我的心意盒")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(PlainButtonStyle())

            if isExpanded {
                if userState.myGiftBoxes.isEmpty {
                    Text("暂无心意盒")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppTheme.Spacing.xl)
                } else {
                    // 显示前3个心意盒
                    VStack(spacing: 8) {
                        ForEach(Array(userState.myGiftBoxes.prefix(3)), id: \.id) { giftBox in
                            HStack {
                                Image(systemName: "gift.fill")
                                    .font(.caption)
                                    .foregroundColor(.pink)

                                Text(giftBox.item)
                                    .font(.subheadline)
                                    .lineLimit(1)

                                Spacer()

                                Text(giftBox.status.displayText)
                                    .font(.caption)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(giftBox.status.color.opacity(0.2))
                                    .cornerRadius(4)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(.systemBackground))
                            .cornerRadius(8)
                        }

                        if userState.myGiftBoxes.count > 3 {
                            Button("查看全部 (\(userState.myGiftBoxes.count) 个)") {
                                showingManageView = true
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        .sheet(isPresented: $showingManageView) {
            GiftBoxManageView()
                .environmentObject(userState)
        }
    }
}

// MARK: - 待处理心意盒卡片
struct PendingGiftBoxCardView: View {
    let giftBox: GiftBox
    let onResponse: (GiftBoxResponse) -> Void

    @State private var showingResponseView = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // 类型标签（图标+文字，粉色）
                HStack(spacing: 4) {
                    Image(systemName: "gift.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.pink)
                    
                    Text("心意")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.pink)
                }
                .frame(width: 50, alignment: .leading)

                Text(giftBox.item)
                    .font(.system(size: AppTheme.FontSize.body, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.text)
                    .lineLimit(1)

                Spacer()

                Text("待处理")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.2))
                    .cornerRadius(8)
            }

            Text("建议地点: \(giftBox.suggestedLocation)")
                .font(.subheadline)
                .foregroundColor(.secondary)

            if let note = giftBox.note, !note.isEmpty {
                Text("备注: \(note)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 12) {
                Button("好滴收下啦🥰") {
                    showingResponseView = true
                }
                .font(.subheadline)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.green)
                .cornerRadius(8)

                Button("不太想要😅") {
                    onResponse(.rejected)
                }
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)

                Spacer()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        .sheet(isPresented: $showingResponseView) {
            GiftBoxResponseView(giftBox: giftBox)
                .environmentObject(UserState())
        }
    }
}

// MARK: - 我的心意盒卡片
struct MyGiftBoxCardView: View {
    let giftBox: GiftBox
    @State private var showingManageView = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "gift.fill")
                    .foregroundColor(.pink)

                Text("心意盒")
                    .font(.subheadline)
                    .font(.subheadline.weight(.medium))

                Spacer()

                Text(giftBox.status.displayText)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(giftBox.status.color.opacity(0.2))
                    .cornerRadius(8)
            }

            Text(giftBox.item)
                .font(.headline)

            Text("建议地点: \(giftBox.suggestedLocation)")
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack {
                Text("查看详情")
                    .font(.caption)
                    .foregroundColor(.blue)

                Spacer()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        .onTapGesture {
            showingManageView = true
        }
        .sheet(isPresented: $showingManageView) {
            GiftBoxManageView()
                .environmentObject(UserState())
        }
    }
}

// 旧的PeacefulClosureCard已移除，使用新的PeacefulClosureCardView组件

// MARK: - 心意盒卡片（旧版本，已废弃）
struct GiftBoxCard: View {
    let giftBox: GiftBox
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "gift.fill")
                    .foregroundColor(.pink)
                
                Text("心意盒")
                    .font(.subheadline)
                    .font(.subheadline.weight(.medium))
                
                Spacer()
                
                Text(giftBox.status.displayText)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(giftBox.status.color.opacity(0.2))
                    .cornerRadius(8)
            }
            
            Text(giftBox.item)
                .font(.headline)
            
            Text("建议地点: \(giftBox.suggestedLocation)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if let note = giftBox.note, !note.isEmpty {
                Text("备注: \(note)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if giftBox.status == .pending && !giftBox.isFromMe {
                Button("查看详情") {
                    // TODO: 打开响应页面
                }
                .font(.subheadline)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.pink)
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

// MARK: - 碎片卡片
struct FragmentCard: View {
    let fragment: Fragment
    @EnvironmentObject var userState: UserState
    @State private var showingWithdrawAlert = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // 类型标签（图标+文字）
                HStack(spacing: 4) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 14))
                        .foregroundColor(.orange)
                    
                    Text("碎片")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.orange)
                }
                .frame(width: 50, alignment: .leading)
                
                Text(fragment.content)
                    .font(.system(size: AppTheme.FontSize.body, weight: .medium))
                    .foregroundColor(AppTheme.Colors.text)
                    .lineLimit(1)
                
                Spacer()
                
                // 已读/未读状态
                HStack(spacing: 4) {
                    Image(systemName: fragment.isRead ? "eye.fill" : "eye.slash")
                        .font(.system(size: 12))
                        .foregroundColor(fragment.isRead ? .blue : .gray)
                    
                    Text(fragment.isRead ? "已读" : "未读")
                        .font(.system(size: AppTheme.FontSize.caption2))
                        .foregroundColor(fragment.isRead ? .blue : .gray)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background((fragment.isRead ? Color.blue : Color.gray).opacity(0.1))
                .cornerRadius(6)
            }
            
            // 链接（如果有）
            if let linkURL = fragment.linkURL {
                HStack(spacing: 4) {
                    Image(systemName: "link")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    Text(linkURL)
                        .font(.system(size: AppTheme.FontSize.caption))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .lineLimit(1)
                }
            }
            
            // 时间信息
            Text(formatDate(fragment.createdAt))
                .font(.system(size: AppTheme.FontSize.caption2))
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.cardBg)
        .cornerRadius(AppTheme.Radius.medium)
        .shadow(color: AppTheme.Shadows.card, radius: 2, x: 0, y: 1)
        .contextMenu {
            if !fragment.isRead {
                Button {
                    showingWithdrawAlert = true
                } label: {
                    Label("撤回（对方未读）", systemImage: "arrow.uturn.backward")
                }
            }
            
            Button(role: .destructive) {
                showingDeleteAlert = true
            } label: {
                Label("删除", systemImage: "trash")
            }
        }
        .alert("确认撤回", isPresented: $showingWithdrawAlert) {
            Button("取消", role: .cancel) { }
            Button("撤回", role: .destructive) {
                let success = userState.withdrawFragment(fragment)
                if !success {
                    // 显示错误提示
                    print("撤回失败")
                }
            }
        } message: {
            Text("撤回后对方将看不到这条碎片")
        }
        .alert("确认删除", isPresented: $showingDeleteAlert) {
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) {
                userState.deleteFragment(fragment)
            }
        } message: {
            Text("删除后您也将看不到这条碎片\n如果对方已读，对方仍可查看")
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - 伴侣信息卡片
struct PartnerInfoCard: View {
    let title: String
    let icon: String
    let color: Color
    let content: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .font(.subheadline.weight(.medium))
                
                Text(content)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Maybe清单卡片
struct MaybeListCard: View {
    @State private var maybeListItems: [(title: String, description: String, location: String)] = []
    @State private var showingEditor = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "list.bullet")
                    .foregroundColor(.blue)
                
                Text("Maybe清单")
                    .font(.subheadline)
                    .font(.subheadline.weight(.medium))
                
                Spacer()
                
                Button("编辑") {
                    showingEditor = true
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(0..<min(5, maybeListItems.count), id: \.self) { index in
                    let item = maybeListItems[index]
                    HStack {
                        Text("•")
                            .foregroundColor(.secondary)
                        Text(item.title)
                            .font(.subheadline)
                        Spacer()
                    }
                }

                if maybeListItems.count > 5 {
                    HStack {
                        Text("...")
                            .foregroundColor(.secondary)
                        Text("还有 \(maybeListItems.count - 5) 项")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .onAppear {
            loadMaybeList()
        }
        .sheet(isPresented: $showingEditor) {
            MaybeListEditorView(items: $maybeListItems, isPresented: $showingEditor)
        }
    }

    private func loadMaybeList() {
        maybeListItems = [
            ("周末看电影", "一起去看最新上映的电影，然后吃晚饭", "万达影城"),
            ("公园散步", "在附近公园散步，呼吸新鲜空气", "中山公园"),
            ("咖啡店聊天", "找个安静的咖啡店，好好聊聊天", "星巴克"),
            ("一起做饭", "在家一起准备晚餐，享受烹饪乐趣", "家里"),
            ("去海边", "去海边看日落，听听海浪声", "海边栈道"),
            ("逛书店", "在书店里慢慢翻书，找找感兴趣的读物", "西西弗书店"),
            ("打保龄球", "来一场有趣的保龄球比赛，看谁得分更高", "汤姆熊保龄球馆"),
            ("看画展", "一起去看艺术展览，感受文化的熏陶", "市美术馆"),
            ("爬山运动", "周末去爬爬山，锻炼身体，亲近自然", "西山公园"),
            ("桌游吧", "玩各种有趣的桌面游戏，增进彼此默契", "欢乐桌游吧"),
            ("DIY烘焙", "一起制作美味的糕点，享受甜蜜时光", "手工烘焙坊"),
            ("骑单车", "沿着河边骑行，感受微风和阳光", "滨江路自行车道"),
            ("听音乐会", "一起去听现场音乐会，享受音乐的魅力", "音乐厅"),
            ("游乐园", "去游乐园玩各种刺激的项目，释放压力", "欢乐谷"),
            ("博物馆参观", "参观历史博物馆，学习新知识", "市博物馆")
        ]
    }
}

// MARK: - Maybe清单编辑数据（符合Identifiable）
struct MaybeListEditingData: Identifiable {
    let id = UUID()
    let index: Int
    let item: (title: String, description: String, location: String)
}

// MARK: - Maybe清单编辑器
struct MaybeListEditorView: View {
    @Binding var items: [(title: String, description: String, location: String)]
    @Binding var isPresented: Bool
    @State private var showingAddItem = false
    @State private var editingItem: MaybeListEditingData? = nil
    @State private var showingDeleteAlert = false
    @State private var itemToDelete: Int? = nil

    var body: some View {
        NavigationView {
            List {
                ForEach(0..<items.count, id: \.self) { index in
                    let item = items[index]
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(item.title)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.primary)
                            Spacer()
                        }

                        Text(item.description)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .lineLimit(2)

                        HStack {
                            Image(systemName: "location")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                            Text(item.location)
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                    }
                    .padding(.vertical, 4)
                    .background(Color.clear)
                    .contextMenu {
                        Button(action: {
                            editingItem = MaybeListEditingData(index: index, item: item)
                        }) {
                            Label("编辑", systemImage: "pencil")
                        }

                        Button(role: .destructive, action: {
                            itemToDelete = index
                            showingDeleteAlert = true
                        }) {
                            Label("删除", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle("Maybe清单-编辑")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        isPresented = false
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddItem = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddItem) {
            MaybeItemEditView(
                item: ("", "", ""),
                onSave: { newItem in
                    items.append(newItem)
                    showingAddItem = false
                },
                onCancel: {
                    showingAddItem = false
                }
            )
        }
        .sheet(item: $editingItem) { editingData in
            MaybeItemEditView(
                item: editingData.item,
                onSave: { updatedItem in
                    items[editingData.index] = updatedItem
                    editingItem = nil
                },
                onCancel: {
                    editingItem = nil
                }
            )
        }
        .alert("确认删除", isPresented: $showingDeleteAlert) {
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) {
                if let index = itemToDelete {
                    items.remove(at: index)
                    itemToDelete = nil
                }
            }
        } message: {
            Text("确定要删除这个活动吗？")
        }
    }
}

// MARK: - Maybe活动编辑器
struct MaybeItemEditView: View {
    let item: (title: String, description: String, location: String)
    let onSave: ((title: String, description: String, location: String)) -> Void
    let onCancel: () -> Void

    @State private var title: String
    @State private var description: String
    @State private var location: String

    init(item: (title: String, description: String, location: String), onSave: @escaping ((title: String, description: String, location: String)) -> Void, onCancel: @escaping () -> Void) {
        self.item = item
        self.onSave = onSave
        self.onCancel = onCancel

        _title = State(initialValue: item.title)
        _description = State(initialValue: item.description)
        _location = State(initialValue: item.location)
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("活动内容 *")) {
                    TextField("请输入活动内容", text: $title)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }

                Section(header: Text("活动描述 (选填)")) {
                    if #available(iOS 16.0, *) {
                        TextField("请描述活动内容", text: $description, axis: .vertical)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .lineLimit(3...6)
                    } else {
                        TextEditor(text: $description)
                            .frame(minHeight: 80, maxHeight: 120)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }
                }

                Section(header: Text("活动地点 (选填)")) {
                    TextField("请输入活动地点", text: $location)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
            }
            .navigationTitle(item.title.isEmpty ? "新增活动" : "编辑活动")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        onCancel()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        onSave((
                            title.trimmingCharacters(in: .whitespacesAndNewlines),
                            description.trimmingCharacters(in: .whitespacesAndNewlines),
                            location.trimmingCharacters(in: .whitespacesAndNewlines)
                        ))
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

// MARK: - 成长花园卡片
struct GrowthGardenCard: View {
    @EnvironmentObject var growthGarden: GrowthGarden
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "leaf")
                    .foregroundColor(.green)
                
                Text("成长花园")
                    .font(.subheadline)
                    .font(.subheadline.weight(.medium))
                
                Spacer()
            }
            
            HStack(spacing: 20) {
                VStack {
                    Text("🌱")
                        .font(.system(size: 40))
                    
                    Text("植物等级 \(growthGarden.plantLevel)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("水分：\(growthGarden.waterLevel)/10")
                        .font(.subheadline)
                    
                    ProgressView(value: Double(growthGarden.waterLevel), total: 10)
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    
                    Button("浇水") {
                        growthGarden.water()
                    }
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue)
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

// MARK: - 伴侣能量规划进度条
// MARK: - 伴侣能量记录视图（参考EnergyProgressView设计）
struct PartnerEnergyRecordView: View {
    @EnvironmentObject var partnerState: PartnerState
    @State private var currentTime: Date = Date() // 当前时间状态，用于触发视图更新
    
    private let hours = Array(7...23) // 7点到23点
    
    var body: some View {
        VStack(spacing: 6) {  // ✅ 调整间距 8px → 6px
            // 时间标签和竖标 - 使用GeometryReader精确定位
            GeometryReader { geometry in
                ZStack {
                    // 时间标签：7点、10点、14点、18点、22点
                    ForEach([7, 10, 14, 18, 22], id: \.self) { hour in
                        VStack(spacing: 0) {
                            // 时间标签
                            Text("\(hour):00")
                                .font(.system(size: AppTheme.FontSize.caption))
                                .foregroundColor(AppTheme.Colors.textSecondary)
                            
                            // 竖标：从标签延伸到能量块左边缘
                            Rectangle()
                                .fill(AppTheme.Colors.textSecondary.opacity(0.3))
                                .frame(width: 1, height: 8)
                        }
                        .position(
                            x: getTimeLabelPosition(for: hour, in: geometry.size.width),
                            y: 10 // 时间标签的垂直位置
                        )
                    }
                }
            }
            .frame(height: 20)
            
            // 进度条 - 按分钟级显示
            GeometryReader { geometry in
                HStack(spacing: 0.5) {
                    ForEach(hours, id: \.self) { hour in
                        PartnerEnergyHourBlock(
                            hour: hour,
                            width: geometry.size.width / CGFloat(hours.count),
                            height: 20,
                            partnerState: partnerState
                        )
                    }
                }
                .background(Color.gray.opacity(0.2))
                .cornerRadius(4)
                
                // 当前时间指示器 - 在7:00-23:59显示
                if getCurrentTime().hour >= 7 && getCurrentTime().hour <= 23 {
                    Rectangle()
                        .fill(AppTheme.Colors.text)
                        .frame(width: 2, height: 20)
                        .offset(x: getCurrentTimeOffset(width: geometry.size.width))
                }
            }
            .frame(height: 20)
        }
        .onAppear {
            // 初始化当前时间
            currentTime = Date()
        }
        .onReceive(partnerState.objectWillChange) { _ in
            // 当partnerState更新时（包括timer触发），更新当前时间以触发能量条重绘
            currentTime = Date()
        }
    }
    
    private func getCurrentTime() -> (hour: Int, minute: Int) {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: currentTime)
        let minute = calendar.component(.minute, from: currentTime)
        return (hour, minute)
    }
    
    private func getCurrentTimeOffset(width: CGFloat) -> CGFloat {
        let currentTime = getCurrentTime()
        let currentHour = currentTime.hour
        let currentMinute = currentTime.minute
        
        // 在7:00-23:59区间内
        if currentHour >= 7 && currentHour <= 23 {
            let totalMinutes = (currentHour - 7) * 60 + currentMinute
            let totalRangeMinutes = 17 * 60 // 7:00-23:59共17小时
            return width * CGFloat(totalMinutes) / CGFloat(totalRangeMinutes)
        }
        
        return 0
    }
    
    // 计算时间标签的位置
    private func getTimeLabelPosition(for hour: Int, in totalWidth: CGFloat) -> CGFloat {
        let hourIndex = hour - 7 // 7点对应索引0
        let blockWidth = totalWidth / CGFloat(hours.count)
        let spacing: CGFloat = 0.5 // 块之间的间距
        return blockWidth * CGFloat(hourIndex) + spacing * CGFloat(hourIndex)
    }
}

// MARK: - 伴侣能量小时块（分钟级显示）
struct PartnerEnergyHourBlock: View {
    let hour: Int
    let width: CGFloat
    let height: CGFloat
    @ObservedObject var partnerState: PartnerState
    
    // 合并后的块信息
    struct MergedBlock: Identifiable {
        let id = UUID()
        let startMinute: Int
        let endMinute: Int
        let color: Color
        
        var minuteCount: Int {
            return endMinute - startMinute + 1
        }
    }
    
    var body: some View {
        let mergedBlocks = getMergedBlocks()
        
        return HStack(spacing: 0) {
            ForEach(mergedBlocks) { block in
                Rectangle()
                    .fill(block.color)
                    .frame(width: width * CGFloat(block.minuteCount) / 60.0, height: height)
            }
        }
        .cornerRadius(2)
    }
    
    // 获取合并后的能量块
    private func getMergedBlocks() -> [MergedBlock] {
        var blocks: [MergedBlock] = []
        
        // 获取第一分钟的颜色
        var currentColor = getEnergyColor(for: 0)
        var startMinute = 0
        
        // 遍历所有分钟
        for minute in 1..<60 {
            let color = getEnergyColor(for: minute)
            
            if color != currentColor {
                // 颜色改变，保存当前块
                blocks.append(MergedBlock(
                    startMinute: startMinute,
                    endMinute: minute - 1,
                    color: currentColor
                ))
                
                // 开始新块
                startMinute = minute
                currentColor = color
            }
        }
        
        // 添加最后一个块（包含最后一分钟）
        blocks.append(MergedBlock(
            startMinute: startMinute,
            endMinute: 59,
            color: currentColor
        ))
        
        return blocks
    }
    
    // 获取指定分钟的能量颜色
    private func getEnergyColor(for minute: Int) -> Color {
        let calendar = Calendar.current
        let now = Date()
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)
        
        // 当前时间之前：显示伴侣的历史状态（模拟为当前状态）
        if hour < currentHour || (hour == currentHour && minute <= currentMinute) {
            return partnerState.energyLevel.color
        }
        
        // 当前时间之后：显示灰色（未来）
        return EnergyLevel.unplanned.color
    }
}

// MARK: - 连接计划卡片
struct ConnectionPlanCard: View {
    @State private var connectionPlans: [ConnectionPlan] = [
        ConnectionPlan(
            title: "周末一起看电影",
            content: "最近上映了一部不错的电影，要不要一起去看？",
            status: .completed,
            createdAt: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date(),
            completedAt: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        ),
        ConnectionPlan(
            title: "一起去公园散步",
            content: "天气不错，要不要去公园走走？",
            status: .inProgress,
            createdAt: Calendar.current.date(byAdding: .hour, value: -3, to: Date()) ?? Date(),
            completedAt: nil
        ),
        ConnectionPlan(
            title: "学习做一道新菜",
            content: "一起尝试做那道你一直想学的菜",
            status: .scheduled,
            createdAt: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date(),
            completedAt: nil
        )
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "link")
                    .foregroundColor(.blue)
                
                Text("连接计划")
                    .font(.system(size: AppTheme.FontSize.headline, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.primary)
                
                Spacer()
                
                Text("\(connectionPlans.count)项")
                    .font(.system(size: AppTheme.FontSize.caption))
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            
            VStack(spacing: 8) {
                ForEach(connectionPlans) { plan in
                    ConnectionPlanItem(plan: plan)
                }
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.cardBg)
        .cornerRadius(AppTheme.Radius.medium)
        .shadow(color: AppTheme.Shadows.card, radius: 4, x: 0, y: 2)
    }
}

// MARK: - 连接计划数据模型
struct ConnectionPlan: Identifiable {
    let id = UUID()
    let title: String
    let content: String
    let status: ConnectionPlanStatus
    let createdAt: Date
    let completedAt: Date?
}

enum ConnectionPlanStatus {
    case scheduled    // 已安排
    case inProgress   // 进行中
    case completed    // 已完成
    
    var color: Color {
        switch self {
        case .scheduled: return .orange
        case .inProgress: return .blue
        case .completed: return .green
        }
    }
    
    var icon: String {
        switch self {
        case .scheduled: return "clock"
        case .inProgress: return "play.circle"
        case .completed: return "checkmark.circle"
        }
    }
    
    var text: String {
        switch self {
        case .scheduled: return "已安排"
        case .inProgress: return "进行中"
        case .completed: return "已完成"
        }
    }
}

// MARK: - 连接计划条目
struct ConnectionPlanItem: View {
    let plan: ConnectionPlan
    
    var body: some View {
        HStack(spacing: 12) {
            // 状态图标
            Image(systemName: plan.status.icon)
                .font(.system(size: 16))
                .foregroundColor(plan.status.color)
                .frame(width: 20)
            
            // 内容
            VStack(alignment: .leading, spacing: 4) {
                Text(plan.title)
                    .font(.system(size: AppTheme.FontSize.body, weight: .medium))
                    .foregroundColor(AppTheme.Colors.text)
                    .lineLimit(1)
                
                Text(plan.content)
                    .font(.system(size: AppTheme.FontSize.caption))
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // 状态标签
            Text(plan.status.text)
                .font(.system(size: AppTheme.FontSize.caption2))
                .foregroundColor(plan.status.color)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(plan.status.color.opacity(0.1))
                .cornerRadius(4)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 伴侣情绪报告卡片
struct PartnerMoodReportCard: View {
    // 模拟数据
    @State private var pressureTotal: Double = 7.2  // TA的压力总分（10分制）
    @State private var nonRelationshipPressure: Double = 4.1  // 来自非关系的部分（5分制）
    @State private var relationshipPressure: Double = 3.1  // 来自关系的部分（5分制）
    @State private var nonRelationshipAnxiety: Double = 6.8  // TA的非关系焦虑值（10分制）
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(.pink)
                
                Text("情绪报告")
                    .font(.system(size: AppTheme.FontSize.headline, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.primary)
                
                Spacer()
                
                Text("刚刚更新")
                    .font(.system(size: AppTheme.FontSize.caption2))
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            
            VStack(spacing: 16) {
                // 1️⃣ TA的压力总分（10分制）
                PressureScoreView(
                    title: "压力总分",
                    score: pressureTotal,
                    maxScore: 10.0,
                    color: getPressureColor(pressureTotal),
                    isMainScore: true
                )
                
                // 子项分解
                VStack(spacing: 8) {
                    // 2️⃣ 来自非关系的部分（5分制）
                    PressureScoreView(
                        title: "非关系压力",
                        score: nonRelationshipPressure,
                        maxScore: 5.0,
                        color: getPressureColor(nonRelationshipPressure * 2), // 转换为10分制颜色
                        isMainScore: false
                    )
                    
                    // 3️⃣ 来自关系的部分（5分制）
                    PressureScoreView(
                        title: "关系压力",
                        score: relationshipPressure,
                        maxScore: 5.0,
                        color: getPressureColor(relationshipPressure * 2), // 转换为10分制颜色
                        isMainScore: false
                    )
                }
                .padding(.leading, 16) // 缩进显示主次关系
                
                // 4️⃣ TA的非关系焦虑值（10分制）
                PressureScoreView(
                    title: "非关系焦虑",
                    score: nonRelationshipAnxiety,
                    maxScore: 10.0,
                    color: getAnxietyColor(nonRelationshipAnxiety),
                    isMainScore: true
                )
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.cardBg)
        .cornerRadius(AppTheme.Radius.medium)
        .shadow(color: AppTheme.Shadows.card, radius: 4, x: 0, y: 2)
    }
    
    private func getPressureColor(_ score: Double) -> Color {
        switch score {
        case 0..<3: return .green
        case 3..<6: return .yellow
        case 6..<8: return .orange
        default: return .red
        }
    }
    
    private func getAnxietyColor(_ score: Double) -> Color {
        switch score {
        case 0..<3: return .green
        case 3..<6: return .yellow
        case 6..<8: return .orange
        default: return .red
        }
    }
}

// MARK: - 压力分数视图
struct PressureScoreView: View {
    let title: String
    let score: Double
    let maxScore: Double
    let color: Color
    let isMainScore: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.system(size: isMainScore ? AppTheme.FontSize.body : AppTheme.FontSize.caption, weight: .medium))
                    .foregroundColor(AppTheme.Colors.text)
                
                Spacer()
                
                Text("\(String(format: "%.1f", score))/\(String(format: "%.0f", maxScore))")
                    .font(.system(size: isMainScore ? AppTheme.FontSize.body : AppTheme.FontSize.caption, weight: .semibold))
                    .foregroundColor(color)
            }
            
            // 进度条
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // 背景
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: isMainScore ? 8 : 6)
                        .cornerRadius(isMainScore ? 4 : 3)
                    
                    // 进度
                    Rectangle()
                        .fill(color)
                        .frame(width: geometry.size.width * (score / maxScore), height: isMainScore ? 8 : 6)
                        .cornerRadius(isMainScore ? 4 : 3)
                        .animation(.easeInOut(duration: 0.3), value: score)
                }
            }
            .frame(height: isMainScore ? 8 : 6)
        }
    }
}

// MARK: - 协作邀请卡片
struct CollaborationInvitationCard: View {
    let invitation: CollaborationInvitation
    @EnvironmentObject var userState: UserState
    @State private var showingResponseView = false
    
    var body: some View {
        Button(action: {
            // 只有待处理的邀请才能点击响应
            if invitation.status == .pending {
                showingResponseView = true
            }
        }) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                // 标题和状态
                HStack {
                    // 类型标签（图标+文字，紫色）
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.system(size: 14))
                            .foregroundColor(.purple)
                        
                        Text("邀请")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.purple)
                    }
                    .frame(width: 50, alignment: .leading)
                    
                    Text(invitation.title)
                        .font(.system(size: AppTheme.FontSize.body, weight: .semibold))
                        .foregroundColor(AppTheme.Colors.text)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    // 状态标签
                    Text(invitation.status.rawValue)
                        .font(.system(size: AppTheme.FontSize.caption2, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(invitation.status.color)
                        .cornerRadius(8)
                }
                
                // 描述
                Text(invitation.description)
                    .font(.system(size: AppTheme.FontSize.caption))
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .lineLimit(2)
                
                // 时间和地点
                HStack(spacing: AppTheme.Spacing.md) {
                    Label {
                        Text(formatDateTime(invitation.startTime))
                            .font(.system(size: AppTheme.FontSize.caption2))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    } icon: {
                        Image(systemName: "clock")
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    
                    Label {
                        Text(invitation.location)
                            .font(.system(size: AppTheme.FontSize.caption2))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .lineLimit(1)
                    } icon: {
                        Image(systemName: "location")
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                }
                
                // 待处理状态显示操作提示
                if invitation.status == .pending {
                    HStack {
                        Spacer()
                        Text("点击查看详情并答复")
                            .font(.system(size: AppTheme.FontSize.caption2))
                            .foregroundColor(AppTheme.Colors.primary)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10))
                            .foregroundColor(AppTheme.Colors.primary)
                    }
                }
            }
            .padding(AppTheme.Spacing.md)
            .background(AppGradient.cardBackground)
            .cornerRadius(AppTheme.Radius.card)
            .shadow(color: AppTheme.Shadows.card, radius: 4, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                    .stroke(AppTheme.Colors.border, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingResponseView) {
            CollaborationInvitationResponseView(invitation: invitation)
                .environmentObject(userState)
        }
    }
    
    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM月dd日 HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - 通知/信息卡片
struct NotificationInfoCard: View {
    let notification: NotificationInfo
    @EnvironmentObject var userState: UserState
    @State private var showingDetailView = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
                // 类型标签（图标+文字，替换原图标位置）
                HStack(spacing: 4) {
                    Image(systemName: notification.type.icon)
                        .font(.system(size: 14))
                        .foregroundColor(categoryColor)
                    
                    Text(notification.category == .info ? "信息" : "提醒")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(categoryColor)
                }
                .frame(width: 50, alignment: .leading)
                
                // 内容
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(notification.title)
                            .font(.system(size: AppTheme.FontSize.body, weight: .semibold))
                            .foregroundColor(AppTheme.Colors.text)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        Text(formatTimeAgo(notification.createdAt))
                            .font(.system(size: AppTheme.FontSize.caption2))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    
                    Text(notification.content)
                        .font(.system(size: AppTheme.FontSize.caption))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            
            // 操作按钮
            HStack(spacing: AppTheme.Spacing.sm) {
                if notification.category == .info {
                    // 信息：点击OK消失
                    Button(action: {
                        userState.dismissNotification(notification)
                    }) {
                        Text("OK")
                            .font(.system(size: AppTheme.FontSize.caption, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(AppTheme.Colors.primary)
                            .cornerRadius(12)
                    }
                } else {
                    // 提醒：查看详情
                    Button(action: {
                        showingDetailView = true
                    }) {
                        Text("查看详情")
                            .font(.system(size: AppTheme.FontSize.caption, weight: .medium))
                            .foregroundColor(AppTheme.Colors.primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(AppTheme.Colors.primary.opacity(0.1))
                            .cornerRadius(12)
                    }
                    
                    // 显示结束时间信息
                    if let endTime = notification.endTime {
                        Text("将于\(formatDateTime(endTime))自动关闭")
                            .font(.system(size: AppTheme.FontSize.caption2))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    } else {
                        Text("需手动关闭")
                            .font(.system(size: AppTheme.FontSize.caption2))
                            .foregroundColor(.orange)
                    }
                }
                
                Spacer()
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(
            notification.isRead
                ? Color(.systemBackground)
                : AppTheme.Colors.primary.opacity(0.03)
        )
        .cornerRadius(AppTheme.Radius.card)
        .shadow(color: AppTheme.Shadows.card, radius: 2, x: 0, y: 1)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                .stroke(
                    notification.isRead
                        ? Color.clear
                        : AppTheme.Colors.primary.opacity(0.1),
                    lineWidth: 1
                )
        )
        .sheet(isPresented: $showingDetailView) {
            NotificationDetailView(notification: notification)
                .environmentObject(userState)
        }
    }
    
    private func formatTimeAgo(_ date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        
        if interval < 3600 { // 1小时内
            let minutes = Int(interval / 60)
            return "\(minutes)分钟前"
        } else if interval < 86400 { // 24小时内
            let hours = Int(interval / 3600)
            return "\(hours)小时前"
        } else { // 超过24小时
            let days = Int(interval / 86400)
            return "\(days)天前"
        }
    }
    
    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM月dd日 HH:mm"
        return formatter.string(from: date)
    }
    
    private var categoryColor: Color {
        notification.category == .info ? .blue : .orange
    }
}

// MARK: - 通知详情页面
struct NotificationDetailView: View {
    let notification: NotificationInfo
    @EnvironmentObject var userState: UserState
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                    // 图标和标题
                    HStack(spacing: AppTheme.Spacing.md) {
                        ZStack {
                            Circle()
                                .fill(notification.type.color.opacity(0.15))
                                .frame(width: 60, height: 60)
                            
                            Image(systemName: notification.type.icon)
                                .font(.system(size: 28))
                                .foregroundColor(notification.type.color)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(notification.category.displayName)
                                .font(.system(size: AppTheme.FontSize.caption))
                                .foregroundColor(AppTheme.Colors.textSecondary)
                            
                            Text(notification.title)
                                .font(.system(size: AppTheme.FontSize.title2, weight: .bold))
                                .foregroundColor(AppTheme.Colors.text)
                        }
                    }
                    
                    Divider()
                    
                    // 内容
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                        Text("详细信息")
                            .font(.system(size: AppTheme.FontSize.headline, weight: .semibold))
                            .foregroundColor(AppTheme.Colors.text)
                        
                        Text(notification.content)
                            .font(.system(size: AppTheme.FontSize.body))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .lineSpacing(4)
                    }
                    
                    Divider()
                    
                    // 时间信息
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                        HStack {
                            Text("创建时间")
                                .font(.system(size: AppTheme.FontSize.caption))
                                .foregroundColor(AppTheme.Colors.textSecondary)
                            Spacer()
                            Text(formatFullDateTime(notification.createdAt))
                                .font(.system(size: AppTheme.FontSize.caption))
                                .foregroundColor(AppTheme.Colors.text)
                        }
                        
                        if let endTime = notification.endTime {
                            HStack {
                                Text("结束时间")
                                    .font(.system(size: AppTheme.FontSize.caption))
                                    .foregroundColor(AppTheme.Colors.textSecondary)
                                Spacer()
                                Text(formatFullDateTime(endTime))
                                    .font(.system(size: AppTheme.FontSize.caption))
                                    .foregroundColor(AppTheme.Colors.text)
                            }
                            
                            HStack {
                                Text("自动关闭")
                                    .font(.system(size: AppTheme.FontSize.caption))
                                    .foregroundColor(AppTheme.Colors.textSecondary)
                                Spacer()
                                Text(notification.isExpired ? "已过期" : "未过期")
                                    .font(.system(size: AppTheme.FontSize.caption))
                                    .foregroundColor(notification.isExpired ? .red : .green)
                            }
                        } else {
                            HStack {
                                Text("关闭方式")
                                    .font(.system(size: AppTheme.FontSize.caption))
                                    .foregroundColor(AppTheme.Colors.textSecondary)
                                Spacer()
                                Text("需手动关闭")
                                    .font(.system(size: AppTheme.FontSize.caption))
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding(AppTheme.Spacing.lg)
            }
            .background(AppGradient.background.ignoresSafeArea())
            .navigationTitle("提醒详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("返回") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        userState.closeReminder(notification)
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("关闭提醒")
                            .foregroundColor(.red)
                    }
                }
            }
        }
    }
    
    private func formatFullDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日 HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - Tab标签按钮
struct TabBarButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: AppTheme.FontSize.caption, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? AppTheme.Colors.primary : AppTheme.Colors.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                // 下划线指示器
                Rectangle()
                    .fill(isSelected ? AppTheme.Colors.primary : Color.clear)
                    .frame(height: 2)
                    .cornerRadius(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 我发起的心意盒卡片（完整操作版）
struct MyInitiatedGiftBoxCard: View {
    let giftBox: GiftBox
    @EnvironmentObject var userState: UserState
    @State private var showingEditView = false
    @State private var showingClosureView = false
    @State private var showingWithdrawAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            // 标题和状态
            HStack {
                // 类型标签（图标+文字，粉色）
                HStack(spacing: 4) {
                    Image(systemName: "gift.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.pink)
                    
                    Text("心意")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.pink)
                }
                .frame(width: 50, alignment: .leading)
                
                Text(giftBox.item)
                    .font(.system(size: AppTheme.FontSize.body, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.text)
                    .lineLimit(1)
                
                Spacer()
                
                // 状态标签
                Text(giftBox.status.displayText)
                    .font(.system(size: AppTheme.FontSize.caption2, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(giftBox.status.color)
                    .cornerRadius(8)
            }
            
            // 地点信息
            HStack(spacing: 6) {
                Image(systemName: "location.fill")
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.Colors.textSecondary)
                Text(giftBox.suggestedLocation)
                    .font(.system(size: AppTheme.FontSize.caption))
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            
            // 备注（如果有）
            if let note = giftBox.note, !note.isEmpty {
                Text(note)
                    .font(.system(size: AppTheme.FontSize.caption))
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .lineLimit(2)
            }
            
            // 时间信息
            HStack(spacing: 8) {
                Text("创建于 \(formatDateTime(giftBox.createdAt))")
                    .font(.system(size: AppTheme.FontSize.caption2))
                    .foregroundColor(AppTheme.Colors.textSecondary)
                
                if let editedAt = giftBox.lastEditedAt {
                    Text("• 编辑于 \(formatDateTime(editedAt))")
                        .font(.system(size: AppTheme.FontSize.caption2))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
            
            Divider()
            
            // 操作按钮（按需求文档）
            HStack(spacing: AppTheme.Spacing.sm) {
                // 待确认状态：只能"撤回"
                if giftBox.status == .pending {
                    Button(action: {
                        showingWithdrawAlert = true
                    }) {
                        Label("撤回", systemImage: "arrow.uturn.backward")
                            .font(.system(size: AppTheme.FontSize.caption, weight: .medium))
                            .foregroundColor(.red)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                    }
                } else {
                    // 其他状态：可"再次编辑发送"
                    Button(action: {
                        showingEditView = true
                    }) {
                        Label("再次编辑发送", systemImage: "arrow.clockwise")
                            .font(.system(size: AppTheme.FontSize.caption, weight: .medium))
                            .foregroundColor(AppTheme.Colors.primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(AppTheme.Colors.primary.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                
                // 已接受状态：额外提供"发起安心确认"选项
                if giftBox.status == .accepted {
                    Button(action: {
                        showingClosureView = true
                    }) {
                        Label("发起安心确认", systemImage: "checkmark.seal")
                            .font(.system(size: AppTheme.FontSize.caption, weight: .medium))
                            .foregroundColor(.green)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                
                Spacer()
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(AppGradient.cardBackground)
        .cornerRadius(AppTheme.Radius.card)
        .shadow(color: AppTheme.Shadows.card, radius: 4, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                .stroke(AppTheme.Colors.border, lineWidth: 1)
        )
        .alert("确认撤回", isPresented: $showingWithdrawAlert) {
            Button("取消", role: .cancel) { }
            Button("撤回", role: .destructive) {
                userState.withdrawGiftBox(giftBox)
            }
        } message: {
            Text("撤回后对方将无法看到这个心意盒")
        }
        .sheet(isPresented: $showingEditView) {
            GiftBoxEditView(giftBox: giftBox)
                .environmentObject(userState)
        }
        .sheet(isPresented: $showingClosureView) {
            // 从心意盒发起安心确认
            // TODO: 需要创建支持预填数据的安心确认创建页
            // 当前先打开普通的创建页，用户需要手动填写
            PeacefulClosureCreateView()
                .environmentObject(userState)
                .onAppear {
                    // 提示：可以基于心意盒 "\(giftBox.item)" 创建安心确认
                    print("💡 提示：基于心意盒创建安心确认")
                    print("   - 物品：\(giftBox.item)")
                    print("   - 地点：\(giftBox.actualLocation ?? giftBox.suggestedLocation)")
                }
        }
    }
    
    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM月dd日 HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - ViewHeightKey（用于动态获取视图高度）
struct ViewHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

// MARK: - 伴侣情绪报告详情页
struct PartnerMoodReportDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    
    // 模拟数据
    @State private var pressureTotal: Double = 7.2
    @State private var nonRelationshipPressure: Double = 4.1
    @State private var relationshipPressure: Double = 3.1
    @State private var nonRelationshipAnxiety: Double = 6.8
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xl) {
                    // 标题和更新时间
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                        HStack {
                            Image(systemName: "heart.text.square.fill")
                                .font(.title)
                                .foregroundColor(.pink)
                            
                            Text("TA的情绪报告")
                                .font(.system(size: AppTheme.FontSize.title2, weight: .bold))
                                .foregroundColor(AppTheme.Colors.text)
                        }
                        
                        Text("刚刚更新")
                            .font(.system(size: AppTheme.FontSize.caption))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    
                    Divider()
                    
                    // 压力总分
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                        Text("压力总分")
                            .font(.system(size: AppTheme.FontSize.headline, weight: .semibold))
                            .foregroundColor(AppTheme.Colors.text)
                        
                        PressureScoreView(
                            title: "当前压力",
                            score: pressureTotal,
                            maxScore: 10.0,
                            color: getPressureColor(pressureTotal),
                            isMainScore: true
                        )
                        
                        Text("压力来源分解")
                            .font(.system(size: AppTheme.FontSize.subheadline, weight: .medium))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .padding(.top, AppTheme.Spacing.sm)
                        
                        VStack(spacing: AppTheme.Spacing.md) {
                            PressureScoreView(
                                title: "非关系压力",
                                score: nonRelationshipPressure,
                                maxScore: 5.0,
                                color: getPressureColor(nonRelationshipPressure * 2),
                                isMainScore: false
                            )
                            
                            PressureScoreView(
                                title: "关系压力",
                                score: relationshipPressure,
                                maxScore: 5.0,
                                color: getPressureColor(relationshipPressure * 2),
                                isMainScore: false
                            )
                        }
                        .padding(.leading, AppTheme.Spacing.md)
                    }
                    
                    Divider()
                    
                    // 非关系焦虑
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                        Text("非关系焦虑")
                            .font(.system(size: AppTheme.FontSize.headline, weight: .semibold))
                            .foregroundColor(AppTheme.Colors.text)
                        
                        PressureScoreView(
                            title: "焦虑指数",
                            score: nonRelationshipAnxiety,
                            maxScore: 10.0,
                            color: getAnxietyColor(nonRelationshipAnxiety),
                            isMainScore: true
                        )
                    }
                    
                    Spacer()
                }
                .padding(AppTheme.Spacing.lg)
            }
            .background(AppGradient.background.ignoresSafeArea())
            .navigationTitle("情绪报告")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    private func getPressureColor(_ score: Double) -> Color {
        switch score {
        case 0..<3: return .green
        case 3..<6: return .yellow
        case 6..<8: return .orange
        default: return .red
        }
    }
    
    private func getAnxietyColor(_ score: Double) -> Color {
        switch score {
        case 0..<3: return .green
        case 3..<6: return .yellow
        case 6..<8: return .orange
        default: return .red
        }
    }
}

#Preview {
    OurSpaceView()
        .environmentObject(UserState())
        .environmentObject(PartnerState())
        .environmentObject(GrowthGarden())
}
