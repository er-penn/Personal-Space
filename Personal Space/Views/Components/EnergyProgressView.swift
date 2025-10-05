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
    
    private let hours = Array(7...23) // 7点到23点
    
    var body: some View {
        Button(action: {
            showingEnergyPlanning = true
        }) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                HStack {
                    Text("能量记录")
                        .font(.system(size: AppTheme.FontSize.headline, weight: .semibold))
                        .foregroundColor(AppTheme.Colors.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: AppTheme.FontSize.caption))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                
                getEnergyRecordSummaryView()
                    .font(.system(size: AppTheme.FontSize.body))
                    .foregroundColor(AppTheme.Colors.textSecondary)
            
                VStack(spacing: AppTheme.Spacing.sm) {
                    // 时间标签和竖标 - 使用GeometryReader精确定位
                    GeometryReader { geometry in
                        ZStack {
                            // 时间标签：7点、10点、14点、18点、22点
                            ForEach([7, 10, 14, 18, 22], id: \.self) { hour in
                                VStack(spacing: 0) {
                                    // 时间标签
                                    Text("\(hour):00")
                                        .font(.system(size: AppTheme.FontSize.caption))
                                        .foregroundColor(AppTheme.Colors.textSecondary)
                                    
                                    // 竖标：从标签延伸到能量块左边缘
                                    Rectangle()
                                        .fill(AppTheme.Colors.textSecondary.opacity(0.3))
                                        .frame(width: 1, height: 8)
                                }
                                .position(
                                    x: getTimeLabelPosition(for: hour, in: geometry.size.width),
                                    y: 10 // 时间标签的垂直位置
                                )
                            }
                        }
                    }
                    .frame(height: 20)
                    
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
                        Text("当前：\(getCurrentTimeString())")
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
        let currentTime = getCurrentTime()
        let currentHour = currentTime.hour
        let currentMinute = currentTime.minute
        
        // 如果当前小时小于查询的小时，或者当前小时等于查询小时但当前分钟为0，显示预规划状态
        if hour < currentHour || (hour == currentHour && currentMinute == 0) {
            // 显示预规划状态
            let finalLevel = userState.getFinalEnergyLevel(for: Date(), hour: hour, minute: 0)
            return finalLevel.color
        } else if hour == currentHour {
            // 当前小时：黑色竖线经过的部分显示顶部状态栏颜色
            return userState.displayEnergyLevel.color
        } else {
            // 未来时间：显示预规划状态
            let finalLevel = userState.getFinalEnergyLevel(for: Date(), hour: hour, minute: 0)
            return finalLevel.color
        }
    }
    
    private func getCurrentHour() -> Int {
        return Calendar.current.component(.hour, from: currentTime)
    }
    
    private func getCurrentTime() -> (hour: Int, minute: Int) {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: currentTime)
        let minute = calendar.component(.minute, from: currentTime)
        return (hour, minute)
    }
    
    private func getCurrentTimeOffset(width: CGFloat) -> CGFloat {
        let currentTime = getCurrentTime()
        let hourIndex = max(0, min(currentTime.hour - 7, hours.count - 1))
        let blockWidth = width / CGFloat(hours.count)
        let spacing: CGFloat = 1 // 块之间的间距，与getTimeLabelPosition保持一致
        
        // 计算指针应该位于的时间块边界位置
        // 考虑块之间的间距
        let blockStartOffset = blockWidth * CGFloat(hourIndex) + spacing * CGFloat(hourIndex)
        
        // 计算在当前小时内的分钟偏移
        let minuteOffset = (CGFloat(currentTime.minute) / 60.0) * blockWidth
        
        let totalOffset = blockStartOffset + minuteOffset
        
        // 确保指针精确对齐到像素边界
        return round(totalOffset)
    }
    
    // 计算时间标签的位置（左边缘对齐到对应时间块）
    private func getTimeLabelPosition(for hour: Int, in totalWidth: CGFloat) -> CGFloat {
        let hourIndex = hour - 7 // 7点对应索引0
        let blockWidth = totalWidth / CGFloat(hours.count)
        let spacing: CGFloat = 1 // 块之间的间距
        return blockWidth * CGFloat(hourIndex) + spacing * CGFloat(hourIndex)
    }
    
    // 获取当前时间的精确字符串（小时:分钟）
    private func getCurrentTimeString() -> String {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: currentTime)
        let minute = calendar.component(.minute, from: currentTime)
        return String(format: "%02d:%02d", hour, minute)
    }
    
    private func getEnergyRecordSummaryView() -> some View {
        var highMinutes = 0
        var mediumMinutes = 0
        var lowMinutes = 0
        var unplannedMinutes = 0
        
        let currentTime = getCurrentTime()
        let currentTotalMinutes = currentTime.hour * 60 + currentTime.minute
        
        // 只统计当前时间之前的状态（以分钟为精度）
        for minute in 0..<currentTotalMinutes {
            let hour = minute / 60
            let min = minute % 60
            
            // 只统计7:00-23:00范围内的时间
            if hour >= 7 && hour <= 23 {
                let finalLevel = userState.getFinalEnergyLevel(for: Date(), hour: hour, minute: min)
                switch finalLevel {
                case .high:
                    highMinutes += 1
                case .medium:
                    mediumMinutes += 1
                case .low:
                    lowMinutes += 1
                case .unplanned:
                    unplannedMinutes += 1
                }
            }
        }
        
        return HStack(spacing: 4) {
            Text("今日记录：")
            
            if highMinutes > 0 {
                HStack(spacing: 2) {
                    Rectangle()
                        .fill(EnergyLevel.high.color)
                        .frame(width: 8, height: 8)
                        .cornerRadius(1)
                    Text("\(highMinutes)分钟")
                }
            }
            
            if mediumMinutes > 0 {
                HStack(spacing: 2) {
                    Rectangle()
                        .fill(EnergyLevel.medium.color)
                        .frame(width: 8, height: 8)
                        .cornerRadius(1)
                    Text("\(mediumMinutes)分钟")
                }
            }
            
            if lowMinutes > 0 {
                HStack(spacing: 2) {
                    Rectangle()
                        .fill(EnergyLevel.low.color)
                        .frame(width: 8, height: 8)
                        .cornerRadius(1)
                    Text("\(lowMinutes)分钟")
                }
            }
            
            if unplannedMinutes > 0 {
                HStack(spacing: 2) {
                    Rectangle()
                        .fill(EnergyLevel.unplanned.color)
                        .frame(width: 8, height: 8)
                        .cornerRadius(1)
                    Text("\(unplannedMinutes)分钟")
                }
            }
        }
    }
    
    private func getEnergyPlanSummary() -> String {
        var highCount = 0
        var mediumCount = 0
        var lowCount = 0
        var unplannedCount = 0
        
        for hour in hours {
            let finalLevel = userState.getFinalEnergyLevel(for: Date(), hour: hour, minute: 0)
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
