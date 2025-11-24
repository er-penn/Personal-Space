//
//  QuickNoteListView.swift
//  Personal Space
//
//  Created by Penn on 2025/11/20.
//

import SwiftUI

// MARK: - UUID包装类型（用于fullScreenCover的item参数）
struct NoteIdWrapper: Identifiable {
    let id: UUID
    let isNewNote: Bool // 标记是否为新建模式
    
    init(id: UUID) {
        self.id = id
        self.isNewNote = false
    }
    
    init(isNewNote: Bool) {
        // 新建模式使用一个特殊的 UUID
        self.id = UUID(uuidString: "00000000-0000-0000-0000-000000000000") ?? UUID()
        self.isNewNote = true
    }
}

struct QuickNoteListView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var manager: QuickNoteManager
    @State private var selectedFilter: QuickNoteFilter = .all
    @State private var selectedNoteId: UUID? = nil
    @State private var showingChatView = false
    
    init(manager: QuickNoteManager? = nil) {
        if let manager = manager {
            _manager = ObservedObject(wrappedValue: manager)
        } else {
            _manager = ObservedObject(wrappedValue: QuickNoteManager())
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 筛选标签栏
                filterTabs
                
                // 列表内容
                if manager.getNotes(filter: selectedFilter).isEmpty {
                    emptyStateView
                } else {
                    notesList
                }
            }
            .navigationTitle("随手记")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(AppTheme.Colors.text)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        selectedNoteId = nil
                        showingChatView = true
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(AppTheme.Colors.primary)
                    }
                }
            }
            .fullScreenCover(item: Binding(
                get: { 
                    if let id = selectedNoteId {
                        return NoteIdWrapper(id: id)
                    } else if showingChatView {
                        return NoteIdWrapper(isNewNote: true)
                    } else {
                        return nil
                    }
                },
                set: { newValue in
                    if let wrapper = newValue {
                        if wrapper.isNewNote {
                            selectedNoteId = nil
                        } else {
                            selectedNoteId = wrapper.id
                        }
                        showingChatView = (newValue != nil)
                    } else {
                        selectedNoteId = nil
                        showingChatView = false
                    }
                }
            )) { wrapper in
                QuickNoteChatView(
                    noteId: wrapper.isNewNote ? nil : wrapper.id,
                    manager: manager,
                    onDismiss: {
                        selectedNoteId = nil
                        showingChatView = false
                    }
                )
            }
        }
    }
    
    // MARK: - 筛选标签栏
    private var filterTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.Spacing.md) {
                ForEach(QuickNoteFilter.allCases, id: \.self) { filter in
                    FilterTabButton(
                        title: filter.rawValue,
                        isSelected: selectedFilter == filter,
                        action: {
                            withAnimation {
                                selectedFilter = filter
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, AppTheme.Spacing.lg)
            .padding(.vertical, AppTheme.Spacing.md)
        }
        .background(AppTheme.Colors.bgMain)
    }
    
    // MARK: - 列表视图
    private var notesList: some View {
        ScrollView {
            LazyVStack(spacing: AppTheme.Spacing.sm) {
                ForEach(manager.getNotes(filter: selectedFilter)) { note in
                    QuickNoteListCardView(note: note) {
                        selectedNoteId = note.id
                    }
                }
            }
            .padding(.horizontal, AppTheme.Spacing.lg)
            .padding(.top, AppTheme.Spacing.md)
            .padding(.bottom, AppTheme.Spacing.lg)
        }
    }
    
    // MARK: - 空状态视图
    private var emptyStateView: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Image(systemName: "note.text")
                .font(.system(size: 64))
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            Text(emptyStateText)
                .font(.system(size: AppTheme.FontSize.body))
                .foregroundColor(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
            
            // 只有选择"全部"筛选且没有数据时，才显示创建按钮
            if selectedFilter == .all {
                Button(action: {
                    selectedNoteId = nil
                    showingChatView = true
                }) {
                    Text("创建第一条随手记")
                        .font(.system(size: AppTheme.FontSize.subheadline, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, AppTheme.Spacing.xl)
                        .padding(.vertical, AppTheme.Spacing.md)
                        .background(AppTheme.Colors.primary)
                        .cornerRadius(AppTheme.Radius.medium)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(AppTheme.Spacing.xl)
    }
    
    private var emptyStateText: String {
        switch selectedFilter {
        case .all:
            return "还没有随手记\n点击下方按钮创建第一条"
        case .notAnalyzed:
            return "暂无未拆解的随手记"
        case .hasInsight:
            return "暂无有洞察的随手记"
        case .hasPainPoint:
            return "暂无有痛点的随手记"
        case .hasSolution:
            return "暂无有方案的随手记"
        }
    }
}

// MARK: - 随手记列表卡片视图
struct QuickNoteListCardView: View {
    let note: QuickNote
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                // 第一行：标题（主）
                Text(note.title)
                    .font(.system(size: AppTheme.FontSize.headline, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.text)
                    .lineLimit(1)
                
                // 第二行：消息预览（辅）
                Text(note.latestMessagePreview)
                    .font(.system(size: AppTheme.FontSize.body))
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(AppTheme.Spacing.md)
            .background(AppTheme.Colors.cardBg)
            .cornerRadius(AppTheme.Radius.card)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                    .stroke(AppTheme.Colors.border, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 筛选标签按钮
struct FilterTabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: AppTheme.FontSize.subheadline, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? AppTheme.Colors.primary : AppTheme.Colors.textSecondary)
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.sm)
                .background(isSelected ? AppTheme.Colors.primary.opacity(0.1) : Color.clear)
                .cornerRadius(AppTheme.Radius.medium)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

