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
    
    var body: some View {
        VStack(spacing: 0) {
            // 空白区域，让遮罩往下挪20像素
            Spacer()
                .frame(height: 20)
            
            // 灰色遮罩区域 - 只覆盖顶部状态卡片区域
            ZStack {
                // 灰色遮罩背景
                Color.black.opacity(0.3)
                    .frame(height: 180) // 限制高度，只覆盖状态卡片区域
                    .frame(maxWidth: .infinity)
                
                // 倒计时框 - 在遮罩中央
                HStack(spacing: 8) {
                    Image(systemName: stateType == .fastCharge ? "bolt.fill" : "battery.25")
                        .font(.title3)
                        .foregroundColor(stateType.buttonColor)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(stateType.rawValue)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text(formatRemainingTime(displayTime))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .monospacedDigit()
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemBackground))
                .cornerRadius(20)
                .shadow(radius: 4)
                .onTapGesture {
                    // 点击状态指示器可以结束状态
                    onEnd()
                }
            }
            
            // 空白区域，让下方内容正常显示
            Spacer()
        }
        .onAppear {
            displayTime = remainingTime
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
        .onChange(of: remainingTime) { newValue in
            displayTime = newValue
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
