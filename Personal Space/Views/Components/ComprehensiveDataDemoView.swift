//
//  ComprehensiveDataDemoView.swift
//  Personal Space
//
//  Created by Penn on 2025/1/27.
//

import SwiftUI

struct ComprehensiveDataDemoView: View {
    @EnvironmentObject var userState: UserState
    @Environment(\.presentationMode) var presentationMode
    @State private var isGeneratingData = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    // 数据生成控制
                    dataGenerationControl
                    
                    // 数据统计
                    dataStatistics

                    Spacer(minLength: 100)
                }
                .padding(AppTheme.Spacing.lg)
            }
            .background(AppGradient.background)
            .navigationTitle("数据管理")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(AppTheme.Colors.text)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("清空数据") {
                        clearAllData()
                    }
                    .foregroundColor(.red)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    // MARK: - 数据生成控制
    private var dataGenerationControl: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack {
                Image(systemName: "gear.badge")
                    .font(.system(size: 24))
                    .foregroundColor(AppTheme.Colors.primary)

                Text("数据生成控制")
                    .font(.system(size: AppTheme.FontSize.headline, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.text)
            }

            Button(action: {
                generateAllData()
            }) {
                HStack {
                    if isGeneratingData {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "wand.and.stars")
                    }
                    Text(isGeneratingData ? "生成中..." : "生成所有示例数据")
                }
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(isGeneratingData ? AppTheme.Colors.textSecondary : AppTheme.Colors.primary)
                .cornerRadius(AppTheme.Radius.medium)
            }
            .disabled(isGeneratingData)
        }
        .padding()
        .background(AppTheme.Colors.cardBg)
        .cornerRadius(AppTheme.Radius.large)
        .shadow(color: AppTheme.Shadows.card, radius: 6, x: 0, y: 3)
    }
    
    // MARK: - 数据统计
    private var dataStatistics: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("当前数据统计")
                .font(.system(size: AppTheme.FontSize.headline, weight: .semibold))
                .foregroundColor(AppTheme.Colors.text)
            
            VStack(spacing: AppTheme.Spacing.sm) {
                StatRow(title: "通知/信息", count: userState.notifications.count)
                StatRow(title: "协作邀请", count: userState.invitations.count)
                StatRow(title: "  - 我发起的", count: userState.myInvitations.count)
                StatRow(title: "安心确认", count: userState.peacefulClosures.count)
                StatRow(title: "  - 待处理", count: userState.pendingClosures.count)
                StatRow(title: "  - 我发起的", count: userState.myClosures.count)
                StatRow(title: "心意盒", count: userState.giftBoxes.count)
                StatRow(title: "  - 待处理", count: userState.pendingGiftBoxes.count)
                StatRow(title: "  - 我发起的", count: userState.myGiftBoxes.count)
                StatRow(title: "碎片分享", count: userState.fragments.count)
            }
        }
        .padding()
        .background(AppTheme.Colors.cardBg)
        .cornerRadius(AppTheme.Radius.large)
        .shadow(color: AppTheme.Shadows.card, radius: 6, x: 0, y: 3)
    }

    // MARK: - 数据操作方法
    private func generateAllData() {
        isGeneratingData = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // 生成协作邀请示例数据（所有状态）
            generateComprehensiveInvitations()

            // 生成安心确认示例数据（所有状态）
            generateComprehensivePeacefulClosures()

            // 生成心意盒示例数据（所有状态）
            generateComprehensiveGiftBoxes()

            // 生成碎片分享示例数据（所有类型）
            generateComprehensiveFragments()

            isGeneratingData = false
        }
    }
    
    // MARK: - 生成全面的协作邀请数据（所有状态）
    private func generateComprehensiveInvitations() {
        userState.invitations.append(contentsOf: CollaborationInvitationDataExamples.allExamples)
        userState.myInvitations.append(contentsOf: CollaborationInvitationDataExamples.myInvitationExamples)
    }

    // MARK: - 生成全面的安心确认数据（所有状态）
    private func generateComprehensivePeacefulClosures() {
        userState.peacefulClosures.append(contentsOf: PeacefulClosureDataExamples.allExamples)
        userState.myClosures.append(contentsOf: PeacefulClosureDataExamples.myClosureExamples)

        // 更新待处理的安心确认
        userState.pendingClosures = userState.peacefulClosures.filter { $0.status == .pending }
    }

    // MARK: - 生成全面的心意盒数据（所有状态）
    private func generateComprehensiveGiftBoxes() {
        userState.giftBoxes.append(contentsOf: GiftBoxDataExamples.allExamples)
        userState.myGiftBoxes.append(contentsOf: GiftBoxDataExamples.myGiftBoxExamples)

        // 更新待处理的心意盒
        userState.pendingGiftBoxes = userState.giftBoxes.filter { $0.status == .pending }
    }

    // MARK: - 生成全面的碎片分享数据（所有类型）
    private func generateComprehensiveFragments() {
        userState.fragments.append(contentsOf: FragmentDataExamples.allExamples)
    }
    
    private func clearAllData() {
        userState.invitations.removeAll()
        userState.myInvitations.removeAll()
        userState.peacefulClosures.removeAll()
        userState.myClosures.removeAll()
        userState.pendingClosures.removeAll()
        userState.giftBoxes.removeAll()
        userState.myGiftBoxes.removeAll()
        userState.pendingGiftBoxes.removeAll()
        userState.fragments.removeAll()
    }
}

// MARK: - 统计行
struct StatRow: View {
    let title: String
    let count: Int
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: AppTheme.FontSize.body))
                .foregroundColor(AppTheme.Colors.text)
            
            Spacer()
            
            Text("\(count)")
                .font(.system(size: AppTheme.FontSize.body, weight: .semibold))
                .foregroundColor(AppTheme.Colors.primary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 预览
#Preview {
    ComprehensiveDataDemoView()
        .environmentObject(UserState())
}

// MARK: - 数据示例定义

/// 协作邀请数据示例（所有状态）
struct CollaborationInvitationDataExamples {
    static var allExamples: [CollaborationInvitation] {
        [
            // 待处理
            CollaborationInvitation(
                title: "周末一起看电影",
                description: "最近上映了一部不错的电影，要不要一起去看？",
                location: "万达影城",
                startTime: Date().addingTimeInterval(2 * 24 * 3600),
                duration: 7200,
                createdBy: "partner"
            ),
            // 待处理
            CollaborationInvitation(
                title: "一起去公园散步",
                description: "天气不错，去公园走走吧",
                location: "中山公园",
                startTime: Date().addingTimeInterval(24 * 3600),
                duration: 3600,
                createdBy: "partner"
            )
        ]
    }
    
    static var myInvitationExamples: [CollaborationInvitation] {
        [
            CollaborationInvitation(
                title: "一起吃火锅",
                description: "尝试一家新开的火锅店",
                location: "海底捞",
                startTime: Date().addingTimeInterval(3 * 24 * 3600),
                duration: 5400,
                createdBy: "me"
            ),
            CollaborationInvitation(
                title: "周末去海边",
                description: "天气预报说周末晴天，去海边走走",
                location: "海滩",
                startTime: Date().addingTimeInterval(5 * 24 * 3600),
                duration: 10800,
                createdBy: "me"
            )
        ]
    }
}

/// 安心确认数据示例（所有状态）
struct PeacefulClosureDataExamples {
    static var allExamples: [PeacefulClosure] {
        [
            // 待确认
            PeacefulClosure(
                type: .item,
                title: "包裹在前台",
                content: "快递已送达前台，取件码8567",
                itemDetails: ItemDetails(
                    itemName: "快递包裹",
                    location: "公司前台",
                    expectedTime: nil,
                    extraInfo: "取件码：8567"
                ),
                createdBy: "partner",
                targetUser: "me"
            ),
            // 待确认
            PeacefulClosure(
                type: .affair,
                title: "我已安全到家",
                content: "已经到家了，请放心",
                createdBy: "partner",
                targetUser: "me"
            )
        ]
    }
    
    static var myClosureExamples: [PeacefulClosure] {
        [
            PeacefulClosure(
                type: .item,
                title: "钥匙在桌上",
                content: "你要的钥匙我放在餐桌上了",
                itemDetails: ItemDetails(
                    itemName: "钥匙",
                    location: "餐桌",
                    expectedTime: nil,
                    extraInfo: nil
                ),
                createdBy: "me",
                targetUser: "partner"
            )
        ]
    }
}

/// 心意盒数据示例（所有状态）
struct GiftBoxDataExamples {
    static var allExamples: [GiftBox] {
        [
            // 待确认
            GiftBox(
                item: "奶茶大杯",
                note: "你最喜欢的口味",
                suggestedLocation: "公司茶水间",
                preparationTime: 1800,
                hasExpiration: false,
                expiresAt: nil,
                isFromMe: false
            ),
            // 待确认
            GiftBox(
                item: "鲜花一束",
                note: "希望你喜欢",
                suggestedLocation: "公司前台",
                preparationTime: 3600,
                hasExpiration: true,
                expiresAt: Date().addingTimeInterval(3 * 24 * 3600),
                isFromMe: false
            )
        ]
    }
    
    static var myGiftBoxExamples: [GiftBox] {
        [
            GiftBox(
                item: "巧克力礼盒",
                note: "甜蜜小惊喜",
                suggestedLocation: "家里",
                preparationTime: 1800,
                hasExpiration: false,
                expiresAt: nil,
                isFromMe: true
            ),
            GiftBox(
                item: "护手霜",
                note: "冬天要好好保护小手",
                suggestedLocation: "办公桌",
                preparationTime: 900,
                hasExpiration: false,
                expiresAt: nil,
                isFromMe: true
            )
        ]
    }
}

/// 碎片分享数据示例（所有类型）
struct FragmentDataExamples {
    static var allExamples: [Fragment] {
        [
            Fragment(
                content: "今天看到一只很可爱的小猫",
                imageURL: nil,
                linkURL: nil,
                createdAt: Date(),
                isFromMe: true
            ),
            Fragment(
                content: "分享一篇很有意思的文章",
                imageURL: nil,
                linkURL: "https://example.com",
                createdAt: Date().addingTimeInterval(-3600),
                isFromMe: true
            ),
            Fragment(
                content: "今天的天气真好",
                imageURL: "photo1.jpg",
                linkURL: nil,
                createdAt: Date().addingTimeInterval(-7200),
                isFromMe: true
            )
        ]
    }
}
