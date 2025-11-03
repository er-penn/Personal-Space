//
//  CollaborationInvitationView.swift
//  Personal Space
//
//  Created by AI Assistant on 2025/1/27.
//

import SwiftUI

struct CollaborationInvitationView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var invitationManager = CollaborationInvitationManager()

    // 表单字段
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var location: String = ""
    @State private var selectedDate: Date = Date()
    @State private var selectedTime: Date = Date()
    @State private var durationHours: Int = 1
    @State private var durationMinutes: Int = 0
    @State private var showingTimePicker = false

    // 表单验证
    @State private var showingAlert = false
    @State private var alertMessage = ""

    // Maybe清单相关状态
    @State private var showingMaybeList = false
    @State private var maybeListItems: [(title: String, description: String, location: String)] = []

    init() {
        // 初始化Maybe清单数据（临时硬编码，实际应该从数据源获取）
        self.maybeListItems = loadMaybeList()
    }

    var body: some View {
        NavigationView {
            Form {
                // 活动内容
                Section(header:
                    HStack {
                        Text("活动内容")
                            .font(.system(size: AppTheme.FontSize.subheadline, weight: .medium))
                            .foregroundColor(AppTheme.Colors.primary)

                        Spacer()

                        Button(action: {
                            showingMaybeList = true
                        }) {
                            Image(systemName: "tray.and.arrow.down")
                                .font(.system(size: 16))
                                .foregroundColor(.blue)
                        }
                    }
                ) {
                    TextField("请输入活动内容", text: $title)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }

                // 活动描述
                Section(header: Text("活动描述")) {
                    if #available(iOS 16.0, *) {
                        TextField("请描述活动内容", text: $description, axis: .vertical)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .lineLimit(3...6)
                    } else {
                        // iOS 15 兼容：使用传统的多行文本输入
                        TextEditor(text: $description)
                            .frame(minHeight: 80, maxHeight: 120)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                            .overlay(
                                Group {
                                    if description.isEmpty {
                                        Text("请描述活动内容")
                                            .foregroundColor(.gray.opacity(0.5))
                                            .padding(.leading, 4)
                                            .padding(.top, 8)
                                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                            .allowsHitTesting(false)
                                    }
                                }
                            )
                    }
                }

                // 活动地点
                Section(header: Text("活动地点")) {
                    TextField("请输入活动地点", text: $location)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }

                // 时间选择
                Section(header: Text("活动时间")) {
                    // 日期选择
                    DatePicker("日期", selection: $selectedDate, displayedComponents: .date)
                        .datePickerStyle(GraphicalDatePickerStyle())

                    // 时间选择
                    HStack {
                        Text("时间")
                        Spacer()
                        Button(action: {
                            showingTimePicker = true
                        }) {
                            Text(formatTime(selectedTime))
                                .foregroundColor(.blue)
                        }
                    }

                    // 持续时间
                    HStack {
                        Text("持续时间")
                        Spacer()
                        Picker("小时", selection: $durationHours) {
                            ForEach(0...12, id: \.self) { hour in
                                Text("\(hour)小时").tag(hour)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(width: 80)

                        Picker("分钟", selection: $durationMinutes) {
                            ForEach([0, 15, 30, 45], id: \.self) { minute in
                                Text("\(minute)分").tag(minute)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(width: 80)
                    }
                }
            }
            .navigationTitle("发起邀请")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("发送") {
                        sendInvitation()
                    }
                    .disabled(!isFormValid)
                }
            }
        }
        .onAppear {
            // 设置默认时间为明天
            selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
            selectedTime = Calendar.current.date(bySettingHour: 14, minute: 0, second: 0, of: selectedDate) ?? selectedDate
        }
        .sheet(isPresented: $showingTimePicker) {
            CollaborationTimePickerView(selectedTime: $selectedTime, isPresented: $showingTimePicker)
        }
        .sheet(isPresented: $showingMaybeList) {
            MaybeListPickerView(
                items: maybeListItems,
                onItemSelected: { item in
                    title = item.title
                    description = item.description
                    location = item.location
                }
            )
        }
        .alert("提示", isPresented: $showingAlert) {
            Button("确定") { }
        } message: {
            Text(alertMessage)
        }
    }

    private var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        durationHours > 0 || durationMinutes > 0
    }

    private func sendInvitation() {
        // 检查24小时限制
        let startTime = combineDateTime(date: selectedDate, time: selectedTime)
        let timeUntilStart = startTime.timeIntervalSinceNow

        if timeUntilStart < 24 * 60 * 60 {
            alertMessage = "无法发起24小时内的邀请，请选择更晚的时间"
            showingAlert = true
            return
        }

        // 计算持续时间
        let duration = TimeInterval(durationHours * 3600 + durationMinutes * 60)

        // 创建邀请
        invitationManager.createInvitation(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            description: description.trimmingCharacters(in: .whitespacesAndNewlines),
            location: location.trimmingCharacters(in: .whitespacesAndNewlines),
            startTime: startTime,
            duration: duration
        )

        // 关闭页面
        presentationMode.wrappedValue.dismiss()
    }

    private func combineDateTime(date: Date, time: Date) -> Date {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: time)

        var combinedComponents = DateComponents()
        combinedComponents.year = dateComponents.year
        combinedComponents.month = dateComponents.month
        combinedComponents.day = dateComponents.day
        combinedComponents.hour = timeComponents.hour
        combinedComponents.minute = timeComponents.minute
        combinedComponents.second = timeComponents.second

        return calendar.date(from: combinedComponents) ?? date
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    // 加载Maybe清单数据（临时硬编码，实际应该从数据源获取）
    private func loadMaybeList() -> [(title: String, description: String, location: String)] {
        return [
            ("周末看电影", "一起去看最新上映的电影，然后吃晚饭", "万达影城"),
            ("公园散步", "在附近公园散步，呼吸新鲜空气", "中山公园"),
            ("咖啡店聊天", "找个安静的咖啡店，好好聊聊天", "星巴克"),
            ("一起做饭", "在家一起准备晚餐，享受烹饪乐趣", "家里"),
            ("去海边", "去海边看日落，听听海浪声", "海边栈道")
        ]
    }
}

// MARK: - 协作邀请时间选择器（重命名避免与EnergyPlanningView冲突）
struct CollaborationTimePickerView: View {
    @Binding var selectedTime: Date
    @Binding var isPresented: Bool

    var body: some View {
        NavigationView {
            VStack {
                DatePicker("选择时间", selection: $selectedTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(WheelDatePickerStyle())
                    .labelsHidden()

                Spacer()
            }
            .padding()
            .navigationTitle("选择时间")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        isPresented = false
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("确定") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

// MARK: - Maybe清单选择器
struct MaybeListPickerView: View {
    let items: [(title: String, description: String, location: String)]
    let onItemSelected: ((_ item: (title: String, description: String, location: String)) -> Void)
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            List {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        HStack {
                            Text(item.title)
                                .font(.system(size: AppTheme.FontSize.body, weight: .medium))
                                .foregroundColor(AppTheme.Colors.text)
                            Spacer()
                        }

                        Text(item.description)
                            .font(.system(size: AppTheme.FontSize.caption))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .lineLimit(2)

                        HStack {
                            Image(systemName: "location")
                                .font(.system(size: AppTheme.FontSize.caption2))
                                .foregroundColor(AppTheme.Colors.textSecondary)
                            Text(item.location)
                                .font(.system(size: AppTheme.FontSize.caption))
                                .foregroundColor(AppTheme.Colors.textSecondary)
                            Spacer()
                        }
                    }
                    .padding(.vertical, AppTheme.Spacing.sm)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onItemSelected(item)
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .navigationTitle("Maybe清单")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    CollaborationInvitationView()
}