//
//  FragmentCreateView.swift
//  Personal Space
//
//  Created by Penn on 2025/1/27.
//

import SwiftUI
import PhotosUI

struct FragmentCreateView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var userState: UserState
    
    @State private var content: String = ""
    @State private var linkURL: String = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var selectedImageData: Data?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    // 每日限额提示
                    dailyLimitSection
                    
                    // 文字内容输入
                    contentInputSection
                    
                    // 图片选择
                    imagePickerSection
                    
                    // 链接输入
                    linkInputSection
                    
                    // 发送按钮
                    sendButton
                }
                .padding(AppTheme.Spacing.lg)
            }
            .navigationTitle("分享碎片")
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
    
    // MARK: - 每日限额提示
    
    private var dailyLimitSection: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: "info.circle.fill")
                .foregroundColor(AppTheme.Colors.primary)
            
            Text("今日还可发送 \(userState.getRemainingFragmentCount()) 个碎片")
                .font(.system(size: AppTheme.FontSize.body))
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            Spacer()
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.primary.opacity(0.1))
        .cornerRadius(AppTheme.Radius.medium)
    }
    
    // MARK: - 文字内容输入
    
    private var contentInputSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack {
                Image(systemName: "text.bubble.fill")
                    .foregroundColor(AppTheme.Colors.primary)
                Text("分享内容")
                    .font(.system(size: AppTheme.FontSize.body, weight: .medium))
                Spacer()
                Text("\(content.count)/200")
                    .font(.system(size: AppTheme.FontSize.caption))
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            
            if #available(iOS 16.0, *) {
                TextField("说说你想分享的...", text: $content, axis: .vertical)
                    .lineLimit(5...10)
                    .padding(AppTheme.Spacing.md)
                    .background(AppTheme.Colors.cardBg)
                    .cornerRadius(AppTheme.Radius.medium)
            } else {
                TextEditor(text: $content)
                    .frame(minHeight: 100, maxHeight: 200)
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
            imagePickerSection_iOS16
        } else {
            imagePickerSection_iOS15
        }
    }
    
    // iOS 16+ 图片选择器
    @available(iOS 16.0, *)
    private var imagePickerSection_iOS16: some View {
        ImagePickerSection_iOS16(selectedImageData: $selectedImageData)
    }
    
    // iOS 15 图片选择器（简化版）
    private var imagePickerSection_iOS15: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack {
                Image(systemName: "photo.fill")
                    .foregroundColor(AppTheme.Colors.primary)
                Text("图片（可选）")
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
    
    // MARK: - 链接输入
    
    private var linkInputSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack {
                Image(systemName: "link")
                    .foregroundColor(AppTheme.Colors.primary)
                Text("链接（可选）")
                    .font(.system(size: AppTheme.FontSize.body, weight: .medium))
                Spacer()
            }
            
            TextField("https://example.com", text: $linkURL)
                .keyboardType(.URL)
                .autocapitalization(.none)
                .padding(AppTheme.Spacing.md)
                .background(AppTheme.Colors.cardBg)
                .cornerRadius(AppTheme.Radius.medium)
        }
    }
    
    // MARK: - 发送按钮
    
    private var sendButton: some View {
        Button {
            sendFragment()
        } label: {
            HStack {
                Image(systemName: "paperplane.fill")
                Text("发送碎片")
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
        content.count <= 200 &&
        userState.getRemainingFragmentCount() > 0
    }
    
    // MARK: - 发送逻辑
    
    private func sendFragment() {
        // TODO: 实际应用中需要上传图片到服务器并获取URL
        let imageURL: String? = selectedImageData != nil ? "local://image/\(UUID().uuidString)" : nil
        let finalLinkURL: String? = linkURL.isEmpty ? nil : linkURL
        
        let success = userState.createFragment(
            content: content.trimmingCharacters(in: .whitespacesAndNewlines),
            imageURL: imageURL,
            linkURL: finalLinkURL
        )
        
        if success {
            alertMessage = "碎片发送成功！"
            showingAlert = true
            
            // 延迟关闭页面
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                dismiss()
            }
        } else {
            alertMessage = "发送失败：今日已达到发送上限（2个）"
            showingAlert = true
        }
    }
}

// MARK: - iOS 16+ 图片选择器组件

@available(iOS 16.0, *)
struct ImagePickerSection_iOS16: View {
    @Binding var selectedImageData: Data?
    @State private var selectedImageItem: PhotosPickerItem?
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack {
                Image(systemName: "photo.fill")
                    .foregroundColor(AppTheme.Colors.primary)
                Text("图片（可选）")
                    .font(.system(size: AppTheme.FontSize.body, weight: .medium))
                Spacer()
            }
            
            if let imageData = selectedImageData,
               let uiImage = UIImage(data: imageData) {
                // 显示已选择的图片
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                        .cornerRadius(AppTheme.Radius.medium)
                    
                    Button {
                        selectedImageData = nil
                        selectedImageItem = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .background(Circle().fill(Color.black.opacity(0.6)))
                    }
                    .padding(AppTheme.Spacing.sm)
                }
            } else {
                // 图片选择按钮
                PhotosPicker(selection: $selectedImageItem, matching: .images) {
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
        .onChange(of: selectedImageItem) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    selectedImageData = data
                }
            }
        }
    }
}

#Preview {
    FragmentCreateView()
        .environmentObject(UserState())
}

