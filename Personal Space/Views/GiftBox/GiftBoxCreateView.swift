//
//  GiftBoxCreateView.swift
//  Personal Space
//
//  Created by Penn on 2025/1/27.
//

import SwiftUI

struct GiftBoxCreateView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var userState: UserState
    @State private var showingAddItemType = false
    @State private var editingItemType: ItemType? = nil
    @State private var refreshID = UUID() // 用于强制刷新列表

    @State private var item: String = ""
    @State private var note: String = ""
    @State private var suggestedLocation: String = ""
    @State private var preparationTime: TimeInterval = 1800 // 默认30分钟
    @State private var hasExpiration: Bool = false
    @State private var expiresAt: Date = Date().addingTimeInterval(7 * 24 * 3600) // 默认7天后

    @State private var showingExpirationPicker = false
    @State private var selectedDays = 0
    @State private var selectedHours = 0
    @State private var selectedMinutes = 30

    // 表单验证
    private var isFormValid: Bool {
        !item.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !suggestedLocation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    // 物品输入
                    itemSection

                    // 备注输入
                    noteSection

                    // 地点
                    locationSection

                    // 心意准备时间
                    preparationTimeSection

                    // 有效期设置
                    expirationSection

                    Spacer(minLength: 100)
                }
                .padding(AppTheme.Spacing.lg)
            }
            .background(AppGradient.background)
            .navigationTitle("新建心意")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(AppTheme.Colors.text)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("创建") {
                        createGiftBox()
                    }
                    .foregroundColor(isFormValid ? AppTheme.Colors.primary : AppTheme.Colors.textSecondary)
                    .disabled(!isFormValid)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showingExpirationPicker) {
            expirationDatePicker
        }
        .onAppear {
            initializeTimePicker()
        }
        .sheet(isPresented: $showingAddItemType) {
            ItemTypeEditView(itemTypeManager: userState.itemTypeManager)
                .onDisappear {
                    refreshItemTypeList()
                }
        }
        .sheet(item: $editingItemType) { itemType in
            ItemTypeEditView(itemTypeManager: userState.itemTypeManager, editingItemType: itemType)
                .onDisappear {
                    refreshItemTypeList()
                }
        }
    }

    // MARK: - 视图组件

    private var itemSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack {
                Image(systemName: "gift.fill")
                    .font(.system(size: 20))
                    .foregroundColor(AppTheme.Colors.primary)

                Text("物品")
                    .font(.system(size: AppTheme.FontSize.headline, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.text)

                Text("*")
                    .font(.system(size: AppTheme.FontSize.headline, weight: .bold))
                    .foregroundColor(.red)
            }

            // 物品输入框
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                TextField("请输入物品名称", text: $item)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)

                // 快速选择标签
                Text("快速选择:")
                    .font(.system(size: AppTheme.FontSize.caption))
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .padding(.horizontal)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppTheme.Spacing.sm) {
                        ForEach(userState.itemTypeManager.itemTypes, id: \.id) { type in
                            itemTypeButtons(type: type)
                                .simultaneousGesture(
                                    LongPressGesture(minimumDuration: 0.5)
                                        .onEnded { _ in
                                            editingItemType = type
                                        }
                                )
                                .id("\(type.id)-\(refreshID)") // 强制刷新每个按钮
                        }

                        // 新增按钮
                        Button(action: {
                            showingAddItemType = true
                        }) {
                            HStack(spacing: AppTheme.Spacing.xs) {
                                Image(systemName: "plus")
                                    .font(.system(size: 16))
                                Text("新增")
                                    .font(.system(size: AppTheme.FontSize.caption, weight: .medium))
                            }
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .padding(.horizontal, AppTheme.Spacing.md)
                            .padding(.vertical, AppTheme.Spacing.sm)
                            .background(AppTheme.Colors.textSecondary.opacity(0.1))
                            .cornerRadius(AppTheme.Radius.medium)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                                    .stroke(AppTheme.Colors.textSecondary, style: StrokeStyle(lineWidth: 1, dash: [5]))
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding()
        .background(AppTheme.Colors.cardBg)
        .cornerRadius(AppTheme.Radius.large)
        .shadow(color: AppTheme.Shadows.card, radius: 6, x: 0, y: 3)
    }

    private func itemTypeButtons(type: ItemType) -> some View {
        VStack(spacing: AppTheme.Spacing.xs) {
            HStack(spacing: AppTheme.Spacing.xs) {
                Image(systemName: type.icon)
                    .font(.system(size: 16))
                Text(type.name)
                    .font(.system(size: AppTheme.FontSize.caption, weight: .medium))
            }
            .foregroundColor(AppTheme.Colors.primary)
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.sm)
            .background(AppTheme.Colors.primary.opacity(0.1))
            .cornerRadius(AppTheme.Radius.medium)
            .contentShape(Rectangle()) // 确保整个区域可点击
            .onTapGesture {
                showItemSuggestions(for: type)
            }
        }
    }

    private var noteSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack {
                Image(systemName: "note.text")
                    .font(.system(size: 20))
                    .foregroundColor(AppTheme.Colors.textSecondary)

                Text("备注")
                    .font(.system(size: AppTheme.FontSize.headline, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.text)

                Text("(选填)")
                    .font(.system(size: AppTheme.FontSize.caption))
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }

            ZStack(alignment: .topLeading) {
                if note.isEmpty {
                    Text("填写一些提示信息...")
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 12)
                }

                TextEditor(text: $note)
                    .frame(minHeight: 80)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(AppTheme.Colors.border, lineWidth: 1)
                    )
            }
            .padding(.horizontal)
        }
        .padding()
        .background(AppTheme.Colors.cardBg)
        .cornerRadius(AppTheme.Radius.large)
        .shadow(color: AppTheme.Shadows.card, radius: 6, x: 0, y: 3)
    }

    private var preparationTimeSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack {
                Image(systemName: "clock.fill")
                    .font(.system(size: 20))
                    .foregroundColor(AppTheme.Colors.primary)

                Text("心意准备时间")
                    .font(.system(size: AppTheme.FontSize.headline, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.text)

                Text("*")
                    .font(.system(size: AppTheme.FontSize.headline, weight: .bold))
                    .foregroundColor(.red)
            }

            Text("对方最早可在当前时间 + 准备时间后接受心意")
                .font(.system(size: AppTheme.FontSize.caption))
                .foregroundColor(AppTheme.Colors.textSecondary)
                .padding(.horizontal)

            // 使用新的时间选择器
            GiftBoxTimePickerView(
                selectedDays: $selectedDays,
                selectedHours: $selectedHours,
                selectedMinutes: $selectedMinutes
            )
            .onChange(of: selectedDays) { _ in updatePreparationTime() }
            .onChange(of: selectedHours) { _ in updatePreparationTime() }
            .onChange(of: selectedMinutes) { _ in updatePreparationTime() }
            .padding(.horizontal)
        }
        .padding()
        .background(AppTheme.Colors.cardBg)
        .cornerRadius(AppTheme.Radius.large)
        .shadow(color: AppTheme.Shadows.card, radius: 6, x: 0, y: 3)
    }

    private func updatePreparationTime() {
        preparationTime = TimeInterval(selectedDays * 24 * 3600 + selectedHours * 3600 + selectedMinutes * 60)
    }

    private var locationSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack {
                Image(systemName: "location.fill")
                    .font(.system(size: 20))
                    .foregroundColor(AppTheme.Colors.primary)

                Text("地点")
                    .font(.system(size: AppTheme.FontSize.headline, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.text)

                Text("*")
                    .font(.system(size: AppTheme.FontSize.headline, weight: .bold))
                    .foregroundColor(.red)
            }

            TextField("请输入地点", text: $suggestedLocation)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
        }
        .padding()
        .background(AppTheme.Colors.cardBg)
        .cornerRadius(AppTheme.Radius.large)
        .shadow(color: AppTheme.Shadows.card, radius: 6, x: 0, y: 3)
    }

    private var expirationSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 20))
                    .foregroundColor(AppTheme.Colors.warning)

                Text("有效期设置")
                    .font(.system(size: AppTheme.FontSize.headline, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.text)
            }

            Toggle("开启有效期", isOn: $hasExpiration)
                .padding(.horizontal)

            if hasExpiration {
                Button(action: {
                    showingExpirationPicker = true
                }) {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(AppTheme.Colors.primary)

                        Text("截止时间: \(formatExpirationDate(expiresAt))")
                            .font(.system(size: AppTheme.FontSize.body))
                            .foregroundColor(AppTheme.Colors.text)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, AppTheme.Spacing.md)
                    .background(AppTheme.Colors.cardBg.opacity(0.5))
                    .cornerRadius(AppTheme.Radius.medium)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal)
            }
        }
        .padding()
        .background(AppTheme.Colors.cardBg)
        .cornerRadius(AppTheme.Radius.large)
        .shadow(color: AppTheme.Shadows.card, radius: 6, x: 0, y: 3)
    }

    private var expirationDatePicker: some View {
        NavigationView {
            VStack {
                DatePicker("选择截止时间", selection: $expiresAt, in: Date()...)
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .padding()

                Spacer()

                Button("确认") {
                    showingExpirationPicker = false
                }
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(AppTheme.Colors.primary)
                .cornerRadius(AppTheme.Radius.large)
                .padding()
            }
            .navigationTitle("设置截止时间")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        showingExpirationPicker = false
                    }
                }
            }
        }
    }

    // MARK: - 辅助方法

    private func initializeTimePicker() {
        let minutes = Int(preparationTime / 60)
        selectedDays = minutes / (24 * 60)
        selectedHours = (minutes % (24 * 60)) / 60
        selectedMinutes = minutes % 60

        // 确保分钟只能是 0, 15, 30, 45
        if selectedMinutes > 0 && selectedMinutes <= 15 {
            selectedMinutes = 15
        } else if selectedMinutes > 15 && selectedMinutes <= 30 {
            selectedMinutes = 30
        } else if selectedMinutes > 30 && selectedMinutes <= 45 {
            selectedMinutes = 45
        }
    }

    private func refreshItemTypeList() {
        // 强制刷新快速选择列表，但不清空其他表单数据
        refreshID = UUID()
    }

    private func showItemSuggestions(for type: ItemType) {
        // 填充类别名称，保持神秘感
        item = type.name
    }

    private func formatPreparationTime(_ time: TimeInterval) -> String {
        let minutes = Int(time / 60)
        if minutes < 60 {
            return "\(minutes)分钟"
        } else {
            let hours = minutes / 60
            return "\(hours)小时"
        }
    }

    private func formatExpirationDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM月dd日 HH:mm"
        return formatter.string(from: date)
    }

    private func createGiftBox() {
        let finalExpiresAt = hasExpiration ? expiresAt : nil

        userState.createGiftBox(
            item: item.trimmingCharacters(in: .whitespacesAndNewlines),
            note: note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : note.trimmingCharacters(in: .whitespacesAndNewlines),
            suggestedLocation: suggestedLocation.trimmingCharacters(in: .whitespacesAndNewlines),
            preparationTime: preparationTime,
            hasExpiration: hasExpiration,
            expiresAt: finalExpiresAt
        )

        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - 预览
#Preview {
    GiftBoxCreateView()
        .environmentObject(UserState())
}