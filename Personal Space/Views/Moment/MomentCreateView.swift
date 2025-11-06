//
//  MomentCreateView.swift
//  Personal Space
//
//  Created by Penn on 2025/1/27.
//

import SwiftUI
import PhotosUI

struct MomentCreateView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var userState: UserState
    
    @State private var content: String = ""
    @State private var selectedImagesData: [Data] = []
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    // 3天隐藏提示
                    hiddenTextNotice
                    
                    // 文案输入
                    contentInputSection
                    
                    // 图片选择
                    imagePickerSection
                    
                    // 发布按钮
                    publishButton
                }
                .padding(AppTheme.Spacing.lg)
            }
            .navigationTitle("发布瞬间")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            .alert("提示", isPresented: $showingAlert) {
                Button("确定", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    // MARK: - 3天隐藏提示
    
    private var hiddenTextNotice: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: "lock.fill")
                .foregroundColor(AppTheme.Colors.warning)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("文案将默认对伴侣隐藏3天")
                    .font(.system(size: AppTheme.FontSize.body, weight: .medium))
                    .foregroundColor(AppTheme.Colors.text)
                
                Text("3天后文案将自动对TA显示，图片始终可见")
                    .font(.system(size: AppTheme.FontSize.caption))
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            
            Spacer()
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.warning.opacity(0.1))
        .cornerRadius(AppTheme.Radius.medium)
    }
    
    // MARK: - 文案输入
    
    private var contentInputSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack {
                Image(systemName: "text.bubble.fill")
                    .foregroundColor(AppTheme.Colors.primary)
                Text("分享内容")
                    .font(.system(size: AppTheme.FontSize.body, weight: .medium))
                Spacer()
                Text("\(content.count)/500")
                    .font(.system(size: AppTheme.FontSize.caption))
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            
            if #available(iOS 16.0, *) {
                TextField("记录此刻的心情...", text: $content, axis: .vertical)
                    .lineLimit(5...15)
                    .padding(AppTheme.Spacing.md)
                    .background(AppTheme.Colors.cardBg)
                    .cornerRadius(AppTheme.Radius.medium)
            } else {
                TextEditor(text: $content)
                    .frame(minHeight: 150, maxHeight: 300)
                    .padding(AppTheme.Spacing.sm)
                    .background(AppTheme.Colors.cardBg)
                    .cornerRadius(AppTheme.Radius.medium)
            }
        }
    }
    
    // MARK: - 图片选择
    
    @ViewBuilder
    private var imagePickerSection: some View {
        if #available(iOS 16.0, *) {
            MomentImagePickerSection_iOS16(selectedImagesData: $selectedImagesData)
        } else {
            imagePickerSection_iOS15
        }
    }
    
    private var imagePickerSection_iOS15: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack {
                Image(systemName: "photo.fill")
                    .foregroundColor(AppTheme.Colors.primary)
                Text("图片（可选，最多9张）")
                    .font(.system(size: AppTheme.FontSize.body, weight: .medium))
                Spacer()
            }
            
            Text("图片选择功能需要 iOS 16.0 或更高版本")
                .font(.system(size: AppTheme.FontSize.caption))
                .foregroundColor(AppTheme.Colors.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(AppTheme.Spacing.md)
                .background(AppTheme.Colors.cardBg)
                .cornerRadius(AppTheme.Radius.medium)
        }
    }
    
    // MARK: - 发布按钮
    
    private var publishButton: some View {
        Button {
            publishMoment()
        } label: {
            HStack {
                Image(systemName: "paperplane.fill")
                Text("发布瞬间")
                    .font(.system(size: AppTheme.FontSize.body, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.Spacing.md)
            .background(isFormValid ? AppTheme.Colors.primary : Color.gray)
            .cornerRadius(AppTheme.Radius.medium)
        }
        .disabled(!isFormValid)
    }
    
    // MARK: - 表单验证
    
    private var isFormValid: Bool {
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        content.count <= 500
    }
    
    // MARK: - 发布逻辑
    
    private func publishMoment() {
        // TODO: 实际应用中需要上传图片到服务器并获取URL
        let imageURLs = selectedImagesData.indices.map { "local://image/moment_\(UUID().uuidString)_\($0)" }
        
        userState.createMoment(
            content: content.trimmingCharacters(in: .whitespacesAndNewlines),
            images: imageURLs
        )
        
        alertMessage = "瞬间发布成功！"
        showingAlert = true
        
        // 延迟关闭页面
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            dismiss()
        }
    }
}

// MARK: - iOS 16+ 图片选择器组件

@available(iOS 16.0, *)
struct MomentImagePickerSection_iOS16: View {
    @Binding var selectedImagesData: [Data]
    @State private var selectedImageItems: [PhotosPickerItem] = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack {
                Image(systemName: "photo.fill")
                    .foregroundColor(AppTheme.Colors.primary)
                Text("图片（可选，最多9张）")
                    .font(.system(size: AppTheme.FontSize.body, weight: .medium))
                Spacer()
                Text("\(selectedImagesData.count)/9")
                    .font(.system(size: AppTheme.FontSize.caption))
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            
            if !selectedImagesData.isEmpty {
                // 图片网格
                let columns = [
                    GridItem(.flexible(), spacing: 8),
                    GridItem(.flexible(), spacing: 8),
                    GridItem(.flexible(), spacing: 8)
                ]
                
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(Array(selectedImagesData.enumerated()), id: \.offset) { index, imageData in
                        if let uiImage = UIImage(data: imageData) {
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 100)
                                    .clipped()
                                    .cornerRadius(AppTheme.Radius.small)
                                
                                Button {
                                    selectedImagesData.remove(at: index)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.white)
                                        .background(Circle().fill(Color.black.opacity(0.6)))
                                }
                                .padding(4)
                            }
                        }
                    }
                    
                    // 添加按钮
                    if selectedImagesData.count < 9 {
                        PhotosPicker(selection: $selectedImageItems, maxSelectionCount: 9 - selectedImagesData.count, matching: .images) {
                            RoundedRectangle(cornerRadius: AppTheme.Radius.small)
                                .fill(AppTheme.Colors.cardBg)
                                .frame(height: 100)
                                .overlay(
                                    VStack(spacing: 4) {
                                        Image(systemName: "plus")
                                            .font(.system(size: 24))
                                        Text("添加")
                                            .font(.system(size: AppTheme.FontSize.caption))
                                    }
                                    .foregroundColor(AppTheme.Colors.textSecondary)
                                )
                        }
                    }
                }
            } else {
                // 初始添加按钮
                PhotosPicker(selection: $selectedImageItems, maxSelectionCount: 9, matching: .images) {
                    HStack {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 20))
                        Text("选择图片")
                            .font(.system(size: AppTheme.FontSize.body))
                    }
                    .foregroundColor(AppTheme.Colors.primary)
                    .frame(maxWidth: .infinity)
                    .padding(AppTheme.Spacing.md)
                    .background(AppTheme.Colors.cardBg)
                    .cornerRadius(AppTheme.Radius.medium)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                            .stroke(AppTheme.Colors.primary.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [5]))
                    )
                }
            }
        }
        .onChange(of: selectedImageItems) { newItems in
            Task {
                for item in newItems {
                    if let data = try? await item.loadTransferable(type: Data.self) {
                        if selectedImagesData.count < 9 {
                            selectedImagesData.append(data)
                        }
                    }
                }
                selectedImageItems = []
            }
        }
    }
}

#Preview {
    MomentCreateView()
        .environmentObject(UserState())
}

