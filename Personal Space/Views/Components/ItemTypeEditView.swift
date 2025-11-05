//
//  ItemTypeEditView.swift
//  Personal Space
//
//  Created by Penn on 2025/1/27.
//

import SwiftUI

struct ItemTypeEditView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var itemTypeManager: ItemTypeManager
    let editingItemType: ItemType?

    @State private var name: String = ""
    @State private var selectedIcon: String = "gift.fill"
    @State private var showingIconPicker = false
    @State private var showingDeleteAlert = false

    // 可选图标列表
    private let availableIcons = [
        "gift.fill", "cup.and.saucer.fill", "fork.knife", "house.fill",
        "heart.fill", "star.fill", "leaf.fill", "flame.fill",
        "moon.fill", "sun.max.fill", "cloud.fill", "snowflake",
        "car.fill", "airplane", "bicycle", "figure.walk",
        "book.fill", "pencil.and.outline", "paintbrush.fill", "camera.fill",
        "gamecontroller.fill", "headphones", "tv.fill", "music.note",
        "cart.fill", "bag.fill", "creditcard.fill", "banknote.fill",
        "pill.fill", "cross.fill", "stethoscope", "tooth.fill",
        "basket.fill", "bottle.fill", "cup.fill", "mug.fill",
        "popcorn.fill", "icecream.fill", "fish.fill", "egg.fill"
    ]

    init(itemTypeManager: ItemTypeManager, editingItemType: ItemType? = nil) {
        self.itemTypeManager = itemTypeManager
        self.editingItemType = editingItemType
        if let editingType = editingItemType {
            _name = State(initialValue: editingType.name)
            _selectedIcon = State(initialValue: editingType.icon)
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    // 名称输入
                    nameSection

                    // 图标选择
                    iconSection

                    // 预览
                    previewSection

                    if editingItemType != nil {
                        // 删除选项
                        deleteSection
                    }

                    Spacer(minLength: 100)
                }
                .padding(AppTheme.Spacing.lg)
            }
            .background(AppGradient.background)
            .navigationTitle(editingItemType == nil ? "新增类别" : "编辑类别")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(AppTheme.Colors.text)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveItemType()
                    }
                    .foregroundColor(isFormValid ? AppTheme.Colors.primary : AppTheme.Colors.textSecondary)
                    .disabled(!isFormValid)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showingIconPicker) {
            iconPickerSheet
        }
        .alert("删除类别", isPresented: $showingDeleteAlert) {
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) {
                deleteItemType()
            }
        } message: {
            Text("确定要删除类别「\(editingItemType?.name ?? "")」吗？此操作不可撤销。")
        }
    }

    // MARK: - 视图组件

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack {
                Image(systemName: "textformat")
                    .font(.system(size: 20))
                    .foregroundColor(AppTheme.Colors.primary)

                Text("类别名称")
                    .font(.system(size: AppTheme.FontSize.headline, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.text)

                Text("*")
                    .font(.system(size: AppTheme.FontSize.headline, weight: .bold))
                    .foregroundColor(.red)
            }

            TextField("请输入类别名称", text: $name)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
        .padding()
        .background(AppTheme.Colors.cardBg)
        .cornerRadius(AppTheme.Radius.large)
        .shadow(color: AppTheme.Shadows.card, radius: 6, x: 0, y: 3)
    }

    private var iconSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack {
                Image(systemName: "photo")
                    .font(.system(size: 20))
                    .foregroundColor(AppTheme.Colors.primary)

                Text("图标")
                    .font(.system(size: AppTheme.FontSize.headline, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.text)

                Text("*")
                    .font(.system(size: AppTheme.FontSize.headline, weight: .bold))
                    .foregroundColor(.red)
            }

            Button(action: {
                showingIconPicker = true
            }) {
                HStack {
                    Image(systemName: selectedIcon)
                        .font(.system(size: 24))
                        .foregroundColor(AppTheme.Colors.primary)

                    Text("选择图标")
                        .font(.system(size: AppTheme.FontSize.body))
                        .foregroundColor(AppTheme.Colors.text)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                .padding()
                .background(AppTheme.Colors.cardBg.opacity(0.5))
                .cornerRadius(AppTheme.Radius.medium)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
        .background(AppTheme.Colors.cardBg)
        .cornerRadius(AppTheme.Radius.large)
        .shadow(color: AppTheme.Shadows.card, radius: 6, x: 0, y: 3)
    }

    private var previewSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack {
                Image(systemName: "eye")
                    .font(.system(size: 20))
                    .foregroundColor(AppTheme.Colors.primary)

                Text("预览效果")
                    .font(.system(size: AppTheme.FontSize.headline, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.text)
            }

            HStack(spacing: AppTheme.Spacing.xs) {
                Image(systemName: selectedIcon)
                    .font(.system(size: 16))
                Text(name.isEmpty ? "类别名称" : name)
                    .font(.system(size: AppTheme.FontSize.caption, weight: .medium))
            }
            .foregroundColor(AppTheme.Colors.primary)
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.sm)
            .background(AppTheme.Colors.primary.opacity(0.1))
            .cornerRadius(AppTheme.Radius.medium)
        }
        .padding()
        .background(AppTheme.Colors.cardBg)
        .cornerRadius(AppTheme.Radius.large)
        .shadow(color: AppTheme.Shadows.card, radius: 6, x: 0, y: 3)
    }

    private var deleteSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack {
                Image(systemName: "trash")
                    .font(.system(size: 20))
                    .foregroundColor(.red)

                Text("删除类别")
                    .font(.system(size: AppTheme.FontSize.headline, weight: .semibold))
                    .foregroundColor(.red)
            }

            Button(action: {
                showingDeleteAlert = true
            }) {
                HStack {
                    Image(systemName: "trash.fill")
                        .foregroundColor(.white)
                    Text("确认删除")
                        .foregroundColor(.white)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.red)
                .cornerRadius(AppTheme.Radius.medium)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
        .background(AppTheme.Colors.cardBg)
        .cornerRadius(AppTheme.Radius.large)
        .shadow(color: AppTheme.Shadows.card, radius: 6, x: 0, y: 3)
    }

    private var iconPickerSheet: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: AppTheme.Spacing.sm) {
                    ForEach(availableIcons, id: \.self) { icon in
                        Button(action: {
                            selectedIcon = icon
                            showingIconPicker = false
                        }) {
                            Image(systemName: icon)
                                .font(.system(size: 24))
                                .foregroundColor(selectedIcon == icon ? AppTheme.Colors.primary : AppTheme.Colors.text)
                                .frame(width: 60, height: 60)
                                .background(selectedIcon == icon ? AppTheme.Colors.primary.opacity(0.1) : AppTheme.Colors.cardBg)
                                .cornerRadius(AppTheme.Radius.medium)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding()
            }
            .navigationTitle("选择图标")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        showingIconPicker = false
                    }
                    .foregroundColor(AppTheme.Colors.text)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    // MARK: - 辅助方法

    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !selectedIcon.isEmpty
    }

    private func saveItemType() {
        guard isFormValid else { return }

        if let editingType = editingItemType {
            // 更新现有类别
            let updatedType = ItemType(
                id: editingType.id,
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                icon: selectedIcon,
                color: editingType.color,
                isDefault: editingType.isDefault,
                createdAt: editingType.createdAt
            )
            itemTypeManager.updateItemType(updatedType)
        } else {
            // 添加新类别
            let newItemType = ItemType(
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                icon: selectedIcon
            )
            itemTypeManager.addItemType(newItemType)
        }

        presentationMode.wrappedValue.dismiss()
    }

    private func deleteItemType() {
        guard let editingType = editingItemType else { return }

        if let index = itemTypeManager.itemTypes.firstIndex(where: { $0.id == editingType.id }) {
            itemTypeManager.deleteItemType(at: IndexSet([index]))
        }

        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - 预览
#Preview {
    ItemTypeEditView(itemTypeManager: ItemTypeManager())
}