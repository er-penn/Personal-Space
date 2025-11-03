//
//  CollaborationInvitationResponseView.swift
//  Personal Space
//
//  Created by AI Assistant on 2025/1/27.
//

import SwiftUI

struct CollaborationInvitationResponseView: View {
    let invitation: CollaborationInvitation
    @StateObject private var invitationManager = CollaborationInvitationManager()
    @Environment(\.presentationMode) var presentationMode

    // 协商相关状态
    @State private var showingNegotiationView = false
    @State private var showingWechatAlert = false
    @State private var showingMaybeImportAlert = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                    // 标题区域
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                        Text(invitation.title)
                            .font(.system(size: AppTheme.FontSize.title2, weight: .bold))
                            .foregroundColor(AppTheme.Colors.text)

                        HStack {
                            Text("来自: \(invitation.createdBy)")
                                .font(.system(size: AppTheme.FontSize.caption))
                                .foregroundColor(AppTheme.Colors.textSecondary)

                            Spacer()

                            Text(formatDate(invitation.createdAt))
                                .font(.system(size: AppTheme.FontSize.caption))
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                    }

                    // 活动详情
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                        SectionTitle(title: "活动描述")
                        Text(invitation.description)
                            .font(.system(size: AppTheme.FontSize.body))
                            .foregroundColor(AppTheme.Colors.text)
                            .lineLimit(nil)

                        SectionTitle(title: "活动地点")
                        Text(invitation.location)
                            .font(.system(size: AppTheme.FontSize.body))
                            .foregroundColor(AppTheme.Colors.text)

                        SectionTitle(title: "时间安排")
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                            Text("开始时间: \(formatDateTime(invitation.startTime))")
                            Text("持续时间: \(formatDuration(invitation.duration))")
                        }
                        .font(.system(size: AppTheme.FontSize.body))
                        .foregroundColor(AppTheme.Colors.text)
                    }

                    // 协商历史（如果有）
                    if !invitation.negotiationHistory.isEmpty {
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                            SectionTitle(title: "协商记录")
                            ForEach(invitation.negotiationHistory) { record in
                                NegotiationRecordView(record: record)
                            }
                        }
                    }

                    Spacer(minLength: 100)
                }
                .padding(AppTheme.Spacing.lg)
            }
            .navigationTitle("邀请详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            // 响应按钮区域
            VStack(spacing: AppTheme.Spacing.md) {
                HStack(spacing: AppTheme.Spacing.md) {
                    // 好呀
                    ResponseButton(
                        title: "好呀",
                        color: .green,
                        action: {
                            invitationManager.respondToInvitation(invitation, status: .accepted)
                            presentationMode.wrappedValue.dismiss()
                        }
                    )

                    // 商量下呗
                    ResponseButton(
                        title: "商量下呗",
                        color: .blue,
                        action: {
                            showingNegotiationView = true
                        }
                    )
                }

                HStack(spacing: AppTheme.Spacing.md) {
                    // 以后看
                    ResponseButton(
                        title: "以后看",
                        color: .gray,
                        action: {
                            invitationManager.respondToInvitation(invitation, status: .postponed)
                            presentationMode.wrappedValue.dismiss()
                        }
                    )

                    // 微信商量
                    ResponseButton(
                        title: "微信商量",
                        color: .purple,
                        action: {
                            invitationManager.respondToInvitation(invitation, status: .wechatNegotiating)
                            showingWechatAlert = true
                        }
                    )
                }
            }
            .padding(AppTheme.Spacing.lg)
            .background(Color(.systemBackground))
        }
        .sheet(isPresented: $showingNegotiationView) {
            NegotiationView(invitation: invitation) {
                presentationMode.wrappedValue.dismiss()
            }
        }
        .alert("提示", isPresented: $showingWechatAlert) {
            Button("确定") { }
        } message: {
            Text("已通知对方，请通过微信进行协商")
        }
        .alert("提示", isPresented: $showingMaybeImportAlert) {
            Button("确定") { }
        } message: {
            Text("活动已添加到Maybe清单")
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM月dd日 HH:mm"
        return formatter.string(from: date)
    }

    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM月dd日 HH:mm"
        return formatter.string(from: date)
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

// MARK: - 辅助组件
struct SectionTitle: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: AppTheme.FontSize.subheadline, weight: .semibold))
            .foregroundColor(AppTheme.Colors.primary)
            .padding(.top, AppTheme.Spacing.md)
    }
}

struct ResponseButton: View {
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: AppTheme.FontSize.body, weight: .medium))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppTheme.Spacing.md)
                .background(color)
                .cornerRadius(AppTheme.Radius.medium)
        }
    }
}

struct NegotiationRecordView: View {
    let record: NegotiationRecord

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            HStack {
                Text("\(record.proposedBy) 提议")
                    .font(.system(size: AppTheme.FontSize.caption, weight: .medium))
                    .foregroundColor(AppTheme.Colors.primary)

                Spacer()

                Text(formatDate(record.proposedAt))
                    .font(.system(size: AppTheme.FontSize.caption))
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }

            if let newLocation = record.newLocation {
                Text("地点: \(newLocation)")
                    .font(.system(size: AppTheme.FontSize.caption))
                    .foregroundColor(AppTheme.Colors.text)
            }

            if let newStartTime = record.newStartTime {
                Text("时间: \(formatDateTime(newStartTime))")
                    .font(.system(size: AppTheme.FontSize.caption))
                    .foregroundColor(AppTheme.Colors.text)
            }

            if let timeOptions = record.timeOptions, !timeOptions.isEmpty {
                Text("时间选项:")
                    .font(.system(size: AppTheme.FontSize.caption, weight: .medium))
                    .foregroundColor(AppTheme.Colors.text)

                ForEach(timeOptions, id: \.self) { time in
                    Text("• \(formatDateTime(time))")
                        .font(.system(size: AppTheme.FontSize.caption))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }

            if let contentOptions = record.contentOptions, !contentOptions.isEmpty {
                Text("内容选项:")
                    .font(.system(size: AppTheme.FontSize.caption, weight: .medium))
                    .foregroundColor(AppTheme.Colors.text)

                ForEach(contentOptions, id: \.self) { content in
                    Text("• \(content)")
                        .font(.system(size: AppTheme.FontSize.caption))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.bgMain)
        .cornerRadius(AppTheme.Radius.small)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM月dd日 HH:mm"
        return formatter.string(from: date)
    }

    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM月dd日 HH:mm"
        return formatter.string(from: date)
    }
}

#Preview {
    CollaborationInvitationResponseView(invitation: CollaborationInvitation(
        title: "周末看电影",
        description: "一起去电影院看最新上映的电影，然后吃晚饭",
        location: "万达影城",
        startTime: Date().addingTimeInterval(86400 * 2),
        duration: 7200,
        createdBy: "用户A"
    ))
}