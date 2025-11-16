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
    @State private var selectedRecord: MoodRecord? = nil
    
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
            
            // 心情趋势图（只显示今天的心情记录）
            if !todayMoodRecords.isEmpty {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    MoodTrendHeader(moodRecords: todayMoodRecords, selectedRecord: $selectedRecord)

                    MoodTrendChart(moodRecords: todayMoodRecords, selectedRecord: $selectedRecord)
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
        
        withAnimation(.easeInOut(duration: 0.3)) {
            // 使用 UserState 的 addMoodRecord 方法，会自动保存到 UserDefaults
            userState.addMoodRecord(
                value: currentMood,
                timestamp: Date(),
                note: trimmedNote.isEmpty ? nil : trimmedNote
            )
            showingRecordButton = false
            moodNote = ""
        }
    }
    
    /// 获取今天的心情记录
    private var todayMoodRecords: [MoodRecord] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return userState.moodRecords.filter { record in
            calendar.isDate(record.timestamp, inSameDayAs: today)
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
    @Binding var selectedRecord: MoodRecord?
    
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
        let availableWidth = width - padding * 2
        let yStep = (height - padding * 2) / 9.0
        
        guard moodRecords.count >= 2 else {
            return []
        }
        
        // 1. 计算所有相邻记录之间的时间间隔（秒）
        var timeIntervals: [TimeInterval] = []
        for i in 1..<moodRecords.count {
            let interval = moodRecords[i].timestamp.timeIntervalSince(moodRecords[i-1].timestamp)
            timeIntervals.append(max(interval, 1)) // 最小1秒，避免除零
        }
        
        // 2. 计算总时间间隔
        let totalInterval = timeIntervals.reduce(0, +)
        
        // 3. 如果总间隔为0（所有记录在同一时间），使用等距分布
        guard totalInterval > 0 else {
            let xStep = availableWidth / CGFloat(moodRecords.count - 1)
            var points: [CGPoint] = []
            for (index, record) in moodRecords.enumerated() {
                let x = padding + CGFloat(index) * xStep
                let y = height - padding - (CGFloat(record.value - 1) * yStep)
                points.append(CGPoint(x: x, y: y))
            }
            return points
        }
        
        // 4. 按时间间隔比例计算每个点的x坐标
        var xPositions: [CGFloat] = [padding] // 第一个点在最左边
        var currentX = padding
        
        for interval in timeIntervals {
            let proportion = CGFloat(interval / totalInterval)
            currentX += proportion * availableWidth
            xPositions.append(currentX)
        }
        
        // 5. 生成所有点
        var points: [CGPoint] = []
        for (index, record) in moodRecords.enumerated() {
            let x = xPositions[index]
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
        let availableWidth = width - padding * 2
        let yStep = (height - padding * 2) / 9.0
        
        guard moodRecords.count >= 2 else {
            let x = padding + CGFloat(index) * availableWidth
            let y = height - padding - (CGFloat(record.value - 1) * yStep)
            return CGPoint(x: x, y: y)
        }
        
        // 1. 计算所有相邻记录之间的时间间隔（秒）
        var timeIntervals: [TimeInterval] = []
        for i in 1..<moodRecords.count {
            let interval = moodRecords[i].timestamp.timeIntervalSince(moodRecords[i-1].timestamp)
            timeIntervals.append(max(interval, 1)) // 最小1秒，避免除零
        }
        
        // 2. 计算总时间间隔
        let totalInterval = timeIntervals.reduce(0, +)
        
        // 3. 如果总间隔为0（所有记录在同一时间），使用等距分布
        guard totalInterval > 0 else {
            let xStep = availableWidth / CGFloat(moodRecords.count - 1)
            let x = padding + CGFloat(index) * xStep
            let y = height - padding - (CGFloat(record.value - 1) * yStep)
            return CGPoint(x: x, y: y)
        }
        
        // 4. 按时间间隔比例计算x坐标
        var xPositions: [CGFloat] = [padding] // 第一个点在最左边
        var currentX = padding
        
        for interval in timeIntervals {
            let proportion = CGFloat(interval / totalInterval)
            currentX += proportion * availableWidth
            xPositions.append(currentX)
        }
        
        // 5. 返回对应索引的点
        let x = xPositions[index]
        let y = height - padding - (CGFloat(record.value - 1) * yStep)
        return CGPoint(x: x, y: y)
    }
}

// MARK: - 心情趋势标题头部
struct MoodTrendHeader: View {
    let moodRecords: [MoodRecord]
    @Binding var selectedRecord: MoodRecord?
    @State private var showFullNote = false

    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Text("心情趋势")
                .font(.system(size: AppTheme.FontSize.subheadline, weight: .medium))
                .foregroundColor(AppTheme.Colors.text)

            // 显示选中的备注信息
            if let record = selectedRecord, let note = record.note {
                HStack(spacing: 4) {
                    Text(formatTime(record.timestamp))
                        .font(.system(size: AppTheme.FontSize.caption2, weight: .medium))
                        .foregroundColor(AppTheme.Colors.textSecondary)

                    Text(truncateNote(note))
                        .font(.system(size: AppTheme.FontSize.caption))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .lineLimit(1)

                    if note.count > 20 {
                        Text("...")
                            .font(.system(size: AppTheme.FontSize.caption))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(AppTheme.Colors.bgMain.opacity(0.8))
                .cornerRadius(AppTheme.Radius.small)
                .onTapGesture {
                    showFullNote.toggle()
                }
                .sheet(isPresented: $showFullNote) {
                    MoodNoteSheet(
                        timeText: formatTime(record.timestamp),
                        note: note,
                        onClose: { showFullNote = false }
                    )
                    .applyMoodSheetModifiers()
                }
            }

            Spacer()
        }
    }

    private func truncateNote(_ note: String) -> String {
        let maxLength = 20
        if note.count > maxLength {
            return String(note.prefix(maxLength))
        }
        return note
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - 心情备注底部弹窗（参考“快充”弹窗样式）
private struct MoodNoteSheet: View {
    let timeText: String
    let note: String
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Text(timeText)
                    .font(.system(size: AppTheme.FontSize.headline, weight: .medium))
                    .foregroundColor(.secondary)

                Spacer()

                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: AppTheme.FontSize.headline, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, AppTheme.Spacing.xl)
            .padding(.vertical, AppTheme.Spacing.lg)

            Divider()

            // 内容（限制高度但支持滚动）
            ScrollView {
                Text(note)
                    .font(.system(size: AppTheme.FontSize.body))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, AppTheme.Spacing.md)
            }
            .padding(.horizontal, AppTheme.Spacing.xl)
            .padding(.bottom, AppTheme.Spacing.lg)
        }
        .background(Color(.systemBackground))
    }
}

// iOS15 兼容：为 sheet 提供条件性修饰符
private extension View {
    @ViewBuilder
    func applyMoodSheetModifiers() -> some View {
        if #available(iOS 16.0, *) {
            self
                .presentationDetents([.height(280)])
                .presentationDragIndicator(.visible)
        } else {
            self
        }
    }
}

// MARK: - 心情记录页面
struct MoodRecordPageView: View {
    @EnvironmentObject var userState: UserState
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedDate: Date? = nil
    @State private var showingCalendar = false
    @State private var displayedDaysCount: Int = 10 // 当前显示的天数
    private let daysPerPage: Int = 10 // 每次加载的天数
    
    var body: some View {
        NavigationView {
            ZStack {
                AppGradient.background
                    .ignoresSafeArea()
                
                // 心情记录列表（使用ScrollViewReader实现滚动定位）
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: AppTheme.Spacing.lg) {
                            // 显示分页的记录，按日期分组（始终显示所有日期，不再过滤）
                            let sortedDates = groupedMoodRecords.keys.sorted(by: >)
                            let displayedDates = Array(sortedDates.prefix(displayedDaysCount))
                            
                            ForEach(displayedDates, id: \.self) { date in
                                DailyMoodRecords(
                                    date: date,
                                    moodRecords: groupedMoodRecords[date] ?? [],
                                    isSelected: selectedDate != nil && Calendar.current.isDate(date, inSameDayAs: selectedDate!)
                                )
                                .id(date) // 为每个日期添加ID，用于滚动定位
                                .onAppear {
                                    // 当最后一个可见的日期出现时，加载更多
                                    if date == displayedDates.last && displayedDates.count < sortedDates.count {
                                        loadMoreDays()
                                    }
                                }
                            }
                            
                            // 加载更多提示
                            if displayedDates.count < sortedDates.count {
                                HStack {
                                    Spacer()
                                    Text("加载更多...")
                                        .font(.system(size: AppTheme.FontSize.body))
                                        .foregroundColor(AppTheme.Colors.textSecondary)
                                        .padding(.vertical, AppTheme.Spacing.md)
                                    Spacer()
                                }
                                .onAppear {
                                    // 当加载提示出现时，自动加载更多
                                    loadMoreDays()
                                }
                            }
                        }
                        .padding(.horizontal, AppTheme.Spacing.lg)
                        .padding(.top, AppTheme.Spacing.lg)
                    }
                    .onChange(of: selectedDate) { newDate in
                        // 当选中日期改变时，滚动到对应位置并自动收起日历
                        if let date = newDate {
                            // 自动收起日历
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showingCalendar = false
                            }
                            
                            // 确保该日期已加载（如果不在已显示的日期中，需要先加载）
                            let sortedDates = groupedMoodRecords.keys.sorted(by: >)
                            if let dateIndex = sortedDates.firstIndex(where: { Calendar.current.isDate($0, inSameDayAs: date) }) {
                                // 如果日期不在已显示的范围内，先加载到该位置
                                let targetDisplayCount = min(dateIndex + 1 + daysPerPage, sortedDates.count)
                                if targetDisplayCount > displayedDaysCount {
                                    displayedDaysCount = targetDisplayCount
                                }
                                
                                // 延迟一下，确保视图已渲染（等待日历收起动画完成）
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    withAnimation(.easeInOut(duration: 0.5)) {
                                        proxy.scrollTo(date, anchor: .top)
                                    }
                                }
                            }
                        }
                    }
                }
                
                // 悬浮日历（使用 overlay 显示，不占用空间）
                if showingCalendar {
                    // 背景遮罩层，点击可隐藏日历
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showingCalendar = false
                            }
                        }
                        .overlay(
                            VStack {
                                Spacer()
                                MoodRecordCalendarView(
                                    selectedDate: $selectedDate,
                                    moodRecords: userState.moodRecords
                                )
                                .padding(.horizontal, AppTheme.Spacing.lg)
                                .padding(.bottom, AppTheme.Spacing.xl)
                            }
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        )
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
    
    /// 加载更多天数
    private func loadMoreDays() {
        let sortedDates = groupedMoodRecords.keys.sorted(by: >)
        let newCount = min(displayedDaysCount + daysPerPage, sortedDates.count)
        
        if newCount > displayedDaysCount {
            withAnimation(.easeInOut(duration: 0.3)) {
                displayedDaysCount = newCount
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
    let isSelected: Bool // 是否被选中（用于高亮显示）
    @State private var selectedRecord: MoodRecord? = nil

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM月dd日"
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            // 日期标题（选中时高亮显示）
            Text(dateFormatter.string(from: date))
                .font(.system(size: AppTheme.FontSize.headline, weight: .semibold))
                .foregroundColor(isSelected ? AppTheme.Colors.primary : AppTheme.Colors.text)
                .padding(.horizontal, isSelected ? AppTheme.Spacing.sm : 0)
                .padding(.vertical, isSelected ? AppTheme.Spacing.xs : 0)
                .background(
                    isSelected ? RoundedRectangle(cornerRadius: AppTheme.Radius.small)
                        .fill(AppTheme.Colors.primary.opacity(0.1)) : nil
                )
            
            if moodRecords.isEmpty {
                Text("暂无记录")
                    .font(.system(size: AppTheme.FontSize.body))
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, AppTheme.Spacing.xl)
            } else {
                // 心情趋势图
                MoodTrendChart(moodRecords: moodRecords, selectedRecord: $selectedRecord)
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
    @State private var isExpanded = false
    @State private var needsExpansion = false
    
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
            
            // 备注区域
            noteContent
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.bgMain)
        .cornerRadius(AppTheme.Radius.medium)
    }
    
    // MARK: - 备注内容视图（拆分为独立计算属性）
    @ViewBuilder
    private var noteContent: some View {
        if let note = record.note, !note.isEmpty {
            noteTextWithExpansion(note: note)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(measurementBackground(note: note))
                .onPreferenceChange(TextHeightPreferenceKey.self) { fullHeight in
                    if fullHeight > 45 {
                        needsExpansion = true
                    }
                }
                .onAppear {
                    if note.count > 50 {
                        needsExpansion = true
                    }
                }
        } else {
            Text("无备注")
                .font(.system(size: AppTheme.FontSize.body))
                .foregroundColor(AppTheme.Colors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    // MARK: - 备注文本（带展开/收起功能）
    @ViewBuilder
    private func noteTextWithExpansion(note: String) -> some View {
        if needsExpansion {
            // 需要展开/收起功能：根据状态显示2行或完整文本
            Text(note)
                .font(.system(size: AppTheme.FontSize.body))
                .foregroundColor(AppTheme.Colors.text)
                .lineLimit(isExpanded ? nil : 2)
                .fixedSize(horizontal: false, vertical: true)
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                }
        } else {
            // 不需要展开：直接显示完整文本
            Text(note)
                .font(.system(size: AppTheme.FontSize.body))
                .foregroundColor(AppTheme.Colors.text)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    // MARK: - 测量背景（用于检测文本高度）
    private func measurementBackground(note: String) -> some View {
        Text(note)
            .font(.system(size: AppTheme.FontSize.body))
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
            .opacity(0)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .preference(
                            key: TextHeightPreferenceKey.self,
                            value: geometry.size.height
                        )
                }
            )
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

// MARK: - 文本高度偏好键（用于检测文本是否超过2行）
struct TextHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}


#Preview {
    MoodChartView()
        .padding()
}
