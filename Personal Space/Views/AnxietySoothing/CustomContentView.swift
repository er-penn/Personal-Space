//
//  CustomContentView.swift
//  Personal Space
//
//  Created by Penn on 2025/1/27.
//

import SwiftUI
import PhotosUI

struct CustomContentView: View {
    @EnvironmentObject var contentManager: CustomContentManager
    @Environment(\.presentationMode) var presentationMode

    @State private var title: String = ""
    @State private var content: String = ""
    @State private var selectedCategory: ContentCategory = .custom
    @State private var tags: String = ""
    @State private var selectedImages: [UIImage] = []
    @State private var showingImagePicker = false
    @State private var showingCamera = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("基本信息")) {
                    TextField("标题", text: $title)
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    Picker("分类", selection: $selectedCategory) {
                        ForEach(ContentCategory.allCases, id: \.self) { category in
                            HStack {
                                Text(category.icon)
                                Text(category.rawValue)
                                Spacer()
                                if selectedCategory == category {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(selectedCategory.color)
                                }
                            }
                            .tag(category)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }

                Section(header: Text("内容")) {
                    TextEditor(text: $content)
                        .frame(minHeight: 120)
                        .overlay(
                            Text(content.isEmpty ? "输入能让你平静下来的内容..." : "")
                                .foregroundColor(.gray)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 8),
                            alignment: .topLeading
                        )
                        .cornerRadius(8)
                }

                Section(header: Text("图片")) {
                    if !selectedImages.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: AppTheme.Spacing.sm) {
                                ForEach(Array(selectedImages.enumerated()), id: \.offset) { index, image in
                                    ZStack(alignment: .topTrailing) {
                                        Image(uiImage: image)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 100, height: 100)
                                            .cornerRadius(8)
                                            .clipped()

                                        Button(action: {
                                            selectedImages.remove(at: index)
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.white)
                                                .background(Color.black.opacity(0.6))
                                                .clipShape(Circle())
                                        }
                                        .padding(4)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }

                    HStack(spacing: AppTheme.Spacing.md) {
                        Button(action: {
                            showingImagePicker = true
                        }) {
                            HStack {
                                Image(systemName: "photo")
                                    .font(.system(size: 20))
                                Text("从相册选择")
                            }
                            .foregroundColor(AppTheme.Colors.primary)
                        }
                        .padding()
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                                .stroke(AppTheme.Colors.primary, lineWidth: 1)
                        )

                        Button(action: {
                            showingCamera = true
                        }) {
                            HStack {
                                Image(systemName: "camera")
                                    .font(.system(size: 20))
                                Text("拍照")
                            }
                            .foregroundColor(AppTheme.Colors.primary)
                        }
                        .padding()
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                                .stroke(AppTheme.Colors.primary, lineWidth: 1)
                        )
                    }
                }

                Section(header: Text("标签")) {
                    TextField("用空格分隔多个标签，例如：放松 平静 阳光", text: $tags)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
            }
            .navigationTitle("添加缓解内容")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(AppTheme.Colors.primary)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveContent()
                    }
                    .disabled(title.isEmpty || content.isEmpty)
                    .foregroundColor(title.isEmpty || content.isEmpty ? .gray : AppTheme.Colors.primary)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImages: $selectedImages)
        }
        .sheet(isPresented: $showingCamera) {
            CameraPicker(selectedImages: $selectedImages)
        }
    }

    // MARK: - 私有方法
    private func saveContent() {
        let tagsArray = tags.trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }

        var newContent = CustomAnxietyContent(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            content: content.trimmingCharacters(in: .whitespacesAndNewlines),
            category: selectedCategory,
            tags: tagsArray
        )

        // 处理图片（保存到本地）
        if !selectedImages.isEmpty {
            newContent = saveImages(newContent)
        }

        contentManager.addContent(newContent)
        presentationMode.wrappedValue.dismiss()
    }

    private func saveImages(_ content: CustomAnxietyContent) -> CustomAnxietyContent {
        // 这里应该保存图片到本地存储并获取路径
        // 为了演示，我们暂时不实现实际的图片保存
        return content
    }
}

// MARK: - 内容卡片视图
struct CustomContentCardView: View {
    let content: CustomAnxietyContent
    let onTap: () -> Void
    let onEdit: (() -> Void)?
    let onFavorite: (() -> Void)?
    let onDelete: (() -> Void)?

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                // 标题行
                HStack {
                    // 分类图标
                    Text(content.category.icon)
                        .font(.system(size: 20))
                        .foregroundColor(content.category.color)

                    // 标题
                    VStack(alignment: .leading, spacing: 4) {
                        Text(content.title)
                            .font(.system(size: AppTheme.FontSize.headline, weight: .semibold))
                            .foregroundColor(AppTheme.Colors.text)
                            .lineLimit(2)

                        Text(formatDate(content.lastAccessed))
                            .font(.system(size: AppTheme.FontSize.caption))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }

                    Spacer()

                    // 收藏图标
                    Button(action: onFavorite ?? {}) {
                        Image(systemName: content.isFavorite ? "heart.fill" : "heart")
                            .font(.system(size: 16))
                            .foregroundColor(content.isFavorite ? .red : .gray)
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                // 内容预览
                Text(content.content)
                    .font(.system(size: AppTheme.FontSize.body))
                    .foregroundColor(AppTheme.Colors.text)
                    .lineLimit(3)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // 图片展示
                if let imagePath = content.imagePath, !imagePath.isEmpty {
                    // 这里应该加载本地图片
                    Image(systemName: "photo")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                        .frame(height: 120)
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(AppTheme.Radius.medium)
                }

                // 标签和访问信息
                HStack {
                    // 标签
                    if !content.tags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 4) {
                                ForEach(content.tags.prefix(3), id: \.self) { tag in
                                    Text("#\(tag)")
                                        .font(.system(size: AppTheme.FontSize.caption))
                                        .foregroundColor(content.category.color)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(content.category.color.opacity(0.1))
                                        .cornerRadius(4)
                                }
                            }
                        }
                    }

                    Spacer()

                    // 访问次数
                    if content.accessCount > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "eye")
                                .font(.system(size: 12))
                            Text("\(content.accessCount)")
                        }
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    }

                    // 操作按钮
                    if onEdit != nil || onDelete != nil {
                        HStack(spacing: 8) {
                            if let onEdit = onEdit {
                                Button(action: onEdit) {
                                    Image(systemName: "square.and.pencil")
                                        .font(.system(size: 14))
                                        .foregroundColor(.blue)
                                }
                            }

                            if let onDelete = onDelete {
                                Button(action: onDelete) {
                                    Image(systemName: "trash")
                                        .font(.system(size: 14))
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }
                }
            }
            .padding(AppTheme.Spacing.md)
            .background(AppTheme.Colors.cardBg)
            .cornerRadius(AppTheme.Radius.medium)
            .shadow(color: AppTheme.Shadows.card, radius: 4, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                    .stroke(content.category.color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture {
            // 长按显示编辑选项
            showActionSheet()
        }
    }

    private func showActionSheet() {
        // 这里可以显示操作菜单
        // 暂时留空
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - 内容列表视图
struct CustomContentListView: View {
    @EnvironmentObject var contentManager: CustomContentManager
    @State private var searchText = ""
    @State private var selectedCategory: ContentCategory?
    @State private var showingCreateView = false
    @State private var showingContentDetail = false
    @State private var selectedContent: CustomAnxietyContent?

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 搜索栏
                SearchBar(text: $searchText)

                // 分类筛选
                if #available(iOS 15.0, *) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: AppTheme.Spacing.sm) {
                            // "全部" 按钮
                            CategoryChip(
                                title: "全部",
                                isSelected: selectedCategory == nil,
                                onTap: { selectedCategory = nil }
                            )

                            ForEach(ContentCategory.allCases, id: \.self) { category in
                                CategoryChip(
                                    title: category.rawValue,
                                    isSelected: selectedCategory == category,
                                    onTap: { selectedCategory = category }
                                )
                            }
                        }
                        .padding(.horizontal, AppTheme.Spacing.lg)
                        .padding(.vertical, AppTheme.Spacing.sm)
                    }
                }

                // 内容列表
                if contentManager.filteredContents.isEmpty {
                    EmptyStateView(
                        icon: "heart.text.square",
                        title: "还没有个性化内容",
                        description: "记录一些能让你平静下来的文字、图片或回忆",
                        actionTitle: "添加内容",
                        action: {
                            showingCreateView = true
                        }
                    )
                    .padding(.top, 60)
                } else {
                    LazyVStack(spacing: AppTheme.Spacing.md) {
                        ForEach(contentManager.filteredContents) { content in
                            CustomContentCardView(
                                content: content,
                                onTap: {
                                    selectedContent = content
                                    contentManager.recordAccess(content)
                                    showingContentDetail = true
                                },
                                onEdit: {
                                    // 这里实现编辑功能
                                },
                                onFavorite: {
                                    contentManager.toggleFavorite(content)
                                },
                                onDelete: {
                                    contentManager.deleteContent(content)
                                }
                            )
                        }
                    }
                    .padding(.horizontal, AppTheme.Spacing.lg)
                }
            }
            .background(AppGradient.background)
            .navigationTitle("我的内容")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingCreateView = true
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 18))
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showingCreateView) {
            CustomContentView()
                .environmentObject(contentManager)
        }
        .sheet(item: $selectedContent) { content in
            ContentDetailView(content: content)
        }
        .onChange(of: searchText) { _ in
            contentManager.searchContents(query: searchText)
        }
        .onChange(of: selectedCategory) { _ in
            contentManager.filterByCategory(selectedCategory)
        }
    }
}

// MARK: - 搜索栏
struct SearchBar: View {
    @Binding var text: String

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)

            TextField("搜索内容...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

// MARK: - 分类标签
struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(.system(size: AppTheme.FontSize.caption, weight: .medium))
                .foregroundColor(isSelected ? .white : AppTheme.Colors.text)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isSelected ? Color.blue : Color(.systemGray5))
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 空状态视图
struct EmptyStateView: View {
    let icon: String
    let title: String
    let description: String
    let actionTitle: String
    let action: () -> Void

    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text(title)
                .font(.system(size: AppTheme.FontSize.headline, weight: .semibold))
                .foregroundColor(AppTheme.Colors.text)

            Text(description)
                .font(.system(size: AppTheme.FontSize.body))
                .foregroundColor(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)

            Button(action: action) {
                Text(actionTitle)
                    .font(.system(size: AppTheme.FontSize.headline, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, AppTheme.Spacing.xl)
                    .padding(.vertical, AppTheme.Spacing.md)
                    .background(AppTheme.Colors.primary)
                    .cornerRadius(AppTheme.Radius.large)
            }
            .padding(.top, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - 内容详情视图
struct ContentDetailView: View {
    let content: CustomAnxietyContent
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var contentManager: CustomContentManager

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                // 头部信息
                VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                    HStack {
                        Text(content.category.icon)
                            .font(.system(size: 24))
                            .foregroundColor(content.category.color)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(content.title)
                                .font(.system(size: AppTheme.FontSize.title2, weight: .bold))
                                .foregroundColor(AppTheme.Colors.text)

                            Text("创建于 \(formatDate(content.createdAt))")
                                .font(.system(size: AppTheme.FontSize.caption))
                                .foregroundColor(AppTheme.Colors.textSecondary)

                            Text("访问 \(content.accessCount) 次")
                                .font(.system(size: AppTheme.FontSize.caption))
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }

                        Spacer()

                        Button(action: {
                            contentManager.toggleFavorite(content)
                        }) {
                            Image(systemName: content.isFavorite ? "heart.fill" : "heart")
                                .font(.system(size: 20))
                                .foregroundColor(content.isFavorite ? .red : .gray)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding()
                .background(AppTheme.Colors.cardBg)
                .cornerRadius(AppTheme.Radius.large)

                // 分类和标签
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    Text("分类")
                        .font(.system(size: AppTheme.FontSize.headline, weight: .semibold))
                        .foregroundColor(AppTheme.Colors.text)

                    HStack(spacing: AppTheme.Spacing.sm) {
                        Text(content.category.icon)
                        Text(content.category.rawValue)
                            .font(.system(size: AppTheme.FontSize.body, weight: .medium))
                            .foregroundColor(content.category.color)
                            .padding(.horizontal, AppTheme.Spacing.sm)
                            .padding(.vertical, AppTheme.Spacing.xs)
                            .background(content.category.color.opacity(0.1))
                            .cornerRadius(AppTheme.Radius.small)
                    }

                    if !content.tags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: AppTheme.Spacing.sm) {
                                ForEach(content.tags, id: \.self) { tag in
                                    Text("#\(tag)")
                                        .font(.system(size: AppTheme.FontSize.caption))
                                        .foregroundColor(content.category.color)
                                        .padding(.horizontal, AppTheme.Spacing.sm)
                                        .padding(.vertical, AppTheme.Spacing.xs)
                                        .background(content.category.color.opacity(0.1))
                                        .cornerRadius(4)
                                }
                            }
                        }
                    }
                }
                .padding()
                .background(AppTheme.Colors.cardBg.opacity(0.5))
                .cornerRadius(AppTheme.Radius.medium)

                // 正文内容
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    Text("内容")
                        .font(.system(size: AppTheme.FontSize.headline, weight: .semibold))
                        .foregroundColor(AppTheme.Colors.text)

                    Text(content.content)
                        .font(.system(size: AppTheme.FontSize.body))
                        .foregroundColor(AppTheme.Colors.text)
                        .lineLimit(nil)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                // 图片内容
                if let imagePath = content.imagePath, !imagePath.isEmpty {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                        Text("图片")
                            .font(.system(size: AppTheme.FontSize.headline, weight: .semibold))
                            .foregroundColor(AppTheme.Colors.text)

                        // 这里应该加载并显示实际图片
                        Image(systemName: "photo")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                            .frame(height: 200)
                            .frame(maxWidth: .infinity)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(AppTheme.Radius.medium)
                    }
                }

                Spacer()
            }
            .padding(AppTheme.Spacing.lg)
        }
        .background(AppGradient.background)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("关闭") {
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(AppTheme.Colors.primary)
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日 HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - 图片选择器
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImages: [UIImage]
    @Environment(\.presentationMode) var presentationMode

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) -> Void {
            if let image = info[.editedImage] as? UIImage {
                parent.selectedImages.append(image)
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.selectedImages.append(originalImage)
            }
            parent.presentationMode.wrappedValue.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - 相机选择器
struct CameraPicker: UIViewControllerRepresentable {
    @Binding var selectedImages: [UIImage]
    @Environment(\.presentationMode) var presentationMode

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.allowsEditing = true
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker

        init(_ parent: CameraPicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) -> Void {
            if let image = info[.editedImage] as? UIImage {
                parent.selectedImages.append(image)
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.selectedImages.append(originalImage)
            }
            parent.presentationMode.wrappedValue.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - 预览
#Preview {
    let sampleContentManager = CustomContentManager()
    sampleContentManager.contents = [
        CustomAnxietyContent(
            title: "今天天气真好",
            content: "阳光明媚，心情也很好。深呼吸几次，感受这份平静。",
            category: .gratitude,
            tags: ["天气", "好心情"]
        ),
        CustomAnxietyContent(
            title: "工作完成",
            content: "今天的工作都处理完了，可以好好放松一下了。泡个热水澡，听点轻音乐。",
            category: .achievement,
            tags: ["工作", "放松"]
        ),
        CustomAnxietyContent(
            title: "静心语句",
            content: "这个时刻很珍贵，完全属于你自己。不需要想任何事情，只是感受现在的平静。",
            category: .mantra,
            tags: ["静心", "平静"]
        )
    ]

    return CustomContentListView()
        .environmentObject(sampleContentManager)
}