//
//  PartnerMomentsView.swift
//  Personal Space
//
//  Created by Penn on 2025/1/27.
//

import SwiftUI

struct PartnerMomentsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var userState: UserState
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    if userState.partnerMoments.isEmpty {
                        emptyStateView
                    } else {
                        ForEach(userState.partnerMoments) { moment in
                            MomentCardView(moment: moment, showAuthor: false)
                        }
                    }
                }
                .padding(AppTheme.Spacing.lg)
            }
            .navigationTitle("TA的瞬间")
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
            
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 60))
                .foregroundColor(AppTheme.Colors.textSecondary.opacity(0.5))
            
            Text("暂无瞬间")
                .font(.system(size: AppTheme.FontSize.title3, weight: .medium))
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            Text("TA还没有发布瞬间")
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
    PartnerMomentsView()
        .environmentObject(UserState())
}

