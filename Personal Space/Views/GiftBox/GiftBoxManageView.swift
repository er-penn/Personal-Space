//
//  GiftBoxManageView.swift
//  Personal Space
//
//  Created by Penn on 2025/1/27.
//

import SwiftUI

struct GiftBoxManageView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var userState: UserState

    @State private var showingCreateView = false
    @State private var showingEditView = false
    @State private var selectedGiftBox: GiftBox?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    // 我的心意盒列表
                    if userState.myGiftBoxes.isEmpty {
                        emptyStateView
                    } else {
                        LazyVStack(spacing: AppTheme.Spacing.md) {
                            ForEach(userState.myGiftBoxes) { giftBox in
                                GiftBoxCardView(
                                    giftBox: giftBox,
                                    onWithdraw: {
                                        withdrawGiftBox(giftBox)
                                    },
                                    onEditAndResend: {
                                        editAndResendGiftBox(giftBox)
                                    },
                                    onCreatePeacefulClosure: {
                                        createPeacefulClosureFromGiftBox(giftBox)
                                    }
                                )
                            }
                        }
                    }

                    Spacer(minLength: 100)
                }
                .padding(AppTheme.Spacing.lg)
            }
            .background(AppGradient.background)
            .navigationTitle("我的心意盒")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(AppTheme.Colors.text)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingCreateView = true
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(AppTheme.Colors.primary)
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showingCreateView) {
            GiftBoxCreateView()
                .environmentObject(userState)
        }
        .sheet(item: $selectedGiftBox) { giftBox in
            if giftBox.status == .pending {
                // 待确认状态只能撤回
                withdrawConfirmationView(for: giftBox)
            } else {
                // 其他状态可以重新编辑
                GiftBoxEditView(giftBox: giftBox)
                    .environmentObject(userState)
            }
        }
    }

    // MARK: - 视图组件

    private var emptyStateView: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Image(systemName: "gift.circle")
                .font(.system(size: 60))
                .foregroundColor(AppTheme.Colors.textSecondary.opacity(0.6))

            VStack(spacing: AppTheme.Spacing.sm) {
                Text("还没有心意盒")
                    .font(.system(size: AppTheme.FontSize.headline, weight: .medium))
                    .foregroundColor(AppTheme.Colors.text)

                Text("点击右上角的 + 号创建你的第一个心意盒")
                    .font(.system(size: AppTheme.FontSize.body))
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Button(action: {
                showingCreateView = true
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                    Text("创建心意盒")
                        .font(.system(size: AppTheme.FontSize.headline, weight: .medium))
                }
                .foregroundColor(.white)
                .padding(.horizontal, AppTheme.Spacing.lg)
                .padding(.vertical, AppTheme.Spacing.md)
                .background(AppTheme.Colors.primary)
                .cornerRadius(AppTheme.Radius.large)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(AppTheme.Spacing.xl)
    }

    private func withdrawConfirmationView(for giftBox: GiftBox) -> some View {
        NavigationView {
            VStack(spacing: AppTheme.Spacing.lg) {
                Spacer()

                VStack(spacing: AppTheme.Spacing.md) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.orange)

                    Text("撤回心意盒")
                        .font(.system(size: AppTheme.FontSize.title2, weight: .bold))
                        .foregroundColor(AppTheme.Colors.text)

                    Text("确定要撤回这个心意盒吗？\n撤回后对方将不再看到这个心意。")
                        .font(.system(size: AppTheme.FontSize.body))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                }

                Spacer()

                VStack(spacing: AppTheme.Spacing.md) {
                    Button("确认撤回") {
                        userState.withdrawGiftBox(giftBox)
                        selectedGiftBox = nil
                    }
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red)
                    .cornerRadius(AppTheme.Radius.large)

                    Button("取消") {
                        selectedGiftBox = nil
                    }
                    .foregroundColor(AppTheme.Colors.primary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(AppTheme.Colors.primary.opacity(0.1))
                    .cornerRadius(AppTheme.Radius.large)
                }
                .padding()
            }
            .padding()
            .background(AppGradient.background)
            .navigationTitle("撤回确认")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        selectedGiftBox = nil
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    // MARK: - 操作方法

    private func withdrawGiftBox(_ giftBox: GiftBox) {
        selectedGiftBox = giftBox
    }

    private func editAndResendGiftBox(_ giftBox: GiftBox) {
        selectedGiftBox = giftBox
    }

    private func createPeacefulClosureFromGiftBox(_ giftBox: GiftBox) {
        // 这里可以跳转到安心确认创建页面，并传入初始数据
        print("基于心意盒创建安心确认: \(giftBox.item)")
        // TODO: 实现跳转逻辑
    }
}

// MARK: - 心意盒卡片视图
struct GiftBoxCardView: View {
    let giftBox: GiftBox
    let onWithdraw: () -> Void
    let onEditAndResend: () -> Void
    let onCreatePeacefulClosure: () -> Void

    var body: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // 头部信息
            headerSection

            // 详细信息
            detailsSection

            // 底部操作
            actionsSection
        }
        .padding()
        .background(AppTheme.Colors.cardBg)
        .cornerRadius(AppTheme.Radius.large)
        .shadow(color: AppTheme.Shadows.card, radius: 6, x: 0, y: 3)
    }

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                HStack {
                    Image(systemName: "gift.fill")
                        .font(.system(size: 16))
                        .foregroundColor(AppTheme.Colors.primary)

                    Text(giftBox.item)
                        .font(.system(size: AppTheme.FontSize.subheadline, weight: .semibold))
                        .foregroundColor(AppTheme.Colors.text)
                        .lineLimit(1)
                }

                Text(formatActivityTime(giftBox))
                    .font(.system(size: AppTheme.FontSize.caption))
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }

            Spacer()

            // 状态标签
            Text(giftBox.status.displayText)
                .font(.system(size: AppTheme.FontSize.caption, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, AppTheme.Spacing.sm)
                .padding(.vertical, 4)
                .background(giftBox.status.color)
                .cornerRadius(AppTheme.Radius.small)
        }
    }

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            if !giftBox.suggestedLocation.isEmpty {
                HStack {
                    Image(systemName: "location")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.Colors.textSecondary)

                    Text("建议地点: \(giftBox.suggestedLocation)")
                        .font(.system(size: AppTheme.FontSize.caption))
                        .foregroundColor(AppTheme.Colors.text)
                        .lineLimit(1)
                }
            }

            if let note = giftBox.note, !note.isEmpty {
                HStack(alignment: .top, spacing: AppTheme.Spacing.xs) {
                    Image(systemName: "note.text")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.Colors.textSecondary)

                    Text("备注: \(note)")
                        .font(.system(size: AppTheme.FontSize.caption))
                        .foregroundColor(AppTheme.Colors.text)
                        .lineLimit(2)
                }
            }

            // 接受后的详细信息
            if giftBox.status == .accepted {
                acceptedDetailsView
            }
        }
    }

    private var acceptedDetailsView: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            if giftBox.acceptedStartTime != nil {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.green)

                    Text("接受时间: \(formatAcceptDetails(giftBox))")
                        .font(.system(size: AppTheme.FontSize.caption))
                        .foregroundColor(.green)
                }
            }
        }
    }

    private var actionsSection: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            switch giftBox.status {
            case .pending:
                Button("撤回") {
                    onWithdraw()
                }
                .foregroundColor(.white)
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.sm)
                .background(Color.red)
                .cornerRadius(AppTheme.Radius.medium)

            case .accepted:
                Button("再次编辑发送") {
                    onEditAndResend()
                }
                .foregroundColor(AppTheme.Colors.primary)
                .padding(.horizontal, AppTheme.Spacing.sm)
                .padding(.vertical, AppTheme.Spacing.sm)
                .background(AppTheme.Colors.primary.opacity(0.1))
                .cornerRadius(AppTheme.Radius.medium)

                Button("发起安心确认") {
                    onCreatePeacefulClosure()
                }
                .foregroundColor(.white)
                .padding(.horizontal, AppTheme.Spacing.sm)
                .padding(.vertical, AppTheme.Spacing.sm)
                .background(AppTheme.Colors.primary)
                .cornerRadius(AppTheme.Radius.medium)

            case .rejected, .expired, .withdrawn:
                Button("再次编辑发送") {
                    onEditAndResend()
                }
                .foregroundColor(AppTheme.Colors.primary)
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.sm)
                .background(AppTheme.Colors.primary.opacity(0.1))
                .cornerRadius(AppTheme.Radius.medium)
            }
        }
    }

    // MARK: - 辅助方法

    private func formatActivityTime(_ giftBox: GiftBox) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd HH:mm"

        if giftBox.status == .pending {
            return "发起: \(formatter.string(from: giftBox.createdAt))"
        } else if let respondedAt = giftBox.respondedAt {
            return "响应: \(formatter.string(from: respondedAt))"
        } else if let lastEditedAt = giftBox.lastEditedAt {
            return "编辑: \(formatter.string(from: lastEditedAt))"
        } else {
            return "发起: \(formatter.string(from: giftBox.createdAt))"
        }
    }

    private func formatAcceptDetails(_ giftBox: GiftBox) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"

        if let startTime = giftBox.acceptedStartTime,
           let endTime = giftBox.acceptedEndTime {
            return "\(formatter.string(from: startTime))-\(formatter.string(from: endTime))"
        } else if let startTime = giftBox.acceptedStartTime,
                  let location = giftBox.actualLocation {
            return "\(formatter.string(from: startTime))起 @\(location)"
        } else {
            return "已接受"
        }
    }
}

// MARK: - 预览
#Preview {
    GiftBoxManageView()
        .environmentObject({
            let state = UserState()
            
            let box1 = GiftBox(
                item: "精美项链",
                note: "希望你喜欢这个小惊喜",
                suggestedLocation: "公司前台",
                preparationTime: 1800,
                isFromMe: true
            )
            
            let box2 = GiftBox(
                item: "奶茶大杯",
                suggestedLocation: "公司茶水间",
                preparationTime: 900,
                isFromMe: true
            )
            
            state.myGiftBoxes = [box1, box2]
            return state
        }())
}