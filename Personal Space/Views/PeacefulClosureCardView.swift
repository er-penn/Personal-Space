//
//  PeacefulClosureCardView.swift
//  Personal Space
//
//  Created by Penn on 2025/1/27.
//

import SwiftUI

struct PeacefulClosureCardView: View {
    let closure: PeacefulClosure
    let onTap: (() -> Void)?
    let onCancel: ((PeacefulClosure) -> Void)?
    let isMyClosure: Bool // 是否是我发起的

    init(closure: PeacefulClosure, onTap: (() -> Void)? = nil, onCancel: ((PeacefulClosure) -> Void)? = nil, isMyClosure: Bool = false) {
        self.closure = closure
        self.onTap = onTap
        self.onCancel = onCancel
        self.isMyClosure = isMyClosure
    }

    var body: some View {
        VStack(spacing: 0) {
            // 主要内容
            mainContentSection

            // 响应结果（如果已完成）
            if let response = closure.response {
                responseSection(response)
            }
        }
        .background(AppTheme.Colors.cardBg)
        .cornerRadius(AppTheme.Radius.large)
        .shadow(color: AppTheme.Shadows.card, radius: 6, x: 0, y: 3)
        .onTapGesture {
            onTap?()
        }
    }

    // MARK: - 主要内容部分
    private var mainContentSection: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // 标题行
            HStack(spacing: AppTheme.Spacing.sm) {
                // 类型标签（图标+文字，绿色）
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.green)
                    
                    Text("确认")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.green)
                }
                .frame(width: 50, alignment: .leading)

                // 标题
                Text(closure.title)
                    .font(.system(size: AppTheme.FontSize.headline, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.text)
                    .lineLimit(1)

                Spacer()

                // 时间和撤销按钮
                HStack(spacing: AppTheme.Spacing.sm) {
                    // 时间
                    Text(formatTime(closure.timestamp))
                        .font(.system(size: AppTheme.FontSize.caption))
                        .foregroundColor(AppTheme.Colors.textSecondary)

                    // 撤销按钮（仅我发起的且待处理的）
                    if isMyClosure && closure.status == .pending {
                        Button(action: {
                            onCancel?(closure)
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.red)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }

                    // 状态图标
                    statusIcon
                }
            }

            // 内容
            Text(closure.content)
                .font(.system(size: AppTheme.FontSize.body))
                .foregroundColor(AppTheme.Colors.text)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(3)

            // 物品类额外信息
            if let itemDetails = closure.itemDetails {
                itemDetailsInfo(itemDetails)
            }
        }
        .padding(AppTheme.Spacing.lg)
    }

    // MARK: - 响应结果部分
    private func responseSection(_ response: PeacefulClosureResponse) -> some View {
        VStack(spacing: 0) {
            Divider()
                .background(AppTheme.Colors.border)

            HStack(spacing: AppTheme.Spacing.md) {
                // 确认图标
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.green)

                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text("回应：\(response.content)")
                        .font(.system(size: AppTheme.FontSize.subheadline, weight: .medium))
                        .foregroundColor(AppTheme.Colors.text)

                    HStack(spacing: AppTheme.Spacing.sm) {
                        Text("时间：\(formatTime(response.timestamp))")
                            .font(.system(size: AppTheme.FontSize.caption))
                            .foregroundColor(AppTheme.Colors.textSecondary)

                        Spacer()

                        Text(confirmationMessage)
                            .font(.system(size: AppTheme.FontSize.caption))
                            .foregroundColor(AppTheme.Colors.primary)
                    }
                }

                Spacer()
            }
            .padding(AppTheme.Spacing.lg)
            .background(AppTheme.Colors.bgMain.opacity(0.5))
        }
    }

    // MARK: - 物品类额外信息
    private func itemDetailsInfo(_ details: ItemDetails) -> some View {
        VStack(spacing: AppTheme.Spacing.xs) {
            if let location = details.location {
                HStack(spacing: AppTheme.Spacing.sm) {
                    Text("📍")
                        .font(.system(size: 14))

                    Text(location)
                        .font(.system(size: AppTheme.FontSize.caption))
                        .foregroundColor(AppTheme.Colors.textSecondary)

                    Spacer()
                }
            }

            if let extraInfo = details.extraInfo {
                HStack(spacing: AppTheme.Spacing.sm) {
                    Text("📝")
                        .font(.system(size: 14))

                    Text(extraInfo)
                        .font(.system(size: AppTheme.FontSize.caption))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .lineLimit(2)

                    Spacer()
                }
            }
        }
    }

    // MARK: - 状态图标
    private var statusIcon: some View {
        Group {
            switch closure.status {
            case .pending:
                Image(systemName: "clock")
                    .font(.system(size: 16))
                    .foregroundColor(.orange)
            case .completed:
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.green)
            case .archived:
                Image(systemName: "archivebox")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
            case .expired:
                Image(systemName: "clock.badge.exclamationmark")
                    .font(.system(size: 16))
                    .foregroundColor(.red)
            case .cancelled:
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.red)
            }
        }
    }

    // MARK: - 确认消息
    private var confirmationMessage: String {
        guard let response = closure.response else { return "" }

        if closure.type == .item {
            // 物品类：检查是否匹配预定义选项
            for responseType in ItemResponseType.allCases {
                if response.content.contains(responseType.rawValue) {
                    return responseType.confirmationMessage
                }
            }
            return "对方已回复，事情办结"
        } else {
            // 事务类
            if response.content == "Done" {
                return "对方已确认，事情办结"
            } else {
                return "对方已回复，事情办结"
            }
        }
    }

    // MARK: - 辅助方法
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - 待处理安心确认卡片
struct PendingPeacefulClosureCardView: View {
    let closure: PeacefulClosure
    let onResponse: (String) -> Void

    var body: some View {
        VStack(spacing: 0) {
            // 主要内容
            mainContentSection

            // 响应区域
            responseSection
        }
        .background(AppTheme.Colors.cardBg)
        .cornerRadius(AppTheme.Radius.large)
        .shadow(color: AppTheme.Shadows.card, radius: 6, x: 0, y: 3)
    }

    // MARK: - 主要内容部分
    private var mainContentSection: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // 标题行
            HStack(spacing: AppTheme.Spacing.sm) {
                // 类型标签（图标+文字，绿色）
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.green)
                    
                    Text("确认")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.green)
                }
                .frame(width: 50, alignment: .leading)

                // 标题
                Text(closure.title)
                    .font(.system(size: AppTheme.FontSize.headline, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.text)
                    .lineLimit(1)

                Spacer()

                // 时间
                Text(formatTime(closure.timestamp))
                    .font(.system(size: AppTheme.FontSize.caption))
                    .foregroundColor(AppTheme.Colors.textSecondary)

                // 待处理图标
                Image(systemName: "exclamationmark.bubble.fill")
                    .font(.system(size: 16))
                    .foregroundColor(AppTheme.Colors.primary)
            }

            // 内容
            Text(closure.content)
                .font(.system(size: AppTheme.FontSize.body))
                .foregroundColor(AppTheme.Colors.text)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(3)

            // 物品类额外信息
            if let itemDetails = closure.itemDetails {
                itemDetailsInfo(itemDetails)
            }
        }
        .padding(AppTheme.Spacing.lg)
    }

    // MARK: - 响应区域
    private var responseSection: some View {
        VStack(spacing: 0) {
            Divider()
                .background(AppTheme.Colors.border)

            if closure.type == .item {
                itemResponseButtons
            } else {
                affairResponseInput
            }
        }
    }

    // MARK: - 物品类响应按钮
    private var itemResponseButtons: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Text("请选择你的回应")
                .font(.system(size: AppTheme.FontSize.subheadline, weight: .medium))
                .foregroundColor(AppTheme.Colors.text)

            HStack(spacing: AppTheme.Spacing.sm) {
                ForEach(ItemResponseType.allCases, id: \.self) { responseType in
                    Button(action: { onResponse(responseType.rawValue) }) {
                        HStack(spacing: 4) {
                            Text(responseType.icon)
                                .font(.system(size: 14))
                            Text(responseType.rawValue)
                                .font(.system(size: AppTheme.FontSize.caption, weight: .medium))
                        }
                        .foregroundColor(AppTheme.Colors.primary)
                        .padding(.horizontal, AppTheme.Spacing.sm)
                        .padding(.vertical, AppTheme.Spacing.xs)
                        .background(AppTheme.Colors.primary.opacity(0.1))
                        .cornerRadius(AppTheme.Radius.small)
                    }
                }
            }
        }
        .padding(AppTheme.Spacing.md)
    }

    // MARK: - 事务类响应输入
    private var affairResponseInput: some View {
        AffairQuickResponse(onResponse: onResponse)
    }

    // MARK: - 物品类额外信息
    private func itemDetailsInfo(_ details: ItemDetails) -> some View {
        VStack(spacing: AppTheme.Spacing.xs) {
            if let location = details.location {
                HStack(spacing: AppTheme.Spacing.sm) {
                    Text("📍")
                        .font(.system(size: 14))

                    Text(location)
                        .font(.system(size: AppTheme.FontSize.caption))
                        .foregroundColor(AppTheme.Colors.textSecondary)

                    Spacer()
                }
            }

            if let extraInfo = details.extraInfo {
                HStack(spacing: AppTheme.Spacing.sm) {
                    Text("📝")
                        .font(.system(size: 14))

                    Text(extraInfo)
                        .font(.system(size: AppTheme.FontSize.caption))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .lineLimit(2)

                    Spacer()
                }
            }
        }
    }

    // MARK: - 辅助方法
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - 事务类快速响应
struct AffairQuickResponse: View {
    let onResponse: (String) -> Void
    @State private var responseText: String = ""

    var body: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            HStack(spacing: AppTheme.Spacing.sm) {
                TextField("可以输入任何内容...", text: $responseText)
                    .font(.system(size: AppTheme.FontSize.caption))
                    .textFieldStyle(PlainTextFieldStyle())

                Button("Done") {
                    let finalResponse = responseText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Done" : responseText.trimmingCharacters(in: .whitespacesAndNewlines)
                    onResponse(finalResponse)
                }
                .font(.system(size: AppTheme.FontSize.caption, weight: .semibold))
                .foregroundColor(AppTheme.Colors.primary)
                .disabled(responseText.isEmpty && false) // Done按钮始终可用
            }

            Text("输入框为选填，直接点Done即可")
                .font(.system(size: AppTheme.FontSize.caption2))
                .foregroundColor(AppTheme.Colors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.sm)
    }
}

#Preview {
    VStack(spacing: AppTheme.Spacing.md) {
        // 待处理的物品类
        PendingPeacefulClosureCardView(closure: sampleItemClosure) { response in
            print("Response: \(response)")
        }

        // 已完成的物品类
        PeacefulClosureCardView(closure: sampleCompletedItemClosure, isMyClosure: false)

        // 事务类
        PeacefulClosureCardView(closure: sampleAffairClosure, isMyClosure: false)
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}

// MARK: - 示例数据
private let sampleItemClosure = PeacefulClosure(
    type: .item,
    title: "包裹在前台",
    content: "快递员王师傅已将包裹放在前台，取件码8567",
    itemDetails: ItemDetails(
        itemName: "快递包裹",
        location: "前台",
        expectedTime: nil,
        extraInfo: "取件码：8567"
    ),
    createdBy: "partner",
    targetUser: "me"
)

private let sampleCompletedItemClosure = PeacefulClosure(
    id: UUID(),
    type: .item,
    title: "包裹在前台",
    content: "快递员王师傅已将包裹放在前台，取件码8567",
    itemDetails: ItemDetails(
        itemName: "快递包裹",
        location: "前台",
        expectedTime: nil,
        extraInfo: "取件码：8567"
    ),
    timestamp: Date().addingTimeInterval(-3600),
    status: .completed,
    createdBy: "partner",
    targetUser: "me",
    response: PeacefulClosureResponse(content: "拿到啦 🙌")
)

private let sampleAffairClosure = PeacefulClosure(
    id: UUID(),
    type: .affair,
    title: "我已安全到家",
    content: "已经到家了，请放心",
    timestamp: Date().addingTimeInterval(-1800),
    status: .completed,
    createdBy: "partner",
    targetUser: "me",
    response: PeacefulClosureResponse(content: "收到啦，放心吧")
)