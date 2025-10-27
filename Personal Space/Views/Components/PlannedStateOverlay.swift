//
//  PlannedStateOverlay.swift
//  Personal Space
//
//  Created by AI Assistant on 2025/1/27.
//

import SwiftUI

struct PlannedStateOverlay: View {
    let energyLevel: EnergyLevel
    let remainingTime: TimeInterval
    let onEnd: () -> Void
    @EnvironmentObject var userState: UserState
    
    @State private var showWarning: Bool = false
    
    var body: some View {
        ZStack {
            // 灰色遮罩背景 - 适应卡片大小
            LinearGradient(
                colors: [
                    Color.black.opacity(0.4),
                    Color.black.opacity(0.2)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // 倒计时框 - 居中显示
            VStack(spacing: 8) {
                HStack(spacing: 10) {
                    // 状态图标 - 根据能量等级显示不同图标
                    Image(systemName: getIconName())
                        .font(.title2)
                        .foregroundColor(energyLevel.color)
                        .scaleEffect(1.1)
                        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: userState.plannedStateCountdown)
                    
                    VStack(alignment: .leading, spacing: 3) {
                        Text("预规划：\(energyLevel.description)")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text(formatRemainingMinutes(userState.plannedStateCountdown))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(showWarning ? .red : .secondary)
                            .monospacedDigit()
                            .animation(.easeInOut(duration: 0.5), value: showWarning)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(energyLevel.color.opacity(0.3), lineWidth: 1)
                )
                .onTapGesture {
                    // 点击状态指示器可以结束状态
                    withAnimation(.easeInOut(duration: 0.3)) {
                        onEnd()
                    }
                }
            }
        }
        .onAppear {
            // 设置分钟级倒计时（将秒转换为分钟，向上取整）
            let minutes = max(1, Int(ceil(remainingTime / 60.0)))
            userState.setPlannedStateCountdown(minutes)
            checkWarning()
        }
        .onChange(of: remainingTime) { newValue in
            // 更新分钟级倒计时（将秒转换为分钟，向上取整）
            let minutes = max(1, Int(ceil(newValue / 60.0)))
            userState.setPlannedStateCountdown(minutes)
            checkWarning()
        }
    }
    
    private func getIconName() -> String {
        switch energyLevel {
        case .high:
            return "bolt.fill"
        case .medium:
            return "leaf.fill"
        case .low:
            return "battery.25"
        case .unplanned:
            return "questionmark.circle"
        }
    }
    
    // 🎯 Timer已移除：使用分钟级倒计时管理

    private func checkWarning() {
        showWarning = userState.plannedStateCountdown <= 5 && userState.plannedStateCountdown > 0 // 最后5分钟显示警告
    }

    private func formatRemainingMinutes(_ minutes: Int) -> String {
        if minutes >= 60 {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 {
                return "\(hours)小时"
            } else {
                return "\(hours)小时\(remainingMinutes)分钟"
            }
        } else {
            return "\(minutes)分钟"
        }
    }
}

struct PlannedStateOverlay_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            // 模拟主界面
            Color.blue.opacity(0.3)
                .ignoresSafeArea()
            
            Text("主界面内容")
                .font(.title)
                .foregroundColor(.white)
        }
        .overlay(
            PlannedStateOverlay(
                energyLevel: .low,
                remainingTime: 300, // 5分钟
                onEnd: { }
            )
        )
    }
}

