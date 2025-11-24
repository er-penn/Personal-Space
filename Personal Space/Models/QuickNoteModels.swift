//
//  QuickNoteModels.swift
//  Personal Space
//
//  Created by Penn on 2025/11/20.
//

import SwiftUI
import Foundation
import Combine

// MARK: - 消息类型枚举
enum MessageType: String, Codable {
    case text = "文字"
    case audio = "语音"
    case image = "图片"
}

// MARK: - 角标类型枚举
enum BadgeType: String, Codable, Identifiable {
    case insight = "洞察"
    case painPoint = "痛点"
    case solution = "方案"
    
    var id: String { rawValue }
    
    var color: Color {
        switch self {
        case .insight:
            return Color(red: 1.0, green: 0.843, blue: 0.0) // #FFD700
        case .painPoint:
            return Color(red: 1.0, green: 0.549, blue: 0.0) // #FF8C00
        case .solution:
            return Color(red: 0.196, green: 0.804, blue: 0.196) // #32CD32
        }
    }
}

// MARK: - 消息数据模型
struct NoteMessage: Identifiable, Codable {
    let id: UUID
    var type: MessageType
    var content: String?
    var audioPath: String?
    var audioDuration: TimeInterval?
    var imagePath: String?
    var badge: BadgeType?
    var referencedMessageId: UUID?
    var referencedMessagePreview: String?
    var createdAt: Date
    
    init(
        id: UUID = UUID(),
        type: MessageType,
        content: String? = nil,
        audioPath: String? = nil,
        audioDuration: TimeInterval? = nil,
        imagePath: String? = nil,
        badge: BadgeType? = nil,
        referencedMessageId: UUID? = nil,
        referencedMessagePreview: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.type = type
        self.content = content
        self.audioPath = audioPath
        self.audioDuration = audioDuration
        self.imagePath = imagePath
        self.badge = badge
        self.referencedMessageId = referencedMessageId
        self.referencedMessagePreview = referencedMessagePreview
        self.createdAt = createdAt
    }
    
    // 检查是否有内容
    var hasContent: Bool {
        return content != nil && !content!.isEmpty ||
               audioPath != nil ||
               imagePath != nil
    }
    
    // 计算语音消息气泡宽度（根据时长）
    var audioBubbleWidth: CGFloat {
        guard let duration = audioDuration else { return 100 }
        let minWidth: CGFloat = 100
        let maxWidth: CGFloat = 200
        let maxDuration: TimeInterval = 60
        let width = minWidth + (maxWidth - minWidth) * CGFloat(min(duration, maxDuration) / maxDuration)
        return width
    }
    
    // 获取消息预览文本（用于列表显示）
    func getPreviewText() -> String {
        switch type {
        case .text:
            if let content = content, !content.isEmpty {
                return content
            }
            return ""
        case .audio:
            if let duration = audioDuration {
                let seconds = Int(duration)
                return "[语音]\(seconds)''"
            }
            return "[语音]"
        case .image:
            return "[图片]"
        }
    }
}

// MARK: - 随手记数据模型
struct QuickNote: Identifiable, Codable {
    let id: UUID
    var title: String
    var messages: [NoteMessage]
    var createdAt: Date
    var updatedAt: Date
    
    // 整理内容（从角标消息中整理得出）
    var insightSummary: String?
    var painPointSummary: String?
    var solutionSummary: String?
    
    init(
        id: UUID = UUID(),
        title: String = "",
        messages: [NoteMessage] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        insightSummary: String? = nil,
        painPointSummary: String? = nil,
        solutionSummary: String? = nil
    ) {
        self.id = id
        self.title = title.isEmpty ? QuickNote.generateDefaultTitle(from: createdAt) : title
        self.messages = messages
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.insightSummary = insightSummary
        self.painPointSummary = painPointSummary
        self.solutionSummary = solutionSummary
    }
    
    // 生成默认标题（时间戳格式）
    static func generateDefaultTitle(from date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyMMddHHmmss"
        return formatter.string(from: date)
    }
    
    // 计算属性
    var hasContent: Bool {
        return !messages.isEmpty
    }
    
    var latestUpdateTime: Date {
        return max(createdAt, updatedAt)
    }
    
    // 获取最近一条消息
    var latestMessage: NoteMessage? {
        let sorted = messages.sorted { $0.createdAt > $1.createdAt }
        let latest = sorted.first
        print("🔍 [QuickNote.latestMessage] title: \(title)")
        print("🔍 [QuickNote.latestMessage] messages.count: \(messages.count)")
        if !messages.isEmpty {
            print("🔍 [QuickNote.latestMessage] 所有消息的时间戳:")
            for (index, msg) in messages.sorted(by: { $0.createdAt < $1.createdAt }).enumerated() {
                print("   [\(index)] createdAt: \(msg.createdAt), type: \(msg.type.rawValue), badge: \(msg.badge?.rawValue ?? "无"), content: \(msg.content?.prefix(20) ?? "无内容")")
            }
        }
        if let latest = latest {
            print("✅ [QuickNote.latestMessage] 最新消息 - createdAt: \(latest.createdAt), type: \(latest.type.rawValue), badge: \(latest.badge?.rawValue ?? "无")")
        } else {
            print("⚠️ [QuickNote.latestMessage] 没有消息")
        }
        return latest
    }
    
    // 获取最近消息预览
    var latestMessagePreview: String {
        print("🔍 [QuickNote.latestMessagePreview] title: \(title)")
        guard let latest = latestMessage else {
            print("⚠️ [QuickNote.latestMessagePreview] 没有最新消息")
            return ""
        }
        var preview = latest.getPreviewText()
        if let badge = latest.badge {
            preview += " [\(badge.rawValue)]"
        }
        print("✅ [QuickNote.latestMessagePreview] 预览文本: \(preview)")
        return preview
    }
    
    // 检查是否有拆解整理
    var hasInsight: Bool {
        let hasSummary = insightSummary != nil && !insightSummary!.isEmpty
        let hasMessage = messages.contains { $0.badge == .insight }
        let result = hasSummary || hasMessage
        print("🔍 [QuickNote.hasInsight] title: \(title), hasSummary: \(hasSummary), hasMessage: \(hasMessage), result: \(result)")
        return result
    }
    
    var hasPainPoint: Bool {
        let hasSummary = painPointSummary != nil && !painPointSummary!.isEmpty
        let hasMessage = messages.contains { $0.badge == .painPoint }
        let result = hasSummary || hasMessage
        print("🔍 [QuickNote.hasPainPoint] title: \(title), hasSummary: \(hasSummary), hasMessage: \(hasMessage), result: \(result)")
        if hasMessage {
            print("   📌 包含痛点的消息:")
            for msg in messages.filter({ $0.badge == .painPoint }) {
                print("      - createdAt: \(msg.createdAt), content: \(msg.content?.prefix(30) ?? "无内容")")
            }
        }
        return result
    }
    
    var hasSolution: Bool {
        let hasSummary = solutionSummary != nil && !solutionSummary!.isEmpty
        let hasMessage = messages.contains { $0.badge == .solution }
        let result = hasSummary || hasMessage
        print("🔍 [QuickNote.hasSolution] title: \(title), hasSummary: \(hasSummary), hasMessage: \(hasMessage), result: \(result)")
        return result
    }
    
    var isAnalyzed: Bool {
        let result = hasInsight || hasPainPoint || hasSolution
        print("🔍 [QuickNote.isAnalyzed] title: \(title), hasInsight: \(hasInsight), hasPainPoint: \(hasPainPoint), hasSolution: \(hasSolution), result: \(result)")
        return result
    }
    
    // 获取指定角标的所有消息（按时间顺序）
    func getMessages(with badge: BadgeType) -> [NoteMessage] {
        return messages.filter { $0.badge == badge }.sorted { $0.createdAt < $1.createdAt }
    }
}

// MARK: - 筛选枚举
enum QuickNoteFilter: String, CaseIterable {
    case all = "全部"
    case notAnalyzed = "未拆解"
    case hasInsight = "有洞察"
    case hasPainPoint = "有痛点"
    case hasSolution = "有方案"
}

// MARK: - 随手记管理器
class QuickNoteManager: ObservableObject {
    @Published var notes: [QuickNote] = []
    
    private let userDefaults = UserDefaults.standard
    private let notesKey = "QuickNotes"
    
    init() {
        loadNotes()
    }
    
    // MARK: - CRUD操作
    
    func addNote(_ note: QuickNote) {
        var newNote = note
        if newNote.title.isEmpty {
            newNote.title = QuickNote.generateDefaultTitle(from: newNote.createdAt)
        }
        notes.append(newNote)
        saveNotes()
    }
    
    func updateNote(_ note: QuickNote) {
        // 先检查是否有重复的 ID
        let duplicateIndices = notes.enumerated().filter { $0.element.id == note.id }.map { $0.offset }
        
        if duplicateIndices.isEmpty {
            print("⚠️ [QuickNoteManager.updateNote] 未找到要更新的 note: \(note.id.uuidString)")
            return
        }
        
        // 如果有多个重复的，先删除所有重复的
        if duplicateIndices.count > 1 {
            print("🔄 [QuickNoteManager.updateNote] 发现 \(duplicateIndices.count) 个重复的 note，先删除所有")
            notes.removeAll { $0.id == note.id }
        }
        
        // 更新或添加 note
        var updatedNote = note
        updatedNote.updatedAt = Date()
        
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            notes[index] = updatedNote
        } else {
            notes.append(updatedNote)
        }
        
        saveNotes()
        print("✅ [QuickNoteManager.updateNote] 更新完成 - id: \(note.id.uuidString), messages.count: \(updatedNote.messages.count)")
    }
    
    func deleteNote(_ note: QuickNote) {
        // 删除关联的文件
        for message in note.messages {
            if let audioPath = message.audioPath {
                deleteFile(at: audioPath)
            }
            if let imagePath = message.imagePath {
                deleteFile(at: imagePath)
            }
        }
        notes.removeAll { $0.id == note.id }
        saveNotes()
    }
    
    // MARK: - 查询操作
    
    func getNotes(filter: QuickNoteFilter = .all) -> [QuickNote] {
        print("🔍 [QuickNoteManager.getNotes] filter: \(filter.rawValue)")
        print("🔍 [QuickNoteManager.getNotes] 原始 notes.count: \(notes.count)")
        
        // 统计空记录
        let emptyNotes = notes.filter { $0.messages.isEmpty }
        if !emptyNotes.isEmpty {
            print("⚠️ [QuickNoteManager.getNotes] 发现 \(emptyNotes.count) 条空记录（没有消息）:")
            for (index, note) in emptyNotes.enumerated() {
                print("   [\(index)] id: \(note.id.uuidString), title: \(note.title), messages.count: \(note.messages.count)")
            }
        }
        
        // 过滤掉没有消息的记录
        let notesWithMessages = notes.filter { !$0.messages.isEmpty }
        print("🔍 [QuickNoteManager.getNotes] 有消息的 notes.count: \(notesWithMessages.count)")
        
        let filtered = filterNotes(notesWithMessages, by: filter)
        print("🔍 [QuickNoteManager.getNotes] 筛选后的 notes.count: \(filtered.count)")
        for (index, note) in filtered.enumerated() {
            print("   [\(index)] title: \(note.title), messages.count: \(note.messages.count), isAnalyzed: \(note.isAnalyzed)")
        }
        
        let sorted = filtered.sorted { $0.latestUpdateTime > $1.latestUpdateTime }
        print("✅ [QuickNoteManager.getNotes] 最终返回 \(sorted.count) 条记录")
        return sorted
    }
    
    func getRecentNotes(count: Int = 3) -> [QuickNote] {
        // 过滤掉没有消息的记录
        let notesWithMessages = notes.filter { !$0.messages.isEmpty }
        let sorted = notesWithMessages.sorted { $0.latestUpdateTime > $1.latestUpdateTime }
        return Array(sorted.prefix(count))
    }
    
    private func filterNotes(_ notes: [QuickNote], by filter: QuickNoteFilter) -> [QuickNote] {
        print("🔍 [QuickNoteManager.filterNotes] filter: \(filter.rawValue), 输入 notes.count: \(notes.count)")
        
        let result: [QuickNote]
        switch filter {
        case .all:
            result = notes
            print("🔍 [QuickNoteManager.filterNotes] 全部 - 返回 \(result.count) 条")
        case .notAnalyzed:
            result = notes.filter { note in
                let isAnalyzed = note.isAnalyzed
                print("   🔍 检查 note '\(note.title)': isAnalyzed = \(isAnalyzed)")
                return !isAnalyzed
            }
            print("🔍 [QuickNoteManager.filterNotes] 未拆解 - 返回 \(result.count) 条")
        case .hasInsight:
            result = notes.filter { $0.hasInsight }
            print("🔍 [QuickNoteManager.filterNotes] 有洞察 - 返回 \(result.count) 条")
        case .hasPainPoint:
            result = notes.filter { $0.hasPainPoint }
            print("🔍 [QuickNoteManager.filterNotes] 有痛点 - 返回 \(result.count) 条")
        case .hasSolution:
            result = notes.filter { $0.hasSolution }
            print("🔍 [QuickNoteManager.filterNotes] 有方案 - 返回 \(result.count) 条")
        }
        
        return result
    }
    
    // MARK: - 文件管理
    
    func saveAudioFile(_ audioData: Data) -> String? {
        let fileName = "audio_\(UUID().uuidString).m4a"
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent(fileName)
        
        do {
            try audioData.write(to: fileURL)
            return fileName
        } catch {
            print("保存语音文件失败: \(error)")
            return nil
        }
    }
    
    func saveImageFile(_ imageData: Data) -> String? {
        let fileName = "image_\(UUID().uuidString).jpg"
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent(fileName)
        
        do {
            try imageData.write(to: fileURL)
            return fileName
        } catch {
            print("保存图片文件失败: \(error)")
            return nil
        }
    }
    
    func getFileURL(for fileName: String) -> URL? {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent(fileName)
    }
    
    private func deleteFile(at path: String) {
        guard let fileURL = getFileURL(for: path) else { return }
        try? FileManager.default.removeItem(at: fileURL)
    }
    
    // MARK: - 数据持久化
    
    private func loadNotes() {
        print("📦 [QuickNoteManager.loadNotes] 开始加载数据")
        if let data = userDefaults.data(forKey: notesKey),
           let decoded = try? JSONDecoder().decode([QuickNote].self, from: data) {
            // 去重：如果有重复的 ID，保留最新的（updatedAt 最大的）
            var uniqueNotes: [UUID: QuickNote] = [:]
            for note in decoded {
                if let existing = uniqueNotes[note.id] {
                    // 如果已存在，保留 updatedAt 更大的
                    if note.updatedAt > existing.updatedAt {
                        uniqueNotes[note.id] = note
                        print("🔄 [QuickNoteManager.loadNotes] 发现重复 ID: \(note.id.uuidString)，保留更新版本")
                    } else {
                        print("🔄 [QuickNoteManager.loadNotes] 发现重复 ID: \(note.id.uuidString)，保留旧版本")
                    }
                } else {
                    uniqueNotes[note.id] = note
                }
            }
            var loadedNotes = Array(uniqueNotes.values)
            
            // 自动清理空记录（没有消息的记录）
            let emptyNotes = loadedNotes.filter { $0.messages.isEmpty }
            if !emptyNotes.isEmpty {
                print("🧹 [QuickNoteManager.loadNotes] 发现 \(emptyNotes.count) 条空记录，自动清理:")
                for note in emptyNotes {
                    print("   🗑️ 删除空记录 - id: \(note.id.uuidString), title: \(note.title)")
                }
                loadedNotes.removeAll { $0.messages.isEmpty }
            }
            
            notes = loadedNotes
            
            if !emptyNotes.isEmpty {
                // 如果有清理，立即保存
                saveNotes()
                print("💾 [QuickNoteManager.loadNotes] 已保存清理后的数据")
            }
            
            print("✅ [QuickNoteManager.loadNotes] 加载成功 - 原始数量: \(decoded.count), 去重后: \(uniqueNotes.count), 清理后: \(notes.count)")
            for (index, note) in notes.enumerated() {
                print("   [\(index)] id: \(note.id.uuidString), title: \(note.title), messages.count: \(note.messages.count), updatedAt: \(note.updatedAt)")
            }
        } else {
            notes = []
            print("⚠️ [QuickNoteManager.loadNotes] 没有数据或解码失败")
        }
    }
    
    private func saveNotes() {
        if let encoded = try? JSONEncoder().encode(notes) {
            userDefaults.set(encoded, forKey: notesKey)
        }
    }
}

