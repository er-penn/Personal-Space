//
//  ProfileView.swift
//  Personal Space
//
//  Created by Penn on 2025/1/27.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var userState: UserState
    @EnvironmentObject var partnerState: PartnerState
    @State private var showingCalmSpace = false
    @State private var showingSettings = false
    
    private var settingsSections: [SettingsSection] {
        [
            SettingsSection(
                title: "工具盒",
                items: [
                    SettingsItem(title: "冷静空间", icon: "heart.fill", color: .pink, action: {
                        showingCalmSpace = true
                    }),
                    SettingsItem(title: "帮助与反馈", icon: "headphones", color: .gray, action: {})
                ]
            )
        ]
    }
    
    var body: some View {
        return NavigationView {
            ZStack {
                // 背景渐变
                AppGradient.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 顶部用户信息区域
                    topUserInfoSection
                    
                    // 设置列表
                    List {
                        // 设置分组
                        ForEach(settingsSections) { section in
                            Section(section.title) {
                                ForEach(section.items) { item in
                                    SettingsRowView(item: item)
                                }
                            }
                            .listRowBackground(AppTheme.Colors.cardBg)
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingCalmSpace) {
            CalmSpaceView()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
    }
    
    // MARK: - 顶部用户信息区域
    private var topUserInfoSection: some View {
        HStack(spacing: AppTheme.Spacing.lg) {
            // 左侧：头像和昵称
            HStack(spacing: AppTheme.Spacing.md) {
                // 头像
                Circle()
                    .fill(LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text("我")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    )
                
                // 昵称
                VStack(alignment: .leading, spacing: 2) {
                    Text("SSSPenn")
                        .font(.system(size: AppTheme.FontSize.headline, weight: .semibold))
                        .foregroundColor(AppTheme.Colors.text)
                    
                    Text("已使用 15 天")
                        .font(.system(size: AppTheme.FontSize.caption))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                
                Spacer()
            }
            
            // 右侧：消息和客服图标
            HStack(spacing: AppTheme.Spacing.md) {
                // 消息气泡图标
                Button(action: {
                    // TODO: 打开消息
                }) {
                    ZStack {
                        Image(systemName: "bubble.left")
                            .font(.system(size: 20))
                            .foregroundColor(AppTheme.Colors.text)
                        
                        // 消息数量徽章
                        if true { // 模拟有未读消息
                            Text("2")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 16, height: 16)
                                .background(Color.red)
                                .clipShape(Circle())
                                .offset(x: 8, y: -8)
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                // 设置图标
                Button(action: {
                    showingSettings = true
                }) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 20))
                        .foregroundColor(AppTheme.Colors.text)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, AppTheme.Spacing.lg)
        .padding(.top, AppTheme.Spacing.lg)
        .padding(.bottom, AppTheme.Spacing.md)
    }
}

// MARK: - 设置分组模型
struct SettingsSection: Identifiable {
    let id = UUID()
    let title: String
    let items: [SettingsItem]
}

// MARK: - 设置项模型
struct SettingsItem: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
}

// MARK: - 设置行视图
struct SettingsRowView: View {
    let item: SettingsItem
    
    var body: some View {
        Button(action: item.action) {
            HStack(spacing: 12) {
                Image(systemName: item.icon)
                    .font(.title3)
                    .foregroundColor(item.color)
                    .frame(width: 24)
                
                Text(item.title)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 冷静空间视图
struct CalmSpaceView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTemplate = 0
    
    private let templates = [
        "我需要一些时间冷静思考，我们稍后再聊好吗？",
        "我现在情绪不太好，让我先调整一下，晚点再联系你。",
        "我想暂停一下我们的对话，我需要独处的时间。",
        "我现在需要空间，我们明天再继续这个话题吧。"
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.pink)
                    
                    Text("冷静空间")
                        .font(.title)
                        .font(.title.weight(.bold))
                    
                    Text("选择一条消息发送给伴侣，表达你需要冷静时间的需求")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("选择消息模板")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    Picker("模板", selection: $selectedTemplate) {
                        ForEach(0..<templates.count, id: \.self) { index in
                            Text(templates[index])
                                .tag(index)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .frame(height: 120)
                }
                
                VStack(spacing: 12) {
                    Button(action: {
                        // TODO: 发送消息
                        dismiss()
                    }) {
                        Text("发送消息")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.pink)
                            .cornerRadius(12)
                    }
                    
                    Button(action: {
                        // TODO: 复制到剪贴板
                    }) {
                        Text("复制到剪贴板")
                            .font(.subheadline)
                            .foregroundColor(.pink)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.pink.opacity(0.1))
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("冷静空间")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - 通知设置视图
struct NotificationSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isAllNotificationsEnabled = false
    @State private var isFocusModeNotificationEnabled = false
    @State private var isGiftBoxNotificationEnabled = false
    @State private var isMomentNotificationEnabled = false
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    Toggle("全部通知", isOn: $isAllNotificationsEnabled)
                        .onChange(of: isAllNotificationsEnabled) { newValue in
                            isFocusModeNotificationEnabled = newValue
                            isGiftBoxNotificationEnabled = newValue
                            isMomentNotificationEnabled = newValue
                        }
                } header: {
                    Text("通知总开关")
                } footer: {
                    Text("关闭后，所有通知都将被禁用")
                }
                
                Section {
                    Toggle("专注模式提醒", isOn: $isFocusModeNotificationEnabled)
                    Toggle("心意盒提醒", isOn: $isGiftBoxNotificationEnabled)
                    Toggle("瞬间公开提醒", isOn: $isMomentNotificationEnabled)
                } header: {
                    Text("具体通知类型")
                } footer: {
                    Text("你可以选择接收哪些类型的通知")
                }
            }
            .navigationTitle("通知设置")
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
}

// MARK: - 关系管理视图
struct RelationshipManagementView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var invitationCode = "BOUNDARY2025"
    @State private var showingInviteSheet = false
    @State private var showingUnlinkAlert = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Image(systemName: "heart.circle")
                        .font(.system(size: 60))
                        .foregroundColor(.pink)
                    
                    Text("关系管理")
                        .font(.title)
                        .font(.title.weight(.bold))
                    
                    Text("管理你与伴侣的关系连接")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 16) {
                    // 邀请伴侣
                    VStack(alignment: .leading, spacing: 12) {
                        Text("邀请伴侣")
                            .font(.headline)
                        
                        HStack {
                            Text("邀请码：\(invitationCode)")
                                .font(.subheadline)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            
                            Button("复制") {
                                // TODO: 复制邀请码
                            }
                            .font(.subheadline)
                            .foregroundColor(.blue)
                        }
                        
                        Button(action: {
                            showingInviteSheet = true
                        }) {
                            Text("生成新邀请码")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // 解除关系
                    VStack(alignment: .leading, spacing: 12) {
                        Text("解除关系")
                            .font(.headline)
                        
                        Text("解除后，所有共享数据将被删除，且无法恢复")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Button(action: {
                            showingUnlinkAlert = true
                        }) {
                            Text("解除关系")
                                .font(.subheadline)
                                .foregroundColor(.red)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("关系管理")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingInviteSheet) {
                InviteSheetView()
            }
            .alert("确认解除关系", isPresented: $showingUnlinkAlert) {
                Button("取消", role: .cancel) { }
                Button("确认解除", role: .destructive) {
                    // TODO: 解除关系
                    dismiss()
                }
            } message: {
                Text("此操作不可撤销，所有共享数据将被永久删除。")
            }
        }
    }
}

// MARK: - 邀请表单视图
struct InviteSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var newInvitationCode = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("生成新的邀请码")
                    .font(.headline)
                
                TextField("输入邀请码", text: $newInvitationCode)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                Button("生成邀请码") {
                    // TODO: 生成新邀请码
                    dismiss()
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
                .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            .navigationTitle("新邀请码")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - 个人信息页面
struct PersonalInfoView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var username = "SSSPenn"
    @State private var nickname = "边界舱用户"
    @State private var partnerNickname = "邀请伴侣"
    @State private var isPartnerBound = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AppGradient.background.ignoresSafeArea()
                
                List {
                    // 基础信息
                    Section("基础信息") {
                        // 头像
                        Button(action: {
                            // TODO: 选择头像
                        }) {
                            HStack {
                                Image(systemName: "photo.circle")
                                    .foregroundColor(.purple)
                                    .font(.title2)
                                
                                VStack(alignment: .leading) {
                                    Text("头像")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("点击更换头像")
                                        .font(.body)
                                        .foregroundColor(.primary)
                                }
                                
                                Spacer()
                                
                                // 当前头像预览
                                Circle()
                                    .fill(LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                                    .frame(width: 30, height: 30)
                                    .overlay(
                                        Text("我")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(.white)
                                    )
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.vertical, 4)
                        
                        HStack {
                            Image(systemName: "person.circle")
                                .foregroundColor(.blue)
                                .font(.title2)
                            
                            VStack(alignment: .leading) {
                                Text("用户名")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(username)
                                    .font(.body)
                            }
                            
                            Spacer()
                        }
                        .padding(.vertical, 4)
                        
                        HStack {
                            Image(systemName: "textformat")
                                .foregroundColor(.green)
                                .font(.title2)
                            
                            VStack(alignment: .leading) {
                                Text("昵称")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(nickname)
                                    .font(.body)
                            }
                            
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowBackground(AppTheme.Colors.cardBg)
                    
                    // 伴侣
                    Section("伴侣") {
                        Button(action: {
                            if !isPartnerBound {
                                // TODO: 邀请伴侣逻辑
                            }
                        }) {
                            HStack {
                                Image(systemName: isPartnerBound ? "person.2" : "person.badge.plus")
                                    .foregroundColor(isPartnerBound ? .purple : .pink)
                                    .font(.title2)
                                
                                VStack(alignment: .leading) {
                                    Text(isPartnerBound ? "伴侣昵称" : "邀请伴侣")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(partnerNickname)
                                        .font(.body)
                                        .foregroundColor(.primary)
                                }
                                
                                Spacer()
                                
                                if !isPartnerBound {
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.vertical, 4)
                    }
                    .listRowBackground(AppTheme.Colors.cardBg)
                }
                .listStyle(InsetGroupedListStyle())
            }
            .navigationTitle("个人信息")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("完成") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

// MARK: - 设置页面
struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var phoneNumber = "138****8888"
    @State private var wechat = "未绑定"
    @State private var basicNotifications = true
    @State private var partnerFocusReminder = true
    
    var body: some View {
        NavigationView {
            ZStack {
                AppGradient.background.ignoresSafeArea()
                
                List {
                    // 隐私
                    Section("隐私") {
                        HStack {
                            Image(systemName: "phone")
                                .foregroundColor(.blue)
                                .font(.title2)
                            
                            VStack(alignment: .leading) {
                                Text("手机号")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(phoneNumber)
                                    .font(.body)
                            }
                            
                            Spacer()
                        }
                        .padding(.vertical, 4)
                        
                        HStack {
                            Image(systemName: "message")
                                .foregroundColor(.green)
                                .font(.title2)
                            
                            VStack(alignment: .leading) {
                                Text("微信")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(wechat)
                                    .font(.body)
                            }
                            
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowBackground(AppTheme.Colors.cardBg)
                    
                    // 通知
                    Section("通知") {
                        HStack {
                            Image(systemName: "bell")
                                .foregroundColor(.orange)
                                .font(.title2)
                            
                            VStack(alignment: .leading) {
                                Text("基础通知配置")
                                    .font(.body)
                                Text("接收App的基本通知")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Toggle("", isOn: $basicNotifications)
                        }
                        .padding(.vertical, 4)
                        
                        HStack {
                            Image(systemName: "moon")
                                .foregroundColor(.purple)
                                .font(.title2)
                            
                            VStack(alignment: .leading) {
                                Text("伴侣专注模式提醒")
                                    .font(.body)
                                Text("当伴侣开启专注模式时通知")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Toggle("", isOn: $partnerFocusReminder)
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowBackground(AppTheme.Colors.cardBg)
                }
                .listStyle(InsetGroupedListStyle())
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("完成") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(UserState())
        .environmentObject(PartnerState())
}
