//
//  GiftBoxResponseView.swift
//  Personal Space
//
//  Created by Penn on 2025/1/27.
//

import SwiftUI

struct GiftBoxResponseView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var userState: UserState

    let giftBox: GiftBox
    @State private var selectedResponse: GiftBoxResponse? = nil
    @State private var acceptedStartTime: Date = Date()
    @State private var acceptedEndTime: Date? = nil
    @State private var actualLocation: String = ""
    @State private var hasEndTime: Bool = false

    // 表单验证
    private var isFormValid: Bool {
        guard let response = selectedResponse else { return false }

        switch response {
        case .accepted:
            return !actualLocation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                   userState.validateAcceptTime(
                       startTime: acceptedStartTime,
                       endTime: acceptedEndTime,
                       preparationTime: giftBox.preparationTime
                   )
        case .rejected:
            return true // 拒绝时无需填写额外信息
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    // 心意盒信息
                    giftBoxInfoSection

                    // 响应选择
                    responseSection

                    // 接受时的详细信息
                    if selectedResponse == .accepted {
                        acceptDetailsSection
                    }

                    Spacer(minLength: 100)
                }
                .padding(AppTheme.Spacing.lg)
            }
            .background(AppGradient.background)
            .navigationTitle("TA的心意")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(AppTheme.Colors.text)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("确认回应") {
                        submitResponse()
                    }
                    .foregroundColor(isFormValid ? AppTheme.Colors.primary : AppTheme.Colors.textSecondary)
                    .disabled(!isFormValid)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            actualLocation = giftBox.suggestedLocation
            acceptedStartTime = userState.getEarliestAcceptTime(for: giftBox)
        }
    }

    // MARK: - 视图组件

    private var giftBoxInfoSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack {
                Image(systemName: "gift.fill")
                    .font(.system(size: 24))
                    .foregroundColor(AppTheme.Colors.primary)

                Text("心意详情")
                    .font(.system(size: AppTheme.FontSize.headline, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.text)
            }

            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                HStack {
                    Text("物品:")
                        .font(.system(size: AppTheme.FontSize.body, weight: .medium))
                        .foregroundColor(AppTheme.Colors.text)

                    Text(giftBox.item)
                        .font(.system(size: AppTheme.FontSize.body))
                        .foregroundColor(AppTheme.Colors.text)
                }

                HStack {
                    Text("建议地点:")
                        .font(.system(size: AppTheme.FontSize.body, weight: .medium))
                        .foregroundColor(AppTheme.Colors.text)

                    Text(giftBox.suggestedLocation)
                        .font(.system(size: AppTheme.FontSize.body))
                        .foregroundColor(AppTheme.Colors.text)
                }

                if let note = giftBox.note, !note.isEmpty {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        Text("备注:")
                            .font(.system(size: AppTheme.FontSize.body, weight: .medium))
                            .foregroundColor(AppTheme.Colors.text)

                        Text(note)
                            .font(.system(size: AppTheme.FontSize.body))
                            .foregroundColor(AppTheme.Colors.text)
                            .padding()
                            .background(AppTheme.Colors.cardBg.opacity(0.5))
                            .cornerRadius(AppTheme.Radius.medium)
                    }
                }

                HStack {
                    Text("心意准备时间:")
                        .font(.system(size: AppTheme.FontSize.body, weight: .medium))
                        .foregroundColor(AppTheme.Colors.text)

                    Text(formatPreparationTime(giftBox.preparationTime))
                        .font(.system(size: AppTheme.FontSize.body))
                        .foregroundColor(AppTheme.Colors.text)

                    Text("(最早可在\(formatTime(userState.getEarliestAcceptTime(for: giftBox)))接受)")
                        .font(.system(size: AppTheme.FontSize.caption))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
        }
        .padding()
        .background(AppTheme.Colors.cardBg)
        .cornerRadius(AppTheme.Radius.large)
        .shadow(color: AppTheme.Shadows.card, radius: 6, x: 0, y: 3)
    }

    private var responseSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack {
                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.pink)

                Text("你的回应")
                    .font(.system(size: AppTheme.FontSize.headline, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.text)
            }

            HStack(spacing: AppTheme.Spacing.lg) {
                ForEach(GiftBoxResponse.allCases, id: \.self) { response in
                    Button(action: {
                        selectedResponse = response
                    }) {
                        Text(response.rawValue)
                            .font(.system(size: AppTheme.FontSize.subheadline, weight: .medium))
                            .foregroundColor(selectedResponse == response ? .white : AppTheme.Colors.primary)
                            .padding(.horizontal, AppTheme.Spacing.lg)
                            .padding(.vertical, AppTheme.Spacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: AppTheme.Radius.large)
                                    .fill(selectedResponse == response ? AppTheme.Colors.primary : AppTheme.Colors.primary.opacity(0.1))
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding()
        .background(AppTheme.Colors.cardBg)
        .cornerRadius(AppTheme.Radius.large)
        .shadow(color: AppTheme.Shadows.card, radius: 6, x: 0, y: 3)
    }

    private var acceptDetailsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 20))
                    .foregroundColor(AppTheme.Colors.primary)

                Text("接受时间")
                    .font(.system(size: AppTheme.FontSize.headline, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.text)

                Text("*")
                    .font(.system(size: AppTheme.FontSize.headline, weight: .bold))
                    .foregroundColor(.red)
            }

            VStack(spacing: AppTheme.Spacing.sm) {
                // 开始时间
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text("开始时间")
                        .font(.system(size: AppTheme.FontSize.caption, weight: .medium))
                        .foregroundColor(AppTheme.Colors.textSecondary)

                    DatePicker("", selection: $acceptedStartTime, in: userState.getEarliestAcceptTime(for: giftBox)...)
                        .datePickerStyle(CompactDatePickerStyle())
                        .labelsHidden()
                }

                // 结束时间
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    HStack {
                        Text("结束时间")
                            .font(.system(size: AppTheme.FontSize.caption, weight: .medium))
                            .foregroundColor(AppTheme.Colors.textSecondary)

                        Text("(可选)")
                            .font(.system(size: AppTheme.FontSize.caption))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }

                    Toggle("设置结束时间", isOn: $hasEndTime)
                        .toggleStyle(SwitchToggleStyle(tint: AppTheme.Colors.primary))

                    if hasEndTime {
                        DatePicker("", selection: Binding(
                            get: { acceptedEndTime ?? acceptedStartTime.addingTimeInterval(3600) },
                            set: { acceptedEndTime = $0 }
                        ), in: acceptedStartTime.addingTimeInterval(60)...)
                        .datePickerStyle(CompactDatePickerStyle())
                        .labelsHidden()
                    }
                }

                // 接受地点
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text("接受地点")
                        .font(.system(size: AppTheme.FontSize.caption, weight: .medium))
                        .foregroundColor(AppTheme.Colors.textSecondary)

                    TextField("请输入接受地点", text: $actualLocation)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
            }
        }
        .padding()
        .background(AppTheme.Colors.cardBg)
        .cornerRadius(AppTheme.Radius.large)
        .shadow(color: AppTheme.Shadows.card, radius: 6, x: 0, y: 3)
    }

    // MARK: - 辅助方法

    private func formatPreparationTime(_ time: TimeInterval) -> String {
        let minutes = Int(time / 60)
        if minutes < 60 {
            return "\(minutes)分钟"
        } else {
            let hours = minutes / 60
            return "\(hours)小时"
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private func submitResponse() {
        guard let response = selectedResponse else { return }

        let finalEndTime = hasEndTime ? acceptedEndTime : nil

        userState.respondToGiftBox(
            giftBox,
            response: response,
            acceptedStartTime: response == .accepted ? acceptedStartTime : nil,
            acceptedEndTime: finalEndTime,
            actualLocation: response == .accepted ? actualLocation.trimmingCharacters(in: .whitespacesAndNewlines) : nil
        )

        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - 预览
#Preview {
    let sampleGiftBox = GiftBox(
        item: "精美项链",
        note: "希望你喜欢这个小惊喜",
        suggestedLocation: "公司前台",
        preparationTime: 1800,
        isFromMe: false
    )

    GiftBoxResponseView(giftBox: sampleGiftBox)
        .environmentObject(UserState())
}