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
                .foregroundColor(.secondary)
                
                Spacer()
                
                Text("设置持续时间")
                    .font(.system(size: 17, weight: .semibold))
                
                Spacer()
                
                Button("确认") {
                    let duration = TimeInterval(selectedMinutes * 60)
                    onConfirm(duration)
                    isPresented = false
                }
                .foregroundColor(.blue)
                .font(.system(size: 17, weight: .semibold))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            
            Divider()
            
            // 时间选择器
            VStack(spacing: 16) {
                Text("选择持续时间")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.top, 16)
                
                // 时间选择轮盘
                Picker("持续时间", selection: $selectedMinutes) {
                    ForEach(timeOptions, id: \.self) { minutes in
                        Text(formatTime(minutes))
                            .tag(minutes)
                    }
                }
                .pickerStyle(WheelPickerStyle())
                .frame(height: 120) // 进一步减少高度
                .onChange(of: selectedMinutes) { newValue in
                    selectedDuration = TimeInterval(newValue * 60)
                }
                
                // 底部区域 - "已选择"部分显示在导航栏上方
                VStack(spacing: 0) {
                    // 空白区域，让"已选择"部分显示在导航栏上方
                    Spacer()
                        .frame(height: 0)
                    
                    // "已选择"部分 - 显示在导航栏上方，一行显示
                    HStack(spacing: 4) {
                        Text("已选择")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(formatTime(selectedMinutes))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.primary)
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    
                    // 底部安全区域 - 确保完全覆盖导航栏
                    Spacer()
                        .frame(height: 100) // 减少高度，为"已选择"部分留出空间
                }
            }
            .padding(.horizontal, 20)
        }
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