//
//  AnxietySoothingGuideView.swift
//  Personal Space
//
//  Created by Penn on 2025/1/27.
//

import SwiftUI

struct AnxietySoothingGuideView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var customContentManager = CustomContentManager()
    @StateObject private var toolsManager = OfficialToolsManager()
    @StateObject private var usageManager = UsageRecordManager()

    @State private var selectedTab: GuideTab = .breathing
    @State private var showingCustomContent = false
    @State private var selectedTool: OfficialTool?
    @State private var isToolActive = false
    @State private var currentStep = 0
    @State private var startTime: Date?
    @State private var showingCompletion = false
    @State private var effectivenessRating: Int?
    @State private var notes: String = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 顶部标题区域
                headerSection

                // Tab 选择器
                tabSelectorSection

                // 内容区域
                contentSection

                Spacer()
            }
            .background(AppGradient.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(AppTheme.Colors.text)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    if selectedTab == .custom {
                        Button(action: {
                            showingCustomContent = true
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(AppTheme.Colors.primary)
                        }
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showingCustomContent) {
            CustomContentView()
                .environmentObject(customContentManager)
        }
        .sheet(item: $selectedTool) { tool in
            NavigationView {
                ToolDetailView(
                    tool: tool,
                    isActive: $isToolActive,
                    currentStep: $currentStep,
                    startTime: $startTime,
                    showingCompletion: $showingCompletion,
                    effectivenessRating: $effectivenessRating,
                    notes: $notes
                )
            }
            .environmentObject(usageManager)
        }
        .sheet(isPresented: $showingCompletion) {
            if let tool = selectedTool, let start = startTime {
                NavigationView {
                    CompletionRecordView(
                        tool: tool,
                        startTime: start,
                        effectivenessRating: $effectivenessRating,
                        notes: $notes,
                        onFinish: finishSession
                    )
                }
                .environmentObject(usageManager)
            }
        }
    }
    
    // MARK: - 工具使用完成处理
    private func finishSession() {
        guard let tool = selectedTool,
              let start = startTime else { return }

        let endTime = Date()
        let record = UsageRecord(
            toolType: tool.title,
            startTime: start,
            endTime: endTime,
            effectivenessRating: effectivenessRating,
            notes: notes.isEmpty ? nil : notes
        )

        usageManager.addRecord(record)

        // 重置状态
        isToolActive = false
        currentStep = 0
        startTime = nil
        selectedTool = nil
        effectivenessRating = nil
        notes = ""
        showingCompletion = false
    }

    // MARK: - 视图组件

    private var headerSection: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Text("焦虑平复指南")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(AppTheme.Colors.text)

            Text("选择适合你的缓解方式，让心情慢慢平静下来")
                .font(.system(size: AppTheme.FontSize.body))
                .foregroundColor(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .padding(.top, AppTheme.Spacing.lg)
        .padding(.horizontal, AppTheme.Spacing.lg)
    }

    private var tabSelectorSection: some View {
        HStack(spacing: 0) {
            ForEach(GuideTab.allCases, id: \.self) { tab in
                Button(action: {
                    selectedTab = tab
                }) {
                    VStack(spacing: AppTheme.Spacing.xs) {
                        Image(systemName: tab.iconName)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(selectedTab == tab ? AppTheme.Colors.primary : AppTheme.Colors.textSecondary)

                        Text(tab.title)
                            .font(.system(size: AppTheme.FontSize.caption, weight: .medium))
                            .foregroundColor(selectedTab == tab ? AppTheme.Colors.primary : AppTheme.Colors.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppTheme.Spacing.md)
                    .background(
                        selectedTab == tab ? AppTheme.Colors.primary.opacity(0.1) : Color.clear
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .background(AppTheme.Colors.cardBg)
        .cornerRadius(AppTheme.Radius.large)
        .padding(.horizontal, AppTheme.Spacing.lg)
        .padding(.vertical, AppTheme.Spacing.md)
        .shadow(color: AppTheme.Shadows.card, radius: 4, x: 0, y: 2)
    }

    private var contentSection: some View {
        Group {
            switch selectedTab {
            case .breathing:
                breathingSection
            case .tools:
                toolsSection
            case .custom:
                customSection
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - 呼吸练习区域
    private var breathingSection: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.lg) {
                // 呼吸动画
                BreathingAnimationView()
                    .frame(height: 400)
                    .padding()
                    .background(AppTheme.Colors.cardBg)
                    .cornerRadius(AppTheme.Radius.large)
                    .shadow(color: AppTheme.Shadows.card, radius: 6, x: 0, y: 3)

                // 呼吸技巧说明
                breathingTipsSection
            }
            .padding(AppTheme.Spacing.lg)
        }
    }

    private var breathingTipsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("呼吸技巧建议")
                .font(.system(size: AppTheme.FontSize.headline, weight: .semibold))
                .foregroundColor(AppTheme.Colors.text)

            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                BreathingTipView(
                    pattern: .box_4_4_4_4,
                    title: "方形呼吸法",
                    description: "简单易学，适合初学者",
                    benefits: ["减少焦虑", "提高专注力", "快速入睡"]
                )

                BreathingTipView(
                    pattern: ._4_7_8,
                    title: "放松呼吸法",
                    description: "无屏息设计，节奏流畅自然",
                    benefits: ["深度放松", "降低心率", "缓解失眠"]
                )

                BreathingTipView(
                    pattern: .triangle_4_7_8,
                    title: "三角呼吸法",
                    description: "平衡身心，增强平静",
                    benefits: ["平衡情绪", "增强意识", "减轻紧张"]
                )
                
                BreathingTipView(
                    pattern: ._7_11,
                    title: "深度呼吸法",
                    description: "深度腹式呼吸，最大程度放松",
                    benefits: ["深度放松", "缓解焦虑", "改善睡眠"]
                )
            }
        }
        .padding()
        .background(AppTheme.Colors.cardBg)
        .cornerRadius(AppTheme.Radius.large)
        .shadow(color: AppTheme.Shadows.card, radius: 4, x: 0, y: 2)
    }

    // MARK: - 官方工具区域
    private var toolsSection: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.lg) {
                // 工具网格
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: AppTheme.Spacing.md) {
                ForEach(toolsManager.tools) { tool in
                    QuickToolCardView(tool: tool) {
                        // 初始化工具使用状态
                        selectedTool = tool
                        isToolActive = false
                        currentStep = 0
                        startTime = nil
                        showingCompletion = false
                        effectivenessRating = nil
                        notes = ""
                    }
                }
                }
            }
            .padding(AppTheme.Spacing.lg)
        }
    }

    // MARK: - 自定义内容区域
    private var customSection: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.lg) {
                // 推荐内容
                if !customContentManager.getRecommendedContents().isEmpty {
                    recommendedContentSection
                }

                // 分类浏览
                categorySection

                // 最近内容
                if !customContentManager.recentContents.isEmpty {
                    recentContentSection
                }

                // 空状态
                if customContentManager.contents.isEmpty {
                    emptyStateSection
                }
            }
            .padding(AppTheme.Spacing.lg)
        }
    }

    private var recommendedContentSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack {
                Text("推荐内容")
                    .font(.system(size: AppTheme.FontSize.headline, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.text)

                Spacer()

                Image(systemName: "sparkles")
                    .font(.system(size: 16))
                    .foregroundColor(.orange)
            }

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: AppTheme.Spacing.md) {
                ForEach(Array(customContentManager.getRecommendedContents().prefix(4)), id: \.id) { content in
                    SimpleCustomContentCardView(content: content) {
                        customContentManager.recordAccess(content)
                        // 这里可以打开内容详情页
                    }
                }
            }
        }
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("分类浏览")
                .font(.system(size: AppTheme.FontSize.headline, weight: .semibold))
                .foregroundColor(AppTheme.Colors.text)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: AppTheme.Spacing.sm) {
                ForEach(ContentCategory.allCases, id: \.self) { category in
                    CategoryCardView(category: category) {
                        // 按分类过滤内容
                    }
                }
            }
        }
    }

    private var recentContentSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("最近内容")
                .font(.system(size: AppTheme.FontSize.headline, weight: .semibold))
                .foregroundColor(AppTheme.Colors.text)

            LazyVStack(spacing: AppTheme.Spacing.sm) {
                ForEach(Array(customContentManager.recentContents.prefix(3)), id: \.id) { content in
                    RecentContentRowView(content: content) {
                        customContentManager.recordAccess(content)
                    }
                }
            }
        }
    }

    private var emptyStateSection: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Image(systemName: "heart.text.square")
                .font(.system(size: 60))
                .foregroundColor(AppTheme.Colors.textSecondary.opacity(0.6))

            VStack(spacing: AppTheme.Spacing.sm) {
                Text("还没有自定义内容")
                    .font(.system(size: AppTheme.FontSize.headline, weight: .medium))
                    .foregroundColor(AppTheme.Colors.text)

                Text("点击右上角的 + 号添加你的第一个缓解焦虑内容")
                    .font(.system(size: AppTheme.FontSize.body))
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Button(action: {
                showingCustomContent = true
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                    Text("添加内容")
                        .font(.system(size: AppTheme.FontSize.headline, weight: .medium))
                }
                .foregroundColor(.white)
                .padding(.horizontal, AppTheme.Spacing.lg)
                .padding(.vertical, AppTheme.Spacing.md)
                .background(AppTheme.Colors.primary)
                .cornerRadius(AppTheme.Radius.large)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(AppTheme.Spacing.xl)
    }
}

// MARK: - 辅助枚举
enum GuideTab: String, CaseIterable {
    case breathing = "呼吸练习"
    case tools = "官方工具"
    case custom = "自定义内容"

    var title: String {
        return self.rawValue
    }

    var iconName: String {
        switch self {
        case .breathing: return "wind"
        case .tools: return "briefcase.medical"
        case .custom: return "heart.text.square"
        }
    }
}

// MARK: - 呼吸技巧卡片
struct BreathingTipView: View {
    let pattern: BreathingPattern
    let title: String
    let description: String
    let benefits: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: AppTheme.FontSize.subheadline, weight: .semibold))
                        .foregroundColor(AppTheme.Colors.text)

                    Text(description)
                        .font(.system(size: AppTheme.FontSize.caption))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }

                Spacer()

                Text(pattern.rawValue)
                    .font(.system(size: AppTheme.FontSize.caption, weight: .medium))
                    .foregroundColor(.blue)
                    .padding(.horizontal, AppTheme.Spacing.sm)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(AppTheme.Radius.small)
            }

            VStack(alignment: .leading, spacing: 4) {
                ForEach(benefits, id: \.self) { benefit in
                    HStack(spacing: AppTheme.Spacing.xs) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.green)

                        Text(benefit)
                            .font(.system(size: AppTheme.FontSize.caption))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                }
            }
        }
        .padding()
        .background(AppTheme.Colors.cardBg.opacity(0.5))
        .cornerRadius(AppTheme.Radius.medium)
    }
}

// MARK: - 快速工具卡片
struct QuickToolCardView: View {
    let tool: OfficialTool
    let onTap: () -> Void

    var body: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: tool.iconName)
                .font(.system(size: 30))
                .foregroundColor(colorFromString(tool.color))

            Text(tool.title)
                .font(.system(size: AppTheme.FontSize.subheadline, weight: .medium))
                .foregroundColor(AppTheme.Colors.text)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            Text("\(Int(tool.duration / 60))分钟")
                .font(.system(size: AppTheme.FontSize.caption))
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
        .padding(AppTheme.Spacing.md)
        .frame(maxWidth: .infinity)
        .background(AppTheme.Colors.cardBg)
        .cornerRadius(AppTheme.Radius.medium)
        .shadow(color: AppTheme.Shadows.card, radius: 4, x: 0, y: 2)
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - 简化的自定义内容卡片（用于网格展示）
struct SimpleCustomContentCardView: View {
    let content: CustomAnxietyContent
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack {
                Image(systemName: content.category.icon)
                    .font(.system(size: 16))
                    .foregroundColor(content.category.color)

                Spacer()

                if content.isFavorite {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                }
            }

            Text(content.title)
                .font(.system(size: AppTheme.FontSize.subheadline, weight: .medium))
                .foregroundColor(AppTheme.Colors.text)
                .lineLimit(2)

            Text(content.content)
                .font(.system(size: AppTheme.FontSize.caption))
                .foregroundColor(AppTheme.Colors.textSecondary)
                .lineLimit(3)

            Spacer()
        }
        .padding()
        .frame(height: 120)
        .frame(maxWidth: .infinity)
        .background(AppTheme.Colors.cardBg)
        .cornerRadius(AppTheme.Radius.medium)
        .shadow(color: AppTheme.Shadows.card, radius: 3, x: 0, y: 1)
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - 分类卡片
struct CategoryCardView: View {
    let category: ContentCategory
    let onTap: () -> Void

    var body: some View {
        VStack(spacing: AppTheme.Spacing.xs) {
            Image(systemName: category.icon)
                .font(.system(size: 24))
                .foregroundColor(category.color)

            Text(category.rawValue)
                .font(.system(size: AppTheme.FontSize.caption, weight: .medium))
                .foregroundColor(AppTheme.Colors.text)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .padding(.vertical, AppTheme.Spacing.md)
        .frame(maxWidth: .infinity)
        .background(AppTheme.Colors.cardBg)
        .cornerRadius(AppTheme.Radius.medium)
        .shadow(color: AppTheme.Shadows.card, radius: 2, x: 0, y: 1)
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - 最近内容行
struct RecentContentRowView: View {
    let content: CustomAnxietyContent
    let onTap: () -> Void

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: content.category.icon)
                .font(.system(size: 20))
                .foregroundColor(content.category.color)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(content.title)
                    .font(.system(size: AppTheme.FontSize.subheadline, weight: .medium))
                    .foregroundColor(AppTheme.Colors.text)
                    .lineLimit(1)

                Text(content.content)
                    .font(.system(size: AppTheme.FontSize.caption))
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .lineLimit(2)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                if content.isFavorite {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.red)
                }

                Text(formatDate(content.lastAccessed))
                    .font(.system(size: AppTheme.FontSize.caption))
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
        .padding(.vertical, AppTheme.Spacing.sm)
        .padding(.horizontal, AppTheme.Spacing.md)
        .background(AppTheme.Colors.cardBg.opacity(0.5))
        .cornerRadius(AppTheme.Radius.medium)
        .onTapGesture {
            onTap()
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter.string(from: date)
    }
}

// MARK: - 辅助函数
/// 将字符串转换为颜色
func colorFromString(_ colorString: String) -> Color {
    switch colorString.lowercased() {
    case "blue":
        return .blue
    case "green":
        return .green
    case "orange":
        return .orange
    case "purple":
        return .purple
    case "red":
        return .red
    case "pink":
        return .pink
    case "yellow":
        return .yellow
    case "teal":
        return .teal
    case "indigo":
        return .indigo
    case "cyan":
        return .cyan
    case "mint":
        if #available(iOS 15.0, *) {
            return .mint
        } else {
            return .green
        }
    default:
        return .blue
    }
}

// MARK: - 完成记录视图
struct CompletionRecordView: View {
    let tool: OfficialTool
    let startTime: Date
    @Binding var effectivenessRating: Int?
    @Binding var notes: String
    let onFinish: () -> Void
    @EnvironmentObject var usageManager: UsageRecordManager
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    // 标题
                    Text("完成记录")
                        .font(.system(size: AppTheme.FontSize.title, weight: .bold))
                        .foregroundColor(AppTheme.Colors.text)
                        .padding(.top, AppTheme.Spacing.lg)
                    
                    // 工具信息
                    HStack {
                        Image(systemName: tool.iconName)
                            .font(.system(size: 30))
                            .foregroundColor(colorFromString(tool.color))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(tool.title)
                                .font(.system(size: AppTheme.FontSize.headline, weight: .semibold))
                                .foregroundColor(AppTheme.Colors.text)
                            
                            Text("时长：\(formatDuration(Date().timeIntervalSince(startTime)))")
                                .font(.system(size: AppTheme.FontSize.caption))
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(AppTheme.Colors.cardBg)
                    .cornerRadius(AppTheme.Radius.large)
                    
                    // 评分选择
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                        Text("请评价这次练习的效果")
                            .font(.system(size: AppTheme.FontSize.headline, weight: .semibold))
                            .foregroundColor(AppTheme.Colors.text)
                        
                        Picker("评分", selection: $effectivenessRating) {
                            Text("未评分").tag(nil as Int?)
                            ForEach(1...5, id: \.self) { rating in
                                Text("\(rating) 分").tag(rating as Int?)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    .padding()
                    .background(AppTheme.Colors.cardBg)
                    .cornerRadius(AppTheme.Radius.large)
                    
                    // 备注输入
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                        Text("备注（可选）")
                            .font(.system(size: AppTheme.FontSize.headline, weight: .semibold))
                            .foregroundColor(AppTheme.Colors.text)
                        
                        if #available(iOS 16.0, *) {
                            TextField("写下你的感受...", text: $notes, axis: .vertical)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .lineLimit(3...6)
                        } else {
                            ZStack(alignment: .topLeading) {
                                if notes.isEmpty {
                                    Text("写下你的感受...")
                                        .foregroundColor(.gray)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 8)
                                }
                                TextEditor(text: $notes)
                                    .frame(minHeight: 100)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                            }
                        }
                    }
                    .padding()
                    .background(AppTheme.Colors.cardBg)
                    .cornerRadius(AppTheme.Radius.large)
                    
                    // 按钮
                    HStack(spacing: AppTheme.Spacing.md) {
                        Button(action: {
                            effectivenessRating = nil
                            notes = ""
                            onFinish()
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Text("跳过")
                                .font(.system(size: AppTheme.FontSize.headline, weight: .medium))
                                .foregroundColor(AppTheme.Colors.textSecondary)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(AppTheme.Colors.cardBg)
                                .cornerRadius(AppTheme.Radius.large)
                        }
                        
                        Button(action: {
                            onFinish()
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Text("提交")
                                .font(.system(size: AppTheme.FontSize.headline, weight: .medium))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(AppTheme.Colors.primary)
                                .cornerRadius(AppTheme.Radius.large)
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .padding(AppTheme.Spacing.lg)
            }
            .background(AppGradient.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(AppTheme.Colors.text)
                }
            }
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        if minutes > 0 {
            return "\(minutes)分\(seconds)秒"
        } else {
            return "\(seconds)秒"
        }
    }
}

// MARK: - 预览
#Preview {
    AnxietySoothingGuideView()
}