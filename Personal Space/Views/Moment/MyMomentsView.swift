//
//  MyMomentsView.swift
//  Personal Space
//
//  Created by Penn on 2025/1/27.
//

import SwiftUI

struct MyMomentsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var userState: UserState
    
    @State private var momentToDelete: Moment?
    @State private var showingDeleteAlert = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    if userState.myMoments.isEmpty {
                        emptyStateView
                    } else {
                        ForEach(userState.myMoments) { moment in
                            MomentCardView(moment: moment, showAuthor: false)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        momentToDelete = moment
                                        showingDeleteAlert = true
                                    } label: {
                                        Label("删除", systemImage: "trash")
                                    }
                                }
                        }
                    }
                }
                .padding(AppTheme.Spacing.lg)
            }
            .navigationTitle("我的动态")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
            .alert("删除瞬间", isPresented: $showingDeleteAlert) {
                Button("取消", role: .cancel) { }
                Button("删除", role: .destructive) {
                    if let moment = momentToDelete {
                        userState.deleteMoment(moment)
                    }
                }
            } message: {
                Text("确定要删除这条瞬间吗？")
            }
        }
    }
    
    // MARK: - 空状态视图
    
    private var emptyStateView: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Spacer()
            
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 60))
                .foregroundColor(AppTheme.Colors.textSecondary.opacity(0.5))
            
            Text("还没有发布瞬间")
                .font(.system(size: AppTheme.FontSize.title3, weight: .medium))
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            Text("点击右下角"+"按钮发布你的第一条瞬间")
                .font(.system(size: AppTheme.FontSize.body))
                .foregroundColor(AppTheme.Colors.textSecondary.opacity(0.7))
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(AppTheme.Spacing.xl)
    }
}

#Preview {
    MyMomentsView()
        .environmentObject(UserState())
}

