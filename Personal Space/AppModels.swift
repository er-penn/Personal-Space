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

// MARK: - 用户状态模型
class UserState: ObservableObject {
    @Published var energyLevel: EnergyLevel = .high
    @Published var isFocusModeOn: Bool = false
    @Published var isEnergyBoostActive: Bool = false
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
    
    init() {
        // 添加一些示例能量规划数据
        setupSampleEnergyPlans()
        // 添加一些示例实际能量记录数据
        setupSampleActualEnergyRecords()
    }
    
    private func setupSampleEnergyPlans() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // 添加今天的测试数据
        // 7:00-8:20 灰色（不设置，保持unplanned状态）
        
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
        // 优先级：临时状态 > 能量快充 > 专注模式 > 基础状态
        if isTemporaryStateActive, let tempType = temporaryStateType {
            return tempType.energyLevel
        }
        return isEnergyBoostActive ? .high : energyLevel
    }
    
    
    // 分钟级查询方法
    func getFinalEnergyLevel(for date: Date, hour: Int, minute: Int, showUnplanned: Bool = true) -> EnergyLevel {
        let calendar = Calendar.current
        let targetDate = calendar.startOfDay(for: date)
        let currentTime = Date()
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
        
        // 2. 专注模式 (高优先级)
        if isFocusModeOn {
            return .high
        }
        
        // 3. 能量快充 (高优先级)
        if isEnergyBoostActive {
            return .high
        }
        
        // 4. 能量预规划 (中优先级) - 精确匹配分钟
        if let plan = energyPlans.first(where: { 
            calendar.isDate($0.date, inSameDayAs: targetDate) && $0.hour == hour && $0.minute == minute
        }) {
            return plan.energyLevel
        }
        
        // 5. 默认状态
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
        
        // 2. 专注模式 (高优先级)
        if isFocusModeOn {
            return .high
        }
        
        // 3. 能量快充 (高优先级)
        if isEnergyBoostActive {
            return .high
        }
        
        // 4. 能量预规划 (中优先级) - 精确匹配分钟
        if let plan = energyPlans.first(where: { 
            calendar.isDate($0.date, inSameDayAs: targetDate) && $0.hour == hour && $0.minute == minute
        }) {
            return plan.energyLevel
        }
        
        // 5. 默认状态 - 对于已记录的部分，如果没有其他状态，返回当前的基础状态
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
    @Published var isFocusModeOn: Bool = false
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

// MARK: - 能量状态优先级枚举
enum EnergyPriority: Int, CaseIterable {
    case dailyCheckIn = 1    // 每天能量状态签到 (最弱)
    case energyPlanning = 2  // 能量预规划
    case energyBoost = 3     // 能量快充
    case focusMode = 4       // 专注模式 (最强)
    
    var description: String {
        switch self {
        case .dailyCheckIn: return "每日签到"
        case .energyPlanning: return "能量预规划"
        case .energyBoost: return "能量快充"
        case .focusMode: return "专注模式"
        }
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
