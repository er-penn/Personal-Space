//
//  PeacefulClosureCreateView.swift
//  Personal Space
//
//  Created by Penn on 2025/1/27.
//

import SwiftUI

struct PeacefulClosureCreateView: View {
    @EnvironmentObject var userState: UserState
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedType: PeacefulClosureType = .item
    @State private var showingDetailsForm = false

    // 物品类表单数据
    @State private var itemName: String = ""
    @State private var location: String = ""
    @State private var expectedTime: Date = Date()
    @State private var useTime = false
    @State private var extraInfo: String = ""

    // 事务类表单数据
    @State private var affairContent: String = ""
    @State private var hasExpiration = false
    @State private var expirationTime: Date = Date().addingTimeInterval(86400) // 默认24小时后

    // 事务类快捷模板
    private let affairTemplates = [
        "我已安全到家，放心吧",
        "事情已经处理好了",
        "重要信息跟你说一下",
        "紧急情况已搞定",
        "约定时间我准备好了"
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    // 类型选择
                    typeSelectionSection

                    // 详情表单
                    if showingDetailsForm {
                        detailsFormSection
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.lg)
                .padding(.top, AppTheme.Spacing.lg)
            }
            .background(AppGradient.background)
            .navigationTitle("安心确认")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(AppTheme.Colors.primary)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("发送") {
                        sendPeacefulClosure()
                    }
                    .foregroundColor(AppTheme.Colors.primary)
                    .disabled(!canSend)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    // MARK: - 类型选择部分
    private var typeSelectionSection: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Text("选择类型")
                .font(.system(size: AppTheme.FontSize.headline, weight: .semibold))
                .foregroundColor(AppTheme.Colors.text)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: AppTheme.Spacing.md) {
                // 物品类选项
                TypeSelectionCard(
                    type: .item,
                    isSelected: selectedType == .item,
                    onTap: { selectType(.item) }
                )

                // 事务类选项
                TypeSelectionCard(
                    type: .affair,
                    isSelected: selectedType == .affair,
                    onTap: { selectType(.affair) }
                )
            }
        }
    }

    // MARK: - 详情表单部分
    private var detailsFormSection: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            if selectedType == .item {
                itemForm
            } else {
                affairForm
            }
        }
    }

    // MARK: - 物品类表单
    private var itemForm: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // 物品名称
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                Text("物品名称 *")
                    .font(.system(size: AppTheme.FontSize.subheadline, weight: .medium))
                    .foregroundColor(AppTheme.Colors.text)

                TextField("请输入物品名称", text: $itemName)
                    .font(.system(size: AppTheme.FontSize.body))
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .padding(.vertical, AppTheme.Spacing.sm)
                    .background(AppTheme.Colors.cardBg)
                    .cornerRadius(AppTheme.Radius.medium)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                            .stroke(AppTheme.Colors.border, lineWidth: 1)
                    )
            }

            // 地点
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                Text("地点")
                    .font(.system(size: AppTheme.FontSize.subheadline, weight: .medium))
                    .foregroundColor(AppTheme.Colors.text)

                TextField("请输入具体地点", text: $location)
                    .font(.system(size: AppTheme.FontSize.body))
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .padding(.vertical, AppTheme.Spacing.sm)
                    .background(AppTheme.Colors.cardBg)
                    .cornerRadius(AppTheme.Radius.medium)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                            .stroke(AppTheme.Colors.border, lineWidth: 1)
                    )
            }

            // 预计时间
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                HStack {
                    Text("预计时间")
                        .font(.system(size: AppTheme.FontSize.subheadline, weight: .medium))
                        .foregroundColor(AppTheme.Colors.text)

                    Spacer()

                    Toggle("", isOn: $useTime)
                        .labelsHidden()
                }

                if useTime {
                    DatePicker("选择时间", selection: $expectedTime, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(CompactDatePickerStyle())
                        .font(.system(size: AppTheme.FontSize.body))
                        .accentColor(AppTheme.Colors.primary)
                }
            }

            // 补充说明
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                Text("补充说明")
                    .font(.system(size: AppTheme.FontSize.subheadline, weight: .medium))
                    .foregroundColor(AppTheme.Colors.text)

                if #available(iOS 16.0, *) {
                    TextField("额外信息...", text: $extraInfo, axis: .vertical)
                        .font(.system(size: AppTheme.FontSize.body))
                        .padding(.horizontal, AppTheme.Spacing.md)
                        .padding(.vertical, AppTheme.Spacing.sm)
                        .background(AppTheme.Colors.cardBg)
                        .cornerRadius(AppTheme.Radius.medium)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                                .stroke(AppTheme.Colors.border, lineWidth: 1)
                        )
                        .lineLimit(3)
                } else {
                    // iOS 15 兼容：使用 TextEditor
                    ZStack(alignment: .topLeading) {
                        if extraInfo.isEmpty {
                            Text("额外信息...")
                                .font(.system(size: AppTheme.FontSize.body))
                                .foregroundColor(AppTheme.Colors.textSecondary)
                                .padding(.horizontal, AppTheme.Spacing.md + 4)
                                .padding(.vertical, AppTheme.Spacing.sm + 8)
                        }
                        TextEditor(text: $extraInfo)
                            .font(.system(size: AppTheme.FontSize.body))
                            .padding(.horizontal, AppTheme.Spacing.md)
                            .padding(.vertical, AppTheme.Spacing.sm)
                            .frame(minHeight: 70)
                            .background(AppTheme.Colors.cardBg)
                            .cornerRadius(AppTheme.Radius.medium)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                                    .stroke(AppTheme.Colors.border, lineWidth: 1)
                            )
                    }
                }
            }
        }
    }

    // MARK: - 事务类表单
    private var affairForm: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // 事务内容
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                Text("事务内容 *")
                    .font(.system(size: AppTheme.FontSize.subheadline, weight: .medium))
                    .foregroundColor(AppTheme.Colors.text)

                if #available(iOS 16.0, *) {
                    TextField("请输入事务内容", text: $affairContent, axis: .vertical)
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
                        if affairContent.isEmpty {
                            Text("请输入事务内容")
                                .font(.system(size: AppTheme.FontSize.body))
                                .foregroundColor(AppTheme.Colors.textSecondary)
                                .padding(.horizontal, AppTheme.Spacing.md + 4)
                                .padding(.vertical, AppTheme.Spacing.sm + 8)
                        }
                        TextEditor(text: $affairContent)
                            .font(.system(size: AppTheme.FontSize.body))
                            .padding(.horizontal, AppTheme.Spacing.md)
                            .padding(.vertical, AppTheme.Spacing.sm)
                            .frame(minHeight: 100)
                            .background(AppTheme.Colors.cardBg)
                            .cornerRadius(AppTheme.Radius.medium)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                                    .stroke(AppTheme.Colors.border, lineWidth: 1)
                            )
                    }
                }
            }

            // 快捷模板
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                Text("快捷模板")
                    .font(.system(size: AppTheme.FontSize.subheadline, weight: .medium))
                    .foregroundColor(AppTheme.Colors.text)

                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: AppTheme.Spacing.sm) {
                    ForEach(affairTemplates, id: \.self) { template in
                        Button(template) {
                            affairContent = template
                        }
                        .font(.system(size: AppTheme.FontSize.caption))
                        .foregroundColor(AppTheme.Colors.primary)
                        .padding(.horizontal, AppTheme.Spacing.sm)
                        .padding(.vertical, AppTheme.Spacing.xs)
                        .background(AppTheme.Colors.primary.opacity(0.1))
                        .cornerRadius(AppTheme.Radius.small)
                    }
                }
            }

            // 有效期设置
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                HStack {
                    Text("有效期")
                        .font(.system(size: AppTheme.FontSize.subheadline, weight: .medium))
                        .foregroundColor(AppTheme.Colors.text)

                    Spacer()

                    Toggle("", isOn: $hasExpiration)
                        .labelsHidden()
                }

                if hasExpiration {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        DatePicker("截止时间", selection: $expirationTime, displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(CompactDatePickerStyle())
                            .font(.system(size: AppTheme.FontSize.body))
                            .accentColor(AppTheme.Colors.primary)

                        Text("设置后，收信息方需要在截止时间前回复，过期后消息自动失效")
                            .font(.system(size: AppTheme.FontSize.caption))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                }
            }
        }
    }

    // MARK: - 辅助方法
    private func selectType(_ type: PeacefulClosureType) {
        selectedType = type
        withAnimation(.easeInOut(duration: 0.3)) {
            showingDetailsForm = true
        }
    }

    private var canSend: Bool {
        if selectedType == .item {
            return !itemName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        } else {
            return !affairContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    private func sendPeacefulClosure() {
        let title: String
        let content: String
        var itemDetails: ItemDetails?

        if selectedType == .item {
            title = itemName.trimmingCharacters(in: .whitespacesAndNewlines)

            var contentParts = [title]
            if !location.isEmpty {
                contentParts.append("地点：\(location)")
            }
            if !extraInfo.isEmpty {
                contentParts.append(extraInfo)
            }
            content = contentParts.joined(separator: "\n")

            if !location.isEmpty || useTime || !extraInfo.isEmpty {
                itemDetails = ItemDetails(
                    itemName: title,
                    location: location.isEmpty ? nil : location,
                    expectedTime: useTime ? expectedTime : nil,
                    extraInfo: extraInfo.isEmpty ? nil : extraInfo
                )
            }
        } else {
            title = extractTitleFromContent(affairContent)
            content = affairContent.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        userState.createPeacefulClosure(
            type: selectedType,
            title: title,
            content: content,
            itemDetails: itemDetails,
            expiresAt: selectedType == .affair && hasExpiration ? expirationTime : nil,
            hasExpiration: selectedType == .affair && hasExpiration
        )

        presentationMode.wrappedValue.dismiss()
    }

    private func extractTitleFromContent(_ content: String) -> String {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count > 10 {
            return String(trimmed.prefix(10)) + "..."
        }
        return trimmed
    }
}

// MARK: - 类型选择卡片
struct TypeSelectionCard: View {
    let type: PeacefulClosureType
    let isSelected: Bool
    let onTap: () -> Void

    private var icon: String {
        type == .item ? "📦" : "🏠"
    }

    private var examples: [String] {
        type == .item ? ["包裹送达", "钥匙转交", "药品购买"] : ["安全到家", "通知知晓", "任务完成"]
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: AppTheme.Spacing.md) {
                // 图标
                Text(icon)
                    .font(.system(size: 40))

                // 类型名称
                Text(type.rawValue)
                    .font(.system(size: AppTheme.FontSize.headline, weight: .semibold))
                    .foregroundColor(isSelected ? .white : AppTheme.Colors.text)

                // 示例
                VStack(spacing: AppTheme.Spacing.xs) {
                    ForEach(examples, id: \.self) { example in
                        Text(example)
                            .font(.system(size: AppTheme.FontSize.caption))
                            .foregroundColor(isSelected ? .white.opacity(0.9) : AppTheme.Colors.textSecondary)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.Spacing.lg)
            .padding(.horizontal, AppTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.large)
                    .fill(isSelected ? AppTheme.Colors.primary : AppTheme.Colors.cardBg)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.large)
                    .stroke(isSelected ? AppTheme.Colors.primary : AppTheme.Colors.border, lineWidth: isSelected ? 0 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    PeacefulClosureCreateView()
        .environmentObject(UserState())
}