//
//  MomentCardView.swift
//  Personal Space
//
//  Created by Penn on 2025/1/27.
//

import SwiftUI

struct MomentCardView: View {
    let moment: Moment
    let showAuthor: Bool // 是否显示作者信息
    let allowInteraction: Bool // 是否允许点赞/评论交互
    @EnvironmentObject var userState: UserState
    
    @State private var isLiked: Bool = false
    @State private var localLikes: Int
    @State private var showingCommentSheet = false
    
    init(moment: Moment, showAuthor: Bool = false, allowInteraction: Bool = true) {
        self.moment = moment
        self.showAuthor = showAuthor
        self.allowInteraction = allowInteraction
        self._localLikes = State(initialValue: moment.likes)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            // 头部：作者和时间
            headerSection
            
            // 图片网格
            if !moment.images.isEmpty {
                imageGridSection
            }
            
            // 文案内容
            contentSection
            
            // 底部：点赞和评论
            footerSection
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.cardBg)
        .cornerRadius(AppTheme.Radius.medium)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - 头部
    
    private var headerSection: some View {
        HStack {
            if showAuthor {
                // 作者头像
                Circle()
                    .fill(moment.isFromMe ? AppTheme.Colors.primary : Color.purple)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(moment.isFromMe ? "我" : "TA")
                            .font(.system(size: AppTheme.FontSize.body, weight: .semibold))
                            .foregroundColor(.white)
                    )
            }
            
            VStack(alignment: .leading, spacing: 2) {
                if showAuthor {
                    Text(moment.isFromMe ? "我" : "伴侣")
                        .font(.system(size: AppTheme.FontSize.body, weight: .medium))
                        .foregroundColor(AppTheme.Colors.text)
                }
                
                Text(formatDate(moment.createdAt))
                    .font(.system(size: AppTheme.FontSize.caption))
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            
            Spacer()
        }
    }
    
    // MARK: - 图片网格
    
    private var imageGridSection: some View {
        let columns = [
            GridItem(.flexible(), spacing: 8),
            GridItem(.flexible(), spacing: 8),
            GridItem(.flexible(), spacing: 8)
        ]
        
        return LazyVGrid(columns: columns, spacing: 8) {
            ForEach(Array(moment.images.enumerated()), id: \.offset) { index, imageURL in
                imagePlaceholder
                    .aspectRatio(1, contentMode: .fill)
                    .clipped()
                    .cornerRadius(AppTheme.Radius.small)
            }
        }
    }
    
    private var imagePlaceholder: some View {
        RoundedRectangle(cornerRadius: AppTheme.Radius.small)
            .fill(Color.gray.opacity(0.2))
            .overlay(
                Image(systemName: "photo")
                    .font(.system(size: 30))
                    .foregroundColor(.gray.opacity(0.5))
            )
    }
    
    // MARK: - 文案内容
    
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            if moment.shouldShowText {
                // 显示文案
                Text(moment.content)
                    .font(.system(size: AppTheme.FontSize.body))
                    .foregroundColor(AppTheme.Colors.text)
                    .lineSpacing(4)
            } else {
                // 隐藏文案提示
                HStack(spacing: AppTheme.Spacing.sm) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    
                    Text("文案将在 \(moment.remainingHiddenDays) 天后显示")
                        .font(.system(size: AppTheme.FontSize.caption))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                .padding(.vertical, AppTheme.Spacing.sm)
                .padding(.horizontal, AppTheme.Spacing.md)
                .background(AppTheme.Colors.textSecondary.opacity(0.1))
                .cornerRadius(AppTheme.Radius.small)
            }
        }
    }
    
    // MARK: - 底部
    
    private var footerSection: some View {
        HStack(spacing: AppTheme.Spacing.xl) {
            // 点赞
            Button {
                if allowInteraction {
                    handleLike()
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .font(.system(size: 16))
                        .foregroundColor(isLiked ? .red : AppTheme.Colors.textSecondary)
                    Text("\(localLikes)")
                        .font(.system(size: AppTheme.FontSize.caption))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
            .disabled(!allowInteraction)
            
            // 评论
            Button {
                if allowInteraction {
                    showingCommentSheet = true
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "bubble.right")
                        .font(.system(size: 16))
                    Text("\(moment.comments)")
                        .font(.system(size: AppTheme.FontSize.caption))
                }
                .foregroundColor(AppTheme.Colors.textSecondary)
            }
            .disabled(!allowInteraction)
            
            Spacer()
        }
        .sheet(isPresented: $showingCommentSheet) {
            CommentSheetView(moment: moment)
        }
    }
    
    // MARK: - 点赞处理
    
    private func handleLike() {
        withAnimation(.easeInOut(duration: 0.2)) {
            isLiked.toggle()
            localLikes += isLiked ? 1 : -1
        }
        
        // 触觉反馈
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        // TODO: 实际应用中需要同步到服务器
        print(isLiked ? "❤️ 点赞瞬间：\(moment.id)" : "💔 取消点赞：\(moment.id)")
    }
    
    // MARK: - 日期格式化
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - 评论弹窗

struct CommentSheetView: View {
    @Environment(\.dismiss) var dismiss
    let moment: Moment
    @State private var commentText: String = ""
    @State private var comments: [CommentItem] = []
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 评论列表
                if comments.isEmpty {
                    VStack(spacing: AppTheme.Spacing.lg) {
                        Spacer()
                        
                        Image(systemName: "bubble.right")
                            .font(.system(size: 50))
                            .foregroundColor(AppTheme.Colors.textSecondary.opacity(0.5))
                        
                        Text("暂无评论")
                            .font(.system(size: AppTheme.FontSize.body))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                        
                        Text("成为第一个评论的人吧")
                            .font(.system(size: AppTheme.FontSize.caption))
                            .foregroundColor(AppTheme.Colors.textSecondary.opacity(0.7))
                        
                        Spacer()
                    }
                } else {
                    ScrollView {
                        VStack(spacing: AppTheme.Spacing.md) {
                            ForEach(comments) { comment in
                                CommentItemView(comment: comment)
                            }
                        }
                        .padding(AppTheme.Spacing.lg)
                    }
                }
                
                Divider()
                
                // 评论输入框
                HStack(spacing: AppTheme.Spacing.sm) {
                    TextField("说点什么...", text: $commentText)
                        .padding(AppTheme.Spacing.sm)
                        .background(AppTheme.Colors.bgMain)
                        .cornerRadius(AppTheme.Radius.medium)
                    
                    Button {
                        sendComment()
                    } label: {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 20))
                            .foregroundColor(commentText.isEmpty ? AppTheme.Colors.textSecondary : AppTheme.Colors.primary)
                    }
                    .disabled(commentText.isEmpty)
                }
                .padding(AppTheme.Spacing.lg)
            }
            .navigationTitle("评论 (\(comments.count))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            // TODO: 加载评论数据
            loadComments()
        }
    }
    
    private func loadComments() {
        // 模拟加载评论
        comments = []
    }
    
    private func sendComment() {
        guard !commentText.isEmpty else { return }
        
        let newComment = CommentItem(
            content: commentText,
            authorName: "我",
            createdAt: Date()
        )
        
        comments.insert(newComment, at: 0)
        commentText = ""
        
        // 触觉反馈
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // TODO: 实际应用中需要同步到服务器
        print("💬 发表评论：\(newComment.content)")
    }
}

// MARK: - 评论项数据模型

struct CommentItem: Identifiable {
    let id = UUID()
    let content: String
    let authorName: String
    let createdAt: Date
}

// MARK: - 评论项视图

struct CommentItemView: View {
    let comment: CommentItem
    
    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
            // 头像
            Circle()
                .fill(AppTheme.Colors.primary)
                .frame(width: 36, height: 36)
                .overlay(
                    Text(String(comment.authorName.prefix(1)))
                        .font(.system(size: AppTheme.FontSize.body, weight: .semibold))
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(comment.authorName)
                        .font(.system(size: AppTheme.FontSize.body, weight: .medium))
                        .foregroundColor(AppTheme.Colors.text)
                    
                    Spacer()
                    
                    Text(formatDate(comment.createdAt))
                        .font(.system(size: AppTheme.FontSize.caption))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                
                Text(comment.content)
                    .font(.system(size: AppTheme.FontSize.body))
                    .foregroundColor(AppTheme.Colors.text)
                    .lineSpacing(4)
            }
        }
        .padding(AppTheme.Spacing.sm)
        .background(AppTheme.Colors.bgMain)
        .cornerRadius(AppTheme.Radius.small)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    VStack(spacing: 16) {
        // 文案可见的瞬间
        MomentCardView(
            moment: Moment(
                content: "今天天气超级好，去了海边看日落 🌅 心情特别平静",
                images: ["img1", "img2"],
                createdAt: Date().addingTimeInterval(-5 * 24 * 3600),
                isFromMe: false,
                isTextHidden: true,
                likes: 10,
                comments: 3
            ),
            showAuthor: true
        )
        .environmentObject(UserState())
        
        // 文案隐藏的瞬间
        MomentCardView(
            moment: Moment(
                content: "这是被隐藏的文案内容",
                images: ["img1"],
                createdAt: Date().addingTimeInterval(-1 * 24 * 3600),
                isFromMe: false,
                isTextHidden: true,
                likes: 5,
                comments: 1
            ),
            showAuthor: true
        )
        .environmentObject(UserState())
    }
    .padding()
}

