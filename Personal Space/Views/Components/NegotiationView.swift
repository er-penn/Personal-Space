//
//  NegotiationView.swift
//  Personal Space
//
//  Created by AI Assistant on 2025/1/27.
//

import SwiftUI

struct NegotiationView: View {
    let invitation: CollaborationInvitation
    let onClose: () -> Void
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var invitationManager = CollaborationInvitationManager()

    // 协商表单字段
    @State private var newLocation: String = ""
    @State private var newDurationHours: Int = 1
    @State private var newDurationMinutes: Int = 0
    @State private var selectedDates: [Date] = []
    @State private var showingDatePicker = false
    @State private var showingTimePicker = false
    @State private var tempSelectedDate = Date()

    // 多选项内容
    @State private var timeOptions: [Date] = []
    @State private var contentOptions: [String] = [""]
    @State private var showingContentOptionsEditor = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("协商修改")) {
                    // 活动地点
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        Text("地点")
                            .font(.system(size: AppTheme.FontSize.subheadline, weight: .medium))
                        TextField("新的活动地点", text: $newLocation)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }

                    // 持续时间
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        Text("持续时间")
                            .font(.system(size: AppTheme.FontSize.subheadline, weight: .medium))

                        HStack {
                            Picker("小时", selection: $newDurationHours) {
                                ForEach(0...12, id: \.self) { hour in
                                    Text("\(hour)小时").tag(hour)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .frame(width: 80)

                            Picker("分钟", selection: $newDurationMinutes) {
                                ForEach([0, 15, 30, 45], id: \.self) { minute in
                                    Text("\(minute)分").tag(minute)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .frame(width: 80)
                        }
                    }
                }

                Section(header: Text("时间选项（提供多个让对方选择）")) {
                    Button("添加时间选项") {
                        showingDatePicker = true
                    }
                    .foregroundColor(.blue)

                    ForEach(Array(timeOptions.enumerated()), id: \.offset) { index, date in
                        HStack {
                            Text(formatDateTime(date))
                                .font(.system(size: AppTheme.FontSize.body))
                            Spacer()
                            Button("删除") {
                                timeOptions.remove(at: index)
                            }
                            .foregroundColor(.red)
                            .font(.system(size: AppTheme.FontSize.caption))
                        }
                    }
                }

                Section(header: Text("内容选项（提供多个活动方案让对方选择）")) {
                    Button("编辑内容选项") {
                        showingContentOptionsEditor = true
                    }
                    .foregroundColor(.blue)

                    ForEach(Array(contentOptions.enumerated()), id: \.offset) { index, content in
                        if !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            HStack {
                                Text(content)
                                    .font(.system(size: AppTheme.FontSize.body))
                                Spacer()
                                Button("删除") {
                                    contentOptions.remove(at: index)
                                }
                                .foregroundColor(.red)
                                .font(.system(size: AppTheme.FontSize.caption))
                            }
                        }
                    }
                }

                Section {
                    Button("直接微信商量") {
                        invitationManager.respondToInvitation(invitation, status: .wechatNegotiating)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.purple)
                }
            }
            .navigationTitle("协商修改")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        onClose()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("发送") {
                        sendNegotiation()
                    }
                    .disabled(!hasModifications)
                }
            }
        }
        .onAppear {
            newLocation = invitation.location
            let hours = Int(invitation.duration) / 3600
            let minutes = (Int(invitation.duration) % 3600) / 60
            newDurationHours = hours
            newDurationMinutes = minutes
        }
        .sheet(isPresented: $showingDatePicker) {
            NavigationView {
                DatePicker("选择时间", selection: $tempSelectedDate, displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .environment(\.locale, Locale(identifier: "zh_Hans_CN"))
                    .padding()
                    .navigationTitle("选择时间")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("取消") {
                                showingDatePicker = false
                            }
                        }
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("添加") {
                                if !timeOptions.contains(tempSelectedDate) {
                                    timeOptions.append(tempSelectedDate)
                                    timeOptions.sort()
                                }
                                showingDatePicker = false
                            }
                        }
                    }
            }
        }
        .sheet(isPresented: $showingContentOptionsEditor) {
            ContentOptionsEditorView(
                contentOptions: $contentOptions,
                isPresented: $showingContentOptionsEditor
            )
        }
    }

    private var hasModifications: Bool {
        !newLocation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        newLocation != invitation.location ||
        newDurationHours != Int(invitation.duration) / 3600 ||
        newDurationMinutes != (Int(invitation.duration) % 3600) / 60 ||
        !timeOptions.isEmpty ||
        contentOptions.contains { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    private func sendNegotiation() {
        let newDuration = TimeInterval(newDurationHours * 3600 + newDurationMinutes * 60)
        let finalLocation = newLocation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : newLocation.trimmingCharacters(in: .whitespacesAndNewlines)

        let finalTimeOptions = timeOptions.isEmpty ? nil : timeOptions
        let finalContentOptions = contentOptions.contains { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty } ? contentOptions.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty } : nil

        invitationManager.createNegotiation(
            for: invitation,
            timeOptions: finalTimeOptions,
            contentOptions: finalContentOptions,
            newLocation: finalLocation,
            newDuration: newDuration
        )

        onClose()
    }

    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM月dd日 HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - 内容选项编辑器
struct ContentOptionsEditorView: View {
    @Binding var contentOptions: [String]
    @Binding var isPresented: Bool

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("活动内容选项")) {
                    ForEach(Array(contentOptions.enumerated()), id: \.offset) { index, content in
                        VStack(alignment: .trailing, spacing: AppTheme.Spacing.xs) {
                            TextField("活动内容 \(index + 1)", text: Binding(
                                get: { content },
                                set: { contentOptions[index] = $0 }
                            ))
                            .textFieldStyle(RoundedBorderTextFieldStyle())

                            if contentOptions.count > 1 {
                                Button("删除") {
                                    contentOptions.remove(at: index)
                                }
                                .foregroundColor(.red)
                                .font(.system(size: AppTheme.FontSize.caption))
                            }
                        }
                    }

                    Button("添加选项") {
                        contentOptions.append("")
                    }
                    .foregroundColor(.blue)
                }
            }
            .navigationTitle("编辑内容选项")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        isPresented = false
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        // 移除空选项
                        contentOptions = contentOptions.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                        isPresented = false
                    }
                }
            }
        }
    }
}

#Preview {
    NegotiationView(invitation: CollaborationInvitation(
        title: "周末看电影",
        description: "一起去电影院看最新上映的电影",
        location: "万达影城",
        startTime: Date().addingTimeInterval(86400 * 2),
        duration: 7200,
        createdBy: "用户A"
    )) {
        // onClose action
    }
}