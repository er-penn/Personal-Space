//
//  PeacefulClosureResponseView.swift
//  Personal Space
//
//  Created by Penn on 2025/1/27.
//

import SwiftUI

struct PeacefulClosureResponseView: View {
    @EnvironmentObject var userState: UserState
    @Environment(\.presentationMode) var presentationMode
    let closure: PeacefulClosure

    // 事务类响应数据
    @State private var responseText: String = ""
    @State private var isSubmitting = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    // 通知详情
                    notificationDetailSection

                    // 响应区域
                    responseSection
                }
                .padding(.horizontal, AppTheme.Spacing.lg)
                .padding(.top, AppTheme.Spacing.lg)
            }
            .background(AppGradient.background)
            .navigationTitle("送达通知")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(AppTheme.Colors.primary)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    // MARK: - 通知详情部分
    private var notificationDetailSection: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // 标题和图标
            HStack(spacing: AppTheme.Spacing.md) {
                Text(closure.type == .item ? "📦" : "🏠")
                    .font(.system(size: 32))

                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text(closure.title)
                        .font(.system(size: AppTheme.FontSize.headline, weight: .semibold))
                        .foregroundColor(AppTheme.Colors.text)

                    Text(formatTime(closure.timestamp))
                        .font(.system(size: AppTheme.FontSize.caption))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }

                Spacer()
            }

            // 内容
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                Text("详情")
                    .font(.system(size: AppTheme.FontSize.subheadline, weight: .medium))
                    .foregroundColor(AppTheme.Colors.text)

                Text(closure.content)
                    .font(.system(size: AppTheme.FontSize.body))
                    .foregroundColor(AppTheme.Colors.text)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(AppTheme.Spacing.md)
                    .background(AppTheme.Colors.cardBg)
                    .cornerRadius(AppTheme.Radius.medium)
            }

            // 物品类额外信息
            if let itemDetails = closure.itemDetails {
                itemDetailsSection(itemDetails)
            }
        }
        .padding(AppTheme.Spacing.lg)
        .background(AppTheme.Colors.cardBg)
        .cornerRadius(AppTheme.Radius.large)
        .shadow(color: AppTheme.Shadows.card, radius: 6, x: 0, y: 3)
    }

    // MARK: - 物品类额外信息
    private func itemDetailsSection(_ details: ItemDetails) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("附加信息")
                .font(.system(size: AppTheme.FontSize.subheadline, weight: .medium))
                .foregroundColor(AppTheme.Colors.text)

            VStack(spacing: AppTheme.Spacing.xs) {
                if let location = details.location {
                    InfoRow(icon: "📍", label: "地点", value: location)
                }

                if let expectedTime = details.expectedTime {
                    InfoRow(icon: "⏰", label: "预计时间", value: formatDateTime(expectedTime))
                }

                if let extraInfo = details.extraInfo {
                    InfoRow(icon: "📝", label: "补充", value: extraInfo)
                }
            }
        }
    }

    // MARK: - 响应区域
    private var responseSection: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            if closure.type == .item {
                itemResponseOptions
            } else {
                affairResponseOptions
            }
        }
    }

    // MARK: - 物品类响应选项
    private var itemResponseOptions: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Text("请选择你的回应")
                .font(.system(size: AppTheme.FontSize.headline, weight: .semibold))
                .foregroundColor(AppTheme.Colors.text)
                .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(ItemResponseType.allCases, id: \.self) { responseType in
                ItemResponseButton(
                    responseType: responseType,
                    onTap: { submitResponse(responseType.rawValue) }
                )
            }
        }
    }

    // MARK: - 事务类响应选项
    private var affairResponseOptions: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Text("请输入你的回应")
                .font(.system(size: AppTheme.FontSize.headline, weight: .semibold))
                .foregroundColor(AppTheme.Colors.text)
                .frame(maxWidth: .infinity, alignment: .leading)

            // 输入框
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                if #available(iOS 16.0, *) {
                    TextField("可以输入任何内容...", text: $responseText, axis: .vertical)
                        .font(.system(size: AppTheme.FontSize.body))
                        .padding(.horizontal, AppTheme.Spacing.md)
                        .padding(.vertical, AppTheme.Spacing.sm)
                        .background(AppTheme.Colors.cardBg)
                        .cornerRadius(AppTheme.Radius.medium)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                                .stroke(AppTheme.Colors.border, lineWidth: 1)
                        )
                        .lineLimit(5)
                } else {
                    // iOS 15 兼容：使用 TextEditor
                    ZStack(alignment: .topLeading) {
                        if responseText.isEmpty {
                            Text("可以输入任何内容...")
                                .font(.system(size: AppTheme.FontSize.body))
                                .foregroundColor(AppTheme.Colors.textSecondary)
                                .padding(.horizontal, AppTheme.Spacing.md + 4)
                                .padding(.vertical, AppTheme.Spacing.sm + 8)
                        }
                        TextEditor(text: $responseText)
                            .font(.system(size: AppTheme.FontSize.body))
                            .padding(.horizontal, AppTheme.Spacing.md)
                            .padding(.vertical, AppTheme.Spacing.sm)
                            .frame(minHeight: 80)
                            .background(AppTheme.Colors.cardBg)
                            .cornerRadius(AppTheme.Radius.medium)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                                    .stroke(AppTheme.Colors.border, lineWidth: 1)
                            )
                    }
                }

                Text("输入框为选填，直接点Done即可")
                    .font(.system(size: AppTheme.FontSize.caption))
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }

            // Done按钮
            Button(action: { submitAffairResponse() }) {
                HStack {
                    Spacer()
                    Text("Done")
                        .font(.system(size: AppTheme.FontSize.headline, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.vertical, AppTheme.Spacing.md)
                .background(AppTheme.Colors.primary)
                .cornerRadius(AppTheme.Radius.medium)
            }
            .disabled(isSubmitting)
        }
    }

    // MARK: - 提交响应
    private func submitResponse(_ response: String) {
        isSubmitting = true
        userState.respondToClosure(closure, response: response)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isSubmitting = false
            presentationMode.wrappedValue.dismiss()
        }
    }

    private func submitAffairResponse() {
        let finalResponse = responseText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Done" : responseText.trimmingCharacters(in: .whitespacesAndNewlines)
        submitResponse(finalResponse)
    }

    // MARK: - 辅助方法
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM月dd日 HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - 信息行
struct InfoRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Text(icon)
                .font(.system(size: 16))

            Text(label)
                .font(.system(size: AppTheme.FontSize.subheadline, weight: .medium))
                .foregroundColor(AppTheme.Colors.text)

            Spacer()

            Text(value)
                .font(.system(size: AppTheme.FontSize.body))
                .foregroundColor(AppTheme.Colors.text)
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.sm)
        .background(AppTheme.Colors.bgMain)
        .cornerRadius(AppTheme.Radius.small)
    }
}

// MARK: - 物品类响应按钮
struct ItemResponseButton: View {
    let responseType: ItemResponseType
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppTheme.Spacing.md) {
                Text(responseType.icon)
                    .font(.system(size: 24))

                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text(responseType.rawValue)
                        .font(.system(size: AppTheme.FontSize.headline, weight: .semibold))
                        .foregroundColor(AppTheme.Colors.text)

                    Text(responseType.description)
                        .font(.system(size: AppTheme.FontSize.body))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }

                Spacer()
            }
            .padding(AppTheme.Spacing.md)
            .background(AppTheme.Colors.cardBg)
            .cornerRadius(AppTheme.Radius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                    .stroke(AppTheme.Colors.border, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    let sampleClosure = PeacefulClosure(
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

    return PeacefulClosureResponseView(closure: sampleClosure)
        .environmentObject(UserState())
}