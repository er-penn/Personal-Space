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

    // 表单验证
    @State private var showingAlert = false
    @State private var alertMessage = ""

    // Maybe清单相关状态
    @State private var showingMaybeList = false
    @State private var maybeListItems: [(title: String, description: String, location: String)] = []

    var body: some View {
        NavigationView {
            Form {
                // 活动内容
                Section(header:
                    HStack {
                        HStack(spacing: 4) {
                            Text("活动内容")
                                .font(.system(size: AppTheme.FontSize.subheadline, weight: .medium))
                                .foregroundColor(AppTheme.Colors.primary)
                            Text("*")
                                .font(.system(size: AppTheme.FontSize.subheadline, weight: .medium))
                                .foregroundColor(.red)
                        }

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
                Section(header:
                    HStack {
                        Text("活动描述")
                            .font(.system(size: AppTheme.FontSize.subheadline, weight: .medium))
                        Text("(选填)")
                            .font(.system(size: AppTheme.FontSize.caption))
                            .foregroundColor(.gray)
                    }
                ) {
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
                Section(header:
                    HStack {
                        Text("活动地点")
                            .font(.system(size: AppTheme.FontSize.subheadline, weight: .medium))
                        Text("(选填)")
                            .font(.system(size: AppTheme.FontSize.caption))
                            .foregroundColor(.gray)
                    }
                ) {
                    TextField("请输入活动地点", text: $location)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }

                // 时间选择
                Section(header: Text("活动时间及持续时间")) {
                    // 日期选择
                    VStack(alignment: .leading, spacing: 8) {
                        DatePicker("日期", selection: $selectedDate, in: (Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date())..., displayedComponents: .date)
                            .datePickerStyle(GraphicalDatePickerStyle())
                            .environment(\.locale, Locale(identifier: "zh_Hans_CN"))

                        HStack {
                            Image(systemName: "info.circle")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                            Text("今天是 \(formatTodayDate())，不可选择")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                    }

                    // 时间选择
                    DatePicker("开始时间", selection: $selectedTime, displayedComponents: .hourAndMinute)
                        .environment(\.locale, Locale(identifier: "zh_Hans_CN"))
                        .frame(maxWidth: .infinity, alignment: .trailing)

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
            .sheet(isPresented: $showingMaybeList) {
            MaybeListPickerView(
                items: maybeListItems.isEmpty ? loadMaybeList() : maybeListItems,
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
        durationHours > 0 || durationMinutes > 0
    }

    private func sendInvitation() {
        // 计算开始时间和持续时间
        let startTime = combineDateTime(date: selectedDate, time: selectedTime)
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

    private func formatTodayDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM月dd日"
        return formatter.string(from: Date())
    }

    // 加载Maybe清单数据（临时硬编码，实际应该从数据源获取）
    private func loadMaybeList() -> [(title: String, description: String, location: String)] {
        return [
            ("周末看电影", "一起去看最新上映的电影，然后吃晚饭", "万达影城"),
            ("公园散步", "在附近公园散步，呼吸新鲜空气", "中山公园"),
            ("咖啡店聊天", "找个安静的咖啡店，好好聊聊天", "星巴克"),
            ("一起做饭", "在家一起准备晚餐，享受烹饪乐趣", "家里"),
            ("去海边", "去海边看日落，听听海浪声", "海边栈道"),
            ("逛书店", "在书店里慢慢翻书，找找感兴趣的读物", "西西弗书店"),
            ("打保龄球", "来一场有趣的保龄球比赛，看谁得分更高", "汤姆熊保龄球馆"),
            ("看画展", "一起去看艺术展览，感受文化的熏陶", "市美术馆"),
            ("爬山运动", "周末去爬爬山，锻炼身体，亲近自然", "西山公园"),
            ("桌游吧", "玩各种有趣的桌面游戏，增进彼此默契", "欢乐桌游吧"),
            ("DIY烘焙", "一起制作美味的糕点，享受甜蜜时光", "手工烘焙坊"),
            ("骑单车", "沿着河边骑行，感受微风和阳光", "滨江路自行车道"),
            ("听音乐会", "一起去听现场音乐会，享受音乐的魅力", "音乐厅"),
            ("游乐园", "去游乐园玩各种刺激的项目，释放压力", "欢乐谷"),
            ("博物馆参观", "参观历史博物馆，学习新知识", "市博物馆")
        ]
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
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(item.title)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.primary)
                            Spacer()
                        }

                        Text(item.description)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .lineLimit(2)

                        HStack {
                            Image(systemName: "location")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                            Text(item.location)
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                    }
                    .padding(.vertical, 8)
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