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
    
    var description: String {
        switch self {
        case .high: return "高能量"
        case .medium: return "中等能量"
        case .low: return "低能量"
        }
    }
    
    var color: Color {
        switch self {
        case .high: return .green
        case .medium: return .yellow
        case .low: return .red
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
    
    init() {
        // 添加一些示例能量规划数据
        setupSampleEnergyPlans()
    }
    
    private func setupSampleEnergyPlans() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // 添加今天的规划
        energyPlans.append(EnergyPlan(date: today, hour: 8, energyLevel: .high))
        energyPlans.append(EnergyPlan(date: today, hour: 9, energyLevel: .high))
        energyPlans.append(EnergyPlan(date: today, hour: 10, energyLevel: .medium))
        energyPlans.append(EnergyPlan(date: today, hour: 14, energyLevel: .low))
        energyPlans.append(EnergyPlan(date: today, hour: 18, energyLevel: .high))
        
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
    }
    
    var displayEnergyLevel: EnergyLevel {
        return isEnergyBoostActive ? .high : energyLevel
    }
    
    // 获取指定日期和小时的最终能量状态（考虑优先级）
    func getFinalEnergyLevel(for date: Date, hour: Int) -> EnergyLevel {
        let calendar = Calendar.current
        let targetDate = calendar.startOfDay(for: date)
        
        // 优先级从高到低检查
        // 1. 专注模式 (最高优先级)
        if isFocusModeOn {
            return .high // 专注模式时显示高能量
        }
        
        // 2. 能量快充 (高优先级)
        if isEnergyBoostActive {
            return .high
        }
        
        // 3. 能量预规划 (中优先级)
        if let plan = energyPlans.first(where: { 
            calendar.isDate($0.date, inSameDayAs: targetDate) && $0.hour == hour 
        }) {
            return plan.energyLevel
        }
        
        // 4. 每日能量状态签到 (最低优先级)
        return energyLevel
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
    let energyLevel: EnergyLevel // 规划的能量状态
    let createdAt: Date // 创建时间
    
    init(date: Date, hour: Int, energyLevel: EnergyLevel, createdAt: Date = Date()) {
        self.id = UUID()
        self.date = date
        self.hour = hour
        self.energyLevel = energyLevel
        self.createdAt = createdAt
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
