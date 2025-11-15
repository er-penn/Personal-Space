//
//  EnergyDataConverter.swift
//  Personal Space
//
//  能量数据转换工具 - 将后端API数据转换为前端模型
//

import Foundation

class EnergyDataConverter {
    
    /// 将后端能量状态字符串转换为前端EnergyLevel枚举
    static func energyLevelFromString(_ string: String) -> EnergyLevel {
        switch string {
        case "🟢":
            return .high
        case "🟡":
            return .medium
        case "🔴":
            return .low
        case "⚪":
            return .unplanned
        default:
            return .unplanned
        }
    }
    
    /// 将前端EnergyLevel枚举转换为后端字符串
    static func energyLevelToString(_ level: EnergyLevel) -> String {
        return level.rawValue
    }
    
    /// 将后端TimeSlot转换为前端TimeSlot
    static func timeSlotFromAPI(_ apiSlot: APIService.TimeSlot) -> TimeSlot {
        return TimeSlot(
            startHour: apiSlot.start_hour,
            startMinute: apiSlot.start_minute,
            endHour: apiSlot.end_hour,
            endMinute: apiSlot.end_minute
        )
    }
    
    /// 将前端TimeSlot转换为后端格式
    static func timeSlotToAPI(_ slot: TimeSlot) -> [String: Int] {
        return [
            "start_hour": slot.startHour,
            "start_minute": slot.startMinute,
            "end_hour": slot.endHour,
            "end_minute": slot.endMinute
        ]
    }
    
    /// 将后端EnergyRecord转换为前端EnergyPlan
    static func energyPlanFromAPI(_ apiRecord: APIService.EnergyRecord) -> EnergyPlan? {
        guard let date = parseDate(apiRecord.date) else { return nil }
        guard let uuid = UUID(uuidString: apiRecord.id) else { return nil }
        
        let timeSlots = apiRecord.time_slots.map { timeSlotFromAPI($0) }
        let energyLevel = energyLevelFromString(apiRecord.energy_level)
        let createdAt = parseDateTime(apiRecord.created_at) ?? Date()
        
        return EnergyPlan(
            id: uuid,
            date: date,
            timeSlots: timeSlots,
            energyLevel: energyLevel,
            createdAt: createdAt
        )
    }
    
    /// 将后端EnergyRecord数组转换为前端EnergyPlan数组
    static func energyPlansFromAPI(_ apiRecords: [APIService.EnergyRecord]) -> [EnergyPlan] {
        return apiRecords.compactMap { energyPlanFromAPI($0) }
    }
    
    /// 解析日期字符串 (YYYY-MM-DD)
    static func parseDate(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        return formatter.date(from: dateString)
    }
    
    /// 解析日期时间字符串 (ISO 8601)
    static func parseDateTime(_ dateTimeString: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: dateTimeString) ?? {
            // 尝试不带毫秒的格式
            formatter.formatOptions = [.withInternetDateTime]
            return formatter.date(from: dateTimeString)
        }()
    }
    
    /// 格式化日期为字符串 (YYYY-MM-DD)
    static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        return formatter.string(from: date)
    }
    
    /// 将后端临时状态类型字符串转换为前端枚举
    static func temporaryStateTypeFromString(_ string: String?) -> TemporaryStateType? {
        guard let string = string else { return nil }
        switch string {
        case "fastCharge":
            return .fastCharge
        case "lowPower":
            return .lowPower
        default:
            return nil
        }
    }
    
    /// 将前端临时状态类型转换为后端字符串
    static func temporaryStateTypeToString(_ type: TemporaryStateType) -> String {
        switch type {
        case .fastCharge:
            return "fastCharge"
        case .lowPower:
            return "lowPower"
        }
    }
}

