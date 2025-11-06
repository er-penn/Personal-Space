//
//  CollaborationInvitationDataExamples.swift
// Personal Space
//
//  Created by Penn on 2025/1/27.
//

import SwiftUI

struct CollaborationInvitationDataExamples {

    // MARK: - 所有协作邀请示例数据
    static let allExamples: [CollaborationInvitation] = [

        // 待处理 - 待处理状态
        CollaborationInvitation(
            title: "周末一起看电影",
            description: "最近上映了一部不错的电影，要不要一起去看？",
            location: "万达影城",
            startTime: Date().addingTimeInterval(2 * 24 * 3600),
            duration: 7200,
            createdBy: "partner",
            status: .pending,
            negotiationHistory: []
        ),

        // 待处理 - 微信商量中
        CollaborationInvitation(
            title: "晚饭吃什么",
            description: "晚上一起做晚餐吧？我想吃面食",
            location: "家里",
            startTime: Date().addingTimeInterval(4 * 3600),
            duration: 5400,
            createdBy: "partner",
            status: .wechatNegotiating,
            negotiationHistory: [
                NegotiationRecord(
                    proposedBy: "partner",
                    proposedAt: Date().addingTimeInterval(-1 * 24 * 3600),
                    newStartTime: Date().addingTimeInterval(3 * 24 * 3600),
                    newLocation: "餐厅"
                ),
                NegotiationRecord(
                    proposedBy: "me",
                    newStartTime: Date().addingTimeInterval(1 * 24 * 3600),
                    newLocation: "公园",
                    newDescription: "换个地方怎么样？"
                )
            ]
        ),

        // 待处理 - 以后再看
        CollaborationInvitation(
            title: "周末爬山",
            description: "天气不错，要不要去爬山？",
            location: "香山",
            startTime: Date().addingTimeInterval(7 * 24 * 3600),
            duration: 14400,
            createdBy: "partner",
            status: .postponed,
            negotiationHistory: []
        ),

        // 已接受 - 好呀
        CollaborationInvitation(
            title: "喝咖啡聊天",
            description: "一起喝杯咖啡聊聊天",
            location: "咖啡馆",
            startTime: Date().addingTimeInterval(1 * 3600),
            duration: 3600,
            createdBy: "partner",
            status: .accepted,
            acceptedStartTime: Date().addingTimeInterval(1 * 3600),
            acceptedEndTime: Date().addingTimeInterval(1 * 3600 + 1800),
            actualLocation: "咖啡馆",
            response: "好滴收下啦🥰",
            respondedAt: Date().addingTimeInterval(1 * 3600 + 1800 + 5),
            negotiationHistory: []
        ),

        // 不想要 - 不想要
        CollaborationInvitation(
            title: "玩游戏",
            description: "一起玩游戏？",
            location: "家里",
            startTime: Date().addingTimeInterval(2 * 24 * 3600),
            duration: 7200,
            createdBy: "partner",
            status: .rejected,
            response: "不太想要😅",
            respondedAt: Date().addingTimeInterval(2 * 24 * 3600 + 600),
            negotiationHistory: []
        ),

        // 已过期 - 已过期
        CollaborationInvitation(
            title: "聚餐",
            description: "一起吃饭",
            location: "餐厅",
            startTime: Date().addingTimeInterval(-3 * 24 * 3600),
            duration: 5400,
            createdBy: "partner",
            status: .expired,
            expiresAt: Date().addingTimeInterval(-1 * 24 * 3600),
            negotiationHistory: []
        )
    ]

    // MARK: - 我发起的协作邀请示例数据
    static let myInvitationExamples: [CollaborationInvitation] = [

        // 待处理 - 刚刚发起
        CollaborationInvitation(
            title: "一起学习",
            description: "周末一起去图书馆学习吧",
            location: "图书馆",
            startTime: Date().addingTimeInterval(3 * 24 * 3600),
            duration: 7200,
            createdBy: "me",
            status: .pending,
            negotiationHistory: []
        ),

        // 已接受 - 好呀
        CollaborationInvitation(
            title: "跑步锻炼",
            description: "早上一起跑步怎么样？",
            location: "滨江公园",
            startTime: Date().addingTimeInterval(1 * 24 * 3600 + 6 * 60),
            duration: 3600,
            createdBy: "me",
            status: .accepted,
            acceptedStartTime: Date().addingTimeInterval(1 * 24 * 3600 + 6 * 60),
            acceptedEndTime: Date().addingTimeInterval(1 * 24 * 3600 + 6 * 60 + 3600),
            actualLocation: "滨江公园",
            response: "好滴！",
            respondedAt: Date().addingTimeInterval(1 * 24 * 3600 + 6 * 60 + 3600 + 300),
            negotiationHistory: []
        ),

        // 商量中 - 商量下呗
        CollaborationInvitation(
            title: "讨论项目计划",
            description: "讨论下周的项目计划",
            location: "会议室",
            startTime: Date().addingTimeInterval(7 * 24 * 3600),
            duration: 3600,
            createdBy: "me",
            status: .negotiating,
            negotiationHistory: [
                NegotiationRecord(
                    proposedBy: "me",
                    proposedAt: Date().addingTimeInterval(7 * 24 * 3600),
                    newStartTime: Date().addingTimeInterval(7 * 24 * 3600 + 12 * 3600),
                    newLocation: "咖啡厅",
                    newDescription: "换个时间？"
                )
            ]
        ),

        // 以后看 - 以后看
        CollaborationInvitation(
            title: "旅行计划",
            description: "计划下个月的旅行",
            location: "机场",
            startTime: Date().addingTimeInterval(30 * 24 * 3600),
            duration: 86400,
            createdBy: "me",
            status: .postponed,
            negotiationHistory: []
        )
    ]

    // MARK: - 不同状态的协作邀请显示效果
    static func getInvitationsByStatus(_ status: InvitationStatus) -> [CollaborationIndicate] {
        switch status {
        case .pending:
            return [
                CollaborationIndicate(
                    title: "待处理事项",
                    description: "有新的协作邀请等待您的回应",
                    badge: "待处理",
                    color: .orange,
                    action: "respond"
                )
            ]
        case .accepted:
            return [
                CollaborationIndicate(
                    title: "已接受的邀请",
                    description: "双方已确认时间",
                    badge: "已接受",
                    color: .green,
                    action: "view"
                )
            ]
        case .negotiating:
            return [
                CollaborationIndicate(
                    title: "商量中",
                    description: "正在微信商量中",
                    badge: "商量中",
                    color: .blue,
                    action: "negotiate"
                )
            ]
        case .postponed:
            return [
                CollaborationIndicate(
                    title: "延期的邀请",
                    description: "用户选择以后再看",
                    badge: "以后看",
                    color: .gray,
                    action: "postpone"
                )
            ]
        case .wechatNegotiating:
            return [
                CollaborationIndicate(
                    title: "微信商量中",
                    description: "正在微信商量",
                    badge: "微信商量",
                    color: .purple,
                    action: "wechat"
                )
            ]
        case .expired:
            return [
                CollaborationIndicate(
                    title: "已过期",
                    description: "邀请已过期",
                    badge: "已过期",
                    color: .red,
                    action: "expired"
                )
            ]
        }
    }
}

// MARK: - 协作邀请展示指示器
struct CollaborationIndicate {
    let title: String
    let description: String
    let badge: String
    let color: Color
    let action: String?

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: appropriateIcon)
                .font(.system(size: 14))
                .foregroundColor(color)

            Text(badge)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(color)
                .cornerRadius(4)

            Spacer()

            if let action = action {
                Button(action) {
                    // action()
                } label: {
                    Text(action)
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

// MARK: - 适当的图标
extension CollaborationIndicate {
    var appropriateIcon: String {
        switch badge {
        case "待处理": return "clock"
        case "已接受": return "checkmark.circle.fill"
        case "商量中": return "message.circle"
        case "以后看": return "clock"
        case "微信商量": return "message.circle.fill"
        case "已过期": return "exclamationmark.triangle.fill"
        default: return "circle"
        }
    }
}
}