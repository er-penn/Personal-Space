//
//  TimePickerView.swift
//  Personal Space
//
//  Created by Penn on 2025/1/27.
//

import SwiftUI

struct GiftBoxTimePickerView: View {
    @Binding var selectedDays: Int
    @Binding var selectedHours: Int
    @Binding var selectedMinutes: Int
    @State private var showingPicker = false

    // 最小时间限制：15分钟
    private var totalMinutes: Int {
        return selectedDays * 24 * 60 + selectedHours * 60 + selectedMinutes
    }

    private var isMinimumTime: Bool {
        return totalMinutes >= 15
    }

    var body: some View {
        Button(action: {
            showingPicker = true
        }) {
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(AppTheme.Colors.primary)

                Text("当前选择：\(formatTime())")
                    .font(.system(size: AppTheme.FontSize.body))
                    .foregroundColor(AppTheme.Colors.text)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.md)
            .background(AppTheme.Colors.cardBg)
            .cornerRadius(AppTheme.Radius.medium)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingPicker) {
            timePickerSheet
        }
    }

    private var timePickerSheet: some View {
        NavigationView {
            VStack(spacing: AppTheme.Spacing.lg) {
                // 当前选择预览
                VStack(spacing: AppTheme.Spacing.sm) {
                    Text("心意准备时间")
                        .font(.system(size: AppTheme.FontSize.title2, weight: .semibold))
                        .foregroundColor(AppTheme.Colors.text)

                    Text(formatTime())
                        .font(.system(size: AppTheme.FontSize.title3, weight: .medium))
                        .foregroundColor(AppTheme.Colors.primary)
                        .padding(.horizontal, AppTheme.Spacing.lg)
                        .padding(.vertical, AppTheme.Spacing.md)
                        .background(AppTheme.Colors.primary.opacity(0.1))
                        .cornerRadius(AppTheme.Radius.large)
                }
                .padding(.top, AppTheme.Spacing.lg)

                // 三列选择器
                HStack(spacing: AppTheme.Spacing.md) {
                    // 天数选择器
                    VStack(spacing: AppTheme.Spacing.xs) {
                        Text("天")
                            .font(.system(size: AppTheme.FontSize.caption, weight: .semibold))
                            .foregroundColor(AppTheme.Colors.textSecondary)

                        Picker("天", selection: $selectedDays) {
                            ForEach(0...5, id: \.self) { day in
                                Text("\(day)").tag(day)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(width: 60, height: 200)
                        .clipped()
                    }

                    // 小时选择器
                    VStack(spacing: AppTheme.Spacing.xs) {
                        Text("小时")
                            .font(.system(size: AppTheme.FontSize.caption, weight: .semibold))
                            .foregroundColor(AppTheme.Colors.textSecondary)

                        Picker("小时", selection: $selectedHours) {
                            ForEach(0...23, id: \.self) { hour in
                                Text("\(hour)").tag(hour)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(width: 60, height: 200)
                        .clipped()
                    }

                    // 分钟选择器
                    VStack(spacing: AppTheme.Spacing.xs) {
                        Text("分钟")
                            .font(.system(size: AppTheme.FontSize.caption, weight: .semibold))
                            .foregroundColor(AppTheme.Colors.textSecondary)

                        Picker("分钟", selection: $selectedMinutes) {
                            ForEach([0, 15, 30, 45], id: \.self) { minute in
                                Text("\(minute)").tag(minute)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(width: 60, height: 200)
                        .clipped()
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.lg)

                // 说明文字
                if !isMinimumTime {
                    Text("⚠️ 准备时间不能少于15分钟")
                        .font(.system(size: AppTheme.FontSize.caption))
                        .foregroundColor(.orange)
                        .padding(.horizontal, AppTheme.Spacing.lg)
                }

                Text("对方最早可在当前时间 + 准备时间后接受心意")
                    .font(.system(size: AppTheme.FontSize.caption))
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppTheme.Spacing.lg)

                Spacer()
            }
            .background(AppGradient.background)
            .navigationTitle("选择准备时间")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        showingPicker = false
                    }
                    .foregroundColor(AppTheme.Colors.text)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("确认") {
                        // 确保最小时间限制
                        if !isMinimumTime {
                            selectedMinutes = 15
                        }
                        showingPicker = false
                    }
                    .foregroundColor(isMinimumTime ? AppTheme.Colors.primary : AppTheme.Colors.textSecondary)
                    .disabled(!isMinimumTime)
                }
            }
        }
        .modifier(PresentationModifier())
    }
    
    // iOS 16.0 兼容性修饰符
    struct PresentationModifier: ViewModifier {
        func body(content: Content) -> some View {
            if #available(iOS 16.0, *) {
                content
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            } else {
                content
            }
        }
    }

    private func formatTime() -> String {
        let totalMinutes = selectedDays * 24 * 60 + selectedHours * 60 + selectedMinutes

        if totalMinutes < 60 {
            return "\(totalMinutes)分钟"
        } else if totalMinutes < 24 * 60 {
            let hours = totalMinutes / 60
            let minutes = totalMinutes % 60
            if minutes == 0 {
                return "\(hours)小时"
            } else {
                return "\(hours)小时\(minutes)分钟"
            }
        } else {
            let days = totalMinutes / (24 * 60)
            let remainingMinutes = totalMinutes % (24 * 60)
            let hours = remainingMinutes / 60
            let minutes = remainingMinutes % 60

            var result = "\(days)天"
            if hours > 0 {
                result += "\(hours)小时"
            }
            if minutes > 0 {
                result += "\(minutes)分钟"
            }
            return result
        }
    }
}

// MARK: - 预览包装器
private struct GiftBoxTimePickerPreview: View {
    @State private var days = 0
    @State private var hours = 0
    @State private var minutes = 30

    var body: some View {
        GiftBoxTimePickerView(
            selectedDays: $days,
            selectedHours: $hours,
            selectedMinutes: $minutes
        )
        .padding()
        .background(AppGradient.background)
    }
}

// MARK: - 预览
#Preview {
    GiftBoxTimePickerPreview()
}