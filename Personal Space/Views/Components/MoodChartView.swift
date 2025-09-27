//
//  MoodChartView.swift
//  Personal Space
//
//  Created by Penn on 2025/1/27.
//

import SwiftUI

struct MoodChartView: View {
    @EnvironmentObject var userState: UserState
    @State private var currentMood: Double = 5.0
    @State private var showingRecordButton = false
    @State private var moodNote: String = ""
    @State private var showingMoodRecordPage = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            // 标题 - 可点击进入心情记录页面
            Button(action: {
                showingMoodRecordPage = true
            }) {
                HStack {
                    Text("心情记录")
                        .font(.system(size: AppTheme.FontSize.headline, weight: .semibold))
                        .foregroundColor(AppTheme.Colors.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: AppTheme.FontSize.caption))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // 滑动条
            VStack(spacing: AppTheme.Spacing.md) {
                HStack {
                    Text("😢")
                        .font(.system(size: 24))
                    Spacer()
                    Text("😊")
                        .font(.system(size: 24))
                }
                
                Slider(value: $currentMood, in: 1...10, step: 0.5)
                    .accentColor(getMoodColor(currentMood))
                    .onChange(of: currentMood) { _ in
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showingRecordButton = true
                        }
                    }
                
                Text("当前心情：\(String(format: "%.1f", currentMood))/10")
                    .font(.system(size: AppTheme.FontSize.body))
                    .foregroundColor(AppTheme.Colors.textSecondary)
                
                // 备注框和记录按钮 - 当滑动滑块时显示
                if showingRecordButton {
                    HStack(spacing: AppTheme.Spacing.md) {
                        // 备注输入框
                        TextField("添加备注（可选）", text: $moodNote)
                            .font(.system(size: AppTheme.FontSize.body))
                            .padding(.horizontal, AppTheme.Spacing.md)
                            .padding(.vertical, AppTheme.Spacing.sm)
                            .background(
                                RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                                    .fill(AppTheme.Colors.bgMain)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                                            .stroke(AppTheme.Colors.border.opacity(0.3), lineWidth: 1)
                                    )
                            )
                            .foregroundColor(AppTheme.Colors.text)
                        
                        // 记录按钮
                        Button("记录") {
                            recordMood()
                        }
                        .font(.system(size: AppTheme.FontSize.subheadline, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, AppTheme.Spacing.lg)
                        .padding(.vertical, AppTheme.Spacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                                .fill(getMoodColor(currentMood))
                                .shadow(
                                    color: getMoodColor(currentMood).opacity(0.3),
                                    radius: 4,
                                    x: 0,
                                    y: 2
                                )
                        )
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            
            // 心情趋势图
            if !userState.moodRecords.isEmpty {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    Text("心情趋势")
                        .font(.system(size: AppTheme.FontSize.subheadline, weight: .medium))
                        .foregroundColor(AppTheme.Colors.text)
                    
                    MoodTrendChart(moodRecords: userState.moodRecords)
                        .frame(height: 120)
                        .background(AppTheme.Colors.bgMain)
                        .cornerRadius(AppTheme.Radius.medium)
                }
            }
        }
        .padding(AppTheme.Spacing.lg)
        .background(AppGradient.cardBackground)
        .cornerRadius(AppTheme.Radius.card)
        .shadow(
            color: AppTheme.Shadows.card,
            radius: 8,
            x: 0,
            y: 4
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                .stroke(AppTheme.Colors.border, lineWidth: 1)
        )
        .sheet(isPresented: $showingMoodRecordPage) {
            MoodRecordPageView()
                .environmentObject(userState)
        }
    }
    
    private func recordMood() {
        let trimmedNote = moodNote.trimmingCharacters(in: .whitespacesAndNewlines)
        let newRecord = MoodRecord(
            value: currentMood,
            timestamp: Date(),
            note: trimmedNote.isEmpty ? nil : trimmedNote
        )
        
        withAnimation(.easeInOut(duration: 0.3)) {
            userState.moodRecords.append(newRecord)
            showingRecordButton = false
            moodNote = ""
        }
    }
    
    private func getMoodColor(_ mood: Double) -> Color {
        switch mood {
        case 1..<3: return .red
        case 3..<5: return .orange
        case 5..<7: return .yellow
        case 7..<9: return .green
        default: return .blue
        }
    }
}

struct MoodDataPoint: Identifiable {
    let id = UUID()
    let time: Date
    let mood: Double
}

struct MoodTrendChart: View {
    let moodRecords: [MoodRecord]
    @State private var selectedRecord: MoodRecord? = nil
    
    var body: some View {
        GeometryReader { geometry in
            if moodRecords.count >= 2 {
                ZStack {
                    // 绘制曲线
                    MoodPath(moodRecords: moodRecords, geometry: geometry)
                    
                    // 绘制数据点
                    MoodDataPoints(moodRecords: moodRecords, geometry: geometry, selectedRecord: $selectedRecord)
                }
            } else {
                Text("记录更多心情数据以查看趋势")
                    .font(.system(size: AppTheme.FontSize.body))
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .overlay(
            // 备注提示框
            Group {
                if let record = selectedRecord, let note = record.note {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            VStack(alignment: .leading, spacing: 4) {
                                Text(formatTime(record.timestamp))
                                    .font(.system(size: AppTheme.FontSize.caption2, weight: .medium))
                                    .foregroundColor(.white)
                                
                                Text(note)
                                    .font(.system(size: AppTheme.FontSize.caption))
                                    .foregroundColor(.white)
                                    .lineLimit(3)
                            }
                            .padding(8)
                            .background(Color.black.opacity(0.8))
                            .cornerRadius(8)
                            .padding(.trailing, 20)
                            .padding(.bottom, 20)
                        }
                    }
                    .transition(.opacity.combined(with: .scale))
                }
            }
        )
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedRecord = nil
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

struct MoodPath: View {
    let moodRecords: [MoodRecord]
    let geometry: GeometryProxy
    
    var body: some View {
        Path { path in
            let points = calculatePoints()
            if !points.isEmpty {
                path.move(to: points[0])
                
                for i in 1..<points.count {
                    let currentPoint = points[i]
                    let previousPoint = points[i-1]
                    
                    let controlPoint1 = CGPoint(
                        x: previousPoint.x + (currentPoint.x - previousPoint.x) / 3,
                        y: previousPoint.y
                    )
                    let controlPoint2 = CGPoint(
                        x: currentPoint.x - (currentPoint.x - previousPoint.x) / 3,
                        y: currentPoint.y
                    )
                    
                    path.addCurve(
                        to: currentPoint,
                        control1: controlPoint1,
                        control2: controlPoint2
                    )
                }
            }
        }
        .stroke(AppTheme.Colors.primary, lineWidth: 3)
    }
    
    private func calculatePoints() -> [CGPoint] {
        let width = geometry.size.width
        let height = geometry.size.height
        let padding: CGFloat = 20
        let xStep = (width - padding * 2) / CGFloat(max(1, moodRecords.count - 1))
        let yStep = (height - padding * 2) / 9.0
        
        var points: [CGPoint] = []
        for (index, record) in moodRecords.enumerated() {
            let x = padding + CGFloat(index) * xStep
            let y = height - padding - (CGFloat(record.value - 1) * yStep)
            points.append(CGPoint(x: x, y: y))
        }
        return points
    }
}

struct MoodDataPoints: View {
    let moodRecords: [MoodRecord]
    let geometry: GeometryProxy
    @Binding var selectedRecord: MoodRecord?
    
    var body: some View {
        ForEach(Array(moodRecords.enumerated()), id: \.offset) { index, record in
            let point = calculatePoint(for: index, record: record)
            let hasNote = record.note != nil && !record.note!.isEmpty
            
            Circle()
                .fill(hasNote ? Color.orange : AppTheme.Colors.primary)
                .frame(width: hasNote ? 10 : 8, height: hasNote ? 10 : 8)
                .position(x: point.x, y: point.y)
                .onTapGesture {
                    if hasNote {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedRecord = record
                        }
                    }
                }
        }
    }
    
    private func calculatePoint(for index: Int, record: MoodRecord) -> CGPoint {
        let width = geometry.size.width
        let height = geometry.size.height
        let padding: CGFloat = 20
        let xStep = (width - padding * 2) / CGFloat(max(1, moodRecords.count - 1))
        let yStep = (height - padding * 2) / 9.0
        
        let x = padding + CGFloat(index) * xStep
        let y = height - padding - (CGFloat(record.value - 1) * yStep)
        return CGPoint(x: x, y: y)
    }
}

// MARK: - 心情记录页面
struct MoodRecordPageView: View {
    @EnvironmentObject var userState: UserState
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedDate: Date? = nil
    @State private var showingCalendar = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AppGradient.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 隐藏的日历
                    if showingCalendar {
                        MoodRecordCalendarView(
                            selectedDate: $selectedDate,
                            moodRecords: userState.moodRecords
                        )
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    // 心情记录列表
                    ScrollView {
                        LazyVStack(spacing: AppTheme.Spacing.lg) {
                            if let selectedDate = selectedDate {
                                // 显示选中日期的记录
                                DailyMoodRecords(
                                    date: selectedDate,
                                    moodRecords: userState.moodRecords.filter { 
                                        Calendar.current.isDate($0.timestamp, inSameDayAs: selectedDate)
                                    }
                                )
                            } else {
                                // 显示所有记录，按日期分组
                                ForEach(groupedMoodRecords.keys.sorted(by: >), id: \.self) { date in
                                    DailyMoodRecords(
                                        date: date,
                                        moodRecords: groupedMoodRecords[date] ?? []
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, AppTheme.Spacing.lg)
                        .padding(.top, AppTheme.Spacing.lg)
                    }
                }
            }
            .navigationTitle("心情记录")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(AppTheme.Colors.primary)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showingCalendar.toggle()
                        }
                    }) {
                        Image(systemName: showingCalendar ? "calendar.badge.minus" : "calendar")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(AppTheme.Colors.primary)
                    }
                }
            }
        }
    }
    
    private var groupedMoodRecords: [Date: [MoodRecord]] {
        let calendar = Calendar.current
        var grouped: [Date: [MoodRecord]] = [:]
        
        for record in userState.moodRecords {
            let date = calendar.startOfDay(for: record.timestamp)
            if grouped[date] == nil {
                grouped[date] = []
            }
            grouped[date]?.append(record)
        }
        
        // 按时间排序每个日期的记录
        for date in grouped.keys {
            grouped[date]?.sort { $0.timestamp < $1.timestamp }
        }
        
        return grouped
    }
}

// MARK: - 心情记录日历视图
struct MoodRecordCalendarView: View {
    @Binding var selectedDate: Date?
    let moodRecords: [MoodRecord]
    
    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月"
        return formatter
    }()
    
    @State private var currentMonth = Date()
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // 月份标题
            HStack {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(AppTheme.Colors.primary)
                }
                
                Spacer()
                
                Text(dateFormatter.string(from: currentMonth))
                    .font(.system(size: AppTheme.FontSize.headline, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.text)
                
                Spacer()
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
                    }
                }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(AppTheme.Colors.primary)
                }
            }
            .padding(.horizontal, AppTheme.Spacing.lg)
            
            // 星期标题
            HStack {
                ForEach(["日", "一", "二", "三", "四", "五", "六"], id: \.self) { day in
                    Text(day)
                        .font(.system(size: AppTheme.FontSize.caption, weight: .medium))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, AppTheme.Spacing.lg)
            
            // 日期网格
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(getDaysInMonth(), id: \.self) { date in
                    if let date = date {
                        let hasRecords = hasMoodRecords(for: date)
                        let isSelected = selectedDate != nil && calendar.isDate(date, inSameDayAs: selectedDate!)
                        
                        Button(action: {
                            if hasRecords {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedDate = date
                                }
                            }
                        }) {
                            Text("\(calendar.component(.day, from: date))")
                                .font(.system(size: AppTheme.FontSize.body, weight: .medium))
                                .foregroundColor(hasRecords ? AppTheme.Colors.text : AppTheme.Colors.textSecondary.opacity(0.5))
                                .frame(width: 32, height: 32)
                                .background(
                                    Circle()
                                        .fill(isSelected ? AppTheme.Colors.primary : Color.clear)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(hasRecords ? AppTheme.Colors.primary : Color.clear, lineWidth: 1)
                                )
                        }
                        .disabled(!hasRecords)
                    } else {
                        Text("")
                            .frame(width: 32, height: 32)
                    }
                }
            }
            .padding(.horizontal, AppTheme.Spacing.lg)
        }
        .padding(.vertical, AppTheme.Spacing.lg)
        .background(AppTheme.Colors.cardBg)
        .cornerRadius(AppTheme.Radius.large)
        .shadow(color: AppTheme.Shadows.card, radius: 6, x: 0, y: 3)
        .padding(.horizontal, AppTheme.Spacing.lg)
    }
    
    private func getDaysInMonth() -> [Date?] {
        let startOfMonth = calendar.dateInterval(of: .month, for: currentMonth)?.start ?? currentMonth
        let range = calendar.range(of: .day, in: .month, for: currentMonth) ?? 1..<32
        let numberOfDays = range.count
        let firstWeekday = calendar.component(.weekday, from: startOfMonth)
        
        var days: [Date?] = []
        
        // 添加空白日期
        for _ in 1..<firstWeekday {
            days.append(nil)
        }
        
        // 添加月份中的日期
        for day in 1...numberOfDays {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                days.append(date)
            }
        }
        
        return days
    }
    
    private func hasMoodRecords(for date: Date) -> Bool {
        return moodRecords.contains { record in
            calendar.isDate(record.timestamp, inSameDayAs: date)
        }
    }
}

// MARK: - 每日心情记录
struct DailyMoodRecords: View {
    let date: Date
    let moodRecords: [MoodRecord]
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM月dd日"
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            // 日期标题
            Text(dateFormatter.string(from: date))
                .font(.system(size: AppTheme.FontSize.headline, weight: .semibold))
                .foregroundColor(AppTheme.Colors.primary)
            
            if moodRecords.isEmpty {
                Text("暂无记录")
                    .font(.system(size: AppTheme.FontSize.body))
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, AppTheme.Spacing.xl)
            } else {
                // 心情趋势图
                MoodTrendChart(moodRecords: moodRecords)
                    .frame(height: 120)
                    .background(AppTheme.Colors.bgMain)
                    .cornerRadius(AppTheme.Radius.medium)
                
                // 记录列表
                VStack(spacing: AppTheme.Spacing.sm) {
                    ForEach(moodRecords) { record in
                        MoodRecordItem(record: record)
                    }
                }
            }
        }
        .padding(AppTheme.Spacing.lg)
        .background(AppTheme.Colors.cardBg)
        .cornerRadius(AppTheme.Radius.large)
        .shadow(color: AppTheme.Shadows.card, radius: 6, x: 0, y: 3)
    }
}

// MARK: - 心情记录条目
struct MoodRecordItem: View {
    let record: MoodRecord
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            // 时间
            Text(timeFormatter.string(from: record.timestamp))
                .font(.system(size: AppTheme.FontSize.caption, weight: .medium))
                .foregroundColor(AppTheme.Colors.textSecondary)
                .frame(width: 40, alignment: .leading)
            
            // 心情值
            Text("\(String(format: "%.1f", record.value))")
                .font(.system(size: AppTheme.FontSize.body, weight: .semibold))
                .foregroundColor(getMoodColor(record.value))
                .frame(width: 30, alignment: .center)
            
            // 备注
            if let note = record.note, !note.isEmpty {
                Text(note)
                    .font(.system(size: AppTheme.FontSize.body))
                    .foregroundColor(AppTheme.Colors.text)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text("无备注")
                    .font(.system(size: AppTheme.FontSize.body))
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.bgMain)
        .cornerRadius(AppTheme.Radius.medium)
    }
    
    private func getMoodColor(_ mood: Double) -> Color {
        switch mood {
        case 1..<3: return .red
        case 3..<5: return .orange
        case 5..<7: return .yellow
        case 7..<9: return .green
        default: return .blue
        }
    }
}

#Preview {
    MoodChartView()
        .padding()
}
