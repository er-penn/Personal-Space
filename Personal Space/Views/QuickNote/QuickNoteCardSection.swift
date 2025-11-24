//
//  QuickNoteCardSection.swift
//  Personal Space
//
//  Created by Penn on 2025/11/20.
//

import SwiftUI

struct QuickNoteCardSection: View {
    @ObservedObject var manager: QuickNoteManager
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: AppTheme.Spacing.lg) {
                // 标题行
                HStack {
                    HStack(spacing: AppTheme.Spacing.sm) {
                        Image(systemName: "note.text")
                            .font(.system(size: 20))
                            .foregroundColor(AppTheme.Colors.primary)
                        
                        Text("随手记")
                            .font(.system(size: AppTheme.FontSize.headline, weight: .semibold))
                            .foregroundColor(AppTheme.Colors.text)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        let displayCount = manager.getNotes(filter: .all).count
                        
                        Text("\(displayCount) 条记录")
                            .font(.system(size: AppTheme.FontSize.caption))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: AppTheme.FontSize.caption))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    .onAppear {
                        print("📊 [QuickNoteCardSection] 计算记录数")
                        print("   📊 manager.notes.count (总数): \(manager.notes.count)")
                        print("   📊 notesWithMessages (有消息的): \(manager.notes.filter { !$0.messages.isEmpty }.count)")
                        print("   📊 getNotes(filter: .all).count (筛选后): \(manager.getNotes(filter: .all).count)")
                        print("   📊 当前显示: \(manager.getNotes(filter: .all).count) 条记录")
                    }
                }
                
                if manager.notes.isEmpty {
                    // 空状态
                    Text("点击右下角"+"按钮创建第一条随手记")
                        .font(.system(size: AppTheme.FontSize.body))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppTheme.Spacing.lg)
                } else {
                    // 显示最近2条（按更新时间排序，去重）
                    let allNotes = manager.notes
                    var seenIds: Set<UUID> = []
                    let uniqueNotes = allNotes.compactMap { note -> QuickNote? in
                        if seenIds.contains(note.id) {
                            return nil
                        }
                        seenIds.insert(note.id)
                        return note
                    }
                    let recentNotes = uniqueNotes
                        .sorted { $0.latestUpdateTime > $1.latestUpdateTime }
                        .prefix(2)
                    
                    if !recentNotes.isEmpty {
                        VStack(spacing: AppTheme.Spacing.sm) {
                            ForEach(Array(recentNotes)) { note in
                                HStack(spacing: AppTheme.Spacing.sm) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(note.title)
                                            .font(.system(size: AppTheme.FontSize.body, weight: .medium))
                                            .foregroundColor(AppTheme.Colors.text)
                                            .lineLimit(1)
                                        
                                        Text(note.latestMessagePreview)
                                            .font(.system(size: AppTheme.FontSize.caption))
                                            .foregroundColor(AppTheme.Colors.textSecondary)
                                            .lineLimit(1)
                                    }
                                    
                                    Spacer()
                                }
                                .padding(AppTheme.Spacing.sm)
                                .background(AppTheme.Colors.bgMain)
                                .cornerRadius(AppTheme.Radius.small)
                            }
                        }
                    }
                }
            }
            .padding(AppTheme.Spacing.lg)
            .background(AppTheme.Colors.cardBg)
            .cornerRadius(AppTheme.Radius.large)
            .shadow(color: AppTheme.Shadows.card, radius: 6, x: 0, y: 3)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

