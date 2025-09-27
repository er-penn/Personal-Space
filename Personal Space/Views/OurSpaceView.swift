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
    
    // 模拟数据
    @State private var pendingItems: [Any] = [
        CollaborationInvitation(title: "周末一起看电影", content: "最近上映了一部不错的电影，要不要一起去看？", createdAt: Date(), isFromMe: false, status: .pending),
        PeacefulClosure(item: "钥匙", location: "门口鞋柜", estimatedTime: "晚上8点", createdAt: Date(), isFromMe: false, isAcknowledged: false),
        GiftBox(item: "小礼物", time: "明天", location: "家里", createdAt: Date(), expiresAt: Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date(), isFromMe: false, isReceived: false)
    ]
    
    @State private var myItems: [Any] = [
        CollaborationInvitation(title: "一起去公园散步", content: "天气不错，要不要去公园走走？", createdAt: Date(), isFromMe: true, status: .accepted),
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
                        // 平复功能
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
                VStack(spacing: 4) {
                    // 时间标签
                    HStack {
                        ForEach(Array(stride(from: 6, through: 22, by: 4)), id: \.self) { hour in
                            Text("\(hour):00")
                                .font(.system(size: 8))
                                .foregroundColor(AppTheme.Colors.textSecondary)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    
                    // 进度条
                    PartnerEnergyProgressView()
                        .frame(height: 8)
                }
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
            Text("待处理事项")
                .font(.headline)
                .foregroundColor(.secondary)
            
            LazyVStack(spacing: 12) {
                ForEach(Array(pendingItems.enumerated()), id: \.offset) { index, item in
                    if let invitation = item as? CollaborationInvitation {
                        CollaborationInvitationCard(invitation: invitation)
                    } else if let closure = item as? PeacefulClosure {
                        PeacefulClosureCard(closure: closure)
                    } else if let giftBox = item as? GiftBox {
                        GiftBoxCard(giftBox: giftBox)
                    }
                }
            }
            
            Divider()
                .padding(.vertical, 8)
            
            Text("我发起的")
                .font(.headline)
                .foregroundColor(.secondary)
            
            LazyVStack(spacing: 12) {
                ForEach(Array(myItems.enumerated()), id: \.offset) { index, item in
                    if let invitation = item as? CollaborationInvitation {
                        CollaborationInvitationCard(invitation: invitation)
                    } else if let fragment = item as? Fragment {
                        FragmentCard(fragment: fragment)
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

// MARK: - 协作邀请卡片
struct CollaborationInvitationCard: View {
    let invitation: CollaborationInvitation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "envelope")
                    .foregroundColor(.blue)
                
                Text("协作邀请")
                    .font(.subheadline)
                    .font(.subheadline.weight(.medium))
                
                Spacer()
                
                Text(invitation.isFromMe ? "我发起的" : "待处理")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(invitation.isFromMe ? Color.blue.opacity(0.2) : Color.orange.opacity(0.2))
                    .cornerRadius(8)
            }
            
            Text(invitation.title)
                .font(.headline)
            
            Text(invitation.content)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if !invitation.isFromMe {
                HStack(spacing: 12) {
                    Button("好") {
                        // TODO: 处理接受
                    }
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.green)
                    .cornerRadius(8)
                    
                    Button("再商量") {
                        // TODO: 处理商量
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(8)
                    
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

// MARK: - 安心闭环卡片
struct PeacefulClosureCard: View {
    let closure: PeacefulClosure
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "checkmark.circle")
                    .foregroundColor(.green)
                
                Text("安心闭环")
                    .font(.subheadline)
                    .font(.subheadline.weight(.medium))
                
                Spacer()
                
                Text(closure.isFromMe ? "我发起的" : "待确认")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(closure.isFromMe ? Color.blue.opacity(0.2) : Color.orange.opacity(0.2))
                    .cornerRadius(8)
            }
            
            Text("物品：\(closure.item)")
                .font(.headline)
            
            Text("地点：\(closure.location)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("预计时间：\(closure.estimatedTime)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if !closure.isFromMe && !closure.isAcknowledged {
                Button("已知悉") {
                    // TODO: 处理确认
                }
                .font(.subheadline)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.green)
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

// MARK: - 心意盒卡片
struct GiftBoxCard: View {
    let giftBox: GiftBox
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "gift")
                    .foregroundColor(.pink)
                
                Text("心意盒")
                    .font(.subheadline)
                    .font(.subheadline.weight(.medium))
                
                Spacer()
                
                Text(giftBox.isFromMe ? "我发起的" : "待接收")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(giftBox.isFromMe ? Color.blue.opacity(0.2) : Color.orange.opacity(0.2))
                    .cornerRadius(8)
            }
            
            Text("物品：\(giftBox.item)")
                .font(.headline)
            
            Text("时间：\(giftBox.time)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("地点：\(giftBox.location)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if !giftBox.isFromMe && !giftBox.isReceived {
                Button("接收") {
                    // TODO: 处理接收
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
    @State private var maybeItems = [
        "一起去海边看日落",
        "学习做一道新菜",
        "看一场音乐会",
        "整理相册"
    ]
    
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
                    // TODO: 编辑清单
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(maybeItems, id: \.self) { item in
                    HStack {
                        Text("•")
                            .foregroundColor(.secondary)
                        Text(item)
                            .font(.subheadline)
                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
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
            // 小时标签（每4小时显示一次）
            HStack {
                ForEach(Array(stride(from: 6, through: 22, by: 4)), id: \.self) { hour in
                    Text("\(hour):00")
                        .font(.system(size: 8))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .frame(maxWidth: .infinity)
                }
            }
            
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
        // 优先级：专注模式 > 预规划 > 当天状态
        if partnerState.isFocusModeOn {
            return .blue
        }
        
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

#Preview {
    OurSpaceView()
        .environmentObject(UserState())
        .environmentObject(PartnerState())
        .environmentObject(GrowthGarden())
}
