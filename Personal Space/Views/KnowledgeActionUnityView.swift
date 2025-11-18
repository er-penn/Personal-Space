//
//  KnowledgeActionUnityView.swift
//  Personal Space
//
//  Created by AI Assistant on 2025/1/27.
//

import SwiftUI

struct KnowledgeActionUnityView: View {
    @StateObject private var knowledgeActionManager = KnowledgeActionManager()
    @State private var selectedTab: TabType = .knowledge

    enum TabType: String, CaseIterable {
        case knowledge = "知"
        case action = "行"

        var systemImage: String {
            switch self {
            case .knowledge:
                return "brain.head.profile"
            case .action:
                return "figure.walk"
            }
        }
    }

    var body: some View {
            VStack(spacing: 0) {
            // Tab切换区域
                HStack(spacing: 0) {
                    ForEach(TabType.allCases, id: \.self) { tab in
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                selectedTab = tab
                            }
                        }) {
                            VStack(spacing: 8) {
                                HStack(spacing: 8) {
                                    Image(systemName: tab.systemImage)
                                        .font(.system(size: 18, weight: .medium))
                                    Text(tab.rawValue)
                                        .font(.system(size: 18, weight: .semibold))
                                }
                                .foregroundColor(selectedTab == tab ? AppTheme.Colors.primary : AppTheme.Colors.textSecondary)

                                // 下划线
                                Rectangle()
                                    .fill(selectedTab == tab ? AppTheme.Colors.primary : Color.clear)
                                    .frame(height: 2)
                                    .animation(.easeInOut(duration: 0.3), value: selectedTab)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppTheme.Spacing.md)
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.lg)
                .background(Color(.systemBackground))

                // 内容区域
                TabView(selection: $selectedTab) {
                    KnowledgeView(manager: knowledgeActionManager)
                        .tag(TabType.knowledge)

                    ActionView(manager: knowledgeActionManager)
                        .tag(TabType.action)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: selectedTab)
            }
            .background(AppGradient.background)
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("知行合一")
    }
}

// MARK: - 知板块视图
struct KnowledgeView: View {
    @ObservedObject var manager: KnowledgeActionManager
    @State private var showingAddKnowledge = false
    @State private var searchText = ""
    @State private var filterType: FilterType = .all
    @State private var selectedKnowledge: Knowledge? = nil

    enum FilterType: String, CaseIterable {
        case all = "全部"
        case withAction = "有行动目标"
        case pureKnowledge = "纯认知记录"
    }

    var filteredKnowledges: [Knowledge] {
        var filtered = manager.knowledges

        // 搜索过滤
        if !searchText.isEmpty {
            filtered = filtered.filter { $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.content.localizedCaseInsensitiveContains(searchText)
            }
        }

        // 类型过滤
        switch filterType {
        case .all:
            break
        case .withAction:
            filtered = filtered.filter { $0.hasAction }
        case .pureKnowledge:
            filtered = filtered.filter { !$0.hasAction }
        }

        return filtered.sorted { $0.updatedAt > $1.updatedAt }
    }

    var body: some View {
        VStack(spacing: 0) {
            // 顶部操作栏
            VStack(spacing: AppTheme.Spacing.md) {
                // 搜索框
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("搜索认知...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding(AppTheme.Spacing.md)
                .background(Color(.systemBackground))
                .cornerRadius(AppTheme.Radius.medium)

                // 分类筛选
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppTheme.Spacing.sm) {
                        ForEach(FilterType.allCases, id: \.self) { type in
                            Button(action: {
                                filterType = type
                            }) {
                                Text(type.rawValue)
                                    .font(.system(size: AppTheme.FontSize.caption, weight: .medium))
                                    .padding(.horizontal, AppTheme.Spacing.md)
                                    .padding(.vertical, AppTheme.Spacing.xs)
                                    .background(filterType == type ? AppTheme.Colors.primary : Color(.systemBackground))
                                    .foregroundColor(filterType == type ? .white : .primary)
                                    .cornerRadius(AppTheme.Radius.small)
                            }
                        }
                    }
                    .padding(.horizontal, AppTheme.Spacing.lg)
                }
            }
            .padding(.horizontal, AppTheme.Spacing.lg)
            .padding(.vertical, AppTheme.Spacing.xs)

            // 认知列表
            ScrollView {
                LazyVStack(spacing: AppTheme.Spacing.md) {
                    ForEach(filteredKnowledges) { knowledge in
                        KnowledgeCardView(
                            knowledge: knowledge,
                            manager: manager,
                            onTap: {
                                selectedKnowledge = knowledge
                            }
                        )
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.lg)
                .padding(.top, AppTheme.Spacing.xs)
                .padding(.bottom, AppTheme.Spacing.xl)
            }
        }
        .background(AppGradient.background)
        .overlay(
            // 新增按钮
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        showingAddKnowledge = true
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                            .background(AppTheme.Colors.primary)
                            .clipShape(Circle())
                            .shadow(color: AppTheme.Colors.primary.opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                    .padding(AppTheme.Spacing.lg)
                }
                .padding(.bottom, AppTheme.Spacing.xl)
            }
        )
        .sheet(isPresented: $showingAddKnowledge) {
            KnowledgeEditView(
                manager: manager,
                isPresented: $showingAddKnowledge
            )
        }
        .sheet(item: $selectedKnowledge) { knowledge in
            KnowledgeDetailView(
                knowledgeId: knowledge.id,
                manager: manager
            )
        }
    }
}

// MARK: - 认知卡片视图
struct KnowledgeCardView: View {
    let knowledge: Knowledge
    let manager: KnowledgeActionManager
    let onTap: () -> Void

    private var actionStats: ActionStats {
        manager.getActionStats(for: knowledge.id)
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                // 标题行
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text(knowledge.title)
                                .font(.system(size: AppTheme.FontSize.headline, weight: .semibold))
                                .foregroundColor(.primary)

                            if knowledge.hasAction {
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(AppTheme.Colors.primary)
                            }
                        }

                        Text(formatDate(knowledge.updatedAt))
                            .font(.system(size: AppTheme.FontSize.caption))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    if knowledge.hasAction {
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(actionStats.completionPercentage)
                                .font(.system(size: AppTheme.FontSize.caption, weight: .semibold))
                                .foregroundColor(actionStats.completionRate > 0.7 ? .green : .orange)

                            Text("\(actionStats.completed)/\(actionStats.total)")
                                .font(.system(size: AppTheme.FontSize.caption2))
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // 内容摘要
                Text(knowledge.content)
                    .font(.system(size: AppTheme.FontSize.body))
                    .foregroundColor(.primary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)

                // 行动类型标签
                if knowledge.hasAction {
                    HStack {
                        Image(systemName: knowledge.actionType == .daily ? "clock" : "lightbulb")
                            .font(.system(size: AppTheme.FontSize.caption2))
                        Text(knowledge.actionType?.displayName ?? "")
                            .font(.system(size: AppTheme.FontSize.caption))
                        Spacer()
                    }
                    .padding(.horizontal, AppTheme.Spacing.sm)
                    .padding(.vertical, AppTheme.Spacing.xs)
                    .background(AppTheme.Colors.primary.opacity(0.1))
                    .foregroundColor(AppTheme.Colors.primary)
                    .cornerRadius(AppTheme.Radius.small)
                }
            }
            .padding(AppTheme.Spacing.lg)
            .background(Color(.systemBackground))
            .cornerRadius(AppTheme.Radius.medium)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM月dd日 HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - 行板块视图
struct ActionView: View {
    @ObservedObject var manager: KnowledgeActionManager


    @State private var showingKnowledgeLibrary = false

    private var todayDailyActions: [ActionRecord] {
        manager.getTodayDailyActions()
    }
    
    private var scenarioActions: [Knowledge] {
        manager.getScenarioActions()
    }

    private var todayPending: Int {
        todayDailyActions.filter { !$0.isCompleted }.count
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.lg) {
                // 统计区域
                ActionStatsView(
                    todayPending: todayPending,
                    onKnowledgeLibraryTap: {
                        showingKnowledgeLibrary = true
                    }
                )

                // 今日行动列表
                VStack(spacing: AppTheme.Spacing.md) {
                    HStack {
                        Text("今日行动")
                            .font(.system(size: AppTheme.FontSize.headline, weight: .semibold))
                            .foregroundColor(AppTheme.Colors.text)
                        Spacer()
                        Text("\(todayDailyActions.count) 项")
                            .font(.system(size: AppTheme.FontSize.caption))
                            .foregroundColor(.secondary)
                    }

                    if todayDailyActions.isEmpty {
                        VStack(spacing: AppTheme.Spacing.md) {
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 48))
                                .foregroundColor(.green)
                            Text("今日无待办行动")
                                .font(.system(size: AppTheme.FontSize.body))
                                .foregroundColor(.secondary)
                            Text("休息一下，明天继续加油")
                                .font(.system(size: AppTheme.FontSize.caption))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(AppTheme.Spacing.xxl)
                        .background(Color(.systemBackground))
                        .cornerRadius(AppTheme.Radius.medium)
                    } else {
                        LazyVStack(spacing: AppTheme.Spacing.sm) {
                            ForEach(todayDailyActions) { action in
                                DailyActionCardView(
                                    action: action,
                                    knowledge: manager.knowledges.first { $0.id == action.knowledgeId },
                                    manager: manager
                                )
                            }
                        }
                    }
                }
                
                // 日常行动列表
                if !scenarioActions.isEmpty {
                    VStack(spacing: AppTheme.Spacing.md) {
                        HStack {
                            Text("日常行动")
                                .font(.system(size: AppTheme.FontSize.headline, weight: .semibold))
                                .foregroundColor(AppTheme.Colors.text)
                            Spacer()
                            Text("\(scenarioActions.count) 项")
                                .font(.system(size: AppTheme.FontSize.caption))
                                .foregroundColor(.secondary)
                        }
                        
                        LazyVStack(spacing: AppTheme.Spacing.sm) {
                            ForEach(scenarioActions) { knowledge in
                                ScenarioActionCardView(
                                    knowledge: knowledge,
                                    manager: manager
                                )
                            }
                        }
                    }
                }

                Spacer(minLength: 100)
            }
            .padding(.horizontal, AppTheme.Spacing.lg)
            .padding(.top, AppTheme.Spacing.xs)
        }
        .background(AppGradient.background)
        .sheet(isPresented: $showingKnowledgeLibrary) {
            KnowledgeLibraryView(manager: manager)
        }
    }
}

// MARK: - 行动统计视图
struct ActionStatsView: View {
    let todayPending: Int
    let onKnowledgeLibraryTap: () -> Void

    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            HStack(spacing: AppTheme.Spacing.lg) {
                // 今日待打卡
                VStack(spacing: AppTheme.Spacing.sm) {
                    Text("\(todayPending)")
                        .font(.system(size: AppTheme.FontSize.title2, weight: .bold))
                        .foregroundColor(todayPending == 0 ? .green : .orange)
                    Text("今日待打卡")
                        .font(.system(size: AppTheme.FontSize.caption))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(AppTheme.Radius.medium)
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)

                // 知行库
                Button(action: onKnowledgeLibraryTap) {
                    VStack(spacing: AppTheme.Spacing.sm) {
                        Image(systemName: "books.vertical")
                            .font(.system(size: AppTheme.FontSize.title2, weight: .bold))
                            .foregroundColor(AppTheme.Colors.primary)
                        Text("知行库")
                            .font(.system(size: AppTheme.FontSize.caption))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(AppTheme.Radius.medium)
                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                }
            }
        }
    }
}

// MARK: - 行动卡片视图
struct ActionCardView: View {
    let action: ActionRecord
    let knowledge: Knowledge?
    let manager: KnowledgeActionManager
    @State private var showingCheckIn = false

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            // 认知引用
            if let knowledge = knowledge {
                HStack {
                    Image(systemName: knowledge.actionType == .daily ? "clock" : "lightbulb")
                        .font(.system(size: AppTheme.FontSize.caption))
                        .foregroundColor(knowledge.actionType == .daily ? .blue : .orange)
                    Text(knowledge.title)
                        .font(.system(size: AppTheme.FontSize.body, weight: .medium))
                        .foregroundColor(.primary)
                    Spacer()

                    // 状态标签
                    if action.isCompleted {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("已完成")
                                .font(.system(size: AppTheme.FontSize.caption))
                                .foregroundColor(.green)
                        }
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: "circle")
                                .foregroundColor(.gray)
                            Text("待打卡")
                                .font(.system(size: AppTheme.FontSize.caption))
                                .foregroundColor(.gray)
                        }
                    }
                }
            }

            // 场景条件（如果是场景触发）
            if let knowledge = knowledge, knowledge.actionType == .scenario,
               let condition = knowledge.actionConfig?.scenarioCondition {
                Text("触发条件：\(condition)")
                    .font(.system(size: AppTheme.FontSize.caption))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, AppTheme.Spacing.sm)
                    .padding(.vertical, AppTheme.Spacing.xs)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(AppTheme.Radius.small)
            }

            // 心得备注
            if let notes = action.notes, !notes.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("心得")
                        .font(.system(size: AppTheme.FontSize.caption, weight: .medium))
                        .foregroundColor(.secondary)
                    Text(notes)
                        .font(.system(size: AppTheme.FontSize.body))
                        .foregroundColor(.primary)
                        .padding(AppTheme.Spacing.sm)
                        .background(Color(.systemGray6))
                        .cornerRadius(AppTheme.Radius.small)
                }
            }

            // 操作按钮
            if !action.isCompleted {
                HStack(spacing: AppTheme.Spacing.sm) {
                    Button(action: {
                        showingCheckIn = true
                    }) {
                        HStack {
                            Image(systemName: "checkmark.circle")
                            Text("打卡")
                        }
                        .font(.system(size: AppTheme.FontSize.body, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppTheme.Spacing.sm)
                        .background(AppTheme.Colors.primary)
                        .cornerRadius(AppTheme.Radius.medium)
                    }

                }
            }
        }
        .padding(AppTheme.Spacing.lg)
        .background(Color(.systemBackground))
        .cornerRadius(AppTheme.Radius.medium)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .sheet(isPresented: $showingCheckIn) {
            if let knowledge = knowledge {
                ActionCheckInView(
                    action: action,
                    knowledge: knowledge,
                    manager: manager,
                    isPresented: $showingCheckIn
                )
            }
        }
    }
}

// MARK: - 认知编辑视图
struct KnowledgeEditView: View {
    @ObservedObject var manager: KnowledgeActionManager
    @Binding var isPresented: Bool
    let knowledgeToEdit: Knowledge? // 可选：如果传入则进入编辑模式，否则为新建模式
    @State private var title: String = ""
    @State private var content: String = ""
    @State private var hasAction: Bool = false
    @State private var selectedActionType: ActionType = .daily
    @State private var dailyTime: Date = Date()
    @State private var scenarioCondition: String = ""
    
    init(manager: KnowledgeActionManager, isPresented: Binding<Bool>, knowledgeToEdit: Knowledge? = nil) {
        self.manager = manager
        self._isPresented = isPresented
        self.knowledgeToEdit = knowledgeToEdit
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("认知信息")) {
                    TextField("认知标题", text: $title)
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    VStack(alignment: .leading, spacing: 8) {
                        Text("认知内容")
                            .font(.system(size: AppTheme.FontSize.subheadline, weight: .medium))
                        if #available(iOS 16.0, *) {
                            TextField("记录你的思考和认知...", text: $content, axis: .vertical)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .lineLimit(5...10)
                        } else {
                            TextEditor(text: $content)
                                .frame(minHeight: 120, maxHeight: 200)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                        }
                    }
                }

                Section(header: Text("行动设置")) {
                    Toggle("需要行动打卡", isOn: $hasAction)

                    if hasAction {
                        Picker("打卡类型", selection: $selectedActionType) {
                            ForEach(ActionType.allCases, id: \.self) { type in
                                Text(type.displayName).tag(type)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())

                        if selectedActionType == .daily {
                            DatePicker("打卡时间", selection: $dailyTime, displayedComponents: .hourAndMinute)
                        } else {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("触发条件")
                                    .font(.system(size: AppTheme.FontSize.subheadline, weight: .medium))
                                TextField("描述触发场景...", text: $scenarioCondition)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                        }
                    }
                }
            }
            .navigationTitle(knowledgeToEdit == nil ? "新增认知" : "编辑认知")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                // 如果是编辑模式，加载现有数据
                if let knowledge = knowledgeToEdit {
                    title = knowledge.title
                    content = knowledge.content
                    hasAction = knowledge.hasAction
                    selectedActionType = knowledge.actionType ?? .daily
                    dailyTime = knowledge.actionConfig?.dailyTime ?? Date()
                    scenarioCondition = knowledge.actionConfig?.scenarioCondition ?? ""
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        isPresented = false
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveKnowledge()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                             content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func saveKnowledge() {
        let actionConfig: ActionConfig?
        if hasAction {
            if selectedActionType == .daily {
                actionConfig = ActionConfig(dailyTime: dailyTime, scenarioCondition: nil)
            } else {
                actionConfig = ActionConfig(dailyTime: nil, scenarioCondition: scenarioCondition)
            }
        } else {
            actionConfig = nil
        }

        if let existingKnowledge = knowledgeToEdit {
            // 编辑模式：更新现有认知（创建新实例，保留id和createdAt）
            let updatedKnowledge = Knowledge(
                id: existingKnowledge.id,
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                content: content.trimmingCharacters(in: .whitespacesAndNewlines),
                createdAt: existingKnowledge.createdAt,
                updatedAt: Date(),
                hasAction: hasAction,
                actionType: hasAction ? selectedActionType : nil,
                actionConfig: actionConfig
            )
            manager.updateKnowledge(updatedKnowledge)
        } else {
            // 新建模式：添加新认知
        let knowledge = Knowledge(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            content: content.trimmingCharacters(in: .whitespacesAndNewlines),
            hasAction: hasAction,
            actionType: hasAction ? selectedActionType : nil,
            actionConfig: actionConfig
        )
        manager.addKnowledge(knowledge)
        }
        
        isPresented = false
    }
}

// MARK: - 打卡心得视图
struct ActionCheckInView: View {
    let action: ActionRecord
    let knowledge: Knowledge
    @ObservedObject var manager: KnowledgeActionManager
    @Binding var isPresented: Bool
    @State private var notes: String = ""
    @State private var isSuccess: Bool? = nil // 成功/失败（仅场景触发类型）
    @State private var score: Double = 5.0 // 评分（1-10，仅成功时有效）
    
    private var isEditing: Bool {
        action.isCompleted
    }
    
    private var isScenarioType: Bool {
        knowledge.actionType == .scenario
    }
    
    private var shouldDefaultToFailure: Bool {
        // 场景触发类型且不是编辑模式时，默认选中失败
        isScenarioType && !isEditing
    }

    var body: some View {
        NavigationView {
            VStack(spacing: AppTheme.Spacing.lg) {
                // 认知回顾
                VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                    Text("认知回顾")
                        .font(.system(size: AppTheme.FontSize.headline, weight: .semibold))
                        .foregroundColor(AppTheme.Colors.primary)

                    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                        Text(knowledge.title)
                            .font(.system(size: AppTheme.FontSize.body, weight: .medium))
                            .foregroundColor(.primary)

                        Text(knowledge.content)
                            .font(.system(size: AppTheme.FontSize.body))
                            .foregroundColor(.secondary)
                            .lineLimit(nil)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(AppTheme.Radius.medium)
                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                }

                // 成功/失败选择（仅场景触发类型）
                if isScenarioType {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                        Text("结果")
                            .font(.system(size: AppTheme.FontSize.headline, weight: .semibold))
                            .foregroundColor(AppTheme.Colors.primary)
                        
                        Picker("结果", selection: $isSuccess) {
                            Text("失败").tag(Bool?.some(false))
                            Text("成功").tag(Bool?.some(true))
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        
                        // 评分（仅成功时显示）
                        if isSuccess == true {
                            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                                HStack {
                                    Text("评分")
                                        .font(.system(size: AppTheme.FontSize.body, weight: .medium))
                                    Spacer()
                                    Text("\(Int(score))分")
                                        .font(.system(size: AppTheme.FontSize.body, weight: .semibold))
                                        .foregroundColor(AppTheme.Colors.primary)
                                }
                                
                                Slider(value: $score, in: 1...10, step: 1)
                                
                                HStack {
                                    Text("1分")
                                        .font(.system(size: AppTheme.FontSize.caption2))
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("10分")
                                        .font(.system(size: AppTheme.FontSize.caption2))
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.top, AppTheme.Spacing.sm)
                        }
                    }
                }
                
                // 心得输入
                VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                    Text("今日心得")
                        .font(.system(size: AppTheme.FontSize.headline, weight: .semibold))
                        .foregroundColor(AppTheme.Colors.primary)

                    if #available(iOS 16.0, *) {
                        TextField("记录你的实践心得...", text: $notes, axis: .vertical)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .lineLimit(5...15)
                    } else {
                        TextEditor(text: $notes)
                            .frame(minHeight: 150, maxHeight: 250)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }

                    Text("心得将同步到对应的认知记录中，帮助你不断优化认知")
                        .font(.system(size: AppTheme.FontSize.caption))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .onAppear {
                    // 如果是编辑模式，加载现有的数据
                    if isEditing {
                        notes = action.notes ?? ""
                        isSuccess = action.isSuccess
                        if let actionScore = action.score {
                            score = Double(actionScore)
                        }
                    } else if shouldDefaultToFailure {
                        // 场景触发类型且不是编辑模式时，默认选中失败
                        isSuccess = false
                    }
                }

                Spacer()

                // 完成按钮
                Button(action: {
                    saveAction()
                }) {
                    Text(isEditing ? "保存修改" : "完成打卡")
                        .font(.system(size: AppTheme.FontSize.body, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppTheme.Spacing.md)
                        .background(AppTheme.Colors.primary)
                        .cornerRadius(AppTheme.Radius.medium)
                }
                .padding(.bottom, AppTheme.Spacing.lg)
            }
            .padding(.horizontal, AppTheme.Spacing.lg)
            .padding(.top, AppTheme.Spacing.lg)
            .background(AppGradient.background)
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(isEditing ? "编辑打卡" : "打卡")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        // 如果是新建模式且未完成，删除这个action
                        if !isEditing && !action.isCompleted {
                            manager.deleteAction(action)
                        }
                        isPresented = false
                    }
                }
            }
        }
    }

    private func saveAction() {
        let finalNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalIsSuccess = isScenarioType ? isSuccess : nil
        let finalScore = (isScenarioType && isSuccess == true) ? Int(score) : nil
        
        if isEditing {
            // 编辑模式：更新心得
            manager.updateActionNotes(action, notes: finalNotes.isEmpty ? nil : finalNotes, isSuccess: finalIsSuccess, score: finalScore)
        } else {
            // 新建模式：完成打卡
            manager.completeAction(action, notes: finalNotes.isEmpty ? nil : finalNotes, isSuccess: finalIsSuccess, score: finalScore)
        }
        isPresented = false
    }
}

// MARK: - 认知详情视图
struct KnowledgeDetailView: View {
    let knowledgeId: UUID // 改为使用ID，而不是直接传递knowledge对象
    @ObservedObject var manager: KnowledgeActionManager
    @Environment(\.presentationMode) var presentationMode
    @State private var showingEditView = false
    
    // 从manager中动态获取最新的knowledge数据
    private var knowledge: Knowledge? {
        manager.knowledges.first { $0.id == knowledgeId }
    }

    private var actionStats: ActionStats {
        manager.getActionStats(for: knowledgeId)
    }

    private var relatedActions: [ActionRecord] {
        manager.getActionsForKnowledge(knowledgeId)
            .sorted { $0.date > $1.date }
    }

    var body: some View {
        Group {
            if let knowledge = knowledge {
                knowledgeDetailContent(knowledge: knowledge)
            } else {
                NavigationView {
                    VStack {
                        Text("认知不存在")
                            .foregroundColor(.secondary)
                        Button("返回") {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func knowledgeDetailContent(knowledge: Knowledge) -> some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    // 认知基本信息
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                        Text(knowledge.title)
                            .font(.system(size: AppTheme.FontSize.title2, weight: .bold))
                            .foregroundColor(.primary)

                        HStack {
                            Text("创建于 \(formatDate(knowledge.createdAt))")
                                .font(.system(size: AppTheme.FontSize.caption))
                                .foregroundColor(.secondary)

                            Spacer()

                            if knowledge.hasAction {
                                HStack(spacing: 8) {
                                    Image(systemName: knowledge.actionType == .daily ? "clock" : "lightbulb")
                                        .font(.system(size: AppTheme.FontSize.caption2))
                                    Text(knowledge.actionType?.displayName ?? "")
                                        .font(.system(size: AppTheme.FontSize.caption))
                                }
                                .padding(.horizontal, AppTheme.Spacing.sm)
                                .padding(.vertical, AppTheme.Spacing.xs)
                                .background(AppTheme.Colors.primary.opacity(0.1))
                                .foregroundColor(AppTheme.Colors.primary)
                                .cornerRadius(AppTheme.Radius.small)
                            }
                        }
                    }
                    .padding(AppTheme.Spacing.lg)
                    .background(Color(.systemBackground))
                    .cornerRadius(AppTheme.Radius.medium)
                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)

                    // 认知内容
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                        Text("认知内容")
                            .font(.system(size: AppTheme.FontSize.headline, weight: .semibold))
                            .foregroundColor(AppTheme.Colors.primary)

                        Text(knowledge.content)
                            .font(.system(size: AppTheme.FontSize.body))
                            .foregroundColor(.primary)
                            .lineLimit(nil)
                    }
                    .padding(AppTheme.Spacing.lg)
                    .background(Color(.systemBackground))
                    .cornerRadius(AppTheme.Radius.medium)
                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)

                    // 行动设置（如果有）
                    if knowledge.hasAction {
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                            Text("行动设置")
                                .font(.system(size: AppTheme.FontSize.headline, weight: .semibold))
                                .foregroundColor(AppTheme.Colors.primary)

                            if let actionType = knowledge.actionType {
                                if actionType == .daily, let dailyTime = knowledge.actionConfig?.dailyTime {
                                    HStack {
                                        Image(systemName: "clock")
                                            .foregroundColor(.blue)
                                        Text("每日打卡")
                                            .font(.system(size: AppTheme.FontSize.body, weight: .medium))
                                        Spacer()
                                        Text(formatTime(dailyTime))
                                            .font(.system(size: AppTheme.FontSize.body))
                                            .foregroundColor(.secondary)
                                    }
                                } else if let condition = knowledge.actionConfig?.scenarioCondition {
                                    HStack {
                                        Image(systemName: "lightbulb")
                                            .foregroundColor(.orange)
                                        Text("场景触发")
                                            .font(.system(size: AppTheme.FontSize.body, weight: .medium))
                                        Spacer()
                                    }
                                    .padding(.bottom, AppTheme.Spacing.xs)

                                    Text(condition)
                                        .font(.system(size: AppTheme.FontSize.body))
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal, AppTheme.Spacing.sm)
                                        .padding(.vertical, AppTheme.Spacing.xs)
                                        .background(Color.orange.opacity(0.1))
                                        .cornerRadius(AppTheme.Radius.small)
                                }
                            }
                        }
                        .padding(AppTheme.Spacing.lg)
                        .background(Color(.systemBackground))
                        .cornerRadius(AppTheme.Radius.medium)
                        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                    }

                    // 统计信息
                    if knowledge.hasAction {
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                            Text("行动统计")
                                .font(.system(size: AppTheme.FontSize.headline, weight: .semibold))
                                .foregroundColor(AppTheme.Colors.primary)

                            HStack(spacing: AppTheme.Spacing.lg) {
                                VStack(spacing: AppTheme.Spacing.sm) {
                                    Text("\(actionStats.total)")
                                        .font(.system(size: AppTheme.FontSize.title2, weight: .bold))
                                        .foregroundColor(.blue)
                                    Text("总行动数")
                                        .font(.system(size: AppTheme.FontSize.caption))
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)

                                VStack(spacing: AppTheme.Spacing.sm) {
                                    Text("\(actionStats.completed)")
                                        .font(.system(size: AppTheme.FontSize.title2, weight: .bold))
                                        .foregroundColor(.green)
                                    Text("已完成")
                                        .font(.system(size: AppTheme.FontSize.caption))
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)

                                VStack(spacing: AppTheme.Spacing.sm) {
                                    Text(actionStats.completionPercentage)
                                        .font(.system(size: AppTheme.FontSize.title2, weight: .bold))
                                        .foregroundColor(actionStats.completionRate > 0.7 ? .green : .orange)
                                    Text("完成率")
                                        .font(.system(size: AppTheme.FontSize.caption))
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .padding(AppTheme.Spacing.lg)
                        .background(Color(.systemBackground))
                        .cornerRadius(AppTheme.Radius.medium)
                        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                    }

                    // 历史记录
                    if !relatedActions.isEmpty {
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                            Text("历史记录")
                                .font(.system(size: AppTheme.FontSize.headline, weight: .semibold))
                                .foregroundColor(AppTheme.Colors.primary)

                            LazyVStack(spacing: AppTheme.Spacing.sm) {
                                ForEach(relatedActions) { action in
                                    ActionHistoryView(action: action)
                                }
                            }
                        }
                        .padding(AppTheme.Spacing.lg)
                        .background(Color(.systemBackground))
                        .cornerRadius(AppTheme.Radius.medium)
                        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                    }

                    Spacer(minLength: 100)
                }
                .padding(.horizontal, AppTheme.Spacing.lg)
                .padding(.top, AppTheme.Spacing.lg)
            }
            .background(AppGradient.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("返回") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("编辑") {
                        showingEditView = true
                    }
                }
            }
            .sheet(isPresented: $showingEditView) {
                KnowledgeEditView(
                    manager: manager,
                    isPresented: $showingEditView,
                    knowledgeToEdit: knowledge
                )
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM月dd日 HH:mm"
        return formatter.string(from: date)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - 行动历史记录视图
struct ActionHistoryView: View {
    let action: ActionRecord

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack {
                Text(formatDate(action.date))
                    .font(.system(size: AppTheme.FontSize.caption))
                    .foregroundColor(.secondary)

                Spacer()

                // 状态标签
                if action.isCompleted {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.green)
                        Text("已完成")
                            .font(.system(size: AppTheme.FontSize.caption2))
                            .foregroundColor(.green)
                    }
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "circle")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                        Text("未完成")
                            .font(.system(size: AppTheme.FontSize.caption2))
                            .foregroundColor(.gray)
                    }
                }
            }

            if let notes = action.notes, !notes.isEmpty {
                Text(notes)
                    .font(.system(size: AppTheme.FontSize.body))
                    .foregroundColor(.primary)
                    .padding(.top, AppTheme.Spacing.xs)
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(Color(.systemGray6))
        .cornerRadius(AppTheme.Radius.small)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM月dd日 HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - 日常打卡行动卡片视图
struct DailyActionCardView: View {
    let action: ActionRecord
    let knowledge: Knowledge?
    let manager: KnowledgeActionManager
    @State private var showingCheckIn = false

    private var currentConsecutiveDays: Int {
        guard let knowledge = knowledge else { return 0 }
        return manager.getCurrentConsecutiveDays(for: knowledge.id)
    }
    
    private var maxConsecutiveDays: Int {
        guard let knowledge = knowledge else { return 0 }
        return manager.getMaxConsecutiveDays(for: knowledge.id)
    }
    
    private var isTodayCompleted: Bool {
        action.isCompleted
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            // 认知引用
            if let knowledge = knowledge {
                HStack {
                    Image(systemName: "clock")
                        .font(.system(size: AppTheme.FontSize.caption))
                        .foregroundColor(.blue)
                    Text(knowledge.title)
                        .font(.system(size: AppTheme.FontSize.body, weight: .medium))
                        .foregroundColor(.primary)
                    Spacer()

                    // 状态标签
                    if action.isCompleted {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("已完成")
                                .font(.system(size: AppTheme.FontSize.caption))
                                .foregroundColor(.green)
                        }
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: "circle")
                                .foregroundColor(.gray)
                            Text("待打卡")
                                .font(.system(size: AppTheme.FontSize.caption))
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            
            // 连续天数统计
            HStack(spacing: AppTheme.Spacing.lg) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("本次连续")
                        .font(.system(size: AppTheme.FontSize.caption2))
                        .foregroundColor(.secondary)
                    Text("\(currentConsecutiveDays)天")
                        .font(.system(size: AppTheme.FontSize.body, weight: .semibold))
                        .foregroundColor(.blue)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("历史最长")
                        .font(.system(size: AppTheme.FontSize.caption2))
                        .foregroundColor(.secondary)
                    Text("\(maxConsecutiveDays)天")
                        .font(.system(size: AppTheme.FontSize.body, weight: .semibold))
                        .foregroundColor(.orange)
                }
                
                Spacer()
            }
            .padding(.vertical, AppTheme.Spacing.sm)
            .padding(.horizontal, AppTheme.Spacing.md)
            .background(Color(.systemGray6))
            .cornerRadius(AppTheme.Radius.small)

            // 心得备注
            if let notes = action.notes, !notes.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("心得")
                        .font(.system(size: AppTheme.FontSize.caption, weight: .medium))
                        .foregroundColor(.secondary)
                    Text(notes)
                        .font(.system(size: AppTheme.FontSize.body))
                        .foregroundColor(.primary)
                        .padding(AppTheme.Spacing.sm)
                        .background(Color(.systemGray6))
                        .cornerRadius(AppTheme.Radius.small)
                }
            }

            // 操作按钮
            Button(action: {
                showingCheckIn = true
            }) {
                HStack {
                    Image(systemName: isTodayCompleted ? "pencil.circle" : "checkmark.circle")
                    Text(isTodayCompleted ? "编辑打卡" : "打卡")
                }
                .font(.system(size: AppTheme.FontSize.body, weight: .medium))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppTheme.Spacing.sm)
                .background(AppTheme.Colors.primary)
                .cornerRadius(AppTheme.Radius.medium)
            }
        }
        .padding(AppTheme.Spacing.lg)
        .background(Color(.systemBackground))
        .cornerRadius(AppTheme.Radius.medium)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .sheet(isPresented: $showingCheckIn) {
            if let knowledge = knowledge {
                ActionCheckInView(
                    action: action,
                    knowledge: knowledge,
                    manager: manager,
                    isPresented: $showingCheckIn
                )
            }
        }
    }
}

// MARK: - 场景触发行动卡片视图
struct ScenarioActionCardView: View {
    let knowledge: Knowledge
    @ObservedObject var manager: KnowledgeActionManager
    @State private var showingCheckIn = false
    @State private var isEditingMode = false // true: 编辑打卡, false: 再打卡
    @State private var actionToEdit: ActionRecord? = nil // 要编辑的action
    @State private var newAction: ActionRecord? = nil // 新建的action
    
    private var latestCompletedAction: ActionRecord? {
        manager.getLatestTodayCompletedAction(for: knowledge.id)
    }
    
    private var hasCompletedToday: Bool {
        latestCompletedAction != nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            // 标题
            HStack {
                Image(systemName: "lightbulb")
                    .font(.system(size: AppTheme.FontSize.caption))
                    .foregroundColor(.orange)
                Text(knowledge.title)
                    .font(.system(size: AppTheme.FontSize.body, weight: .medium))
                    .foregroundColor(.primary)
                Spacer()
            }
            
            // 触发条件
            if let condition = knowledge.actionConfig?.scenarioCondition {
                Text("触发条件：\(condition)")
                    .font(.system(size: AppTheme.FontSize.caption))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, AppTheme.Spacing.sm)
                    .padding(.vertical, AppTheme.Spacing.xs)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(AppTheme.Radius.small)
            }
            
            // 心得备注（显示最近一条的心得）
            if let action = latestCompletedAction, let notes = action.notes, !notes.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("最近心得")
                        .font(.system(size: AppTheme.FontSize.caption, weight: .medium))
                        .foregroundColor(.secondary)
                    Text(notes)
                        .font(.system(size: AppTheme.FontSize.body))
                        .foregroundColor(.primary)
                        .padding(AppTheme.Spacing.sm)
                        .background(Color(.systemGray6))
                        .cornerRadius(AppTheme.Radius.small)
                }
            }

            // 操作按钮
            if hasCompletedToday {
                // 有已完成记录：显示"编辑打卡"和"再打卡"两个按钮
                HStack(spacing: AppTheme.Spacing.sm) {
                    Button(action: {
                        isEditingMode = true
                        actionToEdit = latestCompletedAction
                        showingCheckIn = true
                    }) {
                        HStack {
                            Image(systemName: "pencil.circle")
                            Text("编辑打卡")
                        }
                        .font(.system(size: AppTheme.FontSize.body, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppTheme.Spacing.sm)
                        .background(AppTheme.Colors.primary)
                        .cornerRadius(AppTheme.Radius.medium)
                    }
                    
                    Button(action: {
                        isEditingMode = false
                        actionToEdit = nil
                        // 在按钮点击时创建新的action，而不是在sheet闭包中
                        newAction = manager.createAction(for: knowledge.id, date: Date())
                        showingCheckIn = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle")
                            Text("再打卡")
                        }
                        .font(.system(size: AppTheme.FontSize.body, weight: .medium))
                        .foregroundColor(AppTheme.Colors.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppTheme.Spacing.sm)
                        .background(AppTheme.Colors.primary.opacity(0.1))
                        .cornerRadius(AppTheme.Radius.medium)
                    }
                }
            } else {
                // 没有已完成记录：显示"打卡"按钮
                Button(action: {
                    isEditingMode = false
                    actionToEdit = nil
                    // 在按钮点击时创建新的action，而不是在sheet闭包中
                    newAction = manager.createAction(for: knowledge.id, date: Date())
                    showingCheckIn = true
                }) {
                    HStack {
                        Image(systemName: "checkmark.circle")
                        Text("打卡")
                    }
                    .font(.system(size: AppTheme.FontSize.body, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppTheme.Spacing.sm)
                    .background(AppTheme.Colors.primary)
                    .cornerRadius(AppTheme.Radius.medium)
                }
            }
        }
        .padding(AppTheme.Spacing.lg)
        .background(Color(.systemBackground))
        .cornerRadius(AppTheme.Radius.medium)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .sheet(isPresented: $showingCheckIn) {
            if isEditingMode, let action = actionToEdit {
                // 编辑模式：编辑最近的一条打卡记录
                ActionCheckInView(
                    action: action,
                    knowledge: knowledge,
                    manager: manager,
                    isPresented: $showingCheckIn
                )
            } else if let action = newAction {
                // 新建模式：使用已创建的action
                ActionCheckInView(
                    action: action,
                    knowledge: knowledge,
                    manager: manager,
                    isPresented: $showingCheckIn
                )
            }
        }
        .onChange(of: showingCheckIn) { newValue in
            // sheet关闭时清理状态
            if !newValue {
                // 如果新建的action未完成，删除它
                // 注意：需要从manager中获取最新的action状态，因为newAction是值类型副本
                if let action = newAction {
                    // 从manager中查找最新的action状态
                    if let latestAction = manager.actions.first(where: { $0.id == action.id }) {
                        // 如果action未完成，删除它
                        if !latestAction.isCompleted {
                            manager.deleteAction(action)
                        }
                    } else {
                        // 如果action不存在于manager中（可能已经被删除），不需要处理
                    }
                }
                actionToEdit = nil
                newAction = nil
            }
        }
    }
}

// MARK: - 知行库视图
struct KnowledgeLibraryView: View {
    @ObservedObject var manager: KnowledgeActionManager
    @Environment(\.dismiss) var dismiss
    @State private var selectedKnowledge: Knowledge? = nil

    private var knowledgesWithAction: [Knowledge] {
        let filtered = manager.knowledges.filter { $0.hasAction }
        // 排序：日常打卡类型在前，场景触发类型在后，每组内按创建时间倒序
        return filtered.sorted { k1, k2 in
            // 先按类型排序：日常打卡在前，场景触发在后
            if k1.actionType == .daily && k2.actionType != .daily {
                return true
            }
            if k1.actionType != .daily && k2.actionType == .daily {
                return false
            }
            // 同类型内按创建时间倒序
            return k1.createdAt > k2.createdAt
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: AppTheme.Spacing.md) {
                    ForEach(knowledgesWithAction) { knowledge in
                        KnowledgeLibraryCardView(
                            knowledge: knowledge,
                            manager: manager,
                            onTap: {
                                selectedKnowledge = knowledge
                            }
                        )
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.lg)
                .padding(.vertical, AppTheme.Spacing.md)
            }
            .background(AppGradient.background)
            .navigationTitle("知行库")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $selectedKnowledge) { knowledge in
                KnowledgeActionHistoryView(knowledge: knowledge, manager: manager)
            }
        }
    }
}

// MARK: - 知行库卡片视图
struct KnowledgeLibraryCardView: View {
    let knowledge: Knowledge
    let manager: KnowledgeActionManager
    let onTap: () -> Void
    
    private var completedCount: Int {
        manager.getCompletedCount(for: knowledge.id)
    }
    
    private var maxConsecutiveDays: Int {
        if knowledge.actionType == .daily {
            return manager.getMaxConsecutiveDays(for: knowledge.id)
        }
        return 0
    }
    
    private var completionRate: Double {
        if knowledge.actionType == .daily {
            return manager.getCompletionRate(for: knowledge.id)
        }
        return 0.0
    }
    
    private var successRate: Double {
        if knowledge.actionType == .scenario {
            return manager.getSuccessRate(for: knowledge.id)
        }
        return 0.0
    }
    
    private var averageScore: Double {
        if knowledge.actionType == .scenario {
            return manager.getAverageScore(for: knowledge.id)
        }
        return 0.0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            // 标题（可点击）
            Button(action: onTap) {
                HStack {
                    Text(knowledge.title)
                        .font(.system(size: AppTheme.FontSize.headline, weight: .semibold))
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: AppTheme.FontSize.caption))
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // 统计信息
            if knowledge.actionType == .daily {
                // 日常打卡类型：已打卡次数、最多连续、完成率
                HStack(spacing: 0) {
                    StatItemView(
                        label: "已打卡",
                        value: "\(completedCount)",
                        color: .blue
                    )
                    
                    Divider()
                        .frame(height: 40)
                    
                    StatItemView(
                        label: "最多连续",
                        value: "\(maxConsecutiveDays)天",
                        color: .orange
                    )
                    
                    Divider()
                        .frame(height: 40)
                    
                    StatItemView(
                        label: "完成率",
                        value: "\(Int(completionRate * 100))%",
                        color: completionRate >= 0.7 ? .green : .orange
                    )
                }
                .padding(.vertical, AppTheme.Spacing.md)
                .padding(.horizontal, AppTheme.Spacing.md)
                .background(Color(.systemGray6))
                .cornerRadius(AppTheme.Radius.small)
            } else {
                // 场景触发类型：已打卡次数、成功率、综合评分
                HStack(spacing: 0) {
                    StatItemView(
                        label: "已打卡",
                        value: "\(completedCount)",
                        color: .blue
                    )
                    
                    Divider()
                        .frame(height: 40)
                    
                    StatItemView(
                        label: "成功率",
                        value: "\(Int(successRate * 100))%",
                        color: successRate >= 0.7 ? .green : .orange
                    )
                    
                    Divider()
                        .frame(height: 40)
                    
                    StatItemView(
                        label: "综合评分",
                        value: String(format: "%.1f", averageScore),
                        color: averageScore >= 7.0 ? .green : averageScore >= 5.0 ? .orange : .red
                    )
                }
                .padding(.vertical, AppTheme.Spacing.md)
                .padding(.horizontal, AppTheme.Spacing.md)
                .background(Color(.systemGray6))
                .cornerRadius(AppTheme.Radius.small)
            }
            
            // 开启行动/挂起按钮（仅对日常打卡类型）
            if knowledge.actionType == .daily {
                Button(action: {
                    if knowledge.isSuspended {
                        manager.activateKnowledge(knowledge.id)
                    } else {
                        manager.suspendKnowledge(knowledge.id)
                    }
                }) {
                    HStack {
                        Image(systemName: knowledge.isSuspended ? "play.circle" : "pause.circle")
                        Text(knowledge.isSuspended ? "开启行动" : "挂起")
                    }
                    .font(.system(size: AppTheme.FontSize.body, weight: .medium))
                    .foregroundColor(knowledge.isSuspended ? .white : .orange)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppTheme.Spacing.sm)
                    .background(knowledge.isSuspended ? AppTheme.Colors.primary : Color.orange.opacity(0.1))
                    .cornerRadius(AppTheme.Radius.medium)
                }
            }
        }
        .padding(AppTheme.Spacing.lg)
        .background(Color(.systemBackground))
        .cornerRadius(AppTheme.Radius.medium)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - 行动历史记录视图
struct KnowledgeActionHistoryView: View {
    let knowledge: Knowledge
    @ObservedObject var manager: KnowledgeActionManager
    @Environment(\.dismiss) var dismiss
    
    private var actionRecords: [ActionRecord] {
        // 只显示已完成的记录，未完成的记录不应该出现在历史中
        manager.getActionsForKnowledge(knowledge.id)
            .filter { $0.isCompleted }
            .sorted { $0.date > $1.date }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: AppTheme.Spacing.md) {
                    ForEach(actionRecords) { action in
                        ActionHistoryCardView(action: action)
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.lg)
                .padding(.vertical, AppTheme.Spacing.md)
            }
            .background(AppGradient.background)
            .navigationTitle(knowledge.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - 行动历史卡片视图
struct ActionHistoryCardView: View {
    let action: ActionRecord
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日 HH:mm"
        return formatter.string(from: date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack {
                Text(formatDate(action.date))
                    .font(.system(size: AppTheme.FontSize.caption))
                    .foregroundColor(.secondary)

                Spacer()

                // 状态标签
                if action.isCompleted {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.green)
                        Text("已完成")
                            .font(.system(size: AppTheme.FontSize.caption2))
                            .foregroundColor(.green)
                    }
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "circle")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                        Text("未完成")
                            .font(.system(size: AppTheme.FontSize.caption2))
                            .foregroundColor(.gray)
                    }
                }
            }

            if let notes = action.notes, !notes.isEmpty {
                Text("今日心得：\(notes)")
                    .font(.system(size: AppTheme.FontSize.body))
                    .foregroundColor(.primary)
                    .padding(AppTheme.Spacing.sm)
                    .background(Color(.systemGray6))
                    .cornerRadius(AppTheme.Radius.small)
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(Color(.systemBackground))
        .cornerRadius(AppTheme.Radius.medium)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - 统计项视图
struct StatItemView: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: AppTheme.FontSize.title3, weight: .bold))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: AppTheme.FontSize.caption2))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    KnowledgeActionUnityView()
}