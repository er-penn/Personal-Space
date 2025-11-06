//
//  FragmentInboxView.swift
//  Personal Space
//
//  Created by Penn on 2025/1/27.
//

import SwiftUI

struct FragmentInboxView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var userState: UserState
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    if userState.receivedFragments.isEmpty {
                        emptyStateView
                    } else {
                        // 碎片列表
                        ForEach(userState.receivedFragments) { fragment in
                            FragmentCardView(fragment: fragment)
                        }
                    }
                }
                .padding(AppTheme.Spacing.lg)
            }
            .navigationTitle("TA的分享")
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
    
    // MARK: - 空状态视图
    
    private var emptyStateView: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Spacer()
            
            Image(systemName: "tray")
                .font(.system(size: 60))
                .foregroundColor(AppTheme.Colors.textSecondary.opacity(0.5))
            
            Text("暂无分享碎片")
                .font(.system(size: AppTheme.FontSize.title3, weight: .medium))
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            Text("TA还没有给你发送碎片\n每天可以收到最多2个碎片")
                .font(.system(size: AppTheme.FontSize.body))
                .foregroundColor(AppTheme.Colors.textSecondary.opacity(0.7))
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(AppTheme.Spacing.xl)
    }
}

// MARK: - 碎片卡片视图

struct FragmentCardView: View {
    let fragment: Fragment
    
    @State private var showingFullImage = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            // 头部：时间
            HStack {
                Image(systemName: "clock")
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.Colors.textSecondary)
                
                Text(formatDate(fragment.createdAt))
                    .font(.system(size: AppTheme.FontSize.caption))
                    .foregroundColor(AppTheme.Colors.textSecondary)
                
                Spacer()
            }
            
            // 文字内容
            Text(fragment.content)
                .font(.system(size: AppTheme.FontSize.body))
                .foregroundColor(AppTheme.Colors.text)
                .lineSpacing(4)
            
            // 图片（如果有）
            if let imageURL = fragment.imageURL {
                imageSection(imageURL: imageURL)
            }
            
            // 链接（如果有）
            if let linkURL = fragment.linkURL {
                linkSection(linkURL: linkURL)
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.cardBg)
        .cornerRadius(AppTheme.Radius.medium)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - 图片部分
    
    @ViewBuilder
    private func imageSection(imageURL: String) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            // 占位图片（实际应用中需要异步加载）
            RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                .fill(AppTheme.Colors.cardBg)
                .overlay(
                    VStack {
                        Image(systemName: "photo")
                            .font(.system(size: 40))
                            .foregroundColor(AppTheme.Colors.textSecondary.opacity(0.5))
                        Text("图片占位")
                            .font(.system(size: AppTheme.FontSize.caption))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                )
                .frame(height: 200)
                .onTapGesture {
                    showingFullImage = true
                }
            
            Text("点击查看大图")
                .font(.system(size: AppTheme.FontSize.caption))
                .foregroundColor(AppTheme.Colors.textSecondary.opacity(0.7))
        }
        .sheet(isPresented: $showingFullImage) {
            imageFullScreenView(imageURL: imageURL)
        }
    }
    
    // MARK: - 全屏图片视图
    
    @ViewBuilder
    private func imageFullScreenView(imageURL: String) -> some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                // 占位图片
                RoundedRectangle(cornerRadius: 0)
                    .fill(Color.gray.opacity(0.2))
                    .overlay(
                        VStack {
                            Image(systemName: "photo")
                                .font(.system(size: 80))
                                .foregroundColor(.white.opacity(0.5))
                            Text("图片占位")
                                .font(.system(size: AppTheme.FontSize.body))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    )
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingFullImage = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    }
                }
            }
        }
    }
    
    // MARK: - 链接部分
    
    @ViewBuilder
    private func linkSection(linkURL: String) -> some View {
        Link(destination: URL(string: linkURL) ?? URL(string: "https://example.com")!) {
            HStack {
                Image(systemName: "link")
                    .font(.system(size: 14))
                
                Text(linkURL)
                    .font(.system(size: AppTheme.FontSize.caption))
                    .lineLimit(1)
                
                Spacer()
                
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12))
            }
            .foregroundColor(AppTheme.Colors.primary)
            .padding(AppTheme.Spacing.sm)
            .background(AppTheme.Colors.primary.opacity(0.1))
            .cornerRadius(AppTheme.Radius.small)
        }
    }
    
    // MARK: - 日期格式化
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    FragmentInboxView()
        .environmentObject(UserState())
}

