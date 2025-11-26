//
//  QuickNoteChatView.swift
//  Personal Space
//
//  Created by Penn on 2025/11/20.
//

import SwiftUI
import AVFoundation
import Combine

struct QuickNoteChatView: View {
    @Environment(\.dismiss) var dismiss
    let noteId: UUID?
    @ObservedObject var manager: QuickNoteManager
    let onDismiss: (() -> Void)?
    
    // 用于保存新建的note（新建模式下使用）
    @State private var newNote: QuickNote?
    
    // 获取当前要显示的note（computed property，确保始终从manager获取最新数据）
    private var displayNote: QuickNote {
        print("🔍 [displayNote] 被访问 - noteId: \(noteId?.uuidString ?? "nil")")
        print("🔍 [displayNote] manager.notes.count: \(manager.notes.count)")
        
        if let id = noteId {
            print("🔍 [displayNote] 查找 noteId: \(id.uuidString)")
            if let note = manager.notes.first(where: { $0.id == id }) {
                print("✅ [displayNote] 找到 note - title: \(note.title), messages.count: \(note.messages.count)")
                // 编辑模式：从manager获取最新数据
                return note
            } else {
                print("❌ [displayNote] 未找到匹配的 note")
                print("🔍 [displayNote] manager.notes 中的所有 IDs:")
                for (index, note) in manager.notes.enumerated() {
                    print("   [\(index)] id: \(note.id.uuidString), title: \(note.title), messages.count: \(note.messages.count)")
                }
            }
        }
        
        if let new = newNote {
            print("📝 [displayNote] 使用 newNote - title: \(new.title), messages.count: \(new.messages.count)")
            // 新建模式：使用newNote
            return new
        } else {
            print("⚠️ [displayNote] 返回兜底空 note")
            // 兜底：返回空note
            return QuickNote(
                title: QuickNote.generateDefaultTitle(),
                messages: [],
                createdAt: Date(),
                updatedAt: Date()
            )
        }
    }
    @State private var inputText: String = ""
    @State private var pendingBadge: BadgeType? = nil
    @State private var isVoiceMode: Bool = false
    @State private var isRecording: Bool = false
    @State private var audioRecorder: AVAudioRecorder?
    @State private var recordingURL: URL?
    @State private var recordingStartTime: Date?
    
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var imageSourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var pendingImageBadge: BadgeType? = nil
    
    @State private var showingMenu = false
    @State private var showingRenameSheet = false
    @State private var showingBadgeSummary: BadgeType? = nil
    @State private var selectedMessageForAction: NoteMessage? = nil
    @State private var showingMessageActionSheet = false
    @State private var referencingMessage: NoteMessage? = nil
    
    // 微信绿色
    private let wechatGreen = Color(red: 0.584, green: 0.925, blue: 0.412) // #95EC69
    
    // 计算当前应该显示的角标（优先级：用户手动选择 > 继承的角标 > nil）
    private var currentBadge: BadgeType? {
        // 如果用户手动选择了角标，优先使用用户选择的
        if let userSelectedBadge = pendingBadge {
            return userSelectedBadge
        }
        // 否则，如果引用了消息，继承被引用消息的角标
        if let refMessage = referencingMessage, let refBadge = refMessage.badge {
            return refBadge
        }
        // 否则，无角标
        return nil
    }
    
    init(noteId: UUID?, manager: QuickNoteManager, onDismiss: (() -> Void)? = nil) {
        print("🚀 [QuickNoteChatView.init] 开始初始化")
        print("🚀 [QuickNoteChatView.init] noteId: \(noteId?.uuidString ?? "nil")")
        print("🚀 [QuickNoteChatView.init] manager.notes.count: \(manager.notes.count)")
        
        self.noteId = noteId
        self.manager = manager
        self.onDismiss = onDismiss
        
        // 如果是新建模式，初始化newNote
        if noteId == nil {
            print("📝 [QuickNoteChatView.init] 新建模式")
            _newNote = State(initialValue: QuickNote(
                title: QuickNote.generateDefaultTitle(),
                messages: [],
                createdAt: Date(),
                updatedAt: Date()
            ))
        } else {
            print("✏️ [QuickNoteChatView.init] 编辑模式，noteId: \(noteId!.uuidString)")
            // 尝试在初始化时查找数据
            if let note = manager.notes.first(where: { $0.id == noteId! }) {
                print("✅ [QuickNoteChatView.init] 初始化时找到 note - title: \(note.title), messages.count: \(note.messages.count)")
            } else {
                print("❌ [QuickNoteChatView.init] 初始化时未找到 note")
                print("🔍 [QuickNoteChatView.init] manager.notes 中的所有 IDs:")
                for (index, note) in manager.notes.enumerated() {
                    print("   [\(index)] id: \(note.id.uuidString), title: \(note.title), messages.count: \(note.messages.count)")
                }
            }
            _newNote = State(initialValue: nil)
        }
        print("🚀 [QuickNoteChatView.init] 初始化完成")
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AppGradient.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 消息列表区域
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: AppTheme.Spacing.md) {
                                let sortedMessages = displayNote.messages.sorted { $0.createdAt < $1.createdAt }
                                
                                ForEach(sortedMessages) { message in
                                    MessageBubbleView(
                                        message: message,
                                        manager: manager,
                                        isSelected: selectedMessageForAction?.id == message.id && showingMessageActionSheet,
                                        onBadgeTap: { badge in
                                            showingBadgeSummary = badge
                                        },
                                        onLongPress: {
                                            print("🔘 [MessageAction] 长按消息 - messageId: \(message.id.uuidString)")
                                            selectedMessageForAction = message
                                            showingMessageActionSheet = true
                                            print("🔘 [MessageAction] showingMessageActionSheet = true")
                                        },
                                        onQuote: {
                                            if let message = selectedMessageForAction {
                                                referencingMessage = message
                                                // 强制继承被引用消息的角标（覆盖之前的选择）
                                                pendingBadge = message.badge
                                            }
                                            showingMessageActionSheet = false
                                            selectedMessageForAction = nil
                                        },
                                        onDelete: {
                                            if let message = selectedMessageForAction {
                                                deleteMessage(message)
                                            }
                                            showingMessageActionSheet = false
                                            selectedMessageForAction = nil
                                        },
                                        onDismiss: {
                                            showingMessageActionSheet = false
                                            selectedMessageForAction = nil
                                        }
                                    )
                                    .id(message.id)
                                }
                            }
                            .padding(.horizontal, AppTheme.Spacing.md)
                            .padding(.vertical, AppTheme.Spacing.lg)
                        }
                        .onChange(of: displayNote.messages.count) { newCount in
                            if let lastMessage = displayNote.messages.sorted(by: { $0.createdAt < $1.createdAt }).last {
                                withAnimation {
                                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                        }
                    }
                    
                    // 底部输入栏
                    inputBar
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        handleBack()
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(AppTheme.Colors.text)
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    Text(displayNote.title)
                        .font(.system(size: AppTheme.FontSize.headline, weight: .semibold))
                        .foregroundColor(AppTheme.Colors.text)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        print("🔘 [Menu] 点击右上角三个点按钮")
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showingMenu.toggle()
                            print("🔘 [Menu] showingMenu = \(showingMenu)")
                        }
                    }) {
                        Image(systemName: "ellipsis")
                            .foregroundColor(AppTheme.Colors.text)
                    }
                }
            }
            .overlay(
                // 点击外部区域关闭菜单 - 放在最上层
                Group {
                    if showingMenu || showingBadgeMenu || showingPlusMenu {
                        Color.clear
                            .ignoresSafeArea()
                            .contentShape(Rectangle())
                            .onTapGesture {
                                print("🔘 [Menu] 点击外部区域关闭菜单 - showingMenu: \(showingMenu), showingBadgeMenu: \(showingBadgeMenu), showingPlusMenu: \(showingPlusMenu)")
                                withAnimation {
                                    showingMenu = false
                                    showingBadgeMenu = false
                                    showingPlusMenu = false
                                }
                                print("🔘 [Menu] 菜单已关闭")
                            }
                            .zIndex(998) // 在菜单下方，但在其他内容上方
                    }
                }
            )
            .overlay(
                // 气泡菜单（显示在导航栏外部）
                VStack {
                    HStack {
                        Spacer()
                        if showingMenu {
                            BubbleMenuView(
                                hasInsight: displayNote.hasInsight,
                                hasPainPoint: displayNote.hasPainPoint,
                                hasSolution: displayNote.hasSolution,
                                onEditTitle: {
                                    print("🔘 [Menu] 点击编辑标题")
                                    showingMenu = false
                                    showingRenameSheet = true
                                },
                                onInsight: {
                                    print("🔘 [Menu] 点击洞察")
                                    showingMenu = false
                                    showingBadgeSummary = .insight
                                },
                                onPainPoint: {
                                    print("🔘 [Menu] 点击痛点")
                                    showingMenu = false
                                    showingBadgeSummary = .painPoint
                                },
                                onSolution: {
                                    print("🔘 [Menu] 点击方案")
                                    showingMenu = false
                                    showingBadgeSummary = .solution
                                }
                            )
                            .padding(.top, 8)
                            .padding(.trailing, 16)
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                            .allowsHitTesting(true)
                            .zIndex(1001)
                        }
                    }
                    Spacer()
                }
            )
            .sheet(isPresented: $showingRenameSheet) {
                RenameNoteSheet(
                    currentTitle: displayNote.title,
                    onSave: { newTitle in
                        updateNoteTitle(newTitle)
                    }
                )
                .applyRenameSheetModifiers()
            }
            .sheet(item: Binding(
                get: { showingBadgeSummary },
                set: { showingBadgeSummary = $0 }
            )) { badge in
                BadgeSummaryView(
                    note: displayNote,
                    badge: badge,
                    manager: manager,
                    onSave: { summary in
                        updateSummary(for: badge, content: summary)
                    }
                )
            }
            .sheet(isPresented: $showingImagePicker) {
                QuickNoteImagePicker(sourceType: imageSourceType) { image in
                    handleImageSelected(image)
                }
            }
        }
    }
    
    // MARK: - 底部输入栏
    private var inputBar: some View {
        VStack(spacing: 0) {
            Divider()
            
            // 角标选择菜单（在输入框上方）
            if showingBadgeMenu {
                badgeMenuGrid
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
            
            // 加号菜单（在输入框上方）
            if showingPlusMenu {
                plusMenuGrid
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
            
            HStack(spacing: AppTheme.Spacing.md) {
                // 左侧：语音切换按钮
                Button(action: {
                    withAnimation {
                        isVoiceMode.toggle()
                    }
                }) {
                    Image(systemName: isVoiceMode ? "keyboard" : "mic.fill")
                        .font(.system(size: 24))
                        .foregroundColor(AppTheme.Colors.primary)
                }
                .frame(width: 44, height: 44)
                
                VStack(spacing: AppTheme.Spacing.xs) {
                    if isVoiceMode {
                        // 语音按钮
                        voiceButton
                    } else {
                        // 文字输入框
                        textInputField
                    }
                    
                    // 引用预览（显示在输入框/录音按钮下方）
                    if let refMessage = referencingMessage {
                        referencePreviewView
                    }
                }
                
                // 右侧：加号/发送按钮
                Button(action: {
                    if !isVoiceMode && !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        // 有文字内容时，点击发送
                        sendTextMessage()
                    } else {
                        // 无内容时，显示加号菜单
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            // 关闭角标菜单（如果打开）
                            if showingBadgeMenu {
                                showingBadgeMenu = false
                            }
                            showingPlusMenu.toggle()
                        }
                    }
                }) {
                    if !isVoiceMode && !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        // 显示发送按钮
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(AppTheme.Colors.primary)
                    } else {
                        // 显示加号按钮
                        Image(systemName: showingPlusMenu ? "xmark" : "plus")
                            .font(.system(size: 24))
                            .foregroundColor(AppTheme.Colors.primary)
                    }
                }
                .frame(width: 44, height: 44)
            }
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.sm)
            .background(AppTheme.Colors.cardBg)
        }
    }
    
    // MARK: - 角标选择菜单网格（按钮70x70pt）
    private var badgeMenuGrid: some View {
        VStack(spacing: 0) {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: AppTheme.Spacing.md),
                GridItem(.flexible(), spacing: AppTheme.Spacing.md),
                GridItem(.flexible(), spacing: AppTheme.Spacing.md),
                GridItem(.flexible(), spacing: AppTheme.Spacing.md)
            ], spacing: AppTheme.Spacing.lg) {
                // 洞察
                PlusMenuItem(
                    icon: "lightbulb.fill",
                    title: "洞察",
                    size: 70,
                    action: {
                        pendingBadge = .insight
                        withAnimation {
                            showingBadgeMenu = false
                        }
                    }
                )
                
                // 痛点
                PlusMenuItem(
                    icon: "exclamationmark.triangle.fill",
                    title: "痛点",
                    size: 70,
                    action: {
                        pendingBadge = .painPoint
                        withAnimation {
                            showingBadgeMenu = false
                        }
                    }
                )
                
                // 方案
                PlusMenuItem(
                    icon: "checkmark.circle.fill",
                    title: "方案",
                    size: 70,
                    action: {
                        pendingBadge = .solution
                        withAnimation {
                            showingBadgeMenu = false
                        }
                    }
                )
                
                // 不加角标
                PlusMenuItem(
                    icon: "xmark.circle.fill",
                    title: "无角标",
                    size: 70,
                    action: {
                        pendingBadge = nil
                        withAnimation {
                            showingBadgeMenu = false
                        }
                    }
                )
            }
            .padding(.horizontal, AppTheme.Spacing.lg)
            .padding(.vertical, AppTheme.Spacing.md)
            .background(AppTheme.Colors.cardBg)
        }
    }
    
    // MARK: - 加号菜单网格（按钮70x70pt）
    private var plusMenuGrid: some View {
        VStack(spacing: 0) {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: AppTheme.Spacing.md),
                GridItem(.flexible(), spacing: AppTheme.Spacing.md),
                GridItem(.flexible(), spacing: AppTheme.Spacing.md),
                GridItem(.flexible(), spacing: AppTheme.Spacing.md)
            ], spacing: AppTheme.Spacing.lg) {
                // 照片
                PlusMenuItem(
                    icon: "photo.on.rectangle",
                    title: "照片",
                    size: 70,
                    action: {
                        withAnimation {
                            showingPlusMenu = false
                        }
                        imageSourceType = .photoLibrary
                        showingImagePicker = true
                    }
                )
                
                // 拍摄
                PlusMenuItem(
                    icon: "camera.fill",
                    title: "拍摄",
                    size: 70,
                    action: {
                        withAnimation {
                            showingPlusMenu = false
                        }
                        imageSourceType = .camera
                        showingCamera = true
                    }
                )
            }
            .padding(.horizontal, AppTheme.Spacing.lg)
            .padding(.vertical, AppTheme.Spacing.md)
            .background(AppTheme.Colors.cardBg)
        }
    }
    
    @State private var showingPlusMenu = false
    @State private var showingBadgeMenu = false
    @State private var voiceButtonWidth: CGFloat = 0
    
    private var textInputField: some View {
        Group {
            if #available(iOS 16.0, *) {
                TextField("输入文字...", text: $inputText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .padding(.vertical, AppTheme.Spacing.sm)
                    .background(currentBadge != nil ? currentBadge!.color.opacity(0.05) : AppTheme.Colors.bgMain)
                    .cornerRadius(AppTheme.Radius.medium)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                            .stroke(currentBadge != nil ? currentBadge!.color.opacity(0.3) : Color.clear, lineWidth: 1)
                    )
                    .overlay(
                        // 右上角角标图标
                        badgeIconOverlay
                            .offset(x: -4, y: -4),
                        alignment: .topTrailing
                    )
                    .lineLimit(1...5)
                    .onSubmit {
                        sendTextMessage()
                    }
            } else {
                TextField("输入文字...", text: $inputText)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .padding(.vertical, AppTheme.Spacing.sm)
                    .background(currentBadge != nil ? currentBadge!.color.opacity(0.05) : AppTheme.Colors.bgMain)
                    .cornerRadius(AppTheme.Radius.medium)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                            .stroke(currentBadge != nil ? currentBadge!.color.opacity(0.3) : Color.clear, lineWidth: 1)
                    )
                    .overlay(
                        // 右上角角标图标
                        badgeIconOverlay
                            .offset(x: -4, y: -4),
                        alignment: .topTrailing
                    )
                    .onSubmit {
                        sendTextMessage()
                    }
            }
        }
        .sheet(isPresented: $showingCamera) {
            QuickNoteImagePicker(sourceType: .camera) { image in
                handleImageSelected(image)
            }
        }
            .confirmationDialog("选择角标", isPresented: $showingImageBadgePicker, titleVisibility: .visible) {
                Button("无角标") {
                    if let path = pendingImagePath {
                        sendImageMessage(path: path, badge: nil)
                    }
                }
                Button("洞察") {
                    if let path = pendingImagePath {
                        sendImageMessage(path: path, badge: .insight)
                    }
                }
                Button("痛点") {
                    if let path = pendingImagePath {
                        sendImageMessage(path: path, badge: .painPoint)
                    }
                }
                Button("方案") {
                    if let path = pendingImagePath {
                        sendImageMessage(path: path, badge: .solution)
                    }
                }
                Button("取消", role: .cancel) {
                    pendingImagePath = nil
                }
            }
    }
    
    private var voiceButton: some View {
        Button(action: {}) {
            Text(isRecording ? "松开发送" : "按住说话")
                .font(.system(size: AppTheme.FontSize.body))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppTheme.Spacing.md)
                .background(isRecording ? Color.red : AppTheme.Colors.primary)
                .cornerRadius(AppTheme.Radius.medium)
                .overlay(
                    // 右上角角标图标
                    badgeIconOverlay
                        .offset(x: -4, y: -4),
                    alignment: .topTrailing
                )
                .background(
                    GeometryReader { geometry in
                        Color.clear
                            .preference(key: VoiceButtonWidthKey.self, value: geometry.size.width)
                            .onAppear {
                                print("🎤 [voiceButton] GeometryReader onAppear - size: width=\(geometry.size.width), height=\(geometry.size.height)")
                                voiceButtonWidth = geometry.size.width
                            }
                            .onChange(of: geometry.size.width) { newWidth in
                                print("🎤 [voiceButton] GeometryReader width changed - oldWidth=\(voiceButtonWidth), newWidth=\(newWidth)")
                                voiceButtonWidth = newWidth
                            }
                    }
                )
        }
        .onPreferenceChange(VoiceButtonWidthKey.self) { width in
            print("🎤 [voiceButton] PreferenceKey changed - width=\(width)")
            voiceButtonWidth = width
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    print("🎤 [voiceButton] DragGesture onChanged - location: x=\(value.location.x), y=\(value.location.y), voiceButtonWidth=\(voiceButtonWidth)")
                    
                    // 计算角标区域（右上角，18x18pt，偏移-4pt）
                    let badgeSize: CGFloat = 18
                    let badgeOffset: CGFloat = 4
                    let buttonWidth = voiceButtonWidth > 0 ? voiceButtonWidth : (UIScreen.main.bounds.width - 44 - 44 - AppTheme.Spacing.md * 3)
                    let badgeXMin = buttonWidth - badgeOffset - badgeSize
                    let badgeXMax = buttonWidth - badgeOffset
                    let badgeYMin: CGFloat = -badgeOffset
                    let badgeYMax = badgeYMin + badgeSize
                    
                    print("🎤 [voiceButton] Badge area - buttonWidth=\(buttonWidth), badgeXMin=\(badgeXMin), badgeXMax=\(badgeXMax), badgeYMin=\(badgeYMin), badgeYMax=\(badgeYMax)")
                    
                    // 检查点击位置是否在角标区域内
                    let isInBadgeArea = value.location.x >= badgeXMin && 
                                      value.location.x <= badgeXMax &&
                                      value.location.y >= badgeYMin && 
                                      value.location.y <= badgeYMax
                    
                    print("🎤 [voiceButton] isInBadgeArea=\(isInBadgeArea)")
                    
                    // 如果不在角标区域内，才触发录音
                    if !isInBadgeArea && !isRecording {
                        startRecording()
                    }
                }
                .onEnded { _ in
                    if isRecording {
                        stopRecording()
                    }
                }
        )
    }
    
    // MARK: - 角标图标覆盖层（始终显示）
    @ViewBuilder
    private var badgeIconOverlay: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                // 关闭加号菜单（如果打开）
                if showingPlusMenu {
                    showingPlusMenu = false
                }
                showingBadgeMenu.toggle()
            }
        }) {
            if let badge = currentBadge {
                // 显示选中的角标（用户手动选择或继承的）
                Image(systemName: badgeIconName(for: badge))
                    .font(.system(size: 12))
                    .foregroundColor(.white)
                    .frame(width: 18, height: 18)
                    .background(badge.color)
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
            } else {
                // 默认显示加号
                Image(systemName: "plus")
                    .font(.system(size: 10))
                    .foregroundColor(.white)
                    .frame(width: 18, height: 18)
                    .background(AppTheme.Colors.primary)
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
            }
        }
    }
    
    // MARK: - 引用预览视图
    private var referencePreviewView: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            // 引用内容预览
            Text(referencingMessage?.getPreviewText() ?? "")
                .font(.system(size: AppTheme.FontSize.caption))
                .foregroundColor(AppTheme.Colors.textSecondary)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // 取消引用按钮
            Button(action: {
                withAnimation {
                    // 检查角标是否是继承的（pendingBadge等于被引用消息的角标）
                    let refBadge = referencingMessage?.badge
                    let isInheritedBadge = (refBadge != nil && pendingBadge == refBadge)
                    
                    referencingMessage = nil
                    
                    // 如果角标是继承的，取消引用后清除角标
                    if isInheritedBadge {
                        pendingBadge = nil
                    }
                }
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            .frame(width: 20, height: 20)
        }
        .padding(.horizontal, AppTheme.Spacing.sm)
        .padding(.vertical, AppTheme.Spacing.xs)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(AppTheme.Radius.small)
    }
    
    private func badgeIconName(for badge: BadgeType) -> String {
        switch badge {
        case .insight:
            return "lightbulb.fill"
        case .painPoint:
            return "exclamationmark.triangle.fill"
        case .solution:
            return "checkmark.circle.fill"
        }
    }
    
    // MARK: - 消息发送逻辑
    
    private func sendTextMessage() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let content = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        inputText = ""
        
        // 使用当前角标（已通过currentBadge计算，优先级：用户手动选择 > 继承的角标）
        let badge = currentBadge
        pendingBadge = nil
        
        let message = NoteMessage(
            type: .text,
            content: content,
            badge: badge,
            referencedMessageId: referencingMessage?.id,
            referencedMessagePreview: referencingMessage?.getPreviewText()
        )
        
        addMessage(message)
        referencingMessage = nil
    }
    
    private func handleImageSelected(_ image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 0.8),
              let path = manager.saveImageFile(imageData) else { return }
        
        // 显示角标选择弹窗
        showingImageBadgePicker = true
        pendingImagePath = path
    }
    
    @State private var showingImageBadgePicker = false
    @State private var pendingImagePath: String? = nil
    
    private func sendImageMessage(path: String, badge: BadgeType?) {
        let message = NoteMessage(
            type: .image,
            imagePath: path,
            badge: badge
        )
        
        addMessage(message)
        pendingImagePath = nil
    }
    
    // MARK: - 录音功能
    
    private func startRecording() {
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(.record, mode: .default)
            try audioSession.setActive(true)
            
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let audioFilename = documentsPath.appendingPathComponent("recording_\(UUID().uuidString).m4a")
            recordingURL = audioFilename
            recordingStartTime = Date()
            
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.record()
            isRecording = true
        } catch {
            print("录音失败: \(error)")
        }
    }
    
    private func stopRecording() {
        guard isRecording else { return }
        
        audioRecorder?.stop()
        isRecording = false
        
        guard let url = recordingURL,
              let startTime = recordingStartTime else { return }
        
        let duration = Date().timeIntervalSince(startTime)
        
        if let audioData = try? Data(contentsOf: url),
           let path = manager.saveAudioFile(audioData) {
            // 使用当前角标（已通过currentBadge计算，优先级：用户手动选择 > 继承的角标）
            let badge = currentBadge
            sendAudioMessage(path: path, duration: duration, badge: badge, referencedMessageId: referencingMessage?.id, referencedMessagePreview: referencingMessage?.getPreviewText())
            // 发送后清除角标和引用
            pendingBadge = nil
            referencingMessage = nil
        }
        
        // 删除临时文件
        try? FileManager.default.removeItem(at: url)
        
        audioRecorder = nil
        recordingURL = nil
        recordingStartTime = nil
        
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setActive(false)
    }
    
    private func sendAudioMessage(path: String, duration: TimeInterval, badge: BadgeType?, referencedMessageId: UUID? = nil, referencedMessagePreview: String? = nil) {
        let message = NoteMessage(
            type: .audio,
            audioPath: path,
            audioDuration: duration,
            badge: badge,
            referencedMessageId: referencedMessageId,
            referencedMessagePreview: referencedMessagePreview
        )
        
        addMessage(message)
    }
    
    // MARK: - 其他功能
    
    private func deleteMessage(_ message: NoteMessage) {
        var note = displayNote
        note.messages.removeAll { $0.id == message.id }
        note.updatedAt = Date()
        
        // 删除关联文件
        if let audioPath = message.audioPath {
            if let fileURL = manager.getFileURL(for: audioPath) {
                try? FileManager.default.removeItem(at: fileURL)
            }
        }
        if let imagePath = message.imagePath {
            if let fileURL = manager.getFileURL(for: imagePath) {
                try? FileManager.default.removeItem(at: fileURL)
            }
        }
        
        saveOrUpdateNote(note)
    }
    
    private func updateSummary(for badge: BadgeType, content: String) {
        var note = displayNote
        switch badge {
        case .insight:
            note.insightSummary = content.isEmpty ? nil : content
        case .painPoint:
            note.painPointSummary = content.isEmpty ? nil : content
        case .solution:
            note.solutionSummary = content.isEmpty ? nil : content
        }
        note.updatedAt = Date()
        saveOrUpdateNote(note)
    }
    
    private func updateNoteTitle(_ newTitle: String) {
        var note = displayNote
        note.title = newTitle.isEmpty ? note.title : newTitle
        note.updatedAt = Date()
        saveOrUpdateNote(note)
    }
    
    private func addMessage(_ message: NoteMessage) {
        var note = displayNote
        note.messages.append(message)
        note.updatedAt = Date()
        saveOrUpdateNote(note)
    }
    
    private func saveOrUpdateNote(_ note: QuickNote) {
        if manager.notes.contains(where: { $0.id == note.id }) {
            // 更新现有记录
            manager.updateNote(note)
            
            // 如果是新建模式，也要同步更新 newNote
            if noteId == nil {
                newNote = note
            }
        } else {
            // 新建记录
            if !note.messages.isEmpty || !note.title.isEmpty {
                manager.addNote(note)
                
                // 如果是新建模式，更新newNote
                if noteId == nil {
                    newNote = note
                }
            }
        }
    }
    
    private func handleBack() {
        if displayNote.messages.isEmpty {
            // 未发送任何内容，删除可能已保存的空 note
            if manager.notes.contains(where: { $0.id == displayNote.id }) {
                manager.deleteNote(displayNote)
            }
            dismiss()
            onDismiss?()
        } else {
            // 已发送内容，确保保存后返回
            if noteId == nil, let new = newNote, !new.messages.isEmpty {
                // 新建模式：确保已保存
                if !manager.notes.contains(where: { $0.id == new.id }) {
                    manager.addNote(new)
                }
            }
            dismiss()
            onDismiss?()
        }
    }
}

// MARK: - 消息气泡视图
struct MessageBubbleView: View {
    let message: NoteMessage
    @ObservedObject var manager: QuickNoteManager
    let isSelected: Bool
    let onBadgeTap: (BadgeType) -> Void
    let onLongPress: () -> Void
    let onQuote: () -> Void
    let onDelete: () -> Void
    let onDismiss: () -> Void
    
    private let wechatGreen = Color(red: 0.584, green: 0.925, blue: 0.412) // #95EC69
    
    var body: some View {
        HStack {
            Spacer()
            
            VStack(alignment: .trailing, spacing: AppTheme.Spacing.xs) {
                // 角标（显示在消息内容上方）
                if let badge = message.badge {
                    Button(action: {
                        onBadgeTap(badge)
                    }) {
                        Text("[\(badge.rawValue)]")
                            .font(.system(size: AppTheme.FontSize.caption))
                            .foregroundColor(badge.color)
                            .padding(.horizontal, AppTheme.Spacing.xs)
                            .padding(.vertical, 2)
                            .background(badge.color.opacity(0.1))
                            .cornerRadius(AppTheme.Radius.small)
                    }
                }
                
                // 消息内容
                messageContent
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .padding(.vertical, AppTheme.Spacing.sm)
                    .background(wechatGreen)
                    .cornerRadius(AppTheme.Radius.medium)
                    .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: .trailing)
                
                // 引用预览（显示在消息内容下方，微信风格）
                if let refPreview = message.referencedMessagePreview {
                    WeChatStyleReferenceView(preview: refPreview)
                        .padding(.top, AppTheme.Spacing.xs)
                }
            }
        }
        .overlay(
            // 操作菜单（悬浮显示，不占用布局空间）
            Group {
                if isSelected {
                    WeChatStyleActionMenu(
                        onQuote: {
                            print("🔘 [MessageAction] 点击引用按钮")
                            onQuote()
                        },
                        onDelete: {
                            print("🔘 [MessageAction] 点击删除按钮")
                            onDelete()
                        },
                        onCancel: {
                            print("🔘 [MessageAction] 点击取消按钮")
                            onDismiss()
                        }
                    )
                    .offset(y: -AppTheme.Spacing.lg)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.8)).combined(with: .move(edge: .bottom)),
                        removal: .opacity.combined(with: .scale(scale: 0.8))
                    ))
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
                    .zIndex(1001)
                    .allowsHitTesting(true)
                }
            },
            alignment: .topTrailing
        )
        .onLongPressGesture {
            onLongPress()
        }
    }
    
    @ViewBuilder
    private var messageContent: some View {
        switch message.type {
        case .text:
            if let content = message.content {
                Text(content)
                    .font(.system(size: AppTheme.FontSize.body))
                    .foregroundColor(.white)
            }
        case .audio:
            HStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: "waveform")
                    .foregroundColor(.white)
                if let duration = message.audioDuration {
                    Text(formatDuration(duration))
                        .font(.system(size: AppTheme.FontSize.body))
                        .foregroundColor(.white)
                }
            }
            .frame(width: message.audioBubbleWidth)
        case .image:
            if let imagePath = message.imagePath,
               let url = manager.getFileURL(for: imagePath),
               let imageData = try? Data(contentsOf: url),
               let image = UIImage(data: imageData) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 200, height: 200)
                    .clipped()
                    .cornerRadius(AppTheme.Radius.medium)
            }
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let seconds = Int(duration)
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        if minutes > 0 {
            return String(format: "%d:%02d", minutes, remainingSeconds)
        } else {
            return String(format: "0:%02d", remainingSeconds)
        }
    }
}

// MARK: - 重命名弹窗
struct RenameNoteSheet: View {
    @Environment(\.dismiss) var dismiss
    let currentTitle: String
    let onSave: (String) -> Void
    
    @State private var newTitle: String = ""
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // 标题栏
                HStack {
                    Button("取消") {
                        dismiss()
                    }
                    .font(.system(size: AppTheme.FontSize.body))
                    .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("编辑标题")
                        .font(.system(size: AppTheme.FontSize.headline, weight: .semibold))
                    
                    Spacer()
                    
                    Button("保存") {
                        onSave(newTitle.isEmpty ? currentTitle : newTitle)
                        dismiss()
                    }
                    .font(.system(size: AppTheme.FontSize.headline, weight: .semibold))
                    .foregroundColor(.blue)
                }
                .padding(.horizontal, AppTheme.Spacing.xl)
                .padding(.top, 20) //AppTheme.Spacing.md
                .padding(.bottom, 20) //AppTheme.Spacing.sm
                .background(
                    GeometryReader { headerGeometry in
                        Color.clear
                    }
                )
                
                Divider()
                
                // 输入框区域
                VStack(spacing: AppTheme.Spacing.md) {
                    TextField("标题", text: $newTitle)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal, AppTheme.Spacing.xl)
                        .padding(.top, 30)//AppTheme.Spacing.xl
                }
                .padding(.bottom, AppTheme.Spacing.md)
            }
            .frame(height: 250, alignment: .top)
            .background(Color(.systemBackground))
            .onAppear {
                newTitle = currentTitle
            }
        }
    }
}

// MARK: - 图片选择器
struct QuickNoteImagePicker: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    let onImagePicked: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onImagePicked: onImagePicked)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onImagePicked: (UIImage) -> Void
        
        init(onImagePicked: @escaping (UIImage) -> Void) {
            self.onImagePicked = onImagePicked
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                onImagePicked(image)
            }
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

// MARK: - 加号菜单项
struct PlusMenuItem: View {
    let icon: String
    let title: String
    var size: CGFloat = 80  // 默认80x80pt，方案B使用70x70pt
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: size * 0.4))  // 图标大小随按钮尺寸调整
                    .foregroundColor(AppTheme.Colors.primary)
                    .frame(width: size, height: size)
                    .background(AppTheme.Colors.bgMain)
                    .cornerRadius(AppTheme.Radius.medium)
                
                Text(title)
                    .font(.system(size: AppTheme.FontSize.caption))
                    .foregroundColor(AppTheme.Colors.text)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 菜单按钮视图（带气泡菜单）
struct MenuButtonView: View {
    @Binding var showingMenu: Bool
    let hasInsight: Bool
    let hasPainPoint: Bool
    let hasSolution: Bool
    let onEditTitle: () -> Void
    let onInsight: () -> Void
    let onPainPoint: () -> Void
    let onSolution: () -> Void
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // 三个点按钮
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    showingMenu.toggle()
                }
            }) {
                Image(systemName: "ellipsis")
                    .foregroundColor(AppTheme.Colors.text)
            }
            
            // 气泡菜单
            if showingMenu {
                BubbleMenuView(
                    hasInsight: hasInsight,
                    hasPainPoint: hasPainPoint,
                    hasSolution: hasSolution,
                    onEditTitle: {
                        showingMenu = false
                        onEditTitle()
                    },
                    onInsight: {
                        showingMenu = false
                        onInsight()
                    },
                    onPainPoint: {
                        showingMenu = false
                        onPainPoint()
                    },
                    onSolution: {
                        showingMenu = false
                        onSolution()
                    }
                )
                .offset(x: -8, y: 36)
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
    }
}

// MARK: - 气泡菜单视图
struct BubbleMenuView: View {
    let hasInsight: Bool
    let hasPainPoint: Bool
    let hasSolution: Bool
    let onEditTitle: () -> Void
    let onInsight: () -> Void
    let onPainPoint: () -> Void
    let onSolution: () -> Void
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {
            // 小三角形（指向三个点）
            Triangle()
                .fill(.ultraThinMaterial)
                .frame(width: 12, height: 8)
                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: -1)
                .offset(x: -8)
            
            // 菜单内容
            VStack(alignment: .trailing, spacing: 0) {
                MenuItemButton(title: "编辑标题", action: onEditTitle)
                
                if hasInsight {
                    Divider()
                        .background(AppTheme.Colors.border.opacity(0.3))
                    MenuItemButton(title: "洞察", action: onInsight)
                }
                
                if hasPainPoint {
                    Divider()
                        .background(AppTheme.Colors.border.opacity(0.3))
                    MenuItemButton(title: "痛点", action: onPainPoint)
                }
                
                if hasSolution {
                    Divider()
                        .background(AppTheme.Colors.border.opacity(0.3))
                    MenuItemButton(title: "方案", action: onSolution)
                }
            }
            .background(.ultraThinMaterial)
            .cornerRadius(AppTheme.Radius.medium)
            .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
            .fixedSize(horizontal: true, vertical: false)
        }
    }
}

// MARK: - 菜单项按钮
struct MenuItemButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: AppTheme.FontSize.body))
                .foregroundColor(AppTheme.Colors.text)
                .padding(.horizontal, AppTheme.Spacing.lg)
                .padding(.vertical, AppTheme.Spacing.md)
                .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 三角形形状（用于气泡菜单的指向）
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - PreferenceKey for Voice Button Width
struct VoiceButtonWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - 微信风格操作菜单（横向工具条）
struct WeChatStyleActionMenu: View {
    let onQuote: () -> Void
    let onDelete: () -> Void
    let onCancel: () -> Void
    
    // 固定菜单高度
    private let menuHeight: CGFloat = 40
    
    var body: some View {
        HStack(spacing: 0) {
            // 引用按钮
            Button(action: {
                print("🔘 [WeChatStyleActionMenu] 引用按钮被点击")
                onQuote()
            }) {
                HStack(spacing: AppTheme.Spacing.xs) {
                    Image(systemName: "quote.bubble")
                        .font(.system(size: 14))
                    Text("引用")
                        .font(.system(size: AppTheme.FontSize.body))
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                }
                .foregroundColor(.white)
                .frame(height: menuHeight)
                .padding(.horizontal, AppTheme.Spacing.md)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            .simultaneousGesture(
                TapGesture().onEnded {
                    print("🔘 [WeChatStyleActionMenu] 引用按钮 TapGesture 触发")
                }
            )
            
            // 分隔线
            Rectangle()
                .fill(Color.white.opacity(0.3))
                .frame(width: 1)
                .frame(height: menuHeight * 0.6)
            
            // 删除按钮
            Button(action: {
                print("🔘 [WeChatStyleActionMenu] 删除按钮被点击")
                onDelete()
            }) {
                HStack(spacing: AppTheme.Spacing.xs) {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                    Text("删除")
                        .font(.system(size: AppTheme.FontSize.body))
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                }
                .foregroundColor(.white)
                .frame(height: menuHeight)
                .padding(.horizontal, AppTheme.Spacing.md)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            .simultaneousGesture(
                TapGesture().onEnded {
                    print("🔘 [WeChatStyleActionMenu] 删除按钮 TapGesture 触发")
                }
            )
            
            // 分隔线
            Rectangle()
                .fill(Color.white.opacity(0.3))
                .frame(width: 1)
                .frame(height: menuHeight * 0.6)
            
            // 取消按钮
            Button(action: {
                print("🔘 [WeChatStyleActionMenu] 取消按钮被点击")
                onCancel()
            }) {
                HStack(spacing: AppTheme.Spacing.xs) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14))
                    Text("取消")
                        .font(.system(size: AppTheme.FontSize.body))
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                }
                .foregroundColor(.white)
                .frame(height: menuHeight)
                .padding(.horizontal, AppTheme.Spacing.md)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            .simultaneousGesture(
                TapGesture().onEnded {
                    print("🔘 [WeChatStyleActionMenu] 取消按钮 TapGesture 触发")
                }
            )
        }
        .frame(height: menuHeight)
        .fixedSize(horizontal: true, vertical: true)
        .background(
            // 深色半透明背景
            Color.black.opacity(0.85)
                .cornerRadius(AppTheme.Radius.medium)
        )
        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 2)
        .allowsHitTesting(true)
        .onTapGesture {
            print("🔘 [WeChatStyleActionMenu] 菜单区域被点击")
        }
    }
}

// MARK: - 微信风格引用视图
struct WeChatStyleReferenceView: View {
    let preview: String
    
    // 估算单行文本宽度（字符数 * 平均字符宽度）
    private var estimatedTextWidth: CGFloat {
        let avgCharWidth: CGFloat = 7 // 估算平均字符宽度（根据字体大小 AppTheme.FontSize.caption）
        return CGFloat(preview.count) * avgCharWidth
    }
    
    // 判断是否需要右对齐（如果左对齐会超出屏幕）
    private var shouldAlignRight: Bool {
        // 可用宽度 = 屏幕宽度的75%（与消息气泡一致）
        let maxAvailableWidth = UIScreen.main.bounds.width * 0.75
        // 如果估算宽度超过可用宽度的70%，则右对齐（留一些余量）
        return estimatedTextWidth > maxAvailableWidth * 0.7
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
            // 左侧竖线（微信风格）
            Rectangle()
                .fill(Color.gray.opacity(0.5))
                .frame(width: 3)
                .cornerRadius(1.5)
            
            // 引用内容
            Text(preview)
                .font(.system(size: AppTheme.FontSize.caption))
                .foregroundColor(AppTheme.Colors.textSecondary)
                .lineLimit(2)
                .truncationMode(.tail)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: shouldAlignRight ? .trailing : .leading)
        }
        .padding(.horizontal, AppTheme.Spacing.sm)
        .padding(.vertical, AppTheme.Spacing.xs)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(AppTheme.Radius.small)
        .frame(
            maxWidth: shouldAlignRight ? UIScreen.main.bounds.width * 0.75 : nil,
            alignment: shouldAlignRight ? .trailing : .leading
        )
        .fixedSize(horizontal: !shouldAlignRight, vertical: false)
        // 确保短内容左边缘与消息气泡左边缘对齐（通过右对齐的VStack自然实现）
    }
}


// MARK: - iOS 16.0+ 兼容性扩展
private extension View {
    @ViewBuilder
    func applyRenameSheetModifiers() -> some View {
        if #available(iOS 16.4, *) {
            self
                .presentationDetents([.height(250)])
                .presentationDragIndicator(.hidden)
                .presentationBackground(.clear)
        } else if #available(iOS 16.0, *) {
            self
                .presentationDetents([.height(250)])
                .presentationDragIndicator(.hidden)
        } else {
            self
        }
    }
}

