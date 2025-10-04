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
    
    private let timeOptions = Array(stride(from: 15, through: 480, by: 15)) // 15分钟到8小时，15分钟间隔
    
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
                    .font(.headline)
                    .bold()
                
                Spacer()
                
                Button("确认") {
                    let duration = TimeInterval(selectedMinutes * 60)
                    onConfirm(duration)
                    isPresented = false
                }
                .foregroundColor(.blue)
                .bold()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(.systemBackground))
            
            Divider()
            
            // 时间选择器
            VStack(spacing: 20) {
                Text("选择持续时间")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.top, 20)
                
                // 时间选择轮盘
                Picker("持续时间", selection: $selectedMinutes) {
                    ForEach(timeOptions, id: \.self) { minutes in
                        Text(formatTime(minutes))
                            .tag(minutes)
                    }
                }
                .pickerStyle(WheelPickerStyle())
                .frame(height: 200)
                .onChange(of: selectedMinutes) { newValue in
                    selectedDuration = TimeInterval(newValue * 60)
                }
                
                // 当前选择显示
                VStack(spacing: 8) {
                    Text("已选择")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(formatTime(selectedMinutes))
                        .font(.title2)
                        .bold()
                        .foregroundColor(.primary)
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 20)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                Spacer()
            }
            .padding(.horizontal, 20)
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 10)
        .onAppear {
            // 初始化选择值，限制在最大时间内
            let maxMinutes = Int(maxDuration / 60)
            let availableOptions = timeOptions.filter { $0 <= maxMinutes }
            selectedMinutes = min(120, availableOptions.last ?? 120) // 默认2小时，但不超过最大值
            selectedDuration = TimeInterval(selectedMinutes * 60)
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