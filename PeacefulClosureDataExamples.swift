//
//  PeacefulClosureDataExamples.swift
//  Personal Space
//
//  Created by Penn on 2025/1/27.
//

import SwiftUI

struct PeacefulClosureDataExamples {

    // MARK: - 所有安心确认示例数据
    static let allExamples: [PeacefulClosure] = [

        // 待处理 - 刚刚发起
        PeacefulClosure(
            title: "今天工作很累",
            content: "今天加班到很晚，感觉很疲惫，希望得到一些安慰",
            createdBy: "partner",
            status: .pending,
            createdAt: Date().addingTimeInterval(-2 * 3600),
            responseDeadline: Date().addingTimeInterval(22 * 3600)
        ),

        // 待处理 - 快到期
        PeacefulClosure(
            title: "会议不顺利",
            content: "今天开会时被领导批评了，心情有点低落",
            createdBy: "partner",
            status: .pending,
            createdAt: Date().addingTimeInterval(-20 * 3600),
            responseDeadline: Date().addingTimeInterval(4 * 3600)
        ),

        // 已完成 - 已确认
        PeacefulClosure(
            title: "项目完成",
            content: "终于完成了这个重要的项目，感觉很充实",
            createdBy: "me",
            status: .completed,
            createdAt: Date().addingTimeInterval(-3 * 24 * 3600),
            respondedAt: Date().addingTimeInterval(-2 * 24 * 3600),
            response: "恭喜你！这是你努力的结果，值得庆祝🎉",
            acceptedAt: Date().addingTimeInterval(-2 * 24 * 3600)
        ),

        // 已归档 - 早期完成
        PeacefulClosure(
            title: "考试通过",
            content: "终于通过了考试，这段时间的努力没有白费",
            createdBy: "me",
            status: .archived,
            createdAt: Date().addingTimeInterval(-10 * 24 * 3600),
            respondedAt: Date().addingTimeInterval(-9 * 24 * 3600),
            response: "太棒了！为你感到骄傲",
            acceptedAt: Date().addingTimeInterval(-9 * 24 * 3600),
            archivedAt: Date().addingTimeInterval(-5 * 24 * 3600)
        ),

        // 已过期 - 超时未回应
        PeacefulClosure(
            title: "小烦恼",
            content: "今天遇到一些小麻烦，现在已经不太在意了",
            createdBy: "partner",
            status: .expired,
            createdAt: Date().addingTimeInterval(-2 * 24 * 3600),
            responseDeadline: Date().addingTimeInterval(-1 * 24 * 3600),
            expiredAt: Date().addingTimeInterval(-1 * 24 * 3600)
        ),

        // 已取消 - 撤回
        PeacefulClosure(
            title: "误会一场",
            content: "之前以为是问题，现在发现是误会",
            createdBy: "me",
            status: .cancelled,
            createdAt: Date().addingTimeInterval(-1 * 3600),
            cancelledAt: Date().addingTimeInterval(-30 * 60)
        )
    ]

    // MARK: - 我发起的安心确认示例数据
    static let myClosureExamples: [PeacefulClosure] = [

        // 待处理 - 刚刚发起
        PeacefulClosure(
            title: "今天心情不错",
            content: "今天阳光很好，心情也跟着明媚起来",
            createdBy: "me",
            status: .pending,
            createdAt: Date().addingTimeInterval(-1 * 3600),
            responseDeadline: Date().addingTimeInterval(23 * 3600)
        ),

        // 已完成 - 获得回应
        PeacefulClosure(
            title: "学习新技能",
            content: "开始学习新的编程语言，感觉很有趣",
            createdBy: "me",
            status: .completed,
            createdAt: Date().addingTimeInterval(-2 * 24 * 3600),
            respondedAt: Date().addingTimeInterval(-1 * 24 * 3600),
            response: "支持你！学习新东西总是很棒的体验",
            acceptedAt: Date().addingTimeInterval(-1 * 24 * 3600)
        ),

        // 已归档 - 早期完成
        PeacefulClosure(
            title: "运动成果",
            content: "坚持运动一个月，感觉身体状态好多了",
            createdBy: "me",
            status: .archived,
            createdAt: Date().addingTimeInterval(-15 * 24 * 3600),
            respondedAt: Date().addingTimeInterval(-14 * 24 * 3600),
            response: "太厉害了！坚持就是胜利",
            acceptedAt: Date().addingTimeInterval(-14 * 24 * 3600),
            archivedAt: Date().addingTimeInterval(-7 * 24 * 3600)
        ),

        // 已取消 - 主动撤回
        PeacefulClosure(
            title: "已经解决了",
            content: "之前遇到的困难现在已经解决了",
            createdBy: "me",
            status: .cancelled,
            createdAt: Date().addingTimeInterval(-30 * 60),
            cancelledAt: Date().addingTimeInterval(-5 * 60)
        )
    ]

    // MARK: - 不同状态的安心确认显示效果
    static func getClosuresByStatus(_ status: ClosureStatus) -> [ClosureIndicate] {
        switch status {
        case .pending:
            return [
                ClosureIndicate(
                    title: "待处理事项",
                    description: "有新的安心确认等待您的回应",
                    badge: "待确认",
                    color: .orange,
                    action: "respond"
                )
            ]
        case .completed:
            return [
                ClosureIndicate(
                    title: "已完成的确认",
                    description: "双方已确认完成",
                    badge: "已完成",
                    color: .green,
                    action: "view"
                )
            ]
        case .archived:
            return [
                ClosureIndicate(
                    title: "已归档的确认",
                    description: "历史记录",
                    badge: "已归档",
                    color: .gray,
                    action: "archive"
                )
            ]
        case .expired:
            return [
                ClosureIndicate(
                    title: "已过期",
                    description: "确认已过期",
                    badge: "已过期",
                    color: .red,
                    action: "expired"
                )
            ]
        case .cancelled:
            return [
                ClosureIndicate(
                    title: "已取消",
                    description: "发起人已撤回",
                    badge: "已取消",
                    color: .gray,
                    action: "cancelled"
                )
            ]
        }
    }
}

// MARK: - 安心确认展示指示器
struct ClosureIndicate {
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
extension ClosureIndicate {
    var appropriateIcon: String {
        switch badge {
        case "待确认": return "clock"
        case "已完成": return "checkmark.circle.fill"
        case "已归档": return "archivebox"
        case "已过期": return "exclamationmark.triangle.fill"
        case "已取消": return "xmark.circle.fill"
        default: return "circle"
        }
    }
}