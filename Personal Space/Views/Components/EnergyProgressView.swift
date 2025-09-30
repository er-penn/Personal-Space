//
//  EnergyProgressView.swift
//  Personal Space
//
//  Created by Penn on 2025/1/27.
//

import SwiftUI

struct EnergyProgressView: View {
    @EnvironmentObject var userState: UserState
    @State private var currentTime = Date()
    @State private var timer: Timer?
    @State private var showingEnergyPlanning = false
    
    private let hours = Array(6...22) // 6点到22点
    
    var body: some View {
        Button(action: {
            showingEnergyPlanning = true
        }) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                HStack {
                    Text("今日能量规划")
                        .font(.system(size: AppTheme.FontSize.headline, weight: .semibold))
                        .foregroundColor(AppTheme.Colors.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: AppTheme.FontSize.caption))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                
                Text("今日计划：\(getEnergyPlanSummary())")
                    .font(.system(size: AppTheme.FontSize.body))
                    .foregroundColor(AppTheme.Colors.textSecondary)
            
                VStack(spacing: AppTheme.Spacing.sm) {
                    // 小时标签（每4小时显示一次）
                    HStack {
                        ForEach(Array(stride(from: 6, through: 22, by: 4)), id: \.self) { hour in
                            Text("\(hour):00")
                                .font(.system(size: AppTheme.FontSize.caption))
                                .foregroundColor(AppTheme.Colors.textSecondary)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    
                    // 进度条 - 按小时显示
                    GeometryReader { geometry in
                        HStack(spacing: 1) {
                            ForEach(hours, id: \.self) { hour in
                                Rectangle()
                                    .fill(getEnergyColor(for: hour))
                                    .frame(width: geometry.size.width / CGFloat(hours.count), height: 20)
                                    .cornerRadius(2)
                                    .animation(.easeInOut(duration: 0.3), value: getEnergyColor(for: hour))
                            }
                        }
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(4)
                        
                        // 当前时间指示器
                        Rectangle()
                            .fill(AppTheme.Colors.text)
                            .frame(width: 2, height: 20)
                            .offset(x: getCurrentTimeOffset(width: geometry.size.width))
                    }
                    .frame(height: 20)
                    
                    // 当前时间指示器文本
                    HStack {
                        Spacer()
                        Text("当前：\(getCurrentHour()):00")
                            .font(.system(size: AppTheme.FontSize.caption))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                        Spacer()
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .padding(AppTheme.Spacing.lg)
        .background(AppGradient.cardBackground)
        .cornerRadius(AppTheme.Radius.card)
        .shadow(color: AppTheme.Shadows.card, radius: 8, x: 0, y: 4)
        .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.card).stroke(AppTheme.Colors.border, lineWidth: 1))
        .onAppear {
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
            .fullScreenCover(isPresented: $showingEnergyPlanning) {
                EnergyPlanningView()
                    .environmentObject(userState)
            }
    }
    
    private func getEnergyColor(for hour: Int) -> Color {
        // 使用UserState的优先级系统
        let finalLevel = userState.getFinalEnergyLevel(for: Date(), hour: hour)
        return finalLevel.color
    }
    
    private func getCurrentHour() -> Int {
        return Calendar.current.component(.hour, from: currentTime)
    }
    
    private func getCurrentTimeOffset(width: CGFloat) -> CGFloat {
        let currentHour = getCurrentHour()
        let hourIndex = max(0, min(currentHour - 6, hours.count - 1))
        let segmentWidth = width / CGFloat(hours.count)
        return segmentWidth * CGFloat(hourIndex) + segmentWidth / 2
    }
    
    private func getEnergyPlanSummary() -> String {
        var highCount = 0
        var mediumCount = 0
        var lowCount = 0
        var unplannedCount = 0
        
        for hour in hours {
            let finalLevel = userState.getFinalEnergyLevel(for: Date(), hour: hour)
            switch finalLevel {
            case .high:
                highCount += 1
            case .medium:
                mediumCount += 1
            case .low:
                lowCount += 1
            case .unplanned:
                unplannedCount += 1
            }
        }
        
        if unplannedCount > 0 {
            return "高能量\(highCount)小时，中能量\(mediumCount)小时，低能量\(lowCount)小时，待规划\(unplannedCount)小时"
        } else {
            return "高能量\(highCount)小时，中能量\(mediumCount)小时，低能量\(lowCount)小时"
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            currentTime = Date()
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

#Preview {
    EnergyProgressView()
        .environmentObject(UserState())
        .padding()
}
