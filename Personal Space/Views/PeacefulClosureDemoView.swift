//
//  PeacefulClosureDemoView.swift
//  Personal Space
//
//  Created by Penn on 2025/1/27.
//

import SwiftUI

struct PeacefulClosureDemoView: View {
    @EnvironmentObject var userState: UserState
    @State private var showingCreateView = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    // 创建按钮
                    Button(action: {
                        showingCreateView = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 20))
                            Text("创建安心确认")
                                .font(.system(size: AppTheme.FontSize.headline, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(AppTheme.Colors.primary)
                        .cornerRadius(AppTheme.Radius.medium)
                    }

                    // 分段显示
                    VStack(spacing: AppTheme.Spacing.lg) {
                        // 待处理部分
                        pendingSection

                        // 我发起的部分
                        myClosuresSection

                        // 所有记录部分
                        allClosuresSection
                    }
                }
                .padding(AppTheme.Spacing.lg)
            }
            .background(AppGradient.background)
            .navigationTitle("安心确认演示")
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showingCreateView) {
            PeacefulClosureCreateView()
                .environmentObject(userState)
        }
        .onAppear {
            // 加载示例数据
            if userState.peacefulClosures.isEmpty {
                userState.loadSamplePeacefulClosures()
            }
            userState.updatePendingClosures()
        }
    }

    // MARK: - 待处理部分
    private var pendingSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("待处理事项")
                .font(.system(size: AppTheme.FontSize.headline, weight: .semibold))
                .foregroundColor(AppTheme.Colors.text)

            if userState.pendingClosures.isEmpty {
                Text("暂无待处理事项")
                    .font(.system(size: AppTheme.FontSize.body))
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppTheme.Spacing.lg)
                    .background(AppTheme.Colors.cardBg)
                    .cornerRadius(AppTheme.Radius.medium)
            } else {
                ForEach(userState.pendingClosures) { closure in
                    PendingPeacefulClosureCardView(closure: closure) { response in
                        userState.respondToClosure(closure, response: response)
                    }
                }
            }
        }
    }

    // MARK: - 我发起的部分
    private var myClosuresSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("我发起的")
                .font(.system(size: AppTheme.FontSize.headline, weight: .semibold))
                .foregroundColor(AppTheme.Colors.text)

            let myActiveClosures = userState.myClosures.filter { $0.status != .archived }

            if myActiveClosures.isEmpty {
                Text("暂无发起事项")
                    .font(.system(size: AppTheme.FontSize.body))
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppTheme.Spacing.lg)
                    .background(AppTheme.Colors.cardBg)
                    .cornerRadius(AppTheme.Radius.medium)
            } else {
                ForEach(myActiveClosures) { closure in
                    PeacefulClosureCardView(closure: closure)
                }
            }
        }
    }

    // MARK: - 所有记录部分
    private var allClosuresSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("所有记录")
                .font(.system(size: AppTheme.FontSize.headline, weight: .semibold))
                .foregroundColor(AppTheme.Colors.text)

            if userState.peacefulClosures.isEmpty {
                Text("暂无记录")
                    .font(.system(size: AppTheme.FontSize.body))
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppTheme.Spacing.lg)
                    .background(AppTheme.Colors.cardBg)
                    .cornerRadius(AppTheme.Radius.medium)
            } else {
                ForEach(userState.peacefulClosures) { closure in
                    PeacefulClosureCardView(closure: closure)
                }
            }
        }
    }
}

#Preview {
    PeacefulClosureDemoView()
        .environmentObject(UserState())
}