//
//  GiftBoxDataExamples.swift
//  Personal Space
//
//  Created by Penn on 2025/1/27.
//

import SwiftUI

struct GiftBoxDataExamples {

    // MARK: - 所有心意盒示例数据
    static let allExamples: [GiftBox] = [

        // 待处理 - 刚刚收到
        GiftBox(
            item: "温暖的围巾",
            location: "商场",
            preparationTime: 1800, // 30分钟
            canExpire: true,
            expiresAt: Date().addingTimeInterval(24 * 3600),
            isFromMe: false,
            status: .pending,
            createdAt: Date().addingTimeInterval(-2 * 3600)
        ),

        // 待处理 - 快到期
        GiftBox(
            item: "美味的小蛋糕",
            location: "甜品店",
            preparationTime: 900, // 15分钟
            canExpire: true,
            expiresAt: Date().addingTimeInterval(4 * 3600),
            isFromMe: false,
            status: .pending,
            createdAt: Date().addingTimeInterval(-20 * 3600)
        },

        // 已接受 - 好呀
        GiftBox(
            item: "一本书",
            location: "书店",
            preparationTime: 3600, // 1小时
            canExpire: true,
            expiresAt: Date().addingTimeInterval(48 * 3600),
            isFromMe: false,
            status: .accepted,
            createdAt: Date().addingTimeInterval(-6 * 3600),
            respondedAt: Date().addingTimeInterval(-5 * 3600),
            response: .good,
            acceptedAt: Date().addingTimeInterval(-5 * 3600)
        ),

        // 已接受 - 好的
        GiftBox(
            item: "一杯咖啡",
            location: "咖啡店",
            preparationTime: 600, // 10分钟
            canExpire: false,
            isFromMe: false,
            status: .accepted,
            createdAt: Date().addingTimeInterval(-2 * 24 * 3600),
            respondedAt: Date().addingTimeInterval(-22 * 3600),
            response: .okay,
            acceptedAt: Date().addingTimeInterval(-22 * 3600)
        ),

        // 已拒绝 - 不想要
        GiftBox(
            item: "游戏手柄",
            location: "电子产品店",
            preparationTime: 1800, // 30分钟
            canExpire: true,
            expiresAt: Date().addingTimeInterval(12 * 3600),
            isFromMe: false,
            status: .rejected,
            createdAt: Date().addingTimeInterval(-8 * 3600),
            respondedAt: Date().addingTimeInterval(-7 * 3600),
            response: .notWant
        ),

        // 已拒绝 - 心意收下
        GiftBox(
            item: "昂贵的礼物",
            location: "奢侈品店",
            preparationTime: 7200, // 2小时
            canExpire: false,
            isFromMe: false,
            status: .rejected,
            createdAt: Date().addingTimeInterval(-3 * 24 * 3600),
            respondedAt: Date().addingTimeInterval(-2.5 * 24 * 3600),
            response: .acceptIntention
        ),

        // 已过期 - 超时未回应
        GiftBox(
            item: "新鲜水果",
            location: "水果店",
            preparationTime: 900, // 15分钟
            canExpire: true,
            expiresAt: Date().addingTimeInterval(-1 * 3600),
            isFromMe: false,
            status: .expired,
            createdAt: Date().addingTimeInterval(-25 * 3600),
            expiredAt: Date().addingTimeInterval(-1 * 3600)
        ),

        // 已撤回 - 主动撤回
        GiftBox(
            item: "临时起意的礼物",
            location: "便利店",
            preparationTime: 300, // 5分钟
            canExpire: false,
            isFromMe: false,
            status: .withdrawn,
            createdAt: Date().addingTimeInterval(-30 * 60),
            withdrawnAt: Date().addingTimeInterval(-10 * 60)
        )
    ]

    // MARK: - 我发起的心意盒示例数据
    static let myGiftBoxExamples: [GiftBox] = [

        // 待处理 - 刚刚发起
        GiftBox(
            item: "一束花",
            location: "花店",
            preparationTime: 1800, // 30分钟
            canExpire: true,
            expiresAt: Date().addingTimeInterval(24 * 3600),
            isFromMe: true,
            status: .pending,
            createdAt: Date().addingTimeInterval(-1 * 3600)
        ),

        // 已接受 - 对方同意
        GiftBox(
            item: "电影票",
            location: "电影院",
            preparationTime: 600, // 10分钟
            canExpire: false,
            isFromMe: true,
            status: .accepted,
            createdAt: Date().addingTimeInterval(-6 * 3600),
            respondedAt: Date().addingTimeInterval(-5 * 3600),
            response: .good,
            acceptedAt: Date().addingTimeInterval(-5 * 3600)
        ),

        // 已拒绝 - 对方拒绝
        GiftBox(
            item: "运动装备",
            location: "体育用品店",
            preparationTime: 3600, // 1小时
            canExpire: true,
            expiresAt: Date().addingTimeInterval(48 * 3600),
            isFromMe: true,
            status: .rejected,
            createdAt: Date().addingTimeInterval(-12 * 3600),
            respondedAt: Date().addingTimeInterval(-11 * 3600),
            response: .notWant
        ),

        // 已撤回 - 主动撤回
        GiftBox(
            item: "临时决定的小礼物",
            location: "便利店",
            preparationTime: 300, // 5分钟
            canExpire: false,
            isFromMe: true,
            status: .withdrawn,
            createdAt: Date().addingTimeInterval(-2 * 3600),
            withdrawnAt: Date().addingTimeInterval(-1 * 3600)
        )
    ]

    // MARK: - 不同状态的心意盒显示效果
    static func getGiftBoxesByStatus(_ status: GiftBoxStatus) -> [GiftBoxIndicate] {
        switch status {
        case .pending:
            return [
                GiftBoxIndicate(
                    title: "待处理事项",
                    description: "有新的心意等待您的回应",
                    badge: "待回应",
                    color: .orange,
                    action: "respond"
                )
            ]
        case .accepted:
            return [
                GiftBoxIndicate(
                    title: "已接受的心意",
                    description: "双方已确认心意",
                    badge: "已接受",
                    color: .green,
                    action: "view"
                )
            ]
        case .rejected:
            return [
                GiftBoxIndicate(
                    title: "已拒绝的心意",
                    description: "对方已回应",
                    badge: "已拒绝",
                    color: .red,
                    action: "view"
                )
            ]
        case .expired:
            return [
                GiftBoxIndicate(
                    title: "已过期",
                    description: "心意已过期",
                    badge: "已过期",
                    color: .gray,
                    action: "expired"
                )
            ]
        case .withdrawn:
            return [
                GiftBoxIndicate(
                    title: "已撤回",
                    description: "发起人已撤回",
                    badge: "已撤回",
                    color: .gray,
                    action: "withdrawn"
                )
            ]
        }
    }
}

// MARK: - 心意盒展示指示器
struct GiftBoxIndicate {
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
extension GiftBoxIndicate {
    var appropriateIcon: String {
        switch badge {
        case "待回应": return "gift"
        case "已接受": return "heart.fill"
        case "已拒绝": return "heart.slash"
        case "已过期": return "clock.badge.exclamationmark"
        case "已撤回": return "arrow.uturn.backward"
        default: return "gift"
        }
    }
}