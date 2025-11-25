//
//  AnxietySoothingModels.swift
//  Personal Space
//
//  Created by Penn on 2025/1/27.
//

import Foundation
import SwiftUI
import CoreData
import Combine

// MARK: - 焦虑平复指南核心模型

// 呼吸练习类型
enum BreathingPattern: String, CaseIterable, Codable {
    case box_4_4_4_4 = "方形呼吸 (4-4-4-4)"
    case triangle_4_7_8 = "三角呼吸 (4-7-8)"
    case _4_7_8 = "放松呼吸 (4-8)"
    case _7_11 = "深度呼吸 (7-11)"

    var inhaleTime: TimeInterval {
        switch self {
        case .box_4_4_4_4: return 4.0
        case .triangle_4_7_8: return 4.0
        case ._4_7_8: return 4.0
        case ._7_11: return 7.0
        }
    }

    var holdTime: TimeInterval {
        switch self {
        case .box_4_4_4_4: return 4.0
        case .triangle_4_7_8: return 7.0  // 三角呼吸法：4-7-8（有屏息）
        case ._4_7_8: return 0.0  // 放松呼吸法：4-0-8（无屏息，更流畅）
        case ._7_11: return 0.0
        }
    }

    var exhaleTime: TimeInterval {
        switch self {
        case .box_4_4_4_4: return 4.0
        case .triangle_4_7_8: return 8.0  // 三角呼吸法：4-7-8
        case ._4_7_8: return 8.0  // 放松呼吸法：4-0-8（吸气-呼气，无屏息）
        case ._7_11: return 11.0
        }
    }

    var restTime: TimeInterval {
        switch self {
        case .box_4_4_4_4: return 4.0
        case .triangle_4_7_8: return 0.0
        case ._4_7_8: return 0.0
        case ._7_11: return 0.0
        }
    }

    var totalTime: TimeInterval {
        return inhaleTime + holdTime + exhaleTime + restTime
    }

    var description: String {
        // 如果屏息时间为0，不显示屏息阶段
        if holdTime == 0 {
            return "\(Int(inhaleTime))-\(Int(exhaleTime))\(restTime > 0 ? "-\(Int(restTime))" : "")"
        } else {
        return "\(Int(inhaleTime))-\(Int(holdTime))-\(Int(exhaleTime))\(restTime > 0 ? "-\(Int(restTime))" : "")"
        }
    }
}

// 冥想引导场景
enum MeditationScenario: String, CaseIterable, Codable {
    case nature = "自然环境"
    case ocean = "海浪声音"
    case rain = "雨声"
    case forest = "森林"
    case whiteNoise = "白噪音"
    case guided = "引导冥想"

    var audioFileName: String {
        switch self {
        case .nature: return "nature_sounds"
        case .ocean: return "ocean_waves"
        case .rain: return "rain_sounds"
        case .forest: return "forest_sounds"
        case .whiteNoise: return "white_noise"
        case .guided: return "guided_meditation"
        }
    }

    var iconName: String {
        switch self {
        case .nature: return "leaf.fill"
        case .ocean: return "water.waves"
        case .rain: return "cloud.rain"
        case .forest: return "tree.fill"
        case .whiteNoise: return "waveform"
        case .guided: return "brain.head.profile"
        }
    }

    var color: Color {
        switch self {
        case .nature: return .green
        case .ocean: return .blue
        case .rain: return .gray
        case .forest: return .green.opacity(0.8)
        case .whiteNoise: return .purple
        case .guided: return .indigo
        }
    }
}

// 自定义缓解内容分类
enum ContentCategory: String, CaseIterable, Codable {
    case breathing = "呼吸练习"
    case affirmation = "积极肯定"
    case memory = "美好回忆"
    case gratitude = "感恩记录"
    case achievement = "成就记录"
    case quote = "励志语录"
    case mantra = "静心语句"
    case custom = "自定义"

    var icon: String {
        switch self {
        case .breathing: return "wind"
        case .affirmation: return "heart.fill"
        case .memory: return "photo"
        case .gratitude: return "hand.thumbsup"
        case .achievement: return "star.fill"
        case .quote: return "quote.bubble"
        case .mantra: return "moon.stars"
        case .custom: return "square.and.pencil"
        }
    }

    var color: Color {
        switch self {
        case .breathing: return .blue
        case .affirmation: return .pink
        case .memory: return .purple
        case .gratitude: return .orange
        case .achievement: return .yellow
        case .quote: return .green
        case .mantra: return .indigo
        case .custom: return .gray
        }
    }
}

// 自定义缓解内容
struct CustomAnxietyContent: Identifiable, Codable {
    let id: UUID
    let title: String
    let content: String
    let imagePath: String? // 图片本地路径
    let category: ContentCategory
    let createdAt: Date
    let lastAccessed: Date   // 最后访问时间
    let accessCount: Int     // 访问次数（用于智能推荐）
    let isFavorite: Bool     // 是否收藏
    let tags: [String]       // 标签

    init(title: String, content: String, imagePath: String? = nil,
         category: ContentCategory = .custom, tags: [String] = []) {
        self.id = UUID()
        self.title = title
        self.content = content
        self.imagePath = imagePath
        self.category = category
        self.createdAt = Date()
        self.lastAccessed = Date()
        self.accessCount = 0
        self.isFavorite = false
        self.tags = tags
    }

    // 用于从已有数据创建（包含完整信息）
    init(id: UUID, title: String, content: String, imagePath: String? = nil,
         category: ContentCategory = .custom, createdAt: Date, lastAccessed: Date,
         accessCount: Int = 0, isFavorite: Bool = false, tags: [String] = []) {
        self.id = id
        self.title = title
        self.content = content
        self.imagePath = imagePath
        self.category = category
        self.createdAt = createdAt
        self.lastAccessed = lastAccessed
        self.accessCount = accessCount
        self.isFavorite = isFavorite
        self.tags = tags
    }

    // 用于更新访问记录
    func recordAccess() -> CustomAnxietyContent {
        return CustomAnxietyContent(
            id: self.id,
            title: self.title,
            content: self.content,
            imagePath: self.imagePath,
            category: self.category,
            createdAt: self.createdAt,
            lastAccessed: Date(),
            accessCount: self.accessCount + 1,
            isFavorite: self.isFavorite,
            tags: self.tags
        )
    }

    // 切换收藏状态
    func toggleFavorite() -> CustomAnxietyContent {
        return CustomAnxietyContent(
            id: self.id,
            title: self.title,
            content: self.content,
            imagePath: self.imagePath,
            category: self.category,
            createdAt: self.createdAt,
            lastAccessed: self.lastAccessed,
            accessCount: self.accessCount,
            isFavorite: !self.isFavorite,
            tags: self.tags
        )
    }
}

// 官方缓解工具
struct OfficialTool: Identifiable, Codable {
    let id: UUID
    let title: String
    let description: String
    let iconName: String
    let color: String
    let duration: TimeInterval // 建议使用时长
    let instructions: [String] // 步骤指导
    let isActive: Bool // 是否启用

    init(title: String, description: String, iconName: String, color: String,
         duration: TimeInterval, instructions: [String]) {
        self.id = UUID()
        self.title = title
        self.description = description
        self.iconName = iconName
        self.color = color
        self.duration = duration
        self.instructions = instructions
        self.isActive = true
    }
}

// 使用记录
struct UsageRecord: Identifiable, Codable {
    let id: UUID
    let sessionId: String
    let toolType: String // 工具类型
    let startTime: Date
    let endTime: Date
    let effectivenessRating: Int? // 1-5分
    let notes: String?

    var duration: TimeInterval {
        return endTime.timeIntervalSince(startTime)
    }

    init(toolType: String, startTime: Date, endTime: Date,
         effectivenessRating: Int? = nil, notes: String? = nil) {
        self.id = UUID()
        self.sessionId = UUID().uuidString
        self.toolType = toolType
        self.startTime = startTime
        self.endTime = endTime
        self.effectivenessRating = effectivenessRating
        self.notes = notes
    }
}

// MARK: - 数据管理器

// 自定义内容管理器
class CustomContentManager: ObservableObject {
    @Published var contents: [CustomAnxietyContent] = []
    @Published var filteredContents: [CustomAnxietyContent] = []
    @Published var favoriteContents: [CustomAnxietyContent] = []
    @Published var recentContents: [CustomAnxietyContent] = []

    private let userDefaults = UserDefaults.standard
    private let contentsKey = "CustomAnxietyContents"

    init() {
        loadContents()
        updateFilteredContents()
        updateFavoriteContents()
        updateRecentContents()
    }

    // 添加内容
    func addContent(_ content: CustomAnxietyContent) {
        contents.append(content)
        saveContents()
        updateFilteredContents()
        updateFavoriteContents()
        updateRecentContents()
    }

    // 更新内容
    func updateContent(_ content: CustomAnxietyContent) {
        if let index = contents.firstIndex(where: { $0.id == content.id }) {
            contents[index] = content
            saveContents()
            updateFilteredContents()
            updateFavoriteContents()
            updateRecentContents()
        }
    }

    // 删除内容
    func deleteContent(_ content: CustomAnxietyContent) {
        contents.removeAll { $0.id == content.id }
        saveContents()
        updateFilteredContents()
        updateFavoriteContents()
        updateRecentContents()
    }

    // 切换收藏状态
    func toggleFavorite(_ content: CustomAnxietyContent) {
        let updatedContent = content.toggleFavorite()
        updateContent(updatedContent)
    }

    // 记录访问
    func recordAccess(_ content: CustomAnxietyContent) {
        let updatedContent = content.recordAccess()
        updateContent(updatedContent)
    }

    // 搜索过滤
    func searchContents(query: String) {
        if query.isEmpty {
            updateFilteredContents()
        } else {
            filteredContents = contents.filter { content in
                content.title.localizedCaseInsensitiveContains(query) ||
                content.content.localizedCaseInsensitiveContains(query) ||
                content.tags.contains { $0.localizedCaseInsensitiveContains(query) }
            }
        }
    }

    // 按分类过滤
    func filterByCategory(_ category: ContentCategory?) {
        if let category = category {
            filteredContents = contents.filter { $0.category == category }
        } else {
            filteredContents = contents
        }
    }

    // 获取推荐内容
    func getRecommendedContents(limit: Int = 5) -> [CustomAnxietyContent] {
        let now = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)

        var filteredContents = contents

        // 根据时间段推荐
        switch hour {
        case 6...12: // 早晨：积极肯定和感恩
            filteredContents = filteredContents.filter {
                $0.category == .affirmation || $0.category == .gratitude
            }
        case 12...18: // 下午：成就和美好回忆
            filteredContents = filteredContents.filter {
                $0.category == .achievement || $0.category == .memory
            }
        default: // 晚上：静心和冥想
            filteredContents = filteredContents.filter {
                $0.category == .mantra || $0.category == .breathing
            }
        }

        // 按访问频率排序
        filteredContents.sort { $0.accessCount > $1.accessCount }

        // 优先显示收藏内容
        let favorites = filteredContents.filter { $0.isFavorite }
        let others = filteredContents.filter { !$0.isFavorite }

        return Array(favorites + others).prefix(limit).map { $0 }
    }

    // 私有方法
    private func loadContents() {
        if let data = userDefaults.data(forKey: contentsKey),
           let decoded = try? JSONDecoder().decode([CustomAnxietyContent].self, from: data) {
            contents = decoded
        } else {
            contents = []
        }
    }

    private func saveContents() {
        if let encoded = try? JSONEncoder().encode(contents) {
            userDefaults.set(encoded, forKey: contentsKey)
        }
    }

    private func updateFilteredContents() {
        filteredContents = contents
    }

    private func updateFavoriteContents() {
        favoriteContents = contents.filter { $0.isFavorite }
    }

    private func updateRecentContents() {
        recentContents = Array(contents
            .sorted { $0.lastAccessed > $1.lastAccessed }
            .prefix(10)
        )
    }
}

// 官方工具管理器
class OfficialToolsManager: ObservableObject {
    @Published var tools: [OfficialTool] = []

    init() {
        loadDefaultTools()
    }

    private func loadDefaultTools() {
        tools = [
            OfficialTool(
                title: "渐进式肌肉放松",
                description: "通过紧张和放松肌肉群来缓解身体紧张",
                iconName: "figure.walk",
                color: "green",
                duration: 900,
                instructions: [
                    "找一个舒适的姿势",
                    "从脚趾开始，向上紧张肌肉",
                    "保持紧张5秒钟",
                    "慢慢放松，感受肌肉松弛",
                    "继续向上，直到头部肌肉",
                    "全身放松，深呼吸几次"
                ]
            ),
            OfficialTool(
                title: "5-4-3-2-1 接地技术",
                description: "通过感官体验将注意力带回当下",
                iconName: "leaf",
                color: "orange",
                duration: 600,
                instructions: [
                    "看5个你能看到的东西",
                    "触摸4个你能感觉到的物体",
                    "听3个你能听到的声音",
                    "闻2个你能闻到的气味",
                    "尝1个你能尝到的味道",
                    "感受当下，焦虑逐渐消失"
                ]
            ),
            OfficialTool(
                title: "认知重构练习",
                description: "识别和改变负面思维模式",
                iconName: "brain.head.profile",
                color: "purple",
                duration: 900,
                instructions: [
                    "写下当前让你焦虑的想法",
                    "寻找证据支持或反对这个想法",
                    "思考更平衡、更积极的替代想法",
                    "评估新想法的可信度",
                    "选择相信对你更有帮助的想法"
                ]
            ),
            OfficialTool(
                title: "正念冥想",
                description: "通过专注当下，观察思绪而不评判",
                iconName: "moon.stars",
                color: "indigo",
                duration: 600,
                instructions: [
                    "找一个安静的地方，舒适地坐下或躺下",
                    "闭上眼睛，专注于你的呼吸",
                    "当思绪飘走时，温柔地将注意力带回呼吸",
                    "观察你的想法，但不要评判它们",
                    "感受身体的感受，保持开放和接纳",
                    "慢慢睁开眼睛，带着平静回到当下"
                ]
            ),
            OfficialTool(
                title: "安全空间可视化",
                description: "通过想象创造一个内心的安全空间",
                iconName: "house.fill",
                color: "teal",
                duration: 600,
                instructions: [
                    "闭上眼睛，深呼吸几次",
                    "想象一个让你感到完全安全和舒适的地方",
                    "观察这个地方的细节：颜色、声音、气味",
                    "感受在这个空间中的安全感和放松感",
                    "记住这种感觉，随时可以回到这里",
                    "慢慢睁开眼睛，带着安全感回到当下"
                ]
            ),
            OfficialTool(
                title: "身体扫描",
                description: "通过系统性地关注身体各部分来放松",
                iconName: "hand.raised.fill",
                color: "cyan",
                duration: 900,
                instructions: [
                    "平躺或舒适地坐下，闭上眼睛",
                    "从脚趾开始，慢慢将注意力移到身体各部分",
                    "感受每个部位的感受，不要评判",
                    "依次扫描：脚、小腿、大腿、腹部、胸部",
                    "继续向上：手臂、肩膀、颈部、头部",
                    "感受整个身体的放松和连接"
                ]
            ),
            OfficialTool(
                title: "感恩练习",
                description: "通过关注生活中的积极方面来改善情绪",
                iconName: "heart.fill",
                color: "pink",
                duration: 300,
                instructions: [
                    "找一个安静的时刻，深呼吸几次",
                    "思考今天或最近让你感激的三件事",
                    "可以是小事：一杯热茶、朋友的微笑",
                    "也可以是大事：健康、家人的支持",
                    "感受感激带来的温暖和满足感",
                    "记住这种感觉，让它在心中停留"
                ]
            ),
            OfficialTool(
                title: "交替鼻孔呼吸法",
                description: "通过平衡左右脑活动来平静身心",
                iconName: "wind",
                color: "blue",
                duration: 300,
                instructions: [
                    "用右手拇指按住右鼻孔",
                    "通过左鼻孔慢慢吸气4秒",
                    "用右手无名指按住左鼻孔，屏息4秒",
                    "松开右鼻孔，通过右鼻孔慢慢呼气8秒",
                    "通过右鼻孔吸气4秒，屏息4秒",
                    "松开左鼻孔，通过左鼻孔呼气8秒，重复循环"
                ]
            )
        ]
    }
}

// 使用记录管理器
class UsageRecordManager: ObservableObject {
    @Published var records: [UsageRecord] = []

    private let userDefaults = UserDefaults.standard
    private let recordsKey = "AnxietyUsageRecords"

    init() {
        loadRecords()
    }

    func addRecord(_ record: UsageRecord) {
        records.append(record)
        saveRecords()
    }

    func getToolUsageStats(toolType: String) -> (count: Int, totalTime: TimeInterval, averageDuration: TimeInterval) {
        let toolRecords = records.filter { $0.toolType == toolType }
        let count = toolRecords.count
        let totalTime = toolRecords.reduce(0) { $0 + $1.duration }
        let averageDuration = count > 0 ? totalTime / Double(count) : 0

        return (count, totalTime, averageDuration)
    }

    private func loadRecords() {
        if let data = userDefaults.data(forKey: recordsKey),
           let decoded = try? JSONDecoder().decode([UsageRecord].self, from: data) {
            records = decoded
        } else {
            records = []
        }
    }

    private func saveRecords() {
        if let encoded = try? JSONEncoder().encode(records) {
            userDefaults.set(encoded, forKey: recordsKey)
        }
    }
}