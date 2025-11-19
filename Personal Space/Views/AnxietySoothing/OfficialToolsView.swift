//
//  OfficialToolsView.swift
//  Personal Space
//
//  Created by Penn on 2025/1/27.
//

import SwiftUI

struct OfficialToolsView: View {
    @EnvironmentObject var toolsManager: OfficialToolsManager
    @EnvironmentObject var usageManager: UsageRecordManager
    @State private var selectedTool: OfficialTool?
    @State private var currentStep = 0
    @State private var startTime: Date?
    @State private var isActive = false
    @State private var showingCompletion = false
    @State private var effectivenessRating: Int?
    @State private var notes: String = ""

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    // 工具卡片网格
                    toolsGrid

                    Spacer()
                }
                .padding(AppTheme.Spacing.lg)
            }
            .background(AppGradient.background)
            .navigationTitle("官方工具")
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(item: $selectedTool) { tool in
            ToolDetailView(
                tool: tool,
                isActive: $isActive,
                currentStep: $currentStep,
                startTime: $startTime,
                showingCompletion: $showingCompletion,
                effectivenessRating: $effectivenessRating,
                notes: $notes
            )
        }
        .alert("完成记录", isPresented: $showingCompletion) {
            VStack(spacing: 16) {
                Text("请评价这次练习的效果")
                    .font(.system(size: 16, weight: .medium))

                Picker("评分", selection: $effectivenessRating) {
                    ForEach(1...5, id: \.self) { rating in
                        Text("\(rating) 分").tag(rating)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())

                if #available(iOS 16.0, *) {
                    TextField("备注（可选）", text: $notes, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(3)
                } else {
                    // iOS 15 兼容：使用 TextEditor
                    ZStack(alignment: .topLeading) {
                        if notes.isEmpty {
                            Text("备注（可选）")
                                .foregroundColor(.gray)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 8)
                        }
                        TextEditor(text: $notes)
                            .frame(minHeight: 60)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }
                }

                HStack {
                    Button("跳过") {
                        finishSession()
                    }
                    .foregroundColor(.gray)

                    Spacer()

                    Button("提交") {
                        finishSession()
                    }
                    .foregroundColor(.blue)
                }
            }
            .padding()
        }
    }

    // MARK: - 工具网格
    private var toolsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: AppTheme.Spacing.md) {
            ForEach(toolsManager.tools) { tool in
                ToolCardView(tool: tool) {
                    selectedTool = tool
                    currentStep = 0
                    isActive = true
                    startTime = Date()
                }
            }
        }
    }

    // MARK: - 私有方法
    private func finishSession() {
        guard let tool = selectedTool,
              let start = startTime else { return }

        let endTime = Date()
        let record = UsageRecord(
            toolType: tool.title,
            startTime: start,
            endTime: endTime,
            effectivenessRating: effectivenessRating,
            notes: notes.isEmpty ? nil : notes
        )

        usageManager.addRecord(record)

        // 重置状态
        isActive = false
        currentStep = 0
        startTime = nil
        selectedTool = nil
        effectivenessRating = nil
        notes = ""
        showingCompletion = false
    }
}

// MARK: - 工具卡片视图
struct ToolCardView: View {
    let tool: OfficialTool
    let onTap: () -> Void

    var body: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // 图标
            Image(systemName: tool.iconName)
                .font(.system(size: 40))
                .foregroundColor(colorFromString(tool.color))

            // 标题
            Text(tool.title)
                .font(.system(size: AppTheme.FontSize.headline, weight: .semibold))
                .foregroundColor(AppTheme.Colors.text)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            // 描述
            Text(tool.description)
                .font(.system(size: AppTheme.FontSize.body))
                .foregroundColor(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(3)

            // 时长
            HStack {
                Image(systemName: "clock")
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.Colors.textSecondary)

                Text("\(Int(tool.duration / 60))分钟")
                    .font(.system(size: AppTheme.FontSize.caption))
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
        .padding(AppTheme.Spacing.lg)
        .frame(maxWidth: .infinity)
        .background(AppTheme.Colors.cardBg)
        .cornerRadius(AppTheme.Radius.large)
        .shadow(color: AppTheme.Shadows.card, radius: 6, x: 0, y: 3)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.large)
                .stroke(colorFromString(tool.color).opacity(0.3), lineWidth: 1)
        )
        .onTapGesture {
            onTap()
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 工具详情视图
struct ToolDetailView: View {
    let tool: OfficialTool
    @Binding var isActive: Bool
    @Binding var currentStep: Int
    @Binding var startTime: Date?
    @Binding var showingCompletion: Bool
    @Binding var effectivenessRating: Int?
    @Binding var notes: String
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            // 头部信息
            headerSection

            // 进度指示器
            progressSection

            // 指导步骤
            instructionsSection

            // 控制按钮
            controlSection

            Spacer()
        }
        .padding(AppTheme.Spacing.lg)
        .background(AppGradient.background)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("关闭") {
                    if isActive {
                        stopSession()
                    }
                    // 如果完成记录弹窗正在显示，先关闭它
                    if showingCompletion {
                        showingCompletion = false
                    }
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
        .onDisappear {
            if isActive {
                stopSession()
            }
            // 当视图消失时，如果完成记录弹窗还在显示，关闭它
            if showingCompletion {
                showingCompletion = false
            }
        }
    }

    // MARK: - 视图组件
    private var headerSection: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            HStack {
                Image(systemName: tool.iconName)
                    .font(.system(size: 30))
                    .foregroundColor(colorFromString(tool.color))

                VStack(alignment: .leading, spacing: 4) {
                    Text(tool.title)
                        .font(.system(size: AppTheme.FontSize.headline, weight: .semibold))
                        .foregroundColor(AppTheme.Colors.text)

                    Text("预计时长：\(Int(tool.duration / 60))分钟")
                        .font(.system(size: AppTheme.FontSize.caption))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }

                Spacer()

                // 状态指示器
                Circle()
                    .fill(isActive ? Color.green : Color.gray)
                    .frame(width: 12, height: 12)
            }

            Text(tool.description)
                .font(.system(size: AppTheme.FontSize.body))
                .foregroundColor(AppTheme.Colors.text)
                .multilineTextAlignment(.leading)
        }
        .padding()
        .background(AppTheme.Colors.cardBg)
        .cornerRadius(AppTheme.Radius.large)
    }

    private var progressSection: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Text("进度：\(currentStep + 1)/\(tool.instructions.count)")
                .font(.system(size: AppTheme.FontSize.subheadline, weight: .medium))
                .foregroundColor(AppTheme.Colors.text)

            ProgressView(value: Double(currentStep + 1), total: Double(tool.instructions.count))
                .progressViewStyle(LinearProgressViewStyle(tint: colorFromString(tool.color)))
                .frame(height: 8)
        }
    }

    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("练习步骤")
                .font(.system(size: AppTheme.FontSize.headline, weight: .semibold))
                .foregroundColor(AppTheme.Colors.text)

            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                ForEach(Array(tool.instructions.enumerated()), id: \.offset) { index, instruction in
                    HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
                        Text("\(index + 1).")
                            .font(.system(size: AppTheme.FontSize.body, weight: .medium))
                            .foregroundColor(colorFromString(tool.color))
                            .frame(width: 25, alignment: .leading)

                        Text(instruction)
                            .font(.system(size: AppTheme.FontSize.body))
                            .foregroundColor(index == currentStep ? AppTheme.Colors.text : AppTheme.Colors.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.vertical, AppTheme.Spacing.xs)
                    .background(index == currentStep ? colorFromString(tool.color).opacity(0.1) : Color.clear)
                    .cornerRadius(AppTheme.Radius.small)
                }
            }
        }
    }

    private var controlSection: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            if isActive {
                // 练习进行中：显示停止按钮和步骤控制按钮
                Button(action: stopSession) {
                    HStack {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 18))
                        Text("停止练习")
                            .font(.system(size: AppTheme.FontSize.headline, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red)
                    .cornerRadius(AppTheme.Radius.large)
                }
                .buttonStyle(PlainButtonStyle())
                
                // 步骤控制按钮
                HStack(spacing: AppTheme.Spacing.md) {
                    if currentStep > 0 {
                        Button(action: previousStep) {
                            HStack {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 16))
                                Text("上一步")
                            }
                            .foregroundColor(colorFromString(tool.color))
                            .padding(.horizontal, AppTheme.Spacing.lg)
                            .padding(.vertical, AppTheme.Spacing.md)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                                    .stroke(colorFromString(tool.color), lineWidth: 1)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    } else {
                        // 第一步时，添加一个占位视图，使"下一步"按钮与后续步骤位置一致
                        HStack {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16))
                            Text("上一步")
                        }
                        .foregroundColor(.clear)
                        .padding(.horizontal, AppTheme.Spacing.lg)
                        .padding(.vertical, AppTheme.Spacing.md)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                                .stroke(Color.clear, lineWidth: 1)
                        )
                        .allowsHitTesting(false)
                    }
                    
                    if currentStep < tool.instructions.count - 1 {
                        Button(action: nextStep) {
                            HStack {
                                Text("下一步")
                                    .font(.system(size: AppTheme.FontSize.subheadline, weight: .medium))
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 16))
                            }
                            .foregroundColor(colorFromString(tool.color))
                            .padding(.horizontal, AppTheme.Spacing.lg)
                            .padding(.vertical, AppTheme.Spacing.md)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                                    .stroke(colorFromString(tool.color), lineWidth: 1)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    } else {
                        Button(action: completeSession) {
                            HStack {
                                Text("完成")
                                    .font(.system(size: AppTheme.FontSize.subheadline, weight: .medium))
                                Image(systemName: "checkmark")
                                    .font(.system(size: 16))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, AppTheme.Spacing.lg)
                            .padding(.vertical, AppTheme.Spacing.md)
                            .background(Color.green)
                            .cornerRadius(AppTheme.Radius.medium)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            } else {
                // 未开始练习：只显示开始按钮
                Button(action: startSession) {
                    HStack {
                        Image(systemName: "play.fill")
                            .font(.system(size: 18))
                        Text(currentStep == 0 ? "开始练习" : "继续练习")
                            .font(.system(size: AppTheme.FontSize.headline, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(colorFromString(tool.color))
                    .cornerRadius(AppTheme.Radius.large)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }

    // MARK: - 控制方法
    private func startSession() {
        isActive = true
        if currentStep == 0 {
            startTime = Date()
        }
    }

    private func stopSession() {
        isActive = false
    }

    private func previousStep() {
        if currentStep > 0 {
            currentStep -= 1
        }
    }

    private func nextStep() {
        if currentStep < tool.instructions.count - 1 {
            currentStep += 1
        }
    }

    private func completeSession() {
        isActive = false
        currentStep = 0  // 重置到第一步
        showingCompletion = true
    }
}

// MARK: - 预览
#Preview {
    let sampleToolsManager = OfficialToolsManager()

    return OfficialToolsView()
        .environmentObject(sampleToolsManager)
        .environmentObject(UsageRecordManager())
}