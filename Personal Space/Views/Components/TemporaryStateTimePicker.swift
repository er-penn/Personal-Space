//
//  TemporaryStateTimePicker.swift
//  Personal Space
//
//  Created by Penn on 2025/1/27.
//

import SwiftUI

struct TemporaryStateTimePicker: View {
    @Binding var selectedDuration: TimeInterval // 选中的持续时间（秒）
    @Binding var isPresented: Bool // 是否显示选择器
    let maxDuration: TimeInterval // 最大持续时间
    let onConfirm: (TimeInterval) -> Void // 确认回调
    let onCancel: () -> Void // 取消回调
    
    @State private var selectedMinutes: Int = 120 // 默认2小时
    
    // 动态生成时间选项，基于maxDuration
    private var timeOptions: [Int] {
        let maxMinutes = Int(maxDuration / 60)
        return Array(stride(from: 15, through: maxMinutes, by: 15))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Button("取消") {
                    onCancel()
                    isPresented = false
                }
                .font(.system(size: AppTheme.FontSize.body))
                .foregroundColor(.secondary)
                
                Spacer()
                
                Text("设置持续时间")
                    .font(.system(size: AppTheme.FontSize.headline, weight: .semibold))
                
                Spacer()
                
                Button("确认") {
                    let duration = TimeInterval(selectedMinutes * 60)
                    onConfirm(duration)
                    isPresented = false
                }
                .font(.system(size: AppTheme.FontSize.headline, weight: .semibold))
                .foregroundColor(.blue)
            }
            .padding(.horizontal, AppTheme.Spacing.xl)
            .padding(.vertical, AppTheme.Spacing.lg)
            
            Divider()
            
            // 时间选择器 - 紧凑布局
            VStack(spacing: AppTheme.Spacing.md) {
                Text("选择持续时间")
                    .font(.system(size: AppTheme.FontSize.subheadline))
                    .foregroundColor(.secondary)
                    .padding(.top, AppTheme.Spacing.lg)
                
                // 时间选择轮盘 - 减少高度
                Picker("持续时间", selection: $selectedMinutes) {
                    ForEach(timeOptions, id: \.self) { minutes in
                        Text(formatTime(minutes))
                            .font(.system(size: AppTheme.FontSize.body))
                            .tag(minutes)
                    }
                }
                .pickerStyle(WheelPickerStyle())
                .frame(height: 80) // 大幅减少高度
                .onChange(of: selectedMinutes) { newValue in
                    selectedDuration = TimeInterval(newValue * 60)
                }
                
                // "已选择"部分 - 紧凑显示
                HStack(spacing: AppTheme.Spacing.xs) {
                    Text("已选择")
                        .font(.system(size: AppTheme.FontSize.caption))
                        .foregroundColor(.secondary)
                    
                    Text(formatTime(selectedMinutes))
                        .font(.system(size: AppTheme.FontSize.body, weight: .semibold))
                        .foregroundColor(.primary)
                }
                .padding(.vertical, AppTheme.Spacing.sm)
                .padding(.horizontal, AppTheme.Spacing.md)
                .background(Color(.systemGray6))
                .cornerRadius(AppTheme.Radius.small)
                .padding(.bottom, AppTheme.Spacing.lg)
            }
            .padding(.horizontal, AppTheme.Spacing.xl)
        }
        .frame(maxHeight: 280) // 限制最大高度，确保弹窗不会太高
        .background(Color(.systemBackground))
        .onAppear {
            // 初始化选择值，限制在最大时间内
            let maxMinutes = Int(maxDuration / 60)
            let availableOptions = timeOptions.filter { $0 <= maxMinutes }
            selectedMinutes = min(120, availableOptions.last ?? 120) // 默认2小时，但不超过最大值
            selectedDuration = TimeInterval(selectedMinutes * 60)
            
            print("=== 时间选择器初始化 ===")
            print("maxDuration: \(maxDuration)秒 = \(maxMinutes)分钟")
            print("可用选项: \(availableOptions)")
            print("默认选择: \(selectedMinutes)分钟")
        }
    }
    
    private func formatTime(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        
        if hours > 0 {
            if mins == 0 {
                return "\(hours)小时"
            } else {
                return "\(hours)小时\(mins)分钟"
            }
        } else {
            return "\(mins)分钟"
        }
    }
}

struct TemporaryStateTimePicker_Previews: PreviewProvider {
    static var previews: some View {
        TemporaryStateTimePicker(
            selectedDuration: .constant(7200),
            isPresented: .constant(true),
            maxDuration: 14400, // 4小时
            onConfirm: { _ in },
            onCancel: { }
        )
        .padding()
    }
}