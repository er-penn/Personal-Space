//
//  NegotiationOptionsView.swift
//  Personal Space
//
//  Created by Penn on 2025/1/27.
//

import SwiftUI

struct NegotiationOptionsView: View {
    let invitation: CollaborationInvitation
    let onDismiss: () -> Void

    @Environment(\.presentationMode) var presentationMode
    @StateObject private var invitationManager = CollaborationInvitationManager()
    @State private var showingWechatAlert = false
    @State private var showingNegotiationView = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    // 提示信息
                    VStack(spacing: AppTheme.Spacing.md) {
                        Image(systemName: "message.circle")
                            .font(.system(size: 48))
                            .foregroundColor(AppTheme.Colors.primary)

                        Text("选择协商方式")
                            .font(.system(size: AppTheme.FontSize.title2, weight: .semibold))
                            .foregroundColor(AppTheme.Colors.text)

                        Text("您可以通过以下两种方式与对方协商")
                            .font(.system(size: AppTheme.FontSize.body))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, AppTheme.Spacing.xl)

                    // 协商方式选项
                    VStack(spacing: AppTheme.Spacing.lg) {
                        // 选项1：修改后推送确认
                        NegotiationOptionCard(
                            icon: "square.and.pencil",
                            title: "修改后推送确认",
                            description: "修改活动时间、地点、持续时间、活动内容，可提供多个选项供对方选择",
                            color: AppTheme.Colors.primary,
                            action: {
                                showingNegotiationView = true
                            }
                        )

                        // 选项2：直接微信商量
                        NegotiationOptionCard(
                            icon: "message.fill",
                            title: "直接微信商量",
                            description: "不修改任何内容，直接点击后对方收到微信商量通知",
                            color: .purple,
                            action: {
                                handleWechatNegotiation()
                            }
                        )
                    }

                    Spacer(minLength: 100)
                }
                .padding(AppTheme.Spacing.lg)
            }
            .navigationTitle("商量下呗")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        onDismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingNegotiationView) {
            NegotiationView(invitation: invitation) {
                onDismiss()
            }
        }
        .alert("提示", isPresented: $showingWechatAlert) {
            Button("确定") {
                onDismiss()
            }
        } message: {
            Text("已通知对方，请通过微信进行协商")
        }
    }

    private func handleWechatNegotiation() {
        // 按需求文档：直接微信商量，创建待办事项（仅可手动关闭）
        invitationManager.respondToInvitation(invitation, status: .wechatNegotiating)

        // 创建微信商量待办事项（仅可手动关闭）
        let wechatTodoItem = TodoItem(
            id: UUID(),
            title: "微信商量：\(invitation.title)",
            description: "与对方微信协商活动详情",
            location: nil,
            startTime: Date(),
            endTime: nil,
            isAutoDismiss: false, // 仅可手动关闭
            type: .wechatNegotiation,
            relatedInvitationId: invitation.id
        )

        invitationManager.addTodoItem(wechatTodoItem)
        showingWechatAlert = true
    }
}

// MARK: - 协商选项卡片
struct NegotiationOptionCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: AppTheme.Spacing.md) {
                HStack(spacing: AppTheme.Spacing.md) {
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(color)
                        .frame(width: 32, height: 32)

                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        Text(title)
                            .font(.system(size: AppTheme.FontSize.headline, weight: .semibold))
                            .foregroundColor(AppTheme.Colors.text)

                        Text(description)
                            .font(.system(size: AppTheme.FontSize.body))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .multilineTextAlignment(.leading)
                            .lineLimit(nil)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 16))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                .padding(AppTheme.Spacing.md)
            }
            .background(AppTheme.Colors.cardBg)
            .cornerRadius(AppTheme.Radius.large)
            .shadow(color: AppTheme.Shadows.card, radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    NegotiationOptionsView(invitation: CollaborationInvitation(
        title: "周末看电影",
        description: "一起去电影院看最新上映的电影",
        location: "万达影城",
        startTime: Date().addingTimeInterval(86400 * 2),
        duration: 7200,
        createdBy: "用户A"
    )) {
        // dismiss action
    }
}