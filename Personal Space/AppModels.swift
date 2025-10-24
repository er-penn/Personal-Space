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
    @Published var moodRecords: [MoodRecord] = [] // 心情记录
    @Published var plannedEnergyPlans: [EnergyPlan] = [] // 预规划状态（用户的计划）
    @Published var baseEnergyPlans: [EnergyPlan] = [] // 基础状态（实际发生的历史）
    @Published var actualEnergyRecords: [ActualEnergyRecord] = [] // 实际能量记录
    
    // MARK: - 临时状态相关属性（混合模型）
    @Published var temporaryStatePlans: [EnergyPlan] = [] // 临时状态的时间段规划（支持一天多次临时状态）
    @Published var isTemporaryStateActive: Bool = false // 是否处于临时状态
    @Published var currentTemporaryStateType: TemporaryStateType? = nil // 当前临时状态类型
    @Published var originalEnergyLevel: EnergyLevel? = nil // 原始能量状态（用于恢复）
    @Published var currentTemporaryStateStartTime: Date? = nil // 当前临时状态开始时间
    @Published var currentTemporaryStateEndTime: Date? = nil // 当前临时状态结束时间
    @Published var isShowingTemporaryStateOverlay: Bool = false // 是否显示临时状态遮罩
    
    // MARK: - 基础状态相关属性
    @Published var currentBaseEnergyLevel: EnergyLevel = .unplanned // 实时基础状态（用于UI显示）
    @Published var lastProcessedMinute: Date? = nil // 最后处理的分钟（用于检测分钟变化）

    // MARK: - 预规划状态遮罩相关属性
    @Published var isPlannedStateActive: Bool = false // 是否处于预规划状态遮罩
    @Published var currentPlannedStateLevel: EnergyLevel? = nil // 当前预规划状态的能量等级
    @Published var currentPlannedStateStartTime: Date? = nil // 当前预规划状态的开始时间
    @Published var currentPlannedStateEndTime: Date? = nil // 当前预规划状态的结束时间
    
    // MARK: - 状态切换历史记录（用于统计）
    @Published var energyLevelChangeHistory: [EnergyLevelChange] = [] // 状态切换历史记录
    
    // MARK: - 每日首次打开相关属性
    @Published var lastAppOpenDate: Date? = nil // 最后一次打开app的日期
    
    init() {
        // 检查是否是今天第一次打开app
        checkFirstOpenToday()

        // 初始化基础状态为未规划，覆盖7:00-23:59
        initializeBaseEnergyPlan()

        // 临时启用示例数据来测试预规划状态切换功能
        setupSampleEnergyPlans()
        // setupSampleActualEnergyRecords()

        // 调试：打印当前基础状态信息
        printCurrentBaseStateInfo()

        // 🎯 初始化完成，基础状态追加逻辑已启用
    }

    /// 初始化基础状态规划（创建7:00-当前时间的unplanned状态）
    private func initializeBaseEnergyPlan() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let now = Date()
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)

        // 只有在当前时间大于7:00时才创建基础状态规划
        if currentHour > 7 || (currentHour == 7 && currentMinute >= 0) {
            let initialTimeSlot = TimeSlot(
                startHour: 7, startMinute: 0,
                endHour: currentHour, endMinute: currentMinute
            )

            // 🎯 使用整合逻辑创建基础状态规划
            addOrMergeBaseEnergyPlan(
                date: today,
                timeSlot: initialTimeSlot,
                energyLevel: .unplanned
            )

            print("🎯 初始化基础状态规划：7:00 - \(currentHour):\(String(format: "%02d", currentMinute)) = 未规划")
        }
    }
    
    /// 更新实时基础状态（UI立即响应，数据在下一分钟追加）
    /// - Parameter newLevel: 新的基础能量状态
    func updateCurrentBaseEnergyLevel(to newLevel: EnergyLevel) {
        // 如果状态没有变化，直接返回
        if currentBaseEnergyLevel == newLevel {
            return
        }

        // 更新实时状态（立即生效，影响UI显示）
        currentBaseEnergyLevel = newLevel

        print("🎯 更新实时基础状态为：\(newLevel.description)（将在下一分钟追加时间段）")
    }

    /// 每分钟检查并追加基础状态时间段
    /// 在新的一分钟到来时检查当前基础状态并追加相应的时间段
    func checkAndAppendBaseStateTimeSlot() {
        let calendar = Calendar.current
        let now = Date()
        let currentMinute = calendar.dateInterval(of: .minute, for: now)?.start ?? now

        // 检查是否进入了新的一分钟
        if let lastMinute = lastProcessedMinute,
           calendar.isDate(lastMinute, inSameDayAs: now) &&
           calendar.component(.hour, from: lastMinute) == calendar.component(.hour, from: now) &&
           calendar.component(.minute, from: lastMinute) == calendar.component(.minute, from: now) {
            return // 还是同一分钟，无需处理
        }

        // 更新最后处理的分钟
        lastProcessedMinute = currentMinute

        // 🎯 执行追加逻辑
        appendBaseStateTimeSlot(for: now)
    }

    /// 追加基础状态时间段
    /// - Parameter date: 当前时间
    private func appendBaseStateTimeSlot(for date: Date) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: date)
        let currentHour = calendar.component(.hour, from: date)
        let currentMinute = calendar.component(.minute, from: date)

        print("🎯 追加基础状态时间段：\(currentHour):\(String(format: "%02d", currentMinute)), 状态：\(currentBaseEnergyLevel.description)")

        // 🎯 查找当前基础状态对应的 EnergyPlan
        if let existingPlan = baseEnergyPlans.first(where: {
            calendar.isDate($0.date, inSameDayAs: today) && $0.energyLevel == currentBaseEnergyLevel
        }) {
            // 找到了对应的 EnergyPlan，检查是否有连续的 TimeSlot
            let previousTime = calendar.date(byAdding: .minute, value: -1, to: date)!
            let prevHour = calendar.component(.hour, from: previousTime)
            let prevMinute = calendar.component(.minute, from: previousTime)

            // 查找是否有 endTime = 上一分钟 的 TimeSlot
            if let timeSlotIndex = existingPlan.timeSlots.firstIndex(where: { slot in
                slot.endHour == prevHour && slot.endMinute == prevMinute
            }) {
                // 找到连续的 TimeSlot，更新 endTime
                var updatedPlan = existingPlan
                updatedPlan.timeSlots[timeSlotIndex] = TimeSlot(
                    startHour: updatedPlan.timeSlots[timeSlotIndex].startHour,
                    startMinute: updatedPlan.timeSlots[timeSlotIndex].startMinute,
                    endHour: currentHour,
                    endMinute: currentMinute
                )

                // 更新数组中的对应项
                if let planIndex = baseEnergyPlans.firstIndex(where: { $0.id == existingPlan.id }) {
                    baseEnergyPlans[planIndex] = updatedPlan
                    print("🎯 更新连续时间段：\(updatedPlan.timeSlots[timeSlotIndex].startHour):\(String(format: "%02d", updatedPlan.timeSlots[timeSlotIndex].startMinute)) - \(currentHour):\(String(format: "%02d", currentMinute))")
                }
            } else {
                // 没找到连续的 TimeSlot，创建新的
                let newTimeSlot = TimeSlot(
                    startHour: currentHour,
                    startMinute: currentMinute,
                    endHour: currentHour,
                    endMinute: currentMinute
                )

                var updatedPlan = existingPlan
                updatedPlan.timeSlots.append(newTimeSlot)

                // 更新数组中的对应项
                if let planIndex = baseEnergyPlans.firstIndex(where: { $0.id == existingPlan.id }) {
                    baseEnergyPlans[planIndex] = updatedPlan
                    print("🎯 创建新时间段：\(currentHour):\(String(format: "%02d", currentMinute))")
                }
            }
        } else {
            // 没找到对应的 EnergyPlan，创建新的
            let newTimeSlot = TimeSlot(
                startHour: currentHour,
                startMinute: currentMinute,
                endHour: currentHour,
                endMinute: currentMinute
            )

            let newPlan = EnergyPlan(
                date: today,
                timeSlots: [newTimeSlot],
                energyLevel: currentBaseEnergyLevel
            )

            baseEnergyPlans.append(newPlan)
            print("🎯 创建新的基础状态规划：\(currentBaseEnergyLevel.description), 时间段：\(currentHour):\(String(format: "%02d", currentMinute))")
        }
    }

    /// 检查是否是今天第一次打开app
    private func checkFirstOpenToday() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // 如果今天还没有打开过app，或者是第一次打开app
        if lastAppOpenDate == nil || !calendar.isDate(lastAppOpenDate!, inSameDayAs: today) {
            // 重置为未规划状态（使用新的追加逻辑）
            initializeBaseEnergyPlan()
            currentBaseEnergyLevel = .unplanned
            // 清除状态切换历史记录
            energyLevelChangeHistory.removeAll()
            // 清除临时状态
            temporaryStatePlans.removeAll()
            endTemporaryState()
            // 清除预规划和基础状态
            plannedEnergyPlans.removeAll()
            baseEnergyPlans.removeAll()

            print("今天第一次打开app，重置为未规划状态")
        }

        // 更新最后打开app的日期
        lastAppOpenDate = Date()
    }
    
    private func setupSampleEnergyPlans() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // 添加今天的测试数据（使用新的混合模型）
        // 7:00-8:20 灰色（不设置，保持unplanned状态）

        // 8:20-10:00 绿色（高能量）- 使用整合逻辑
        addOrMergePlannedEnergyPlan(
            date: today,
            timeSlot: TimeSlot(startHour: 8, startMinute: 20, endHour: 9, endMinute: 59),
            energyLevel: .high
        )

        // 10:00-10:55 红色（低能量）- 使用整合逻辑
        addOrMergePlannedEnergyPlan(
            date: today,
            timeSlot: TimeSlot(startHour: 10, startMinute: 0, endHour: 10, endMinute: 54),
            energyLevel: .low
        )

        // 10:55-11:20 绿色（高能量）- 这会合并到前面的高能量规划中
        addOrMergePlannedEnergyPlan(
            date: today,
            timeSlot: TimeSlot(startHour: 10, startMinute: 55, endHour: 11, endMinute: 19),
            energyLevel: .high
        )

        // 11:20-12:50 黄色（中能量）- 使用整合逻辑
        addOrMergePlannedEnergyPlan(
            date: today,
            timeSlot: TimeSlot(startHour: 11, startMinute: 20, endHour: 12, endMinute: 49),
            energyLevel: .medium
        )

        // 12:50-当前时间 绿色（高能量）- 这会合并到前面的高能量规划中
        let currentHour = calendar.component(.hour, from: Date())
        let currentMinute = calendar.component(.minute, from: Date())
        if currentHour >= 12 && currentMinute >= 50 {
            addOrMergePlannedEnergyPlan(
                date: today,
                timeSlot: TimeSlot(startHour: 12, startMinute: 50, endHour: currentHour, endMinute: currentMinute),
                energyLevel: .high
            )
        }
  
        // 添加未来时间的测试数据（使用新的混合模型）
        let testStartHour = currentHour
        let testStartMinute = currentMinute + 2 // 2分钟后开始

        var testHour = testStartHour
        var testMinute = testStartMinute

        // 调整时间（处理分钟溢出）
        if testMinute >= 60 {
            testMinute -= 60
            testHour += 1
        }

        print("🎯 添加测试预规划数据（混合模型）：")

        // 第一段：红色（低能量）- 5分钟
        let firstEndHour = testHour + (testStartMinute + 4) / 60
        let firstEndMinute = (testStartMinute + 4) % 60
        addOrMergePlannedEnergyPlan(
            date: today,
            timeSlot: TimeSlot(startHour: testHour, startMinute: testStartMinute, endHour: firstEndHour, endMinute: firstEndMinute),
            energyLevel: .low
        )
        print("  📍 \(testHour):\(String(format: "%02d", testStartMinute))-\(firstEndHour):\(String(format: "%02d", firstEndMinute)) 红色（低能量）")

        // 第二段：黄色（中能量）- 5分钟
        let secondSegmentStart = testStartMinute + 5
        let secondSegmentEnd = testStartMinute + 9
        let secondStartHour = testHour + secondSegmentStart / 60
        let secondStartMinute = secondSegmentStart % 60
        let secondEndHour = testHour + secondSegmentEnd / 60
        let secondEndMinute = secondSegmentEnd % 60
        addOrMergePlannedEnergyPlan(
            date: today,
            timeSlot: TimeSlot(startHour: secondStartHour, startMinute: secondStartMinute, endHour: secondEndHour, endMinute: secondEndMinute),
            energyLevel: .medium
        )
        print("  📍 \(secondStartHour):\(String(format: "%02d", secondStartMinute))-\(secondEndHour):\(String(format: "%02d", secondEndMinute)) 黄色（中能量）")

        print("  当前时间: \(currentHour):\(String(format: "%02d", currentMinute))")
        print("  测试将在 \(testHour):\(String(format: "%02d", testStartMinute)) 开始")

        // 添加明天的规划（混合模型示例：多个分散时间段）
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) {
            // 示例：上午有两个高能量时段
            addOrMergePlannedEnergyPlan(
                date: tomorrow,
                timeSlot: TimeSlot(startHour: 9, startMinute: 0, endHour: 11, endMinute: 30),
                energyLevel: .high
            )
            addOrMergePlannedEnergyPlan(
                date: tomorrow,
                timeSlot: TimeSlot(startHour: 14, startMinute: 0, endHour: 15, endMinute: 30),
                energyLevel: .high
            )

            // 中午时段：中能量
            addOrMergePlannedEnergyPlan(
                date: tomorrow,
                timeSlot: TimeSlot(startHour: 12, startMinute: 0, endHour: 13, endMinute: 30),
                energyLevel: .medium
            )

            // 晚上：低能量
            addOrMergePlannedEnergyPlan(
                date: tomorrow,
                timeSlot: TimeSlot(startHour: 20, startMinute: 0, endHour: 22, endMinute: 0),
                energyLevel: .low
            )
        }

        // 添加后天的规划（混合模型示例：单个长时段）
        if let dayAfterTomorrow = calendar.date(byAdding: .day, value: 2, to: today) {
            addOrMergePlannedEnergyPlan(
                date: dayAfterTomorrow,
                timeSlot: TimeSlot(startHour: 7, startMinute: 0, endHour: 18, endMinute: 0),
                energyLevel: .high
            )
        }
    }
    
    var displayEnergyLevel: EnergyLevel {
        // 简化逻辑：临时状态 > 预规划状态 > 基础状态（带截断）

        // 1. 临时状态优先级最高
        if isTemporaryStateActive, let tempType = currentTemporaryStateType {
            return tempType.energyLevel
        }

        // 2. 检查当前时间的预规划状态
        let currentTime = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: currentTime)
        let minute = calendar.component(.minute, from: currentTime)

        // 获取预规划状态（用户的计划）
        if let plan = plannedEnergyPlans.first(where: {
            calendar.isDate($0.date, inSameDayAs: calendar.startOfDay(for: currentTime)) &&
            $0.containsTime(hour: hour, minute: minute)
        }) {
            return plan.energyLevel
        }

        // 3. 基础状态（实际发生的历史记录）
        if let basePlan = baseEnergyPlans.first(where: {
            calendar.isDate($0.date, inSameDayAs: calendar.startOfDay(for: currentTime)) &&
            $0.containsTime(hour: hour, minute: minute)
        }) {
            return basePlan.energyLevel
        }

        // 4. 默认返回实时基础状态
        return currentBaseEnergyLevel
    }
    
    
    // 分钟级查询方法（完整混合模型支持）
    func getPlannedEnergyLevel(for date: Date, hour: Int, minute: Int, showUnplanned: Bool = true) -> EnergyLevel {
        let calendar = Calendar.current
        let targetDate = calendar.startOfDay(for: date)

        // 🎯 未来时间：只检查预规划状态，其他显示未规划
        if let plan = plannedEnergyPlans.first(where: {
            calendar.isDate($0.date, inSameDayAs: targetDate) && $0.containsTime(hour: hour, minute: minute)
        }) {
            return plan.energyLevel
        }

        // 没有预规划则显示未规划状态
        return .unplanned
    }
    
    // MARK: - 能量规划相关方法
    
    // 获取有规划的日期
    func getPlannedDates() -> [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return plannedEnergyPlans
            .filter { calendar.isDate($0.date, inSameDayAs: today) || $0.date > today }
            .map { $0.date }
            .removingDuplicates()
            .sorted()
    }
    
    // 获取指定日期的能量规划
    func getEnergyPlans(for date: Date) -> [EnergyPlan] {
        let calendar = Calendar.current
        let targetDate = calendar.startOfDay(for: date)

        return plannedEnergyPlans.filter { plan in
            calendar.isDate(plan.date, inSameDayAs: targetDate)
        }.sorted { (plan1: EnergyPlan, plan2: EnergyPlan) in
            // 按第一个时间段的开始时间排序
            guard let slot1 = plan1.timeSlots.first,
                  let slot2 = plan2.timeSlots.first else {
                return false
            }

            let start1 = slot1.startHour * 60 + slot1.startMinute
            let start2 = slot2.startHour * 60 + slot2.startMinute

            return start1 < start2
        }
    }
    
    // MARK: - 实际能量记录相关方法
    
    // 获取有实际记录的日期
    func getActualEnergyRecordDates() -> [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return actualEnergyRecords
            .filter { calendar.isDate($0.date, inSameDayAs: today) || $0.date < today }
            .map { $0.date }
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
    
    /// 启动临时状态（使用混合模型）
    /// - Parameters:
    ///   - type: 临时状态类型（快充模式或低电量模式）
    ///   - duration: 持续时间（秒）
    func startTemporaryState(type: TemporaryStateType, duration: TimeInterval) {
        let currentTime = Date()
        let endTime = currentTime.addingTimeInterval(duration)
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: currentTime)

        // 保存原始状态（使用混合模型）
        originalEnergyLevel = currentBaseEnergyLevel

        // 🎯 记录临时状态的开始到历史记录中
        recordEnergyLevelChange(to: type.energyLevel)

        // 创建临时状态的时间段规划
        let startHour = calendar.component(.hour, from: currentTime)
        let startMinute = calendar.component(.minute, from: currentTime)
        let endHour = calendar.component(.hour, from: endTime)
        let endMinute = calendar.component(.minute, from: endTime)

        let temporaryTimeSlot = TimeSlot(
            startHour: startHour, startMinute: startMinute,
            endHour: endHour, endMinute: endMinute
        )

        // 🎯 方式1：查找是否有相同能量等级的EnergyPlan可以合并
        if let existingPlan = temporaryStatePlans.first(where: {
            calendar.isDate($0.date, inSameDayAs: today) && $0.energyLevel == type.energyLevel
        }) {
            // 找到相同能量等级的EnergyPlan，添加新的TimeSlot
            var updatedPlan = existingPlan
            updatedPlan.timeSlots.append(temporaryTimeSlot)

            // 更新数组中的对应项
            if let index = temporaryStatePlans.firstIndex(where: { $0.id == existingPlan.id }) {
                temporaryStatePlans[index] = updatedPlan
                print("🎯 合并到现有临时状态规划: \(type.rawValue), 现有\(updatedPlan.timeSlots.count)个时间段")
            }
        } else {
            // 没有找到相同能量等级的EnergyPlan，创建新的
            let newTemporaryPlan = EnergyPlan(
                date: today,
                timeSlots: [temporaryTimeSlot],
                energyLevel: type.energyLevel
            )

            // 添加到临时状态规划数组中
            temporaryStatePlans.append(newTemporaryPlan)
            print("🎯 创建新的临时状态规划: \(type.rawValue)")
        }

        // 设置当前临时状态
        isTemporaryStateActive = true
        currentTemporaryStateType = type
        currentTemporaryStateStartTime = currentTime
        currentTemporaryStateEndTime = endTime
        isShowingTemporaryStateOverlay = true

        print("启动临时状态: \(type.rawValue), 持续时间: \(duration/60)分钟, 结束时间: \(endTime)")
        print("🎯 临时状态时间段: \(startHour):\(String(format: "%02d", startMinute)) - \(endHour):\(String(format: "%02d", endMinute))")
    }
    
    /// 结束临时状态，恢复到原始状态（使用混合模型）
    func endTemporaryState() {
        guard isTemporaryStateActive else { return }

        print("结束临时状态: \(currentTemporaryStateType?.rawValue ?? "未知")")

        // 🎯 记录临时状态的结束到历史记录中
        if let original = originalEnergyLevel {
            recordEnergyLevelChange(to: original)
        }

        // 恢复原始状态（UI立即响应）
        if let original = originalEnergyLevel {
            updateCurrentBaseEnergyLevel(to: original)
        }

        // 清除当前临时状态
        isTemporaryStateActive = false
        currentTemporaryStateType = nil
        originalEnergyLevel = nil
        currentTemporaryStateStartTime = nil
        currentTemporaryStateEndTime = nil
        isShowingTemporaryStateOverlay = false

        print("🎯 已清除临时状态时间段规划")
    }
    
    /// 检查临时状态是否已过期，如果过期则自动结束
    func checkTemporaryStateExpiration() {
        guard isTemporaryStateActive, let endTime = currentTemporaryStateEndTime else { return }
        
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
        let plannedLevel = getPlannedEnergyLevel(for: currentTime, hour: hour, minute: minute, showUnplanned: false)
        
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
        let currentPlans = plannedEnergyPlans.filter { plan in
            calendar.isDate(plan.date, inSameDayAs: today) &&
            plan.containsTime(hour: currentHour, minute: currentMinute)
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
        
        // 查找包含当前时间的预规划
        let currentPlans = plannedEnergyPlans.filter { plan in
            calendar.isDate(plan.date, inSameDayAs: today) &&
            plan.containsTime(hour: startHour, minute: startMinute) &&
            plan.energyLevel == energyLevel
        }
        
        guard let currentPlan = currentPlans.first else { return nil }
        
        // 找到包含当前时间的 TimeSlot
        for slot in currentPlan.timeSlots {
            if slot.contains(hour: startHour, minute: startMinute) {
                // 返回这个 TimeSlot 的结束时间
                return calendar.date(bySettingHour: slot.endHour, minute: slot.endMinute, second: 0, of: today)
            }
        }
        
        return nil
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
        let baseLevel = currentBaseEnergyLevel
        recordEnergyLevelChange(to: baseLevel)
        
        isPlannedStateActive = false
        currentPlannedStateLevel = nil
        currentPlannedStateStartTime = nil
        currentPlannedStateEndTime = nil
        
        print("🎯 预规划遮罩自然结束，记录状态切换为: \(baseLevel.description)")
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
              let _ = currentPlannedStateStartTime,
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
            let plansAtTime = plannedEnergyPlans.filter { plan in
                calendar.isDate(plan.date, inSameDayAs: today) &&
                plan.containsTime(hour: hour, minute: minute)
            }
            plansToRemove.append(contentsOf: plansAtTime)
            
            // 下一分钟
            minute += 1
            if minute >= 60 {
                minute = 0
                hour += 1
            }
        }
        
        // 从 plannedEnergyPlans 中移除这些预规划
        for planToRemove in plansToRemove {
            if let index = plannedEnergyPlans.firstIndex(where: { plan in
                calendar.isDate(plan.date, inSameDayAs: planToRemove.date) &&
                plan.energyLevel == planToRemove.energyLevel &&
                plan.id == planToRemove.id
            }) {
                plannedEnergyPlans.remove(at: index)
            }
        }
        
        print("🎯 手动结束预规划遮罩，已清除 \(plansToRemove.count) 个预规划数据（\(currentHour):\(currentMinute) - \(endHour):\(endMinute)）")
        
        // 记录预规划状态结束，切换到基础状态
        let baseLevel = currentBaseEnergyLevel
        recordEnergyLevelChange(to: baseLevel)
        
        // 结束预规划状态
        isPlannedStateActive = false
        currentPlannedStateLevel = nil
        currentPlannedStateStartTime = nil
        currentPlannedStateEndTime = nil
        
        print("🎯 手动结束预规划遮罩，记录状态切换为: \(baseLevel.description)")
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

    /// 记录状态切换（用于统计分析）
    func recordEnergyLevelChange(to newLevel: EnergyLevel) {
        let changeTime = Date()

        // 添加到状态切换历史记录
        let change = EnergyLevelChange(changeTime: changeTime, newEnergyLevel: newLevel)
        energyLevelChangeHistory.append(change)

        // 为了防止历史记录无限增长，只保留今天的记录
        let calendar = Calendar.current
        energyLevelChangeHistory = energyLevelChangeHistory.filter {
            calendar.isDate($0.changeTime, inSameDayAs: Date())
        }

        print("🎯 记录状态切换：\(newLevel.description) at \(changeTime)")
    }

    /// 获取过去时间的能量状态（简化版：移除刷子逻辑）
    func getActualRecordedEnergyLevel(for date: Date, hour: Int, minute: Int) -> EnergyLevel {
        let calendar = Calendar.current
        let targetDate = calendar.startOfDay(for: date)

        // 🎯 过去时间：简化逻辑，只检查临时状态和基础状态
        // 1. 临时状态优先级最高 - 检查所有临时状态规划
        if let tempLevel = getTemporaryStateEnergyLevel(for: date, hour: hour, minute: minute) {
            return tempLevel
        }
        
        // 🎯
        //2.预规划状态优先级次之：检查预规划状态
        if let plan = plannedEnergyPlans.first(where: {
            calendar.isDate($0.date, inSameDayAs: targetDate) && $0.containsTime(hour: hour, minute: minute)
        }) {
            return plan.energyLevel
        }

        // 3. 基础状态（实际发生的历史记录）
        if let basePlan = baseEnergyPlans.first(where: {
            calendar.isDate($0.date, inSameDayAs: targetDate) && $0.containsTime(hour: hour, minute: minute)
        }) {
            return basePlan.energyLevel
        }

        //return currentBaseEnergyLevel
        // 4. 默认返回未规划状态
        return .unplanned
    }
    
    
    /// 获取当前临时状态（如果激活）
    var currentTemporaryEnergyLevel: EnergyLevel? {
        return currentTemporaryStateType?.energyLevel
    }

    /// 检查指定时间是否在任意临时状态时间段内
    func isInTemporaryStateTime(hour: Int, minute: Int) -> Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        return temporaryStatePlans.contains { plan in
            guard calendar.isDate(plan.date, inSameDayAs: today) else { return false }

            return plan.timeSlots.contains { slot in
                let targetTotalMinutes = hour * 60 + minute
                let startTotalMinutes = slot.startHour * 60 + slot.startMinute
                let endTotalMinutes = slot.endHour * 60 + slot.endMinute
                return targetTotalMinutes >= startTotalMinutes && targetTotalMinutes <= endTotalMinutes
            }
        }
    }

    /// 检查指定时间是否在基础状态时间段内
    func isInBaseStateTime(hour: Int, minute: Int) -> Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return baseEnergyPlans.contains { plan in
            calendar.isDate(plan.date, inSameDayAs: today) &&
            plan.containsTime(hour: hour, minute: minute)
        }
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

    /// 获取当前基础状态详细信息（调试用）
    func printCurrentBaseStateInfo() {
        print("\n🎯 ===== 当前基础状态详细信息 =====")
        print("🔄 实时状态: \(currentBaseEnergyLevel.description)")
        print("📝 最后处理分钟: \(lastProcessedMinute?.description ?? "未设置")")

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let todayBasePlans = baseEnergyPlans.filter {
            calendar.isDate($0.date, inSameDayAs: today)
        }

        if !todayBasePlans.isEmpty {
            print("⏱️ 今日基础状态规划: \(todayBasePlans.count) 个能量等级")

            for (planIndex, plan) in todayBasePlans.enumerated() {
                print("  🎯 能量等级 \(planIndex + 1): \(plan.energyLevel.description) - \(plan.timeSlots.count) 个时间段")

                for (slotIndex, slot) in plan.timeSlots.enumerated() {
                    print("    📍 段落 \(slotIndex + 1): \(String(format: "%02d:%02d", slot.startHour, slot.startMinute)) - \(String(format: "%02d:%02d", slot.endHour, slot.endMinute))")
                }

                let totalMinutes = plan.totalDurationMinutes
                print("    📊 总时长: \(totalMinutes) 分钟 (\(String(format: "%.1f", Double(totalMinutes) / 60.0)) 小时)")
            }
        } else {
            print("❌ 今日还没有基础状态记录")
        }

        print("========================================\n")
    }

    /// 获取临时状态剩余时间（秒）
    func getTemporaryStateRemainingTime() -> TimeInterval {
        guard isTemporaryStateActive, let endTime = currentTemporaryStateEndTime else { return 0 }
        return max(0, endTime.timeIntervalSince(Date()))
    }
    
    /// 获取临时状态剩余时间（分钟）
    func getTemporaryStateRemainingMinutes() -> Int {
        return Int(getTemporaryStateRemainingTime() / 60)
    }

    /// 获取指定时间的临时状态能量等级
    func getTemporaryStateEnergyLevel(for date: Date, hour: Int, minute: Int) -> EnergyLevel? {
        let calendar = Calendar.current
        let targetDate = calendar.startOfDay(for: date)

        // 🎯 遍历所有匹配日期的临时状态规划（支持多个不同能量等级的规划）
        for plan in temporaryStatePlans {
            guard calendar.isDate(plan.date, inSameDayAs: targetDate) else { continue }

            // 检查是否在该规划的任意时间段内
            for slot in plan.timeSlots {
                let targetTotalMinutes = hour * 60 + minute
                let startTotalMinutes = slot.startHour * 60 + slot.startMinute
                let endTotalMinutes = slot.endHour * 60 + slot.endMinute

                if targetTotalMinutes >= startTotalMinutes && targetTotalMinutes <= endTotalMinutes {
                    return plan.energyLevel
                }
            }
        }

        return nil
    }

    /// 添加或整合预规划状态（用户的计划）
    /// - Parameters:
    ///   - date: 规划日期
    ///   - timeSlot: 时间段
    ///   - energyLevel: 能量等级
    func addOrMergePlannedEnergyPlan(date: Date, timeSlot: TimeSlot, energyLevel: EnergyLevel) {
        let calendar = Calendar.current

        // 🎯 查找是否有相同能量等级的EnergyPlan可以合并
        if let existingPlan = plannedEnergyPlans.first(where: {
            calendar.isDate($0.date, inSameDayAs: date) && $0.energyLevel == energyLevel
        }) {
            // 找到相同能量等级的EnergyPlan，添加新的TimeSlot
            var updatedPlan = existingPlan
            updatedPlan.timeSlots.append(timeSlot)

            // 更新数组中的对应项
            if let index = plannedEnergyPlans.firstIndex(where: { $0.id == existingPlan.id }) {
                plannedEnergyPlans[index] = updatedPlan
                print("🎯 合并到现有预规划状态: \(energyLevel.rawValue), 现有\(updatedPlan.timeSlots.count)个时间段")
            }
        } else {
            // 没有找到相同能量等级的EnergyPlan，创建新的
            let newPlan = EnergyPlan(
                date: date,
                timeSlots: [timeSlot],
                energyLevel: energyLevel
            )

            // 添加到预规划状态数组中
            plannedEnergyPlans.append(newPlan)
            print("🎯 创建新的预规划状态: \(energyLevel.rawValue)")
        }
    }

    /// 添加或整合基础状态（实际发生的历史）
    /// - Parameters:
    ///   - date: 日期
    ///   - timeSlot: 时间段
    ///   - energyLevel: 能量等级
    func addOrMergeBaseEnergyPlan(date: Date, timeSlot: TimeSlot, energyLevel: EnergyLevel) {
        let calendar = Calendar.current

        // 🎯 查找是否有相同能量等级的EnergyPlan可以合并
        if let existingPlan = baseEnergyPlans.first(where: {
            calendar.isDate($0.date, inSameDayAs: date) && $0.energyLevel == energyLevel
        }) {
            // 找到相同能量等级的EnergyPlan，添加新的TimeSlot
            var updatedPlan = existingPlan
            updatedPlan.timeSlots.append(timeSlot)

            // 更新数组中的对应项
            if let index = baseEnergyPlans.firstIndex(where: { $0.id == existingPlan.id }) {
                baseEnergyPlans[index] = updatedPlan
                print("🎯 合并到现有基础状态: \(energyLevel.rawValue), 现有\(updatedPlan.timeSlots.count)个时间段")
            }
        } else {
            // 没有找到相同能量等级的EnergyPlan，创建新的
            let newPlan = EnergyPlan(
                date: date,
                timeSlots: [timeSlot],
                energyLevel: energyLevel
            )

            // 添加到基础状态数组中
            baseEnergyPlans.append(newPlan)
            print("🎯 创建新的基础状态: \(energyLevel.rawValue)")
        }
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

// MARK: - 时间段结构
struct TimeSlot: Codable, Equatable {
    let startHour: Int
    let startMinute: Int
    let endHour: Int
    let endMinute: Int

    init(startHour: Int, startMinute: Int, endHour: Int, endMinute: Int) {
        self.startHour = startHour
        self.startMinute = startMinute
        self.endHour = endHour
        self.endMinute = endMinute
    }

    // 检查指定时间是否在时间段内
    func contains(hour: Int, minute: Int) -> Bool {
        let totalMinutes = hour * 60 + minute
        let startTotalMinutes = startHour * 60 + startMinute
        let endTotalMinutes = endHour * 60 + endMinute

        return totalMinutes >= startTotalMinutes && totalMinutes <= endTotalMinutes
    }

    // 获取时间段的总分钟数
    var durationMinutes: Int {
        let startTotalMinutes = startHour * 60 + startMinute
        let endTotalMinutes = endHour * 60 + endMinute
        return endTotalMinutes - startTotalMinutes + 1
    }
}

// MARK: - 能量预规划模型（方案三：混合模型）
struct EnergyPlan: Identifiable, Codable {
    let id: UUID
    let date: Date // 规划日期（仅存储日期部分，时间为00:00:00）
    var timeSlots: [TimeSlot] // 时间段数组（支持多个分散时间段）
    var energyLevel: EnergyLevel // 统一能量状态（支持修改）
    let createdAt: Date // 创建时间

    init(date: Date, timeSlots: [TimeSlot], energyLevel: EnergyLevel, createdAt: Date = Date()) {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: date)
        self.timeSlots = timeSlots
        self.energyLevel = energyLevel
        self.createdAt = createdAt
    }

    // 便捷初始化器：单个时间段
    init(date: Date, startHour: Int, startMinute: Int, endHour: Int, endMinute: Int, energyLevel: EnergyLevel, createdAt: Date = Date()) {
        let timeSlot = TimeSlot(startHour: startHour, startMinute: startMinute, endHour: endHour, endMinute: endMinute)
        self.init(date: date, timeSlots: [timeSlot], energyLevel: energyLevel, createdAt: createdAt)
    }

    // 检查指定时间是否在任一时间段内
    func containsTime(hour: Int, minute: Int) -> Bool {
        return timeSlots.contains { $0.contains(hour: hour, minute: minute) }
    }

    // 获取所有时间点的数组（用于兼容现有渲染逻辑）
    func getAllMinutePoints() -> [(hour: Int, minute: Int)] {
        var allPoints: [(hour: Int, minute: Int)] = []

        for slot in timeSlots {
            var currentHour = slot.startHour
            var currentMinute = slot.startMinute

            while currentHour < slot.endHour || (currentHour == slot.endHour && currentMinute <= slot.endMinute) {
                allPoints.append((hour: currentHour, minute: currentMinute))

                // 下一分钟
                currentMinute += 1
                if currentMinute >= 60 {
                    currentMinute = 0
                    currentHour += 1
                }
            }
        }

        return allPoints.sorted { $0.hour < $1.hour || ($0.hour == $1.hour && $0.minute < $1.minute) }
    }

    // 计算总规划时长（分钟）
    var totalDurationMinutes: Int {
        return timeSlots.reduce(0) { $0 + $1.durationMinutes }
    }
}

// MARK: - 实际能量记录模型
struct ActualEnergyRecord: Identifiable, Codable {
    let id: UUID
    let date: Date // 记录日期（仅存储日期部分，时间为00:00:00）
    let hour: Int // 小时 (0-23)
    let energyLevel: EnergyLevel // 实际经历的能量状态
    let recordedAt: Date // 记录时间
    let note: String? // 可选备注

    init(date: Date, hour: Int, energyLevel: EnergyLevel, recordedAt: Date = Date(), note: String? = nil) {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: date)
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
