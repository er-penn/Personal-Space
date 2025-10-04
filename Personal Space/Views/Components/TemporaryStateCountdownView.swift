//
//  TemporaryStateCountdownView.swift
//  Personal Space
//
//  Created by Penn on 2025/1/27.
//

import SwiftUI

struct TemporaryStateCountdownView: View {
    let remainingTime: TimeInterval // 剩余时间（秒）
    let stateType: TemporaryStateType // 状态类型
    let onEnd: () -> Void // 结束回调
    
    @State private var timer: Timer?
    @State private var displayTime: TimeInterval = 0
    
    var body: some View {
        VStack(spacing: 12) {
            // 状态图标和标题
            HStack(spacing: 8) {
                Image(systemName: stateType == .fastCharge ? "bolt.fill" : "battery.25")
                    .font(.title2)
                    .foregroundColor(stateType.buttonColor)
                
                Text(stateType.rawValue)
                    .font(.headline)
                    .bold()
                    .foregroundColor(.primary)
            }
            
            // 倒计时显示
            VStack(spacing: 4) {
                Text("剩余时间")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(formatCountdownTime(displayTime))
                    .font(.title)
                    .bold()
                    .foregroundColor(stateType.buttonColor)
                    .monospacedDigit()
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(stateType.buttonColor.opacity(0.1))
            .cornerRadius(12)
            
            // 进度条
            ProgressView(value: 1.0 - (displayTime / remainingTime), total: 1.0)
                .progressViewStyle(LinearProgressViewStyle(tint: stateType.buttonColor))
                .frame(height: 4)
                .cornerRadius(2)
            
            // 结束按钮
            Button(action: onEnd) {
                HStack(spacing: 6) {
                    Image(systemName: "stop.fill")
                        .font(.caption)
                    Text("结束\(stateType.rawValue)")
                        .font(.subheadline)
                        .bold()
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(stateType.buttonColor)
                .cornerRadius(20)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 8)
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
    
    private func formatCountdownTime(_ time: TimeInterval) -> String {
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

struct TemporaryStateCountdownView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            TemporaryStateCountdownView(
                remainingTime: 3661, // 1小时1分1秒
                stateType: .fastCharge,
                onEnd: { }
            )
            
            TemporaryStateCountdownView(
                remainingTime: 1800, // 30分钟
                stateType: .lowPower,
                onEnd: { }
            )
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
}
