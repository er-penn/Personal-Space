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
    
    var body: some View {
        ZStack {
            // 半透明背景
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            // 状态栏遮罩
            VStack {
                HStack {
                    Spacer()
                    
                    // 状态指示器
                    HStack(spacing: 8) {
                        Image(systemName: stateType == .fastCharge ? "bolt.fill" : "battery.25")
                            .font(.title3)
                            .foregroundColor(stateType.buttonColor)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(stateType.rawValue)
                                .font(.subheadline)
                                .bold()
                                .foregroundColor(.primary)
                            
                            Text(formatRemainingTime(remainingTime))
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
                    
                    Spacer()
                }
                .padding(.top, 8)
                
                Spacer()
            }
        }
        .onTapGesture {
            // 点击遮罩区域可以结束状态
            onEnd()
        }
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
