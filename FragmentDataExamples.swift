//
//  FragmentDataExamples.swift
//  Personal Space
//
//  Created by Penn on 2025/1/27.
//

import SwiftUI

struct FragmentDataExamples {

    // MARK: - 所有碎片分享示例数据
    static let allExamples: [Fragment] = [

        // 纯文本 - 我发起的
        Fragment(
            content: "今天看到一只很可爱的小猫，橘色的，胖乎乎的，在路边晒太阳",
            imageURL: nil,
            linkURL: nil,
            createdAt: Date().addingTimeInterval(-30 * 60),
            isFromMe: true
        ),

        // 纯文本 - 对方发起的
        Fragment(
            content: "下班路上看到夕阳很美，想到了你",
            imageURL: nil,
            linkURL: nil,
            createdAt: Date().addingTimeInterval(-2 * 3600),
            isFromMe: false
        ),

        // 带图片 - 我发起的
        Fragment(
            content: "今天做的晚餐，味道还不错哦",
            imageURL: "dinner_photo.jpg",
            linkURL: nil,
            createdAt: Date().addingTimeInterval(-5 * 3600),
            isFromMe: true
        ),

        // 带图片 - 对方发起的
        Fragment(
            content: "办公室窗外的景色，雨后的彩虹",
            imageURL: "rainbow.jpg",
            linkURL: nil,
            createdAt: Date().addingTimeInterval(-4 * 3600),
            isFromMe: false
        ),

        // 带链接 - 我发起的
        Fragment(
            content: "分享一篇很有意思的文章，关于时间管理的方法",
            imageURL: nil,
            linkURL: "https://example.com/time-management",
            createdAt: Date().addingTimeInterval(-6 * 3600),
            isFromMe: true
        ),

        // 带链接 - 对方发起的
        Fragment(
            content: "这个视频太有趣了，一定要看",
            imageURL: nil,
            linkURL: "https://example.com/funny-video",
            createdAt: Date().addingTimeInterval(-3 * 3600),
            isFromMe: false
        ),

        // 图文链接都有 - 我发起的
        Fragment(
            content: "发现一家很棒的咖啡店，环境很好，下次可以一起去",
            imageURL: "coffee_shop.jpg",
            linkURL: "https://example.com/coffee-shop-info",
            createdAt: Date().addingTimeInterval(-8 * 3600),
            isFromMe: true
        ),

        // 图文链接都有 - 对方发起的
        Fragment(
            content: "周末去公园玩，拍了很多照片，这里有一张最美的",
            imageURL: "park_photo.jpg",
            linkURL: "https://example.com/park-album",
            createdAt: Date().addingTimeInterval(-12 * 3600),
            isFromMe: false
        ),

        // 短文本 - 我发起的
        Fragment(
            content: "想你❤️",
            imageURL: nil,
            linkURL: nil,
            createdAt: Date().addingTimeInterval(-15 * 60),
            isFromMe: true
        ),

        // 长文本 - 对方发起的
        Fragment(
            content: "今天工作遇到了一些挑战，不过最终还是顺利解决了。感谢你的鼓励和支持，让我有信心面对困难。想到晚上可以和你聊天，一整天的疲惫都消失了。",
            imageURL: nil,
            linkURL: nil,
            createdAt: Date().addingTimeInterval(-10 * 3600),
            isFromMe: false
        )
    ]

    // MARK: - 我发起的碎片分享示例数据
    static let myFragmentExamples: [Fragment] = [

        // 最近的 - 纯文本
        Fragment(
            content: "今天天气真好，心情也跟着好起来了",
            imageURL: nil,
            linkURL: nil,
            createdAt: Date().addingTimeInterval(-1 * 3600),
            isFromMe: true
        ),

        // 今天的 - 带图片
        Fragment(
            content: "午餐吃的麻辣烫，很香",
            imageURL: "lunch.jpg",
            linkURL: nil,
            createdAt: Date().addingTimeInterval(-4 * 3600),
            isFromMe: true
        ),

        // 昨天的 - 带链接
        Fragment(
            content: "这个学习方法很有效，推荐给你",
            imageURL: nil,
            linkURL: "https://example.com/learning-method",
            createdAt: Date().addingTimeInterval(24 * 3600),
            isFromMe: true
        ),

        // 更早的 - 图文链接
        Fragment(
            content: "上周末去爬山，风景很美",
            imageURL: "mountain.jpg",
            linkURL: "https://example.com/mountain-photos",
            createdAt: Date().addingTimeInterval(-3 * 24 * 3600),
            isFromMe: true
        ),

        // 最早的 - 纯文本
        Fragment(
            content: "早上好！又是充满希望的一天",
            imageURL: nil,
            linkURL: nil,
            createdAt: Date().addingTimeInterval(-5 * 24 * 3600),
            isFromMe: true
        )
    ]

    // MARK: - 不同类型的碎片分享显示效果
    static func getFragmentsByType(_ type: FragmentType) -> [FragmentIndicate] {
        switch type {
        case .textOnly:
            return [
                FragmentIndicate(
                    title: "纯文字分享",
                    description: "只有文字内容的碎片",
                    badge: "文字",
                    color: .blue,
                    action: "view"
                )
            ]
        case .imageOnly:
            return [
                FragmentIndicate(
                    title: "图片分享",
                    description: "包含图片的碎片",
                    badge: "图片",
                    color: .green,
                    action: "view"
                )
            ]
        case .linkOnly:
            return [
                FragmentIndicate(
                    title: "链接分享",
                    description: "包含链接的碎片",
                    badge: "链接",
                    color: .orange,
                    action: "open"
                )
            ]
        case .mixed:
            return [
                FragmentIndicate(
                    title: "综合分享",
                    description: "包含多种内容的碎片",
                    badge: "综合",
                    color: .purple,
                    action: "view"
                )
            ]
        }
    }
}

// MARK: - 碎片分享类型枚举
enum FragmentType {
    case textOnly
    case imageOnly
    case linkOnly
    case mixed
}

// MARK: - 碎片分享展示指示器
struct FragmentIndicate {
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
extension FragmentIndicate {
    var appropriateIcon: String {
        switch badge {
        case "文字": return "text.bubble"
        case "图片": return "photo"
        case "链接": return "link"
        case "综合": return "square.stack.3d.up"
        default: return "bubble.left"
        }
    }
}