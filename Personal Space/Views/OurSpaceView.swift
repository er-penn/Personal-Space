//
//  OurSpaceView.swift
//  Personal Space
//
//  Created by Penn on 2025/1/27.
//

import SwiftUI

struct OurSpaceView: View {
    @EnvironmentObject var userState: UserState
    @EnvironmentObject var partnerState: PartnerState
    @EnvironmentObject var growthGarden: GrowthGarden
    @State private var showingPartnerInfo = true
    @State private var showingCommonRecords = true

    // MARK: - 焦虑平复指南相关状态变量
    @State private var showingAnxietySoothingGuide = false
    @State private var showingDataDemo = false
    
    // 模拟数据 - 将使用UserState中的数据
    @State private var pendingItems: [Any] = []
    
    @State private var myItems: [Any] = [
        // CollaborationInvitation 使用新的初始化方法
        // CollaborationInvitation(title: "一起去公园散步", description: "天气不错，要不要去公园走走？", location: "公园", startTime: Date(), duration: 3600, createdBy: "user1"),
        Fragment(content: "今天看到一只很可爱的小猫", imageURL: nil, linkURL: nil, createdAt: Date(), isFromMe: true)
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景渐变
                AppGradient.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: AppTheme.Spacing.xxl) {
                        // 顶部状态区（与我的空间布局一致）
                        partnerStatusSection
                        
                        // 信息列表区
                        informationListSection
                        
                        // 伴侣信息区
                        partnerInfoSection
                        
                        // 共同记录区
                        commonRecordsSection
                    }
                    .padding(.horizontal, AppTheme.Spacing.lg)
                    .padding(.top, AppTheme.Spacing.lg)
                }
            }
            .navigationBarHidden(true)

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
        .sheet(isPresented: $showingAnxietySoothingGuide) {
            AnxietySoothingGuideView()
        }
        .sheet(isPresented: $showingDataDemo) {
            ComprehensiveDataDemoView()
        }
    }
    
    // MARK: - 伴侣状态区（参考我的空间布局）
    private var partnerStatusSection: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            // 主状态区域
            HStack(spacing: AppTheme.Spacing.lg) {
                // 1. 伴侣能量状态（电池图标设计）
                VStack(spacing: AppTheme.Spacing.sm) {
                    ZStack {
                        // 背景圆形渐变
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        partnerState.energyLevel.color.opacity(0.2),
                                        partnerState.energyLevel.color.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 90, height: 90) // 调小电池图标
                        
                        // 电池图标
                        BatteryIconView(energyLevel: partnerState.energyLevel)
                            .scaleEffect(0.75) // 进一步缩小电池图标
                    }
                    
                    Text(partnerState.energyLevel.description)
                        .font(.system(size: AppTheme.FontSize.subheadline, weight: .semibold))
                        .foregroundColor(partnerState.energyLevel.color)
                }
                .frame(maxWidth: .infinity)
                
                Spacer()
                
                // 右侧：平复按钮（与我的空间样式一致）
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
            
            // 伴侣能量规划进度条（如果有预规划）
            if hasPartnerEnergyPlan() {
                PartnerEnergyProgressView()
                    .frame(height: 20)
            }
        }
        .padding(AppTheme.Spacing.lg)
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
    
    // MARK: - 信息列表区
    private var informationListSection: some View {
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
    
    // MARK: - 伴侣信息区
    private var partnerInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showingPartnerInfo.toggle()
                }
            }) {
                HStack {
                    Text("TA的信息")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Image(systemName: showingPartnerInfo ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            if showingPartnerInfo {
                VStack(spacing: 12) {
                    // 情绪报告
                    PartnerMoodReportCard()
                    
                    // 碎片收件箱
                    if userState.displayEnergyLevel == .high {
                        Button(action: {
                            // TODO: 进入碎片收件箱
                        }) {
                            PartnerInfoCard(
                                title: "碎片收件箱",
                                icon: "photo",
                                color: .orange,
                                content: "有2条新分享"
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    } else {
                        PartnerInfoCard(
                            title: "碎片收件箱",
                            icon: "photo",
                            color: .gray,
                            content: "能量不足时暂不可访问"
                        )
                        .opacity(0.6)
                    }
                    
                    // TA的瞬间
                    if userState.displayEnergyLevel != .low {
                        PartnerInfoCard(
                            title: "TA的瞬间",
                            icon: "camera",
                            color: .purple,
                            content: "发布了1条新动态"
                        )
                    }
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

                    // 我的心意盒
                    MyGiftBoxSection()
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
                Image(systemName: "gift.fill")
                    .foregroundColor(.pink)

                Text("心意盒")
                    .font(.subheadline)
                    .font(.subheadline.weight(.medium))

                Spacer()

                Text("待处理")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.2))
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "photo")
                    .foregroundColor(.orange)
                
                Text("分享碎片")
                    .font(.subheadline)
                    .font(.subheadline.weight(.medium))
                
                Spacer()
                
                Text("我分享的")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(8)
            }
            
            Text(fragment.content)
                .font(.subheadline)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
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
struct PartnerEnergyProgressView: View {
    @EnvironmentObject var partnerState: PartnerState
    @State private var currentTime = Date()
    @State private var timer: Timer?
    
    // 模拟伴侣预规划数据 - 按小时
    @State private var partnerPlannedEnergy: [Int: EnergyLevel] = [
        8: .high,    // 8点
        9: .high,    // 9点
        10: .high,   // 10点
        11: .medium, // 11点
        12: .medium, // 12点
        13: .low,    // 13点
        14: .low,    // 14点
        15: .medium, // 15点
        16: .medium, // 16点
        17: .high,   // 17点
        18: .high,   // 18点
        19: .medium, // 19点
        20: .low,    // 20点
        21: .low,    // 21点
        22: .low     // 22点
    ]
    
    private let hours = Array(6...22) // 6点到22点
    
    var body: some View {
        VStack(spacing: 4) {
            // 小时标签（每4小时显示一次）- 使用GeometryReader精确定位
            GeometryReader { geometry in
                ZStack {
                    ForEach(Array(stride(from: 6, through: 22, by: 4)), id: \.self) { hour in
                        Text("\(hour):00")
                            .font(.system(size: 8))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .position(
                                x: getTimeLabelPosition(for: hour, in: geometry.size.width),
                                y: 6 // 时间标签的垂直位置
                            )
                    }
                }
            }
            .frame(height: 12)
            
            // 进度条 - 按小时显示
            GeometryReader { geometry in
                HStack(spacing: 0.5) {
                    ForEach(hours, id: \.self) { hour in
                        Rectangle()
                            .fill(getEnergyColor(for: hour))
                            .frame(width: geometry.size.width / CGFloat(hours.count), height: 8)
                            .cornerRadius(1)
                    }
                }
                .background(Color.gray.opacity(0.2))
                .cornerRadius(2)
                
                // 当前时间指示器
                Rectangle()
                    .fill(AppTheme.Colors.text)
                    .frame(width: 1, height: 8)
                    .offset(x: getCurrentTimeOffset(width: geometry.size.width))
            }
            .frame(height: 8)
        }
        .onAppear {
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
    }
    
    private func getEnergyColor(for hour: Int) -> Color {
        // 优先级：预规划 > 当天状态
        // 注意：PartnerState 暂时没有 isFocusModeOn 属性，已移除专注模式检查
        
        // 检查是否有预规划
        if let plannedLevel = partnerPlannedEnergy[hour] {
            return plannedLevel.color
        }
        
        // 使用当天状态
        return partnerState.energyLevel.color
    }
    
    private func getCurrentTimeOffset(width: CGFloat) -> CGFloat {
        let currentHour = Calendar.current.component(.hour, from: currentTime)
        let hourIndex = max(0, min(currentHour - 6, hours.count - 1))
        let segmentWidth = width / CGFloat(hours.count)
        return segmentWidth * CGFloat(hourIndex) + segmentWidth / 2
    }
    
    // 计算时间标签的位置（居中对齐到对应时间块）
    private func getTimeLabelPosition(for hour: Int, in totalWidth: CGFloat) -> CGFloat {
        let hourIndex = hour - 6 // 6点对应索引0
        let blockWidth = totalWidth / CGFloat(hours.count)
        return blockWidth * CGFloat(hourIndex) + blockWidth / 2
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            currentTime = Date()
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
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
                    Image(systemName: "calendar")
                        .foregroundColor(AppTheme.Colors.primary)
                        .font(.system(size: 20))
                    
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
                // 图标
                ZStack {
                    Circle()
                        .fill(notification.type.color.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: notification.type.icon)
                        .font(.system(size: 18))
                        .foregroundColor(notification.type.color)
                }
                
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

#Preview {
    OurSpaceView()
        .environmentObject(UserState())
        .environmentObject(PartnerState())
        .environmentObject(GrowthGarden())
}
