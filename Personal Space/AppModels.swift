//
//  AppModels.swift
//  Personal Space
//
//  Created by Penn on 2025/1/27.
//

import Foundation
import SwiftUI
import Combine

// MARK: - 能量状态枚举
enum EnergyLevel: String, CaseIterable, Codable {
    case high = "🟢"
    case medium = "🟡"
    case low = "🔴"
    case unplanned = "⚪"
    
    var description: String {
        switch self {
        case .high: return "满血复活\n状态拉满"
        case .medium: return "血条还行\n但别催我"
        case .low: return "血槽空了\n莫挨老子"
        case .unplanned: return "待规划"
        }
    }
    
    var color: Color {
        switch self {
        case .high: return .green
        case .medium: return .yellow
        case .low: return .red
        case .unplanned: return Color.gray.opacity(0.3)
        }
    }
}

// MARK: - 临时状态类型枚举
enum TemporaryStateType: String, CaseIterable, Codable {
    case fastCharge = "快充模式"
    case lowPower = "低电量模式"
    
    var energyLevel: EnergyLevel {
        switch self {
        case .fastCharge: return .high
        case .lowPower: return .low
        }
    }
    
    var buttonColor: Color {
        switch self {
        case .fastCharge: return .green
        case .lowPower: return .red
        }
    }
}

// MARK: - 状态切换历史记录
struct EnergyLevelChange: Identifiable, Codable {
    let id: UUID
    let changeTime: Date // 状态切换时间
    let newEnergyLevel: EnergyLevel // 切换后的新状态

    init(changeTime: Date, newEnergyLevel: EnergyLevel) {
        self.id = UUID()
        self.changeTime = changeTime
        self.newEnergyLevel = newEnergyLevel
    }
}

// MARK: - 用户状态模型
class UserState: ObservableObject {
    @Published var energyLevel: EnergyLevel = .unplanned
    @Published var moodRecords: [MoodRecord] = [] // 心情记录
    @Published var energyPlans: [EnergyPlan] = [] // 能量预规划
    @Published var actualEnergyRecords: [ActualEnergyRecord] = [] // 实际能量记录
    
    // MARK: - 临时状态相关属性
    @Published var isTemporaryStateActive: Bool = false // 是否处于临时状态
    @Published var temporaryStateType: TemporaryStateType? = nil // 临时状态类型
    @Published var originalEnergyLevel: EnergyLevel? = nil // 原始能量状态（用于恢复）
    @Published var temporaryStateStartTime: Date? = nil // 临时状态开始时间
    @Published var temporaryStateDuration: TimeInterval = 0 // 临时状态持续时间（秒）
    @Published var temporaryStateEndTime: Date? = nil // 临时状态结束时间
    @Published var isShowingTemporaryStateOverlay: Bool = false // 是否显示临时状态遮罩
    
    // MARK: - 预规划状态遮罩相关属性
    @Published var isPlannedStateActive: Bool = false // 是否处于预规划状态遮罩
    @Published var currentPlannedStateLevel: EnergyLevel? = nil // 当前预规划状态的能量等级
    @Published var currentPlannedStateStartTime: Date? = nil // 当前预规划状态的开始时间
    @Published var currentPlannedStateEndTime: Date? = nil // 当前预规划状态的结束时间
    
    // MARK: - 刷子逻辑相关属性
    @Published var lastEnergyLevelChangeTime: Date? = nil // 最后一次能量状态切换的时间
    @Published var energyLevelChangeHistory: [EnergyLevelChange] = [] // 状态切换历史记录
    
    // MARK: - 每日首次打开相关属性
    @Published var lastAppOpenDate: Date? = nil // 最后一次打开app的日期
    
    init() {
        // 检查是否是今天第一次打开app
        checkFirstOpenToday()
        
        // 临时启用示例数据来测试预规划状态切换功能
        setupSampleEnergyPlans()
        // setupSampleActualEnergyRecords()
    }
    
    /// 检查是否是今天第一次打开app
    private func checkFirstOpenToday() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // 如果今天还没有打开过app，或者是第一次打开app
        if lastAppOpenDate == nil || !calendar.isDate(lastAppOpenDate!, inSameDayAs: today) {
            // 重置为未规划状态
            energyLevel = .unplanned
            // 清除状态切换历史记录
            energyLevelChangeHistory.removeAll()
            // 清除临时状态
            endTemporaryState()
            
            print("今天第一次打开app，重置为未规划状态")
        }
        
        // 更新最后打开app的日期
        lastAppOpenDate = Date()
    }
    
    private func setupSampleEnergyPlans() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // 添加今天的测试数据
        // 7:00-8:20 灰色（不设置，保持unplanned状态）
        // 注意：不需要为每个分钟都创建EnergyPlan，让getActualRecordedEnergyLevel方法处理默认状态
        
        // 8:20-10:00 绿色（高能量）
        for minute in 20..<60 {
            energyPlans.append(EnergyPlan(date: today, hour: 8, minute: minute, energyLevel: .high))
        }
        for hour in 9...9 {
            for minute in 0..<60 {
                energyPlans.append(EnergyPlan(date: today, hour: hour, minute: minute, energyLevel: .high))
            }
        }
        
        // 10:00-10:55 红色（低能量）
        for minute in 0..<55 {
            energyPlans.append(EnergyPlan(date: today, hour: 10, minute: minute, energyLevel: .low))
        }
        
        // 10:55-11:20 绿色（高能量）
        for minute in 55..<60 {
            energyPlans.append(EnergyPlan(date: today, hour: 10, minute: minute, energyLevel: .high))
        }
        for minute in 0..<20 {
            energyPlans.append(EnergyPlan(date: today, hour: 11, minute: minute, energyLevel: .high))
        }
        
        // 11:20-12:50 黄色（中能量）
        for minute in 20..<60 {
            energyPlans.append(EnergyPlan(date: today, hour: 11, minute: minute, energyLevel: .medium))
        }
        for minute in 0..<50 {
            energyPlans.append(EnergyPlan(date: today, hour: 12, minute: minute, energyLevel: .medium))
        }
        
        // 12:50-当前时间 绿色（高能量）
        for minute in 50..<60 {
            energyPlans.append(EnergyPlan(date: today, hour: 12, minute: minute, energyLevel: .high))
        }
        // 13:00-14:00 绿色（高能量）
        for minute in 0..<60 {
            energyPlans.append(EnergyPlan(date: today, hour: 13, minute: minute, energyLevel: .high))
        }
        // 14:00-当前时间 绿色（高能量）
        let currentHour = calendar.component(.hour, from: Date())
        let currentMinute = calendar.component(.minute, from: Date())
        if currentHour >= 14 {
            for minute in 0..<min(currentMinute, 60) {
                energyPlans.append(EnergyPlan(date: today, hour: 14, minute: minute, energyLevel: .high))
            }
        }
        
        // 添加未来时间的测试数据，用于测试自动切换功能
        // 添加从当前时间后2分钟开始的测试数据
        let testStartHour = currentHour
        let testStartMinute = currentMinute + 2 // 2分钟后开始
        
        var testHour = testStartHour
        var testMinute = testStartMinute
        
        // 调整时间（处理分钟溢出）
        if testMinute >= 60 {
            testMinute -= 60
            testHour += 1
        }
        
        print("🎯 添加测试预规划数据：")
        
        // 第一段：红色（低能量）- 5分钟
        for i in 0..<5 {
            var hour = testHour
            var minute = testMinute + i
            if minute >= 60 {
                minute -= 60
                hour += 1
            }
            energyPlans.append(EnergyPlan(date: today, hour: hour, minute: minute, energyLevel: .low))
            if i == 0 {
                print("  📍 \(hour):\(String(format: "%02d", minute))-\(hour):\(String(format: "%02d", minute + 4)) 红色（低能量）")
            }
        }
        
        // 第二段：黄色（中能量）- 5分钟
        for i in 5..<10 {
            var hour = testHour
            var minute = testMinute + i
            if minute >= 60 {
                minute -= 60
                hour += 1
            }
            energyPlans.append(EnergyPlan(date: today, hour: hour, minute: minute, energyLevel: .medium))
            if i == 5 {
                print("  📍 \(hour):\(String(format: "%02d", minute))-\(hour):\(String(format: "%02d", minute + 4)) 黄色（中能量）")
            }
        }
        
        print("  当前时间: \(currentHour):\(String(format: "%02d", currentMinute))")
        print("  测试将在 \(testHour):\(String(format: "%02d", testMinute)) 开始")
        
        // 添加明天的规划
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) {
            energyPlans.append(EnergyPlan(date: tomorrow, hour: 9, energyLevel: .high))
            energyPlans.append(EnergyPlan(date: tomorrow, hour: 15, energyLevel: .medium))
            energyPlans.append(EnergyPlan(date: tomorrow, hour: 20, energyLevel: .low))
        }
        
        // 添加后天的规划
        if let dayAfterTomorrow = calendar.date(byAdding: .day, value: 2, to: today) {
            energyPlans.append(EnergyPlan(date: dayAfterTomorrow, hour: 7, energyLevel: .high))
            energyPlans.append(EnergyPlan(date: dayAfterTomorrow, hour: 12, energyLevel: .medium))
            energyPlans.append(EnergyPlan(date: dayAfterTomorrow, hour: 16, energyLevel: .low))
            energyPlans.append(EnergyPlan(date: dayAfterTomorrow, hour: 19, energyLevel: .high))
        }
        
        // 为10月4日添加分钟级测试数据（假设今天是10月3日）
        let october4 = calendar.date(from: DateComponents(year: 2025, month: 10, day: 4)) ?? today
        if calendar.isDate(october4, inSameDayAs: today) || october4 > today {
            // 为12:00-13:00这个小时块添加分钟级颜色分割
            // 0-20分钟：高能量（绿色）
            for minute in 0..<20 {
                energyPlans.append(EnergyPlan(date: october4, hour: 12, minute: minute, energyLevel: .high))
            }
            // 20-40分钟：中能量（黄色）
            for minute in 20..<40 {
                energyPlans.append(EnergyPlan(date: october4, hour: 12, minute: minute, energyLevel: .medium))
            }
            // 40-60分钟：低能量（红色）
            for minute in 40..<60 {
                energyPlans.append(EnergyPlan(date: october4, hour: 12, minute: minute, energyLevel: .low))
            }
            
            // 为14:00-15:00这个小时块添加另一种分钟级颜色分割
            // 0-30分钟：高能量（绿色）
            for minute in 0..<30 {
                energyPlans.append(EnergyPlan(date: october4, hour: 14, minute: minute, energyLevel: .high))
            }
            // 30-60分钟：中能量（黄色）
            for minute in 30..<60 {
                energyPlans.append(EnergyPlan(date: october4, hour: 14, minute: minute, energyLevel: .medium))
            }
        }
    }
    
    var displayEnergyLevel: EnergyLevel {
        // 优先级：临时状态 > 预规划状态 > 基础状态

        // 1. 临时状态优先级最高
        if isTemporaryStateActive, let tempType = temporaryStateType {
            return tempType.energyLevel
        }

        // 2. 检查当前时间是否有预规划状态
        let currentTime = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: currentTime)
        let minute = calendar.component(.minute, from: currentTime)

        // 获取当前时间的预规划状态
        let plannedLevel = getFinalEnergyLevel(for: currentTime, hour: hour, minute: minute, showUnplanned: true)

        // 3. 如果有预规划状态且不是待规划，则使用预规划状态
        if plannedLevel != .unplanned {
            return plannedLevel
        }

        // 4. 最后返回基础状态
        return energyLevel
    }
    
    
    // 分钟级查询方法
    func getFinalEnergyLevel(for date: Date, hour: Int, minute: Int, showUnplanned: Bool = true) -> EnergyLevel {
        let calendar = Calendar.current
        let targetDate = calendar.startOfDay(for: date)
        let targetTime = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: date) ?? date

        // 优先级从高到低检查
        // 1. 临时状态 (最高优先级) - 只对当前时间到结束时间有效
        if isTemporaryStateActive,
           let tempType = temporaryStateType,
           let startTime = temporaryStateStartTime,
           let endTime = temporaryStateEndTime,
           targetTime >= startTime && targetTime <= endTime {
            return tempType.energyLevel
        }

        // 2. 能量预规划 (中优先级) - 精确匹配分钟
        if let plan = energyPlans.first(where: {
            calendar.isDate($0.date, inSameDayAs: targetDate) && $0.hour == hour && $0.minute == minute
        }) {
            return plan.energyLevel
        }

        // 3. 默认状态
        if showUnplanned {
            return .unplanned
        } else {
            return .medium
        }
    }
    
    // MARK: - 能量规划相关方法
    
    // 获取有规划的日期
    func getPlannedDates() -> [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return energyPlans
            .filter { calendar.isDate($0.date, inSameDayAs: today) || $0.date > today }
            .map { calendar.startOfDay(for: $0.date) }
            .removingDuplicates()
            .sorted()
    }
    
    // 获取指定日期的能量规划
    func getEnergyPlans(for date: Date) -> [EnergyPlan] {
        let calendar = Calendar.current
        let targetDate = calendar.startOfDay(for: date)
        
        return energyPlans.filter { plan in
            calendar.isDate(plan.date, inSameDayAs: targetDate)
        }.sorted { $0.hour < $1.hour }
    }
    
    // MARK: - 实际能量记录相关方法
    
    // 获取有实际记录的日期
    func getActualEnergyRecordDates() -> [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return actualEnergyRecords
            .filter { calendar.isDate($0.date, inSameDayAs: today) || $0.date < today }
            .map { calendar.startOfDay(for: $0.date) }
            .removingDuplicates()
            .sorted()
    }
    
    // 获取指定日期的实际记录
    func getActualEnergyRecords(for date: Date) -> [ActualEnergyRecord] {
        let calendar = Calendar.current
        let targetDate = calendar.startOfDay(for: date)
        
        return actualEnergyRecords.filter { record in
            calendar.isDate(record.date, inSameDayAs: targetDate)
        }.sorted { $0.hour < $1.hour }
    }
    
    // 设置示例实际记录数据
    private func setupSampleActualEnergyRecords() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // 添加昨天的一些示例记录
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        
        // 昨天的高能量时段
        for hour in 9...11 {
            let record = ActualEnergyRecord(
                date: yesterday,
                hour: hour,
                energyLevel: .high,
                recordedAt: calendar.date(byAdding: .hour, value: hour, to: yesterday)!
            )
            actualEnergyRecords.append(record)
        }
        
        // 昨天的中等能量时段
        for hour in 14...16 {
            let record = ActualEnergyRecord(
                date: yesterday,
                hour: hour,
                energyLevel: .medium,
                recordedAt: calendar.date(byAdding: .hour, value: hour, to: yesterday)!
            )
            actualEnergyRecords.append(record)
        }
        
        // 昨天的低能量时段
        for hour in 19...21 {
            let record = ActualEnergyRecord(
                date: yesterday,
                hour: hour,
                energyLevel: .low,
                recordedAt: calendar.date(byAdding: .hour, value: hour, to: yesterday)!
            )
            actualEnergyRecords.append(record)
        }
        
        // 添加前天的记录
        let dayBeforeYesterday = calendar.date(byAdding: .day, value: -2, to: today)!
        
        for hour in 8...10 {
            let record = ActualEnergyRecord(
                date: dayBeforeYesterday,
                hour: hour,
                energyLevel: .high,
                recordedAt: calendar.date(byAdding: .hour, value: hour, to: dayBeforeYesterday)!
            )
            actualEnergyRecords.append(record)
        }
        
        for hour in 15...17 {
            let record = ActualEnergyRecord(
                date: dayBeforeYesterday,
                hour: hour,
                energyLevel: .medium,
                recordedAt: calendar.date(byAdding: .hour, value: hour, to: dayBeforeYesterday)!
            )
            actualEnergyRecords.append(record)
        }
    }
    
    // MARK: - 临时状态相关方法
    
    /// 启动临时状态
    /// - Parameters:
    ///   - type: 临时状态类型（快充模式或低电量模式）
    ///   - duration: 持续时间（秒）
    func startTemporaryState(type: TemporaryStateType, duration: TimeInterval) {
        let currentTime = Date()
        let endTime = currentTime.addingTimeInterval(duration)

        // 保存原始状态
        originalEnergyLevel = energyLevel

        // 🎯 记录临时状态的开始到历史记录中
        recordEnergyLevelChange(to: type.energyLevel)

        // 设置临时状态
        isTemporaryStateActive = true
        temporaryStateType = type
        temporaryStateStartTime = currentTime
        temporaryStateDuration = duration
        temporaryStateEndTime = endTime
        isShowingTemporaryStateOverlay = true

        print("启动临时状态: \(type.rawValue), 持续时间: \(duration/60)分钟, 结束时间: \(endTime)")
    }
    
    /// 结束临时状态，恢复到原始状态
    func endTemporaryState() {
        guard isTemporaryStateActive else { return }

        print("结束临时状态: \(temporaryStateType?.rawValue ?? "未知")")

        // 🎯 记录临时状态的结束到历史记录中
        if let original = originalEnergyLevel {
            recordEnergyLevelChange(to: original)
        }

        // 恢复原始状态
        if let original = originalEnergyLevel {
            energyLevel = original
        }

        // 清除临时状态
        isTemporaryStateActive = false
        temporaryStateType = nil
        originalEnergyLevel = nil
        temporaryStateStartTime = nil
        temporaryStateDuration = 0
        temporaryStateEndTime = nil
        isShowingTemporaryStateOverlay = false
    }
    
    /// 检查临时状态是否已过期，如果过期则自动结束
    func checkTemporaryStateExpiration() {
        guard isTemporaryStateActive, let endTime = temporaryStateEndTime else { return }
        
        if Date() >= endTime {
            print("临时状态已过期，自动结束")
            endTemporaryState()
        }
    }
    
    /// 检查是否需要提醒用户临时状态即将结束
    func shouldShowExpirationWarning() -> Bool {
        guard isTemporaryStateActive else { return false }
        let remainingTime = getTemporaryStateRemainingTime()
        return remainingTime <= 300 && remainingTime > 0 // 最后5分钟提醒
    }
    
    /// 获取临时状态剩余时间描述
    func getTemporaryStateTimeDescription() -> String {
        guard isTemporaryStateActive else { return "" }
        let remainingTime = getTemporaryStateRemainingTime()
        let minutes = Int(remainingTime / 60)
        
        if minutes <= 0 {
            return "即将结束"
        } else if minutes < 60 {
            return "剩余 \(minutes) 分钟"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            return "剩余 \(hours) 小时 \(mins) 分钟"
        }
    }
    
    /// 获取当前时间对应的预规划状态颜色（用于顶部状态栏）
    func getCurrentPlannedEnergyColor() -> Color {
        let currentTime = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: currentTime)
        let minute = calendar.component(.minute, from: currentTime)
        
        // 获取当前时间的预规划状态
        let plannedLevel = getFinalEnergyLevel(for: currentTime, hour: hour, minute: minute, showUnplanned: false)
        
        // 如果是待规划状态，返回默认状态栏颜色
        if plannedLevel == .unplanned {
            return displayEnergyLevel.color
        }
        
        // 返回预规划状态的颜色
        return plannedLevel.color
    }
    
    /// 检测并更新预规划状态遮罩
    /// 这个方法应该每分钟被调用一次（通过定时器）
    func checkAndUpdatePlannedState() {
        let currentTime = Date()
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: currentTime)
        let currentMinute = calendar.component(.minute, from: currentTime)
        let today = calendar.startOfDay(for: currentTime)
        
        // 查找当前时间对应的预规划
        let currentPlans = energyPlans.filter { plan in
            calendar.isDate(plan.date, inSameDayAs: today) &&
            plan.hour == currentHour &&
            plan.minute == currentMinute
        }
        
        // 如果当前时间有预规划，且不是 unplanned
        if let currentPlan = currentPlans.first, currentPlan.energyLevel != .unplanned {
            // 查找这个预规划时间段的结束时间
            if let endTime = findPlannedSegmentEndTime(startHour: currentHour, startMinute: currentMinute, energyLevel: currentPlan.energyLevel) {
                // 如果不在预规划状态中，或者预规划状态改变了，则启动新的预规划遮罩
                if !isPlannedStateActive || currentPlannedStateLevel != currentPlan.energyLevel {
                    startPlannedState(level: currentPlan.energyLevel, startTime: currentTime, endTime: endTime)
                }
            }
        } else {
            // 当前时间没有预规划，检查是否需要结束预规划状态
            if isPlannedStateActive {
                // 自然结束（时间到了）
                endPlannedStateNaturally()
            }
        }
    }
    
    /// 查找预规划时间段的结束时间
    /// - Parameters:
    ///   - startHour: 开始小时
    ///   - startMinute: 开始分钟
    ///   - energyLevel: 能量等级
    /// - Returns: 结束时间（Date）
    private func findPlannedSegmentEndTime(startHour: Int, startMinute: Int, energyLevel: EnergyLevel) -> Date? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        var currentHour = startHour
        var currentMinute = startMinute
        
        // 从当前时刻开始，向后查找连续的相同能量等级的预规划
        while currentHour < 24 {
            let plans = energyPlans.filter { plan in
                calendar.isDate(plan.date, inSameDayAs: today) &&
                plan.hour == currentHour &&
                plan.minute == currentMinute &&
                plan.energyLevel == energyLevel
            }
            
            if plans.isEmpty {
                // 找到了结束点，返回这个时间点
                return calendar.date(bySettingHour: currentHour, minute: currentMinute, second: 0, of: today)
            }
            
            // 继续下一分钟
            currentMinute += 1
            if currentMinute >= 60 {
                currentMinute = 0
                currentHour += 1
            }
        }
        
        // 如果到了一天的结束还没结束，返回23:59
        return calendar.date(bySettingHour: 23, minute: 59, second: 59, of: today)
    }
    
    /// 启动预规划状态遮罩
    private func startPlannedState(level: EnergyLevel, startTime: Date, endTime: Date) {
        // 记录预规划状态开始
        recordEnergyLevelChange(to: level)
        
        isPlannedStateActive = true
        currentPlannedStateLevel = level
        currentPlannedStateStartTime = startTime
        currentPlannedStateEndTime = endTime
        
        print("🎯 启动预规划遮罩: \(level.description), 开始: \(startTime), 结束: \(endTime)")
    }
    
    /// 自然结束预规划状态（时间到了）
    private func endPlannedStateNaturally() {
        // 记录预规划状态结束，切换到基础状态
        recordEnergyLevelChange(to: energyLevel)
        
        isPlannedStateActive = false
        currentPlannedStateLevel = nil
        currentPlannedStateStartTime = nil
        currentPlannedStateEndTime = nil
        
        print("🎯 预规划遮罩自然结束，记录状态切换为: \(energyLevel.description)")
    }
    
    /// 获取当前预规划状态的剩余时间
    func getPlannedStateRemainingTime() -> TimeInterval {
        guard isPlannedStateActive,
              let endTime = currentPlannedStateEndTime else {
            return 0
        }
        
        let now = Date()
        let remaining = endTime.timeIntervalSince(now)
        return max(0, remaining)
    }
    
    /// 手动结束预规划状态（用户点击了倒计时）
    /// 会清除当前时刻到预规划结束时刻的所有预规划数据
    func endPlannedStateManually() {
        guard isPlannedStateActive,
              let startTime = currentPlannedStateStartTime,
              let endTime = currentPlannedStateEndTime else {
            return
        }
        
        let calendar = Calendar.current
        let now = Date()
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)
        let endHour = calendar.component(.hour, from: endTime)
        let endMinute = calendar.component(.minute, from: endTime)
        let today = calendar.startOfDay(for: now)
        
        // 计算需要清除的时间范围：从当前时刻到预规划结束时刻
        var plansToRemove: [EnergyPlan] = []
        
        var hour = currentHour
        var minute = currentMinute
        
        while hour < endHour || (hour == endHour && minute < endMinute) {
            // 查找并标记要删除的预规划
            let plansAtTime = energyPlans.filter { plan in
                calendar.isDate(plan.date, inSameDayAs: today) &&
                plan.hour == hour &&
                plan.minute == minute
            }
            plansToRemove.append(contentsOf: plansAtTime)
            
            // 下一分钟
            minute += 1
            if minute >= 60 {
                minute = 0
                hour += 1
            }
        }
        
        // 从 energyPlans 中移除这些预规划
        for planToRemove in plansToRemove {
            if let index = energyPlans.firstIndex(where: { plan in
                calendar.isDate(plan.date, inSameDayAs: planToRemove.date) &&
                plan.hour == planToRemove.hour &&
                plan.minute == planToRemove.minute &&
                plan.energyLevel == planToRemove.energyLevel
            }) {
                energyPlans.remove(at: index)
            }
        }
        
        print("🎯 手动结束预规划遮罩，已清除 \(plansToRemove.count) 个预规划数据（\(currentHour):\(currentMinute) - \(endHour):\(endMinute)）")
        
        // 记录预规划状态结束，切换到基础状态
        recordEnergyLevelChange(to: energyLevel)
        
        // 结束预规划状态
        isPlannedStateActive = false
        currentPlannedStateLevel = nil
        currentPlannedStateStartTime = nil
        currentPlannedStateEndTime = nil
        
        print("🎯 手动结束预规划遮罩，记录状态切换为: \(energyLevel.description)")
    }
    
    /// 获取今天第一次设置非灰色状态的时间（分钟）
    func getFirstNonGrayStateTime() -> Int? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // 从7:00开始查找第一个非灰色状态
        for hour in 7...23 {
            for minute in 0..<60 {
                let level = getActualRecordedEnergyLevel(for: today, hour: hour, minute: minute)
                if level != .unplanned {
                    return hour * 60 + minute
                }
            }
        }
        
        return nil // 今天还没有设置过非灰色状态
    }

    /// 记录状态切换（用于刷子逻辑）
    func recordEnergyLevelChange(to newLevel: EnergyLevel) {
        let changeTime = Date()
        lastEnergyLevelChangeTime = changeTime

        // 添加到状态切换历史记录
        let change = EnergyLevelChange(changeTime: changeTime, newEnergyLevel: newLevel)
        energyLevelChangeHistory.append(change)

        // 为了防止历史记录无限增长，只保留今天的记录
        let calendar = Calendar.current
        energyLevelChangeHistory = energyLevelChangeHistory.filter {
            calendar.isDate($0.changeTime, inSameDayAs: Date())
        }
    }

    /// 获取实际记录的能量状态（用于已记录部分的统计和显示）
    func getActualRecordedEnergyLevel(for date: Date, hour: Int, minute: Int) -> EnergyLevel {
        let calendar = Calendar.current
        let targetDate = calendar.startOfDay(for: date)
        let currentTime = Date()
        let targetTime = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: date) ?? date

        // 如果查询的是未来时间，返回待规划状态
        if targetTime > currentTime {
            return .unplanned
        }

        // 优先级从高到低检查（只检查实际记录的状态）
        // 1. 临时状态 (最高优先级) - 只对当前时间到结束时间有效
        if isTemporaryStateActive,
           let tempType = temporaryStateType,
           let startTime = temporaryStateStartTime,
           let endTime = temporaryStateEndTime,
           targetTime >= startTime && targetTime <= endTime {
            return tempType.energyLevel
        }

        // 2. 能量预规划 (中优先级) - 精确匹配分钟
        if let plan = energyPlans.first(where: {
            calendar.isDate($0.date, inSameDayAs: targetDate) && $0.hour == hour && $0.minute == minute
        }) {
            return plan.energyLevel
        }

        // 3. 默认状态处理
        let targetTotalMinutes = hour * 60 + minute
        let currentTotalMinutes = calendar.component(.hour, from: currentTime) * 60 + calendar.component(.minute, from: currentTime)

        // 如果是当前时间点，显示顶部状态栏颜色（刷子逻辑）
        if targetTotalMinutes == currentTotalMinutes {
            return displayEnergyLevel
        }

        // 刷子逻辑：基于状态切换历史记录确定每个时间段的颜色
        // 按时间倒序排列状态切换历史，找到目标时间对应的状态
        let sortedHistory = energyLevelChangeHistory.sorted { $0.changeTime > $1.changeTime }

        for change in sortedHistory {
            let changeTotalMinutes = calendar.component(.hour, from: change.changeTime) * 60 + calendar.component(.minute, from: change.changeTime)

            // 如果查询的时间在这次状态切换之后（或等于），使用这次切换后的状态
            if targetTotalMinutes >= changeTotalMinutes {
                return change.newEnergyLevel
            }
        }

        // 对于所有过去时间段，如果没有其他状态，返回基础状态
        // 这样预规划状态结束后，会显示基础状态而不是灰色
        return energyLevel
    }
    
    /// 获取今天剩余时间（秒）
    func getTodayRemainingTime() -> TimeInterval {
        let calendar = Calendar.current
        let now = Date()
        let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 0, of: now) ?? now
        return max(0, endOfDay.timeIntervalSince(now))
    }
    
    /// 获取今天剩余时间（向上取整到15分钟）
    func getTodayRemainingTimeRoundedTo15Minutes() -> TimeInterval {
        let remaining = getTodayRemainingTime()
        let minutes = Int(remaining / 60)
        let roundedMinutes = ((minutes + 14) / 15) * 15 // 向上取整到15分钟
        
        print("=== 时间计算调试 ===")
        print("当前时间: \(Date())")
        print("剩余时间: \(minutes)分钟")
        print("向上取整后: \(roundedMinutes)分钟")
        print("向上取整后: \(roundedMinutes/60)小时\(roundedMinutes%60)分钟")
        
        return TimeInterval(roundedMinutes * 60)
    }
    
    /// 获取临时状态剩余时间（秒）
    func getTemporaryStateRemainingTime() -> TimeInterval {
        guard isTemporaryStateActive, let endTime = temporaryStateEndTime else { return 0 }
        return max(0, endTime.timeIntervalSince(Date()))
    }
    
    /// 获取临时状态剩余时间（分钟）
    func getTemporaryStateRemainingMinutes() -> Int {
        return Int(getTemporaryStateRemainingTime() / 60)
    }
}

// MARK: - 伴侣状态模型
class PartnerState: ObservableObject {
    @Published var energyLevel: EnergyLevel = .medium
    @Published var lastSeen: Date = Date()
}

// MARK: - 功能卡片模型
struct FunctionCard: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let color: Color
    let content: String
    let action: () -> Void
}

// MARK: - 协作邀请模型
struct CollaborationInvitation: Identifiable {
    let id = UUID()
    let title: String
    let content: String
    let createdAt: Date
    let isFromMe: Bool
    let status: InvitationStatus
}

enum InvitationStatus {
    case pending
    case accepted
    case declined
    case discuss
}

// MARK: - 安心闭环模型
struct PeacefulClosure: Identifiable {
    let id = UUID()
    let item: String
    let location: String
    let estimatedTime: String
    let createdAt: Date
    let isFromMe: Bool
    let isAcknowledged: Bool
}

// MARK: - 心意盒模型
struct GiftBox: Identifiable {
    let id = UUID()
    let item: String
    let time: String
    let location: String
    let createdAt: Date
    let expiresAt: Date
    let isFromMe: Bool
    let isReceived: Bool
    
    var isExpired: Bool {
        Date() > expiresAt
    }
}

// MARK: - 碎片模型
struct Fragment: Identifiable {
    let id = UUID()
    let content: String
    let imageURL: String?
    let linkURL: String?
    let createdAt: Date
    let isFromMe: Bool
}

// MARK: - 瞬间模型
struct Moment: Identifiable {
    let id = UUID()
    let content: String
    let images: [String]
    let createdAt: Date
    let isFromMe: Bool
    let isTextHidden: Bool
    let likes: Int
    let comments: Int
    
    var shouldShowText: Bool {
        !isTextHidden || Date().timeIntervalSince(createdAt) > 3 * 24 * 3600
    }
}

// MARK: - 情绪报告模型
struct EmotionReport: Identifiable {
    let id = UUID()
    let mood: String
    let energy: Int
    let stress: Int
    let notes: String
    let createdAt: Date
    let isFromMe: Bool
}

// MARK: - Maybe清单项模型
struct MaybeItem: Identifiable {
    let id = UUID()
    let content: String
    let createdAt: Date
    let isFromMe: Bool
}

// MARK: - 心情记录模型
struct MoodRecord: Identifiable, Codable {
    let id: UUID
    let value: Double
    let timestamp: Date
    let note: String? // 备注内容
    
    init(value: Double, timestamp: Date, note: String? = nil) {
        self.id = UUID()
        self.value = value
        self.timestamp = timestamp
        self.note = note
    }
}

// MARK: - 能量预规划模型
struct EnergyPlan: Identifiable, Codable {
    let id: UUID
    let date: Date // 规划日期
    let hour: Int // 小时 (0-23)
    let minute: Int // 分钟 (0-59)，支持分钟级精度
    let energyLevel: EnergyLevel // 规划的能量状态
    let createdAt: Date // 创建时间
    
    init(date: Date, hour: Int, energyLevel: EnergyLevel, createdAt: Date = Date()) {
        self.id = UUID()
        self.date = date
        self.hour = hour
        self.minute = 0 // 默认整点
        self.energyLevel = energyLevel
        self.createdAt = createdAt
    }
    
    // 分钟级初始化器
    init(date: Date, hour: Int, minute: Int, energyLevel: EnergyLevel, createdAt: Date = Date()) {
        self.id = UUID()
        self.date = date
        self.hour = hour
        self.minute = minute
        self.energyLevel = energyLevel
        self.createdAt = createdAt
    }
}

// MARK: - 实际能量记录模型
struct ActualEnergyRecord: Identifiable, Codable {
    let id: UUID
    let date: Date // 记录日期
    let hour: Int // 小时 (0-23)
    let energyLevel: EnergyLevel // 实际经历的能量状态
    let recordedAt: Date // 记录时间
    let note: String? // 可选备注

    init(date: Date, hour: Int, energyLevel: EnergyLevel, recordedAt: Date = Date(), note: String? = nil) {
        self.id = UUID()
        self.date = date
        self.hour = hour
        self.energyLevel = energyLevel
        self.recordedAt = recordedAt
        self.note = note
    }
}


// MARK: - 成长花园模型
class GrowthGarden: ObservableObject {
    @Published var plantLevel: Int = 1
    @Published var waterLevel: Int = 0
    @Published var lastWatered: Date = Date()
    
    func water() {
        waterLevel = min(waterLevel + 1, 10)
        lastWatered = Date()
        if waterLevel >= 5 && plantLevel < 5 {
            plantLevel += 1
        }
    }
}

// MARK: - Array扩展
extension Array where Element: Equatable {
    func removingDuplicates() -> [Element] {
        var result: [Element] = []
        for element in self {
            if !result.contains(element) {
                result.append(element)
            }
        }
        return result
    }
}
