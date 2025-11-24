//
//  BadgeSummaryView.swift
//  Personal Space
//
//  Created by Penn on 2025/11/20.
//

import SwiftUI

struct BadgeSummaryView: View {
    @Environment(\.dismiss) var dismiss
    let note: QuickNote
    let badge: BadgeType
    @ObservedObject var manager: QuickNoteManager
    let onSave: (String) -> Void
    
    @State private var summaryText: String = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 消息展示区
                ScrollView {
                    LazyVStack(spacing: AppTheme.Spacing.md) {
                        ForEach(note.getMessages(with: badge)) { message in
                            BadgeMessageItemView(message: message, manager: manager)
                        }
                    }
                    .padding(.horizontal, AppTheme.Spacing.lg)
                    .padding(.vertical, AppTheme.Spacing.md)
                }
                
                Divider()
                
                // 底部编辑框
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    Text("整理内容")
                        .font(.system(size: AppTheme.FontSize.subheadline, weight: .medium))
                        .foregroundColor(AppTheme.Colors.text)
                        .padding(.horizontal, AppTheme.Spacing.md)
                        .padding(.top, AppTheme.Spacing.md)
                    
                    if #available(iOS 16.0, *) {
                        TextField(placeholderText, text: $summaryText, axis: .vertical)
                            .textFieldStyle(.plain)
                            .padding(.horizontal, AppTheme.Spacing.md)
                            .padding(.vertical, AppTheme.Spacing.sm)
                            .background(AppTheme.Colors.bgMain)
                            .cornerRadius(AppTheme.Radius.medium)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                                    .stroke(AppTheme.Colors.border, lineWidth: 1)
                            )
                            .lineLimit(5...15)
                            .padding(.horizontal, AppTheme.Spacing.md)
                    } else {
                        TextEditor(text: $summaryText)
                            .frame(minHeight: 120, maxHeight: 200)
                            .padding(.horizontal, AppTheme.Spacing.md)
                            .padding(.vertical, AppTheme.Spacing.sm)
                            .background(AppTheme.Colors.bgMain)
                            .cornerRadius(AppTheme.Radius.medium)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                                    .stroke(AppTheme.Colors.border, lineWidth: 1)
                            )
                            .padding(.horizontal, AppTheme.Spacing.md)
                    }
                }
                .padding(.bottom, AppTheme.Spacing.md)
            }
            .navigationTitle("\(badge.rawValue)整理")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("返回") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        onSave(summaryText)
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadSummary()
            }
        }
    }
    
    private var placeholderText: String {
        switch badge {
        case .insight:
            return "整理你的洞察..."
        case .painPoint:
            return "整理你的痛点..."
        case .solution:
            return "整理你的方案..."
        }
    }
    
    private func loadSummary() {
        switch badge {
        case .insight:
            summaryText = note.insightSummary ?? ""
        case .painPoint:
            summaryText = note.painPointSummary ?? ""
        case .solution:
            summaryText = note.solutionSummary ?? ""
        }
    }
}

// MARK: - 角标消息项视图
struct BadgeMessageItemView: View {
    let message: NoteMessage
    @ObservedObject var manager: QuickNoteManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            // 时间
            Text(formatTime(message.createdAt))
                .font(.system(size: AppTheme.FontSize.caption))
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            // 消息内容
            HStack {
                switch message.type {
                case .text:
                    if let content = message.content {
                        Text(content)
                            .font(.system(size: AppTheme.FontSize.body))
                            .foregroundColor(AppTheme.Colors.text)
                    }
                case .audio:
                    HStack(spacing: AppTheme.Spacing.sm) {
                        Image(systemName: "waveform")
                            .foregroundColor(AppTheme.Colors.primary)
                        if let duration = message.audioDuration {
                            Text("[语音]\(Int(duration))''")
                                .font(.system(size: AppTheme.FontSize.body))
                                .foregroundColor(AppTheme.Colors.text)
                        }
                    }
                case .image:
                    Text("[图片]")
                        .font(.system(size: AppTheme.FontSize.body))
                        .foregroundColor(AppTheme.Colors.text)
                }
                
                Spacer()
            }
            .padding(AppTheme.Spacing.md)
            .background(AppTheme.Colors.bgMain)
            .cornerRadius(AppTheme.Radius.medium)
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: date)
    }
}

