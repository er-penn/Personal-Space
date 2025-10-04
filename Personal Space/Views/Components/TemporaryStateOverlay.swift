//
//  TemporaryStateOverlay.swift
//  Personal Space
//
//  Created by Penn on 2025/1/27.
//

import SwiftUI

struct TemporaryStateOverlay: View {
    let stateType: TemporaryStateType
    let remainingTime: TimeInterval
    let onEnd: () -> Void
    
    @State private var displayTime: TimeInterval = 0
    @State private var timer: Timer?
    @State private var showWarning: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 空白区域，让遮罩往下挪20像素
            Spacer()
                .frame(height: 16)
            
            // 灰色遮罩区域 - 只覆盖顶部状态卡片区域
            ZStack {
                // 灰色遮罩背景 - 添加渐变效果
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.4),
                        Color.black.opacity(0.2)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 180) // 限制高度，只覆盖状态卡片区域
                .frame(maxWidth: .infinity)
                
                // 倒计时框 - 在遮罩中央，添加更好的视觉效果
                HStack(spacing: 10) {
                    // 状态图标 - 添加脉冲动画
                    Image(systemName: stateType == .fastCharge ? "bolt.fill" : "battery.25")
                        .font(.title2)
                        .foregroundColor(stateType.buttonColor)
                        .scaleEffect(1.1)
                        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: displayTime)
                    
                    VStack(alignment: .leading, spacing: 3) {
                        Text(stateType.rawValue)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text(formatRemainingTime(displayTime))
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
                        .stroke(stateType.buttonColor.opacity(0.3), lineWidth: 1)
                )
                .onTapGesture {
                    // 点击状态指示器可以结束状态
                    withAnimation(.easeInOut(duration: 0.3)) {
                        onEnd()
                    }
                }
            }
            
            // 空白区域，让下方内容正常显示
            Spacer()
        }
        .onAppear {
            displayTime = remainingTime
            startTimer()
            checkWarning()
        }
        .onDisappear {
            stopTimer()
        }
        .onChange(of: remainingTime) { newValue in
            displayTime = newValue
            checkWarning()
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if displayTime > 0 {
                displayTime -= 1
            } else {
                stopTimer()
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func checkWarning() {
        showWarning = displayTime <= 300 && displayTime > 0 // 最后5分钟显示警告
    }
    
    private func formatRemainingTime(_ time: TimeInterval) -> String {
        let totalSeconds = Int(time)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}

struct TemporaryStateOverlay_Previews: PreviewProvider {
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
            TemporaryStateOverlay(
                stateType: .fastCharge,
                remainingTime: 3661, // 1小时1分1秒
                onEnd: { }
            )
        )
    }
}
