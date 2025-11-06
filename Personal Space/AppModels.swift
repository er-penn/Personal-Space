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
    @Published var currentTime: Date = Date() // 全局当前时间（统一管理）
    
    // MARK: - 预规划状态遮罩相关属性
    @Published var isPlannedStateActive: Bool = false // 是否处于预规划状态遮罩
    @Published var currentPlannedStateLevel: EnergyLevel? = nil // 当前预规划状态的能量等级
    @Published var currentPlannedStateStartTime: Date? = nil // 当前预规划状态的开始时间
    @Published var currentPlannedStateEndTime: Date? = nil // 当前预规划状态的结束时间
    
    // MARK: - 统一倒计时管理（分钟级）
    @Published var plannedStateCountdown: Int = 0 // 预规划状态倒计时（分钟）
    @Published var temporaryStateCountdown: Int = 0 // 临时状态倒计时（分钟）
    // 注意：改为分钟级倒计时，使用主Timer进行更新，无需独立Timer
    
    // MARK: - 状态切换历史记录（用于统计）
    @Published var energyLevelChangeHistory: [EnergyLevelChange] = [] // 状态切换历史记录
    
    // MARK: - 每日首次打开相关属性
    @Published var lastAppOpenDate: Date? = nil // 最后一次打开app的日期
    
    init() {
        // 检查是否是今天第一次打开app
        checkFirstOpenToday()

        // 初始化基础状态为未规划，覆盖7:00-23:59
        initializeBaseEnergyPlan()
        
        // 仅在DEBUG模式下启用示例数据
        #if DEBUG
        setupSampleEnergyPlans()
        // setupSampleActualEnergyRecords()
        #endif

        // 调试：打印当前基础状态信息
        printCurrentBaseStateInfo()
        
        // 初始化心意盒列表
        updateGiftBoxLists()
        
        // 加载示例协作邀请数据
        loadSampleInvitations()
        
        // 加载示例碎片数据
        loadSampleFragments()
        
        // 加载示例通知数据
        loadSampleNotifications()
        
        // 加载示例心意盒数据
        loadSampleGiftBoxes()

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
    
    // MARK: - 统一倒计时管理方法
    
  // MARK: - 分钟级倒计时管理（集成到主Timer）

    /// 分钟级倒计时更新（由主Timer每分钟调用一次）
    func updateMinuteCountdowns() {
        // 更新预规划状态倒计时（分钟级）
        if isPlannedStateActive && plannedStateCountdown > 0 {
            plannedStateCountdown -= 1
            if plannedStateCountdown <= 0 {
                endPlannedStateNaturally()
            }
        }

        // 更新临时状态倒计时（分钟级）
        if isTemporaryStateActive && temporaryStateCountdown > 0 {
            temporaryStateCountdown -= 1
            if temporaryStateCountdown <= 0 {
                endTemporaryState()
            }
        }
    }

    /// 设置预规划状态倒计时（分钟）
    func setPlannedStateCountdown(_ minutes: Int) {
        plannedStateCountdown = minutes
    }

    /// 设置临时状态倒计时（分钟）
    func setTemporaryStateCountdown(_ minutes: Int) {
        temporaryStateCountdown = minutes
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
        // 🎯 只有在临时状态或预规划状态遮罩激活时，才按优先级检查
        // 其他时候直接返回实时基础状态，确保UI立即响应
        
        // 检查是否有遮罩状态激活
        let hasActiveOverlay = isTemporaryStateActive || isPlannedStateActive
        
        // 如果没有遮罩状态激活，直接返回实时基础状态
        if !hasActiveOverlay {
            return currentBaseEnergyLevel
        }
        
        // 有遮罩状态激活时，按优先级检查：临时状态 > 预规划状态 > 基础状态

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

        // 🎯 设置分钟级倒计时
        let remainingMinutes = max(1, Int(ceil(duration / 60.0)))
        setTemporaryStateCountdown(remainingMinutes)

        print("🎯 设置临时状态倒计时: \(remainingMinutes)分钟")
    }
    
    /// 结束临时状态，恢复到原始状态（使用混合模型）
    func endTemporaryState() {
        guard isTemporaryStateActive else { return }

        print("结束临时状态: \(currentTemporaryStateType?.rawValue ?? "未知")")

        // 🎯 截断当前临时状态的TimeSlot到当前时间的上一分钟
        if let tempType = currentTemporaryStateType {
            let modified = truncateCurrentTimeSlot(
                for: tempType.energyLevel,
                in: &temporaryStatePlans,
                isTemporaryState: true
            )

            if modified {
                print("🎯 临时状态TimeSlot已截断")
            }
        }

        // 🎯 记录临时状态的结束到历史记录中
        if let original = originalEnergyLevel {
            recordEnergyLevelChange(to: original)
        }

        // 恢复原始状态（UI立即响应）
        if let original = originalEnergyLevel {
            updateCurrentBaseEnergyLevel(to: original)
        }

        // 🎯 立即执行一次主定时器内的逻辑
        checkAndAppendBaseStateTimeSlot()

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
        
        // 🎯 设置分钟级倒计时
        let remainingSeconds = max(0, endTime.timeIntervalSince(Date()))
        let remainingMinutes = max(1, Int(ceil(remainingSeconds / 60.0)))
        setPlannedStateCountdown(remainingMinutes)

        print("🎯 启动预规划遮罩: \(level.description), 开始: \(startTime), 结束: \(endTime), 倒计时: \(remainingMinutes)分钟")
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
    /// 会截断当前预规划状态的TimeSlot到当前时间的上一分钟
    func endPlannedStateManually() {
        guard isPlannedStateActive,
              let plannedLevel = currentPlannedStateLevel else {
            return
        }
        
        print("🎯 手动结束预规划遮罩，能量等级: \(plannedLevel.description)")
        
        // 🎯 截断当前预规划状态的TimeSlot到当前时间的上一分钟
        let modified = truncateCurrentTimeSlot(
            for: plannedLevel,
            in: &plannedEnergyPlans,
            isTemporaryState: false
        )

        if modified {
            print("🎯 预规划状态TimeSlot已截断")
        }
        
        // 记录预规划状态结束，切换到基础状态
        let baseLevel = currentBaseEnergyLevel
        recordEnergyLevelChange(to: baseLevel)

        // 🎯 立即执行一次主定时器内的逻辑
        checkAndAppendBaseStateTimeSlot()
        
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

    // MARK: - TimeSlot截断辅助方法

    /// 截断指定能量状态类型中包含当前时间的TimeSlot
    /// - Parameters:
    ///   - energyLevel: 能量等级
    ///   - plans: 要修改的EnergyPlan数组
    ///   - isTemporaryState: 是否为临时状态（true: 临时状态, false: 预规划状态）
    /// - Returns: 是否成功截断
    @discardableResult
    private func truncateCurrentTimeSlot(
        for energyLevel: EnergyLevel,
        in plans: inout [EnergyPlan],
        isTemporaryState: Bool
    ) -> Bool {
        let calendar = Calendar.current
        let now = Date()
        let today = calendar.startOfDay(for: now)
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)

        // 计算当前时间的上一分钟
        let previousTime = calendar.date(byAdding: .minute, value: -1, to: now)!
        let prevHour = calendar.component(.hour, from: previousTime)
        let prevMinute = calendar.component(.minute, from: previousTime)

        print("🎯 截断TimeSlot: 当前时间 \(currentHour):\(String(format: "%02d", currentMinute)), 截断到 \(prevHour):\(String(format: "%02d", prevMinute))")

        // 查找包含当前时间的EnergyPlan
        guard let planIndex = plans.firstIndex(where: { plan in
            calendar.isDate(plan.date, inSameDayAs: today) &&
            plan.energyLevel == energyLevel &&
            plan.containsTime(hour: currentHour, minute: currentMinute)
        }) else {
            print("❌ 未找到包含当前时间的EnergyPlan")
            return false
        }

        var plan = plans[planIndex]
        var modified = false

        // 查找包含当前时间的TimeSlot
        for (slotIndex, slot) in plan.timeSlots.enumerated() {
            if slot.contains(hour: currentHour, minute: currentMinute) {
                let slotStartMinutes = slot.startHour * 60 + slot.startMinute
                //let slotEndMinutes = slot.endHour * 60 + slot.endMinute
                let currentMinutes = currentHour * 60 + currentMinute
                let prevMinutes = prevHour * 60 + prevMinute

                print("🎯 找到TimeSlot: \(slot.startHour):\(String(format: "%02d", slot.startMinute)) - \(slot.endHour):\(String(format: "%02d", slot.endMinute))")

                // 检查是否当前时间等于TimeSlot的开始时间
                if currentMinutes == slotStartMinutes {
                    // 直接删除这个TimeSlot
                    plan.timeSlots.remove(at: slotIndex)
                    print("🎯 删除TimeSlot（当前时间等于开始时间）")
                    modified = true
                } else if prevMinutes >= slotStartMinutes {
                    // 截断TimeSlot的结束时间到上一分钟
                    let newSlot = TimeSlot(
                        startHour: slot.startHour,
                        startMinute: slot.startMinute,
                        endHour: prevHour,
                        endMinute: prevMinute
                    )
                    plan.timeSlots[slotIndex] = newSlot
                    print("🎯 截断TimeSlot: \(newSlot.startHour):\(String(format: "%02d", newSlot.startMinute)) - \(newSlot.endHour):\(String(format: "%02d", newSlot.endMinute))")
                    modified = true
                } else {
                    print("❌ 截断时间早于TimeSlot开始时间，不进行截断")
                }

                break // 只处理第一个匹配的TimeSlot
            }
        }

        // 如果TimeSlot数组为空，移除整个EnergyPlan
        if plan.timeSlots.isEmpty {
            plans.remove(at: planIndex)
            print("🎯 删除空的EnergyPlan")
            modified = true
        } else if modified {
            plans[planIndex] = plan
            print("🎯 更新EnergyPlan")
        }

        return modified
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

    // MARK: - 安心确认相关属性
    @Published var peacefulClosures: [PeacefulClosure] = [] // 安心确认列表
    @Published var myClosures: [PeacefulClosure] = [] // 我发起的安心确认
    @Published var pendingClosures: [PeacefulClosure] = [] // 待我处理的安心确认

    // MARK: - 心意盒相关属性
    @Published var giftBoxes: [GiftBox] = [] // 所有心意盒
    @Published var myGiftBoxes: [GiftBox] = [] // 我发起的心意盒
    @Published var pendingGiftBoxes: [GiftBox] = [] // 待我处理的心意盒
    
    // MARK: - 协作邀请相关属性
    @Published var invitations: [CollaborationInvitation] = [] // 所有协作邀请
    @Published var myInvitations: [CollaborationInvitation] = [] // 我发起的协作邀请

    // MARK: - 待办事项相关属性
    @Published var todoItems: [TodoItem] = [] // 待办事项

    // MARK: - Maybe清单相关属性
    @Published var maybeList: [MaybeItem] = [] // Maybe清单

    // MARK: - 碎片相关属性
    @Published var fragments: [Fragment] = [] // 所有碎片
    
    // MARK: - 通知/信息相关属性
    @Published var notifications: [NotificationInfo] = [] // 所有通知/信息

    // MARK: - 物品类型管理
    @Published var itemTypeManager = ItemTypeManager()

    // MARK: - 安心确认方法

    /// 创建新的安心确认
    func createPeacefulClosure(type: PeacefulClosureType, title: String, content: String,
                              itemDetails: ItemDetails? = nil, targetUserId: String = "partner",
                              expiresAt: Date? = nil, hasExpiration: Bool = false) {
        let newClosure = PeacefulClosure(
            type: type,
            title: title,
            content: content,
            itemDetails: itemDetails,
            createdBy: "me",
            targetUser: targetUserId,
            expiresAt: expiresAt,
            hasExpiration: hasExpiration
        )

        peacefulClosures.append(newClosure)
        myClosures.append(newClosure)

        print("✅ 创建安心确认: \(type.rawValue) - \(title)")

        if hasExpiration, let expiresAt = expiresAt {
            let formatter = DateFormatter()
            formatter.dateFormat = "MM月dd日 HH:mm"
            print("⏰ 设置过期时间: \(formatter.string(from: expiresAt))")
        }
    }

    /// 响应安心确认
    func respondToClosure(_ closure: PeacefulClosure, response: String) {
        guard let index = peacefulClosures.firstIndex(where: { $0.id == closure.id }) else { return }

        let responseObj = PeacefulClosureResponse(content: response)

        // 更新原确认记录
        peacefulClosures[index] = PeacefulClosure(
            id: closure.id,
            type: closure.type,
            title: closure.title,
            content: closure.content,
            itemDetails: closure.itemDetails,
            timestamp: closure.timestamp,
            status: .completed,
            createdBy: closure.createdBy,
            targetUser: closure.targetUser,
            response: responseObj,
            expiresAt: closure.expiresAt,
            hasExpiration: closure.hasExpiration
        )

        // 从待处理列表中移除
        pendingClosures.removeAll { $0.id == closure.id }

        print("✅ 响应安心确认: \(response)")

        // 5分钟后自动归档
        DispatchQueue.main.asyncAfter(deadline: .now() + 300) {
            self.archiveClosure(closure.id)
        }
    }

    /// 归档安心确认
    private func archiveClosure(_ closureId: UUID) {
        guard let index = peacefulClosures.firstIndex(where: { $0.id == closureId }) else { return }

        peacefulClosures[index] = PeacefulClosure(
            id: peacefulClosures[index].id,
            type: peacefulClosures[index].type,
            title: peacefulClosures[index].title,
            content: peacefulClosures[index].content,
            itemDetails: peacefulClosures[index].itemDetails,
            timestamp: peacefulClosures[index].timestamp,
            status: .archived,
            createdBy: peacefulClosures[index].createdBy,
            targetUser: peacefulClosures[index].targetUser,
            response: peacefulClosures[index].response
        )

        print("📦 安心确认已归档: \(peacefulClosures[index].title)")
    }

    /// 撤销安心确认
    func cancelClosure(_ closure: PeacefulClosure) {
        guard let index = peacefulClosures.firstIndex(where: { $0.id == closure.id }) else { return }

        // 更新状态为已撤销
        peacefulClosures[index] = PeacefulClosure(
            id: closure.id,
            type: closure.type,
            title: closure.title,
            content: closure.content,
            itemDetails: closure.itemDetails,
            timestamp: closure.timestamp,
            status: .cancelled,
            createdBy: closure.createdBy,
            targetUser: closure.targetUser,
            response: closure.response,
            expiresAt: closure.expiresAt,
            hasExpiration: closure.hasExpiration
        )

        // 从待处理列表中移除
        pendingClosures.removeAll { $0.id == closure.id }

        print("🚫 撤销安心确认: \(closure.title)")
    }

    /// 检查并处理过期的安心确认
    func checkExpiredClosures() {
        for (index, closure) in peacefulClosures.enumerated() {
            if closure.status == .pending && closure.isExpired {
                // 标记为已过期
                peacefulClosures[index] = PeacefulClosure(
                    id: closure.id,
                    type: closure.type,
                    title: closure.title,
                    content: closure.content,
                    itemDetails: closure.itemDetails,
                    timestamp: closure.timestamp,
                    status: .expired,
                    createdBy: closure.createdBy,
                    targetUser: closure.targetUser,
                    response: closure.response,
                    expiresAt: closure.expiresAt,
                    hasExpiration: closure.hasExpiration
                )

                print("⏰ 安心确认已过期: \(closure.title)")
            }
        }

        // 更新待处理列表
        updatePendingClosures()
    }

    /// 更新待处理列表
    func updatePendingClosures() {
        pendingClosures = peacefulClosures.filter { closure in
            closure.status == .pending && closure.targetUser == "me" && !closure.isExpired
        }
    }

    /// 获取示例数据
    func loadSamplePeacefulClosures() {
        let sample1 = PeacefulClosure(
            type: .item,
            title: "包裹在前台",
            content: "快递员王师傅已将包裹放在前台，取件码8567",
            itemDetails: ItemDetails(
                itemName: "快递包裹",
                location: "前台",
                expectedTime: nil,
                extraInfo: "取件码：8567"
            ),
            createdBy: "partner",
            targetUser: "me"
        )

        let sample2 = PeacefulClosure(
            type: .affair,
            title: "我已安全到家",
            content: "已经到家了，请放心",
            createdBy: "partner",
            targetUser: "me"
        )

        let sample3 = PeacefulClosure(
            id: UUID(),
            type: .item,
            title: "药品买回来了",
            content: "你需要的维生素已经买好了",
            itemDetails: ItemDetails(
                itemName: "维生素",
                location: "餐桌",
                expectedTime: nil,
                extraInfo: "记得按时服用"
            ),
            timestamp: Date().addingTimeInterval(-3600),
            status: .completed,
            createdBy: "partner",
            targetUser: "me",
            response: PeacefulClosureResponse(content: "拿到啦 🙌")
        )

        peacefulClosures = [sample1, sample2, sample3]
        updatePendingClosures()
    }

    // MARK: - 心意盒方法

    /// 创建新的心意盒
    func createGiftBox(item: String, note: String? = nil, suggestedLocation: String,
                      preparationTime: TimeInterval, hasExpiration: Bool = false,
                      expiresAt: Date? = nil) {
        let newGiftBox = GiftBox(
            item: item,
            note: note,
            suggestedLocation: suggestedLocation,
            preparationTime: preparationTime,
            hasExpiration: hasExpiration,
            expiresAt: expiresAt,
            isFromMe: true
        )

        giftBoxes.append(newGiftBox)
        updateGiftBoxLists()
        saveGiftBoxes()
    }

    /// 响应心意盒
    func respondToGiftBox(_ giftBox: GiftBox, response: GiftBoxResponse,
                          acceptedStartTime: Date? = nil,
                          acceptedEndTime: Date? = nil,
                          actualLocation: String? = nil) {
        guard let index = giftBoxes.firstIndex(where: { $0.id == giftBox.id }) else { return }

        var updatedGiftBox = giftBox
        updatedGiftBox.response = response
        updatedGiftBox.respondedAt = Date()

        switch response {
        case .accepted:
            updatedGiftBox.status = .accepted
            updatedGiftBox.acceptedStartTime = acceptedStartTime
            updatedGiftBox.acceptedEndTime = acceptedEndTime
            updatedGiftBox.actualLocation = actualLocation ?? giftBox.suggestedLocation

        case .rejected:
            updatedGiftBox.status = .rejected
        }

        giftBoxes[index] = updatedGiftBox
        updateGiftBoxLists()
        saveGiftBoxes()
    }

    /// 撤回心意盒
    func withdrawGiftBox(_ giftBox: GiftBox) {
        guard let index = giftBoxes.firstIndex(where: { $0.id == giftBox.id }) else { return }

        var updatedGiftBox = giftBox
        updatedGiftBox.status = .withdrawn
        updatedGiftBox.isWithdrawn = true

        giftBoxes[index] = updatedGiftBox
        updateGiftBoxLists()
        saveGiftBoxes()
    }

    /// 再次编辑发送心意盒
    func editAndResendGiftBox(_ giftBox: GiftBox,
                              newItem: String,
                              newNote: String? = nil,
                              newLocation: String,
                              newPreparationTime: TimeInterval,
                              newHasExpiration: Bool = false,
                              newExpiresAt: Date? = nil) {
        guard let index = giftBoxes.firstIndex(where: { $0.id == giftBox.id }) else { return }

        let updatedGiftBox = GiftBox(
            id: giftBox.id,
            item: newItem,
            note: newNote,
            suggestedLocation: newLocation,
            preparationTime: newPreparationTime,
            hasExpiration: newHasExpiration,
            expiresAt: newExpiresAt,
            isFromMe: true,
            status: .pending,
            acceptedStartTime: nil,
            acceptedEndTime: nil,
            actualLocation: nil,
            response: nil,
            respondedAt: nil,
            createdAt: giftBox.createdAt,
            lastEditedAt: Date(),
            isWithdrawn: false
        )

        giftBoxes[index] = updatedGiftBox
        updateGiftBoxLists()
        saveGiftBoxes()
    }

    /// 检查过期的心意盒
    func checkExpiredGiftBoxes() {
        for index in giftBoxes.indices {
            if giftBoxes[index].isExpired && giftBoxes[index].status == .pending {
                giftBoxes[index].status = .expired
            }
        }
        updateGiftBoxLists()
    }

    /// 更新心意盒列表
    private func updateGiftBoxLists() {
        myGiftBoxes = giftBoxes.filter { $0.isFromMe }
            .sorted { $0.lastActivityTime > $1.lastActivityTime }

        pendingGiftBoxes = giftBoxes.filter {
            $0.status == .pending && !$0.isFromMe && !$0.isExpired
        }
    }

    /// 保存心意盒数据
    private func saveGiftBoxes() {
        // 这里可以添加数据持久化逻辑
        // 目前先使用内存存储
    }

    /// 获取最早可接受时间
    func getEarliestAcceptTime(for giftBox: GiftBox) -> Date {
        return Date().addingTimeInterval(giftBox.preparationTime)
    }

    /// 验证接受时间
    func validateAcceptTime(startTime: Date, endTime: Date?,
                          preparationTime: TimeInterval) -> Bool {
        let earliestTime = Date().addingTimeInterval(preparationTime)
        if startTime < earliestTime { return false }

        if let endTime = endTime {
            return endTime > startTime
        }
        return true
    }

    /// 基于心意盒创建安心确认的初始数据
    func createPeacefulClosureFromGiftBox(_ giftBox: GiftBox) -> PeacefulClosureInitialData {
        return PeacefulClosureInitialData(
            closureType: .item,
            itemName: giftBox.item,
            location: giftBox.actualLocation ?? giftBox.suggestedLocation,
            relatedGiftBoxId: giftBox.id
        )
    }
    
    // MARK: - 心意盒示例数据
    
    /// 加载心意盒示例数据（覆盖所有状态）
    func loadSampleGiftBoxes() {
        var sampleBoxes: [GiftBox] = []
        
        // 1. 待确认状态（我发起的，等待对方响应）
        let pendingBox1 = GiftBox(
            item: "奶茶大杯",
            note: "你最喜欢的芋泥波波奶茶",
            suggestedLocation: "公司茶水间",
            preparationTime: 1800, // 30分钟
            hasExpiration: false,
            expiresAt: nil,
            isFromMe: true
        )
        sampleBoxes.append(pendingBox1)
        
        let pendingBox2 = GiftBox(
            item: "鲜花一束",
            note: "希望你喜欢这束向日葵",
            suggestedLocation: "公司前台",
            preparationTime: 3600, // 1小时
            hasExpiration: true,
            expiresAt: Date().addingTimeInterval(3 * 24 * 3600), // 3天后过期
            isFromMe: true
        )
        sampleBoxes.append(pendingBox2)
        
        // 2. 已接受状态（对方已同意接收）
        let acceptedBox = GiftBox(
            id: UUID(),
            item: "巧克力礼盒",
            note: "甜蜜小惊喜",
            suggestedLocation: "家里",
            preparationTime: 1800,
            hasExpiration: false,
            expiresAt: nil,
            isFromMe: true,
            status: .accepted,
            acceptedStartTime: Date().addingTimeInterval(24 * 3600), // 明天
            acceptedEndTime: Date().addingTimeInterval(26 * 3600), // 明天+2小时
            actualLocation: "家里客厅",
            response: .accepted,
            respondedAt: Date().addingTimeInterval(-3600), // 1小时前响应
            createdAt: Date().addingTimeInterval(-2 * 24 * 3600), // 2天前创建
            lastEditedAt: nil,
            isWithdrawn: false
        )
        sampleBoxes.append(acceptedBox)
        
        // 3. 已拒绝状态（对方不想要）
        let rejectedBox = GiftBox(
            id: UUID(),
            item: "护手霜",
            note: "冬天要好好保护小手",
            suggestedLocation: "办公桌",
            preparationTime: 900, // 15分钟
            hasExpiration: false,
            expiresAt: nil,
            isFromMe: true,
            status: .rejected,
            acceptedStartTime: nil,
            acceptedEndTime: nil,
            actualLocation: nil,
            response: .rejected,
            respondedAt: Date().addingTimeInterval(-12 * 3600), // 12小时前响应
            createdAt: Date().addingTimeInterval(-3 * 24 * 3600), // 3天前创建
            lastEditedAt: nil,
            isWithdrawn: false
        )
        sampleBoxes.append(rejectedBox)
        
        // 4. 已过期状态（超过有效期）
        let expiredBox = GiftBox(
            id: UUID(),
            item: "冰淇淋",
            note: "趁着还没化掉快来拿",
            suggestedLocation: "公司冰箱",
            preparationTime: 300, // 5分钟
            hasExpiration: true,
            expiresAt: Date().addingTimeInterval(-2 * 3600), // 2小时前过期
            isFromMe: true,
            status: .expired,
            acceptedStartTime: nil,
            acceptedEndTime: nil,
            actualLocation: nil,
            response: nil,
            respondedAt: nil,
            createdAt: Date().addingTimeInterval(-5 * 24 * 3600), // 5天前创建
            lastEditedAt: nil,
            isWithdrawn: false
        )
        sampleBoxes.append(expiredBox)
        
        // 5. 已撤回状态（我主动撤回）
        let withdrawnBox = GiftBox(
            id: UUID(),
            item: "咖啡",
            note: "给你带了一杯热美式",
            suggestedLocation: "办公室",
            preparationTime: 600, // 10分钟
            hasExpiration: false,
            expiresAt: nil,
            isFromMe: true,
            status: .withdrawn,
            acceptedStartTime: nil,
            acceptedEndTime: nil,
            actualLocation: nil,
            response: nil,
            respondedAt: nil,
            createdAt: Date().addingTimeInterval(-24 * 3600), // 1天前创建
            lastEditedAt: Date().addingTimeInterval(-23 * 3600), // 1天前撤回
            isWithdrawn: true
        )
        sampleBoxes.append(withdrawnBox)
        
        // 6. 再次编辑发送的例子（已接受，后来又编辑重发）
        let resentBox = GiftBox(
            id: UUID(),
            item: "下午茶套餐",
            note: "重新准备了一份，希望这次你喜欢",
            suggestedLocation: "公司休息区",
            preparationTime: 2700, // 45分钟
            hasExpiration: true,
            expiresAt: Date().addingTimeInterval(2 * 24 * 3600), // 2天后过期
            isFromMe: true,
            status: .pending, // 重新发送后变为待确认
            acceptedStartTime: nil,
            acceptedEndTime: nil,
            actualLocation: nil,
            response: nil,
            respondedAt: nil,
            createdAt: Date().addingTimeInterval(-7 * 24 * 3600), // 7天前创建
            lastEditedAt: Date().addingTimeInterval(-2 * 3600), // 2小时前编辑
            isWithdrawn: false
        )
        sampleBoxes.append(resentBox)
        
        // 添加到列表
        giftBoxes.append(contentsOf: sampleBoxes)
        updateGiftBoxLists()
        
        print("✅ 已加载心意盒示例数据: \(sampleBoxes.count)个")
        print("   - 待确认: \(sampleBoxes.filter { $0.status == .pending }.count)个")
        print("   - 已接受: \(sampleBoxes.filter { $0.status == .accepted }.count)个")
        print("   - 已拒绝: \(sampleBoxes.filter { $0.status == .rejected }.count)个")
        print("   - 已过期: \(sampleBoxes.filter { $0.status == .expired }.count)个")
        print("   - 已撤回: \(sampleBoxes.filter { $0.status == .withdrawn }.count)个")
    }
    
    // MARK: - 协作邀请示例数据
    
    /// 加载协作邀请示例数据（包含所有状态）
    func loadSampleInvitations() {
        // 1. 待处理的协作邀请（来自伴侣）
        let pendingInvitation1 = CollaborationInvitation(
            title: "周末一起看电影",
            description: "最近上映了一部不错的电影《流浪地球3》，要不要一起去看？可以周六晚上或者周日下午。",
            location: "万达影城",
            startTime: Date().addingTimeInterval(3 * 24 * 3600), // 3天后
            duration: 7200, // 2小时
            createdBy: "partner"
        )
        
        let pendingInvitation2 = CollaborationInvitation(
            title: "一起去公园散步",
            description: "天气预报说明天天气不错，要不要去中山公园走走？顺便可以拍拍照。",
            location: "中山公园",
            startTime: Date().addingTimeInterval(26 * 3600), // 明天下午
            duration: 5400, // 1.5小时
            createdBy: "partner"
        )
        
        let pendingInvitation3 = CollaborationInvitation(
            title: "周五晚上一起吃火锅",
            description: "发现了一家新开的火锅店，评价很不错，要不要周五晚上一起去试试？",
            location: "海底捞（人民广场店）",
            startTime: Date().addingTimeInterval(4 * 24 * 3600), // 4天后
            duration: 7200, // 2小时
            createdBy: "partner"
        )
        
        // 2. 已接受的邀请（测试【好呀】逻辑）
        var acceptedInvitation = CollaborationInvitation(
            title: "一起去书店看书",
            description: "最近想买几本书，要不要一起去书店逛逛？",
            location: "西西弗书店",
            startTime: Date().addingTimeInterval(5 * 24 * 3600), // 5天后
            duration: 3600, // 1小时
            createdBy: "partner"
        )
        acceptedInvitation.status = .accepted
        acceptedInvitation.lastModified = Date()
        
        // 3. 协商中的邀请（测试【商量下呗】逻辑）
        var negotiatingInvitation = CollaborationInvitation(
            title: "周末去海边",
            description: "天气预报说周末晴天，去海边走走吧！",
            location: "金山海滩",
            startTime: Date().addingTimeInterval(6 * 24 * 3600), // 6天后
            duration: 14400, // 4小时
            createdBy: "partner"
        )
        negotiatingInvitation.status = .negotiating
        negotiatingInvitation.lastModified = Date().addingTimeInterval(-3600)
        
        // 4. 延后的邀请（测试【以后看】逻辑）
        var postponedInvitation = CollaborationInvitation(
            title: "去博物馆看展览",
            description: "最近有个很有意思的艺术展，要不要找时间一起去看？",
            location: "上海博物馆",
            startTime: Date().addingTimeInterval(7 * 24 * 3600), // 7天后
            duration: 7200, // 2小时
            createdBy: "partner"
        )
        postponedInvitation.status = .postponed
        postponedInvitation.lastModified = Date().addingTimeInterval(-7200)
        
        // 5. 我发起的邀请
        let myInvitation1 = CollaborationInvitation(
            title: "一起吃早午餐",
            description: "发现了一家不错的早午餐店，要不要一起去试试？",
            location: "绿茶餐厅",
            startTime: Date().addingTimeInterval(2 * 24 * 3600), // 2天后
            duration: 5400, // 1.5小时
            createdBy: "me"
        )
        
        var myInvitation2 = CollaborationInvitation(
            title: "周日去爬山",
            description: "好久没运动了，周日一起去爬山吧！",
            location: "佘山",
            startTime: Date().addingTimeInterval(5 * 24 * 3600), // 5天后
            duration: 10800, // 3小时
            createdBy: "me"
        )
        myInvitation2.status = .accepted
        
        // 添加到对应列表
        invitations = [
            pendingInvitation1,
            pendingInvitation2,
            pendingInvitation3,
            acceptedInvitation,
            negotiatingInvitation,
            postponedInvitation
        ]
        
        myInvitations = [
            myInvitation1,
            myInvitation2
        ]
        
        print("✅ 已加载协作邀请示例数据")
        print("   - 待处理邀请: 3个")
        print("   - 已接受邀请: 1个")
        print("   - 协商中邀请: 1个")
        print("   - 已延后邀请: 1个")
        print("   - 我发起的邀请: 2个")
    }
    
    // MARK: - 碎片示例数据
    
    /// 加载碎片示例数据
    func loadSampleFragments() {
        let fragments = [
            Fragment(
                content: "今天看到一只很可爱的小猫",
                imageURL: nil,
                linkURL: nil,
                createdAt: Date(),
                isFromMe: true
            ),
            Fragment(
                content: "分享一篇很有意思的文章",
                imageURL: nil,
                linkURL: "https://example.com",
                createdAt: Date().addingTimeInterval(-3600),
                isFromMe: true
            )
        ]
        
        self.fragments = fragments
    }
    
    // MARK: - 通知/信息相关方法
    
    /// 创建通知
    func createNotification(type: NotificationInfo.NotificationType, title: String, content: String, relatedItemId: UUID? = nil, endTime: Date? = nil) {
        let notification = NotificationInfo(
            type: type,
            title: title,
            content: content,
            relatedItemId: relatedItemId,
            createdAt: Date(),
            endTime: endTime,
            isRead: false
        )
        notifications.insert(notification, at: 0) // 插入到最前面
        print("✅ 创建通知: \(title)")
    }
    
    /// 删除通知（信息点OK后）
    func dismissNotification(_ notification: NotificationInfo) {
        notifications.removeAll { $0.id == notification.id }
        print("✅ 已删除通知: \(notification.title)")
    }
    
    /// 关闭提醒（查看详情后手动关闭）
    func closeReminder(_ notification: NotificationInfo) {
        notifications.removeAll { $0.id == notification.id }
        print("✅ 已关闭提醒: \(notification.title)")
    }
    
    /// 自动清理过期的提醒
    func cleanExpiredReminders() {
        let expiredCount = notifications.filter { $0.isExpired }.count
        notifications.removeAll { $0.isExpired }
        if expiredCount > 0 {
            print("✅ 已自动清理\(expiredCount)条过期提醒")
        }
    }
    
    /// 加载通知示例数据
    func loadSampleNotifications() {
        // 模拟各种通知场景
        notifications = [
            // 1. 对方接受了我的邀请（信息）
            NotificationInfo(
                id: UUID(),
                type: .invitationAccepted,
                category: .info,
                title: "周日去爬山",
                content: "对方已接受您的邀请，系统已创建待办提醒",
                relatedItemId: nil,
                createdAt: Date().addingTimeInterval(-3600), // 1小时前
                isRead: false
            ),
            
            // 2. 待办事项提醒（有结束时间，会自动消失）
            NotificationInfo(
                id: UUID(),
                type: .todoReminder,
                category: .reminder,
                title: "一起去书店看书",
                content: "活动将在2天后开始，请准时参加",
                relatedItemId: nil,
                createdAt: Date().addingTimeInterval(-7200), // 2小时前
                endTime: Date().addingTimeInterval(2 * 24 * 3600), // 2天后结束
                isRead: false
            ),
            
            // 3. 待办事项提醒（无结束时间，需手动关闭）
            NotificationInfo(
                id: UUID(),
                type: .todoReminder,
                category: .reminder,
                title: "记得联系对方",
                content: "对方选择微信商量，请及时联系",
                relatedItemId: nil,
                createdAt: Date().addingTimeInterval(-10800), // 3小时前
                endTime: nil, // 无结束时间
                isRead: false
            ),
            
            // 4. 对方选择"以后看"（信息）
            NotificationInfo(
                id: UUID(),
                type: .invitationPostponed,
                category: .info,
                title: "一起吃早午餐",
                content: "对方选择了\"以后看\"，活动已存入Maybe清单",
                relatedItemId: nil,
                createdAt: Date().addingTimeInterval(-14400), // 4小时前
                isRead: false
            ),
            
            // 5. 对方接受了心意盒（信息）
            NotificationInfo(
                id: UUID(),
                type: .giftBoxAccepted,
                category: .info,
                title: "巧克力礼盒",
                content: "对方已收下您的心意，将在明天下午取走",
                relatedItemId: nil,
                createdAt: Date().addingTimeInterval(-18000), // 5小时前
                isRead: false
            ),
            
            // 6. 对方选择"微信商量"（信息，已读）
            NotificationInfo(
                id: UUID(),
                type: .invitationWechat,
                category: .info,
                title: "周末去海边",
                content: "对方选择通过微信商量，请及时查看微信消息",
                relatedItemId: nil,
                createdAt: Date().addingTimeInterval(-86400), // 1天前
                isRead: true // 已读
            )
        ]
        
        print("✅ 已加载通知示例数据: \(notifications.count)条")
        print("   - 信息: \(notifications.filter { $0.category == .info }.count)条")
        print("   - 提醒: \(notifications.filter { $0.category == .reminder }.count)条")
    }
}

// 安心确认初始数据结构
struct PeacefulClosureInitialData {
    let closureType: PeacefulClosureType  // 自动设为 .item
    let itemName: String                  // 从心意盒继承的物品名称
    let location: String?                 // 预填地点
    let relatedGiftBoxId: UUID            // 关联的心意盒ID
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

// MARK: - 旧的协作邀请模型已移除，使用下方完整版本

// MARK: - 安心确认模型

enum PeacefulClosureType: String, CaseIterable, Codable {
    case item = "物品"
    case affair = "事务"
}

struct PeacefulClosure: Identifiable, Codable {
    let id: UUID
    let type: PeacefulClosureType
    let title: String
    let content: String
    let itemDetails: ItemDetails? // 仅物品类使用
    let timestamp: Date
    let status: ClosureStatus
    let createdBy: String // 创建者ID
    let targetUser: String // 目标用户ID
    let response: PeacefulClosureResponse?
    let expiresAt: Date? // 过期时间（仅事务类可选）
    let hasExpiration: Bool // 是否有过期时间

    init(id: UUID = UUID(), type: PeacefulClosureType, title: String, content: String,
         itemDetails: ItemDetails? = nil, createdBy: String, targetUser: String,
         expiresAt: Date? = nil, hasExpiration: Bool = false) {
        self.id = id
        self.type = type
        self.title = title
        self.content = content
        self.itemDetails = itemDetails
        self.timestamp = Date()
        self.status = .pending
        self.createdBy = createdBy
        self.targetUser = targetUser
        self.response = nil
        self.expiresAt = expiresAt
        self.hasExpiration = hasExpiration
    }

    // 用于从已有数据创建（包含响应）
    init(id: UUID, type: PeacefulClosureType, title: String, content: String,
         itemDetails: ItemDetails? = nil, timestamp: Date, status: ClosureStatus,
         createdBy: String, targetUser: String, response: PeacefulClosureResponse? = nil,
         expiresAt: Date? = nil, hasExpiration: Bool = false) {
        self.id = id
        self.type = type
        self.title = title
        self.content = content
        self.itemDetails = itemDetails
        self.timestamp = timestamp
        self.status = status
        self.createdBy = createdBy
        self.targetUser = targetUser
        self.response = response
        self.expiresAt = expiresAt
        self.hasExpiration = hasExpiration
    }

    // 检查是否过期
    var isExpired: Bool {
        guard let expiresAt = expiresAt, hasExpiration else { return false }
        return Date() > expiresAt
    }
}

struct ItemDetails: Codable {
    let itemName: String      // 物品名称
    let location: String?     // 地点（可选）
    let expectedTime: Date?   // 预计时间（可选）
    let extraInfo: String?    // 补充信息（可选）
}

struct PeacefulClosureResponse: Codable {
    let content: String       // 具体回复内容
    let timestamp: Date
    let isFinal: Bool         // 标记为最终状态

    init(content: String) {
        self.content = content
        self.timestamp = Date()
        self.isFinal = true
    }
}

enum ClosureStatus: String, Codable {
    case pending = "待确认"
    case completed = "已完成"
    case archived = "已归档"
    case expired = "已过期"
    case cancelled = "已撤销"
}

// MARK: - 物品类响应选项
enum ItemResponseType: String, CaseIterable {
    case noted = "知道啦"
    case gotIt = "拿到啦"
    case later = "等下去拿"

    var icon: String {
        switch self {
        case .noted: return "💙"
        case .gotIt: return "🙌"
        case .later: return "⏰"
        }
    }

    var description: String {
        switch self {
        case .noted: return "收到信息，不用管我"
        case .gotIt: return "已经取回来了"
        case .later: return "忙完就去取"
        }
    }

    var confirmationMessage: String {
        switch self {
        case .noted: return "对方已知悉信息"
        case .gotIt: return "物品已取回，事情办结"
        case .later: return "对方稍后处理，无需提醒"
        }
    }
}

// MARK: - 心意盒模型
struct GiftBox: Identifiable, Codable {
    let id: UUID
    let item: String                    // 物品
    let note: String?                   // 备注（选填）
    let suggestedLocation: String       // 建议地点
    let preparationTime: TimeInterval   // 心意准备时间（分钟）
    let hasExpiration: Bool            // 是否有有效期
    let expiresAt: Date?               // 过期时间
    let isFromMe: Bool                // 是否我发起的
    var status: GiftBoxStatus         // 状态（改为 var 允许修改）

    // 接收方填写的信息
    var acceptedStartTime: Date?       // 接受开始时间
    var acceptedEndTime: Date?         // 接受结束时间（可选）
    var actualLocation: String?        // 实际接受地点
    var response: GiftBoxResponse?     // 接收方响应
    var respondedAt: Date?             // 响应时间

    // 时间戳
    let createdAt: Date
    var lastEditedAt: Date?           // 最后编辑时间
    var isWithdrawn: Bool             // 是否已撤回

    // 用于排序的时间
    var lastActivityTime: Date {
        if let respondedAt = respondedAt {
            return respondedAt
        }
        if let lastEditedAt = lastEditedAt {
            return lastEditedAt
        }
        return createdAt
    }

    var isExpired: Bool {
        guard hasExpiration, let expiresAt = expiresAt else { return false }
        return Date() > expiresAt
    }

    init(item: String, note: String? = nil, suggestedLocation: String,
         preparationTime: TimeInterval, hasExpiration: Bool = false,
         expiresAt: Date? = nil, isFromMe: Bool = true) {
        self.id = UUID()
        self.item = item
        self.note = note
        self.suggestedLocation = suggestedLocation
        self.preparationTime = preparationTime
        self.hasExpiration = hasExpiration
        self.expiresAt = expiresAt
        self.isFromMe = isFromMe
        self.status = .pending
        self.createdAt = Date()
        self.isWithdrawn = false
    }

    // 用于从已有数据创建（包含完整信息）
    init(id: UUID, item: String, note: String?, suggestedLocation: String,
         preparationTime: TimeInterval, hasExpiration: Bool, expiresAt: Date?,
         isFromMe: Bool, status: GiftBoxStatus, acceptedStartTime: Date?,
         acceptedEndTime: Date?, actualLocation: String?, response: GiftBoxResponse?,
         respondedAt: Date?, createdAt: Date, lastEditedAt: Date?,
         isWithdrawn: Bool) {
        self.id = id
        self.item = item
        self.note = note
        self.suggestedLocation = suggestedLocation
        self.preparationTime = preparationTime
        self.hasExpiration = hasExpiration
        self.expiresAt = expiresAt
        self.isFromMe = isFromMe
        self.status = status
        self.acceptedStartTime = acceptedStartTime
        self.acceptedEndTime = acceptedEndTime
        self.actualLocation = actualLocation
        self.response = response
        self.respondedAt = respondedAt
        self.createdAt = createdAt
        self.lastEditedAt = lastEditedAt
        self.isWithdrawn = isWithdrawn
    }
}

enum GiftBoxStatus: String, CaseIterable, Codable {
    case pending = "待确认"
    case accepted = "已接受"
    case rejected = "不想要"
    case expired = "已过期"
    case withdrawn = "已撤回"

    var displayText: String {
        return self.rawValue
    }

    var color: Color {
        switch self {
        case .pending: return .orange
        case .accepted: return .green
        case .rejected: return .gray
        case .expired: return .red
        case .withdrawn: return .purple
        }
    }
}

enum GiftBoxResponse: String, CaseIterable, Codable {
    case accepted = "好滴收下啦🥰"
    case rejected = "不太想要😅"
}

// 可管理的物品类型选项（用于快速填入）
struct ItemType: Codable, Identifiable {
    let id: UUID
    var name: String
    var icon: String
    var color: String // 用于标识颜色
    var isDefault: Bool // 是否为默认类别
    let createdAt: Date

    init(name: String, icon: String, color: String = "primary", isDefault: Bool = false) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.color = color
        self.isDefault = isDefault
        self.createdAt = Date()
    }

    // 用于更新的初始化方法
    init(id: UUID, name: String, icon: String, color: String, isDefault: Bool, createdAt: Date) {
        self.id = id
        self.name = name
        self.icon = icon
        self.color = color
        self.isDefault = isDefault
        self.createdAt = createdAt
    }
}

// 物品类型管理器
class ItemTypeManager: ObservableObject {
    @Published var itemTypes: [ItemType] = []

    private let userDefaults = UserDefaults.standard
    private let itemTypesKey = "giftBoxItemTypes"

    init() {
        loadItemTypes()
    }

    // 加载物品类型
    func loadItemTypes() {
        if let data = userDefaults.data(forKey: itemTypesKey),
           let decoded = try? JSONDecoder().decode([ItemType].self, from: data) {
            self.itemTypes = decoded
        } else {
            // 首次使用，加载默认类型
            loadDefaultItemTypes()
        }
    }

    // 加载默认物品类型
    private func loadDefaultItemTypes() {
        self.itemTypes = [
            ItemType(name: "礼物", icon: "gift.fill", color: "primary", isDefault: true),
            ItemType(name: "下午茶", icon: "cup.and.saucer.fill", color: "secondary", isDefault: true),
            ItemType(name: "正餐", icon: "fork.knife", color: "tertiary", isDefault: true),
            ItemType(name: "日常用品", icon: "house.fill", color: "quaternary", isDefault: true)
        ]
        saveItemTypes()
    }

    // 保存物品类型
    func saveItemTypes() {
        if let encoded = try? JSONEncoder().encode(itemTypes) {
            userDefaults.set(encoded, forKey: itemTypesKey)
        }
    }

    // 添加新的物品类型
    func addItemType(_ itemType: ItemType) {
        itemTypes.append(itemType)
        saveItemTypes()
    }

    // 删除物品类型
    func deleteItemType(at indexSet: IndexSet) {
        itemTypes.remove(atOffsets: indexSet)
        saveItemTypes()
    }

    // 更新物品类型
    func updateItemType(_ itemType: ItemType) {
        if let index = itemTypes.firstIndex(where: { $0.id == itemType.id }) {
            itemTypes[index] = itemType
            saveItemTypes()
        }
    }

    // 获取所有类型（兼容旧代码）
    var allTypes: [ItemType] {
        return itemTypes
    }

    // 恢复默认设置
    func resetToDefaults() {
        loadDefaultItemTypes()
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

// MARK: - 协作邀请相关模型

enum InvitationStatus: String, CaseIterable, Codable {
    case pending = "待处理"
    case accepted = "好呀"
    case negotiating = "商量下呗"
    case postponed = "以后看"
    case wechatNegotiating = "微信商量"

    var color: Color {
        switch self {
        case .pending: return .orange
        case .accepted: return .green
        case .negotiating: return .blue
        case .postponed: return .gray
        case .wechatNegotiating: return .purple
        }
    }
}

struct CollaborationInvitation: Identifiable, Codable {
    let id: UUID
    let title: String
    let description: String
    let location: String
    let startTime: Date
    let duration: TimeInterval // 持续时间（秒）
    let createdBy: String // 创建者ID
    let createdAt: Date
    var status: InvitationStatus
    var lastModified: Date

    // 协商相关字段
    var negotiationHistory: [NegotiationRecord] = []
    var multipleTimeOptions: [Date] = []
    var multipleContentOptions: [String] = []

    init(title: String, description: String, location: String, startTime: Date, duration: TimeInterval, createdBy: String) {
        self.id = UUID()
        self.title = title
        self.description = description
        self.location = location
        self.startTime = startTime
        self.duration = duration
        self.createdBy = createdBy
        self.createdAt = Date()
        self.status = .pending
        self.lastModified = Date()
    }
}

struct NegotiationRecord: Identifiable, Codable {
    let id: UUID
    let proposedBy: String
    let proposedAt: Date
    let newStartTime: Date?
    let newDuration: TimeInterval?
    let newLocation: String?
    let newDescription: String?
    let timeOptions: [Date]?
    let contentOptions: [String]?

    init(proposedBy: String, newStartTime: Date? = nil, newDuration: TimeInterval? = nil, newLocation: String? = nil, newDescription: String? = nil, timeOptions: [Date]? = nil, contentOptions: [String]? = nil) {
        self.id = UUID()
        self.proposedBy = proposedBy
        self.proposedAt = Date()
        self.newStartTime = newStartTime
        self.newDuration = newDuration
        self.newLocation = newLocation
        self.newDescription = newDescription
        self.timeOptions = timeOptions
        self.contentOptions = contentOptions
    }
}

// 协作邀请管理器
class CollaborationInvitationManager: ObservableObject {
    @Published var invitations: [CollaborationInvitation] = []
    
    // 计算属性不能使用@Published
    var pendingInvitations: [CollaborationInvitation] {
        invitations.filter { $0.status == .pending }
    }
    
    var myInvitations: [CollaborationInvitation] {
        invitations.filter { $0.createdBy == getCurrentUserID() }
    }

    private func getCurrentUserID() -> String {
        // TODO: 实现用户ID获取逻辑
        return "user1" // 临时硬编码
    }

    // 创建新邀请
    func createInvitation(title: String, description: String, location: String, startTime: Date, duration: TimeInterval) {
        let invitation = CollaborationInvitation(
            title: title,
            description: description,
            location: location,
            startTime: startTime,
            duration: duration,
            createdBy: getCurrentUserID()
        )

        invitations.append(invitation)
    }

    // 响应邀请
    func respondToInvitation(_ invitation: CollaborationInvitation, status: InvitationStatus) {
        if let index = invitations.firstIndex(where: { $0.id == invitation.id }) {
            invitations[index].status = status
            invitations[index].lastModified = Date()

            // 如果选择了"好呀"，创建待办事项
            if status == .accepted {
                createTodoItem(for: invitations[index])
            }

            // 如果选择了"以后看"，添加到Maybe清单
            if status == .postponed {
                addToMaybeList(invitation: invitations[index])
            }
        }
    }

    // 创建协商记录
    func createNegotiation(for invitation: CollaborationInvitation, timeOptions: [Date]? = nil, contentOptions: [String]? = nil, newLocation: String? = nil, newDuration: TimeInterval? = nil) {
        let negotiation = NegotiationRecord(
            proposedBy: getCurrentUserID(),
            newStartTime: timeOptions?.first,
            newDuration: newDuration,
            newLocation: newLocation,
            newDescription: nil,
            timeOptions: timeOptions,
            contentOptions: contentOptions
        )

        if let index = invitations.firstIndex(where: { $0.id == invitation.id }) {
            invitations[index].negotiationHistory.append(negotiation)
            invitations[index].status = .negotiating
            invitations[index].lastModified = Date()

            // 如果提供了多选项，添加到邀请中
            if let timeOptions = timeOptions {
                invitations[index].multipleTimeOptions = timeOptions
            }
            if let contentOptions = contentOptions {
                invitations[index].multipleContentOptions = contentOptions
            }
        }
    }

    // 创建待办事项（好呀响应后）
    func createTodoItem(for invitation: CollaborationInvitation) {
        // TODO: 这里应该添加到UserState的todoItems中
        // 由于CollaborationInvitationManager没有直接访问UserState，暂时只打印日志
        print("✅ 创建待办事项: \(invitation.title)")
        print("   - 开始时间: \(invitation.startTime)")
        print("   - 结束时间: \(invitation.startTime.addingTimeInterval(invitation.duration))")
        print("   - 自动消失: 是")
    }

    // 添加到Maybe清单（以后看响应后）
    func addToMaybeList(invitation: CollaborationInvitation) {
        // TODO: 这里应该添加到UserState的maybeList中
        // 由于CollaborationInvitationManager没有直接访问UserState，暂时只打印日志
        print("✅ 添加到Maybe清单: \(invitation.title)")
        print("   - 地点: \(invitation.location)")
        print("   - 建议时长: \(formatDuration(invitation.duration))")
    }

    // 添加待办事项（供外部调用）
    func addTodoItem(_ todoItem: TodoItem) {
        print("✅ 添加待办事项: \(todoItem.title)")
        // TODO: 实际添加到UserState.todoItems中
    }

    // 添加Maybe清单项目（供外部调用）
    func addToMaybeList(_ maybeItem: MaybeItem) {
        print("✅ 添加到Maybe清单: \(maybeItem.title)")
        // TODO: 实际添加到UserState.maybeList中
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60

        if hours > 0 && minutes > 0 {
            return "\(hours)小时\(minutes)分钟"
        } else if hours > 0 {
            return "\(hours)小时"
        } else {
            return "\(minutes)分钟"
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

// MARK: - 待办事项模型
struct TodoItem: Identifiable, Codable {
    let id: UUID
    let title: String
    let description: String
    let location: String?
    let startTime: Date
    let endTime: Date?
    let isAutoDismiss: Bool
    let type: TodoType
    let relatedInvitationId: UUID?

    enum TodoType: String, Codable {
        case invitation = "invitation"
        case wechatNegotiation = "wechat_negotiation"
    }
}

// MARK: - Maybe清单项目模型
struct MaybeItem: Identifiable, Codable {
    let id: UUID
    let title: String
    let description: String
    let location: String
    let suggestedDuration: TimeInterval
    let createdAt: Date
    let sourceInvitationId: UUID?
}

// MARK: - 通知/信息模型
struct NotificationInfo: Identifiable, Codable {
    let id: UUID
    let type: NotificationType
    let category: NotificationCategory  // 分类：信息 or 提醒
    let title: String
    let content: String
    let relatedItemId: UUID? // 关联的邀请/事项ID
    let createdAt: Date
    let endTime: Date?       // 提醒的结束时间（信息没有）
    var isRead: Bool         // 改为 var，允许修改
    
    enum NotificationCategory: String, Codable {
        case info = "info"          // 信息：点OK消失
        case reminder = "reminder"  // 提醒：需要查看详情或自动消失
        
        var displayName: String {
            switch self {
            case .info: return "信息"
            case .reminder: return "提醒"
            }
        }
    }
    
    enum NotificationType: String, Codable {
        case invitationAccepted = "accepted"        // 对方接受了我的邀请（信息）
        case invitationPostponed = "postponed"      // 对方选择"以后看"（信息）
        case invitationWechat = "wechat"           // 对方选择"微信商量"（信息）
        case todoReminder = "todo_reminder"         // 待办事项提醒（提醒）
        case giftBoxAccepted = "gift_accepted"      // 对方接受了心意盒（信息）
        case giftBoxRejected = "gift_rejected"      // 对方拒绝了心意盒（信息）
        case closureConfirmed = "closure_confirmed" // 对方确认了安心闭环（信息）
        
        var icon: String {
            switch self {
            case .invitationAccepted: return "checkmark.circle.fill"
            case .invitationPostponed: return "clock.fill"
            case .invitationWechat: return "message.fill"
            case .todoReminder: return "bell.fill"
            case .giftBoxAccepted: return "gift.fill"
            case .giftBoxRejected: return "xmark.circle.fill"
            case .closureConfirmed: return "checkmark.seal.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .invitationAccepted: return .green
            case .invitationPostponed: return .orange
            case .invitationWechat: return .purple
            case .todoReminder: return .blue
            case .giftBoxAccepted: return .pink
            case .giftBoxRejected: return .gray
            case .closureConfirmed: return .green
            }
        }
        
        // 默认分类
        var defaultCategory: NotificationCategory {
            switch self {
            case .todoReminder:
                return .reminder
            default:
                return .info
            }
        }
    }
    
    // 判断提醒是否已过期（自动消失）
    var isExpired: Bool {
        guard category == .reminder, let endTime = endTime else {
            return false
        }
        return Date() > endTime
    }
    
    init(id: UUID = UUID(), type: NotificationType, category: NotificationCategory? = nil, title: String, content: String, relatedItemId: UUID? = nil, createdAt: Date = Date(), endTime: Date? = nil, isRead: Bool = false) {
        self.id = id
        self.type = type
        self.category = category ?? type.defaultCategory
        self.title = title
        self.content = content
        self.relatedItemId = relatedItemId
        self.createdAt = createdAt
        self.endTime = endTime
        self.isRead = isRead
    }
}

// MARK: - 知行合一数据模型
struct Knowledge: Identifiable, Codable {
    let id: UUID
    var title: String
    var content: String
    var createdAt: Date
    var updatedAt: Date
    var hasAction: Bool
    var actionType: ActionType?
    var actionConfig: ActionConfig?

    init(title: String, content: String, hasAction: Bool = false, actionType: ActionType? = nil, actionConfig: ActionConfig? = nil) {
        self.id = UUID()
        self.title = title
        self.content = content
        self.hasAction = hasAction
        self.actionType = actionType
        self.actionConfig = actionConfig
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // 计算相关联的行动统计
    var actionStats: ActionStats {
        // 这里需要从数据源获取相关actions来计算
        return ActionStats(total: 0, completed: 0, suspended: 0, completionRate: 0)
    }
}

struct ActionStats {
    let total: Int
    let completed: Int
    let suspended: Int
    let completionRate: Double

    var completionPercentage: String {
        return "\(Int(completionRate * 100))%"
    }
}

enum ActionType: String, CaseIterable, Codable {
    case daily = "daily"
    case scenario = "scenario"

    var displayName: String {
        switch self {
        case .daily:
            return "日常打卡"
        case .scenario:
            return "场景触发"
        }
    }
}

struct ActionConfig: Codable {
    var dailyTime: Date? // 日常打卡时间
    var scenarioCondition: String? // 场景触发条件
    var isActive: Bool = true // 是否激活
}

struct ActionRecord: Identifiable, Codable {
    let id: UUID
    let knowledgeId: UUID
    var date: Date
    var isCompleted: Bool
    var isSuspended: Bool // 挂起状态
    var notes: String? // 心得备注
    var scenarioTriggered: Bool // 场景是否已触发
    var attachments: [String] = [] // 图片/附件路径

    init(knowledgeId: UUID, date: Date = Date()) {
        self.id = UUID()
        self.knowledgeId = knowledgeId
        self.date = date
        self.isCompleted = false
        self.isSuspended = false
        self.scenarioTriggered = false
    }
}

// MARK: - 知行合一管理器
class KnowledgeActionManager: ObservableObject {
    @Published var knowledges: [Knowledge] = []
    @Published var actions: [ActionRecord] = []

    init() {
        #if DEBUG
        loadSampleData()
        #endif
    }

    // MARK: - 认知管理
    func addKnowledge(_ knowledge: Knowledge) {
        knowledges.append(knowledge)
        saveData()
    }

    func updateKnowledge(_ knowledge: Knowledge) {
        if let index = knowledges.firstIndex(where: { $0.id == knowledge.id }) {
            knowledges[index] = knowledge
            saveData()
        }
    }

    func deleteKnowledge(_ knowledge: Knowledge) {
        knowledges.removeAll { $0.id == knowledge.id }
        // 同时删除相关的行动记录
        actions.removeAll { $0.knowledgeId == knowledge.id }
        saveData()
    }

    // MARK: - 行动管理
    func createAction(for knowledgeId: UUID, date: Date = Date()) -> ActionRecord {
        let action = ActionRecord(knowledgeId: knowledgeId, date: date)
        actions.append(action)
        saveData()
        return action
    }

    func completeAction(_ action: ActionRecord, notes: String? = nil) {
        if let index = actions.firstIndex(where: { $0.id == action.id }) {
            actions[index].isCompleted = true
            actions[index].notes = notes
            actions[index].isSuspended = false
            saveData()
        }
    }

    func suspendAction(_ action: ActionRecord) {
        if let index = actions.firstIndex(where: { $0.id == action.id }) {
            actions[index].isSuspended = true
            actions[index].isCompleted = false
            saveData()
        }
    }

    func getActionsForKnowledge(_ knowledgeId: UUID) -> [ActionRecord] {
        return actions.filter { $0.knowledgeId == knowledgeId }
    }

    func getTodayActions() -> [ActionRecord] {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!

        return actions.filter { action in
            let actionDate = Calendar.current.startOfDay(for: action.date)
            return actionDate >= today && actionDate < tomorrow
        }
    }

    func getActionStats(for knowledgeId: UUID) -> ActionStats {
        let knowledgeActions = getActionsForKnowledge(knowledgeId)
        let total = knowledgeActions.count
        let completed = knowledgeActions.filter { $0.isCompleted }.count
        let suspended = knowledgeActions.filter { $0.isSuspended }.count
        let completionRate = total > 0 ? Double(completed) / Double(total) : 0

        return ActionStats(total: total, completed: completed, suspended: suspended, completionRate: completionRate)
    }

    // MARK: - 数据持久化
    private func saveData() {
        // TODO: 实现Core Data或UserDefaults保存
    }

    private func loadData() {
        // TODO: 实现数据加载
    }

    private func loadSampleData() {
        // 加载示例数据
        let sampleKnowledges = [
            Knowledge(
                title: "保持内心平静",
                content: "无论外界环境如何变化，都要保持内心的平静和专注。遇到困难时深呼吸，专注于当下可以控制的事情。",
                hasAction: true,
                actionType: .daily,
                actionConfig: ActionConfig(
                    dailyTime: Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()),
                    scenarioCondition: nil
                )
            ),
            Knowledge(
                title: "有效沟通",
                content: "在沟通中先倾听对方，理解对方的立场和需求。表达自己的想法时要温和而坚定，避免指责和批评。",
                hasAction: true,
                actionType: .scenario,
                actionConfig: ActionConfig(
                    dailyTime: nil,
                    scenarioCondition: "与他人发生分歧或需要表达不同意见时"
                )
            ),
            Knowledge(
                title: "学习新技能",
                content: "每月至少学习一项新技能或知识，保持好奇心和成长心态。",
                hasAction: false
            )
        ]

        knowledges = sampleKnowledges

        // 创建一些示例行动记录
        let today = Date()
        var sampleActions: [ActionRecord] = []

        for knowledge in knowledges.filter({ $0.hasAction }) {
            for i in 0..<7 {
                let actionDate = Calendar.current.date(byAdding: .day, value: -i, to: today)!
                let action = ActionRecord(knowledgeId: knowledge.id, date: actionDate)

                // 模拟一些已完成的数据
                if i > 0 && Double.random(in: 0...1) > 0.3 {
                    var completedAction = action
                    completedAction.isCompleted = true
                    completedAction.notes = "今天做得不错，继续保持。"
                    sampleActions.append(completedAction)
                } else if Double.random(in: 0...1) > 0.8 {
                    var suspendedAction = action
                    suspendedAction.isSuspended = true
                    sampleActions.append(suspendedAction)
                } else {
                    sampleActions.append(action)
                }
            }
        }

        actions = sampleActions
    }
}
