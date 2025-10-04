//
//  TemporaryStateButton.swift
//  Personal Space
//
//  Created by Penn on 2025/1/27.
//

import SwiftUI

struct TemporaryStateButton: View {
    let stateType: TemporaryStateType
    let isActive: Bool
    let onShortPress: () -> Void
    let onLongPress: () -> Void
    
    @State private var isPressed = false
    @State private var longPressTimer: Timer?
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(
                        isActive 
                            ? stateType.buttonColor.opacity(0.1) 
                            : stateType.buttonColor.opacity(0.15)
                    )
                    .frame(width: 50, height: 50)
                    .scaleEffect(isPressed ? 0.95 : 1.0)
                    .animation(.easeInOut(duration: 0.1), value: isPressed)
                
                Image(systemName: stateType == .fastCharge ? "bolt.fill" : "battery.25")
                    .font(.system(size: 20))
                    .foregroundColor(
                        isActive 
                            ? stateType.buttonColor.opacity(0.3) 
                            : stateType.buttonColor
                    )
            }
            .onTapGesture {
                // 短按：立即设置未来所有未规划区域
                if !isActive {
                    onShortPress()
                }
            }
            .onLongPressGesture(minimumDuration: 0.5) {
                // 长按：显示时间选择器（无论是否激活都可以长按）
                print("长按检测到: \(stateType.rawValue)")
                onLongPress()
            } onPressingChanged: { pressing in
                isPressed = pressing
            }
            
            Text(stateType == .fastCharge ? "快充" : "低电量模式")
                .font(.system(size: AppTheme.FontSize.caption2, weight: .medium))
                .foregroundColor(
                    isActive 
                        ? AppTheme.Colors.textSecondary.opacity(0.3) 
                        : AppTheme.Colors.textSecondary
                )
        }
    }
}

struct TemporaryStateButton_Previews: PreviewProvider {
    static var previews: some View {
        HStack(spacing: 20) {
            TemporaryStateButton(
                stateType: .fastCharge,
                isActive: false,
                onShortPress: { print("快充短按") },
                onLongPress: { print("快充长按") }
            )
            
            TemporaryStateButton(
                stateType: .lowPower,
                isActive: true,
                onShortPress: { print("低电量短按") },
                onLongPress: { print("低电量长按") }
            )
        }
        .padding()
    }
}
