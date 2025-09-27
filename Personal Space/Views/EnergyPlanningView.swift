//
//  EnergyPlanningView.swift
//  Personal Space
//
//  Created by Penn on 2025/1/27.
//

import SwiftUI

struct EnergyPlanningView: View {
    @EnvironmentObject var userState: UserState
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedDate = Date()
    @State private var showingCalendar = false
    @State private var selectedHour: Int? = nil
    @State private var selectedEnergyLevel: EnergyLevel? = nil
    @State private var batchStartHour: Int? = nil
    @State private var batchEndHour: Int? = nil
    @State private var showingBatchSelector = false
    @State private var showingHistory = false
    
    private let hours = Array(6...22) // 6点到22点
    
    var body: some View {
        ZStack {
            AppGradient.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 自定义导航栏
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(AppTheme.Colors.primary)
                    }
                    
                    Spacer()
                    
                    Text("能量预规划")
                        .font(.system(size: AppTheme.FontSize.headline, weight: .semibold))
                        .foregroundColor(AppTheme.Colors.text)
                    
                    Spacer()
                    
                    Button(action: {
                        showingHistory = true
                    }) {
                        Text("查看历史")
                            .font(.system(size: AppTheme.FontSize.body, weight: .medium))
                            .foregroundColor(AppTheme.Colors.primary)
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.lg)
                .padding(.top, AppTheme.Spacing.sm)
                .padding(.bottom, AppTheme.Spacing.md)
                
                ScrollView {
                    VStack(spacing: AppTheme.Spacing.lg) {
                        // 能量规划时间轴（包含日期选择）
                        EnergyTimelineView(
                            selectedDate: $selectedDate,
                            selectedHour: $selectedHour,
                            selectedEnergyLevel: $selectedEnergyLevel,
                            batchStartHour: $batchStartHour,
                            batchEndHour: $batchEndHour,
                            showingBatchSelector: $showingBatchSelector,
                            showingCalendar: $showingCalendar
                        )
                        .environmentObject(userState)
                        
                        // 能量状态选择器
                        if showingBatchSelector, let start = batchStartHour, let end = batchEndHour, let energyLevel = selectedEnergyLevel {
                            EnergyLevelSelector(
                                selectedEnergyLevel: $selectedEnergyLevel,
                                hour: nil,
                                isBatchMode: true,
                                startHour: start,
                                endHour: end
                            )
                        } else if let hour = selectedHour {
                            EnergyLevelSelector(
                                selectedEnergyLevel: $selectedEnergyLevel,
                                hour: hour,
                                isBatchMode: false,
                                startHour: nil,
                                endHour: nil
                            )
                        }
                        
                        // 保存按钮
                        if showingBatchSelector, let start = batchStartHour, let end = batchEndHour, let energyLevel = selectedEnergyLevel {
                            SaveEnergyPlanButton(
                                date: selectedDate,
                                hour: nil,
                                energyLevel: energyLevel,
                                isBatchMode: true,
                                startHour: start,
                                endHour: end
                            )
                            .environmentObject(userState)
                        } else if let hour = selectedHour, let energyLevel = selectedEnergyLevel {
                            SaveEnergyPlanButton(
                                date: selectedDate,
                                hour: hour,
                                energyLevel: energyLevel,
                                isBatchMode: false,
                                startHour: nil,
                                endHour: nil
                            )
                            .environmentObject(userState)
                        }
                    }
                    .padding(.horizontal, AppTheme.Spacing.lg)
                    .padding(.top, AppTheme.Spacing.lg)
                }
            }
            
            // 悬浮日历
            if showingCalendar {
                VStack {
                    Spacer()
                    FloatingCalendarView(
                        selectedDate: $selectedDate,
                        energyPlans: userState.energyPlans,
                        showingCalendar: $showingCalendar
                    )
                    .padding(.horizontal, AppTheme.Spacing.lg)
                    .padding(.bottom, AppTheme.Spacing.xl)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingHistory) {
            HistoricalEnergyTimelinesView()
                .environmentObject(userState)
        }
    }
}

// MARK: - 日期选择视图
struct DateSelectionView: View {
    @Binding var selectedDate: Date
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日"
        return formatter
    }()
    
    var body: some View {
        HStack {
            Text("选择日期")
                .font(.system(size: AppTheme.FontSize.headline, weight: .semibold))
                .foregroundColor(AppTheme.Colors.primary)
            
            Spacer()
            
            Text(dateFormatter.string(from: selectedDate))
                .font(.system(size: AppTheme.FontSize.body, weight: .medium))
                .foregroundColor(AppTheme.Colors.text)
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.sm)
                .background(AppTheme.Colors.bgMain)
                .cornerRadius(AppTheme.Radius.medium)
        }
        .padding(AppTheme.Spacing.lg)
        .background(AppTheme.Colors.cardBg)
        .cornerRadius(AppTheme.Radius.large)
        .shadow(color: AppTheme.Shadows.card, radius: 6, x: 0, y: 3)
    }
}

// MARK: - 能量时间轴视图
struct EnergyTimelineView: View {
    @EnvironmentObject var userState: UserState
    @Binding var selectedDate: Date
    @Binding var selectedHour: Int?
    @Binding var selectedEnergyLevel: EnergyLevel?
    @Binding var batchStartHour: Int?
    @Binding var batchEndHour: Int?
    @Binding var showingBatchSelector: Bool
    @Binding var showingCalendar: Bool
    @State private var showingEnergyButtons = false
    @State private var selectedHourForButtons: Int? = nil
    
    private let hours = Array(6...22) // 6点到22点
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            // 标题和日期选择
            HStack {
                Text("能量时间轴")
                    .font(.system(size: AppTheme.FontSize.headline, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.primary)
                
                Spacer()
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showingCalendar.toggle()
                    }
                }) {
                    Text(formatDate(selectedDate))
                        .font(.system(size: AppTheme.FontSize.body, weight: .medium))
                        .foregroundColor(AppTheme.Colors.primary)
                        .padding(.horizontal, AppTheme.Spacing.md)
                        .padding(.vertical, AppTheme.Spacing.sm)
                        .background(AppTheme.Colors.primary.opacity(0.1))
                        .cornerRadius(AppTheme.Radius.medium)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // 时间标签
            HStack {
                ForEach(Array(stride(from: 6, through: 22, by: 4)), id: \.self) { hour in
                    Text("\(hour):00")
                        .font(.system(size: AppTheme.FontSize.caption2))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // 能量条
            GeometryReader { geometry in
                ZStack {
                    HStack(spacing: 0.5) {
                        ForEach(hours, id: \.self) { hour in
                            Button(action: {
                                handleHourTap(hour: hour)
                            }) {
                                Rectangle()
                                    .fill(getEnergyColor(for: hour))
                                    .frame(width: geometry.size.width / CGFloat(hours.count), height: 20)
                                    .cornerRadius(2)
                                    .overlay(
                                        Rectangle()
                                            .stroke(getSelectionStrokeColor(for: hour), lineWidth: 2)
                                    )
                                    .overlay(
                                        // 过去时间的灰色覆盖层
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.4))
                                            .frame(width: geometry.size.width / CGFloat(hours.count), height: 20)
                                            .cornerRadius(2)
                                            .opacity(isHourSelectable(hour) ? 0 : 1)
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(4)
                    
                    // 当前时间指示器（仅今天显示）
                    if isToday(selectedDate) {
                        Rectangle()
                            .fill(AppTheme.Colors.text)
                            .frame(width: 2, height: 20)
                            .offset(x: getCurrentTimeOffset(width: geometry.size.width))
                    }
                }
            }
            .frame(height: 20)
            
            // 当前时间指示器文本（仅今天显示）
            if isToday(selectedDate) {
                HStack {
                    Spacer()
                    Text("当前：\(getCurrentHour()):00")
                        .font(.system(size: AppTheme.FontSize.caption))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    Spacer()
                }
            }
            
            // 选择状态提示
            if let start = batchStartHour, let end = batchEndHour {
                HStack {
                    Text("已选择：\(start):00 - \(end):00")
                        .font(.system(size: AppTheme.FontSize.caption))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    
                    Spacer()
                    
                    Button("取消选择") {
                        batchStartHour = nil
                        batchEndHour = nil
                        selectedHour = nil
                        selectedEnergyLevel = nil
                    }
                    .font(.system(size: AppTheme.FontSize.caption))
                    .foregroundColor(AppTheme.Colors.primary)
                }
            }
        }
        .padding(AppTheme.Spacing.lg)
        .background(AppTheme.Colors.cardBg)
        .cornerRadius(AppTheme.Radius.large)
        .shadow(color: AppTheme.Shadows.card, radius: 6, x: 0, y: 3)
        .overlay(
            // 悬浮能量状态按钮
            Group {
                if showingEnergyButtons, let hour = selectedHourForButtons {
                    FloatingEnergyButtons(
                        hour: hour,
                        selectedEnergyLevel: $selectedEnergyLevel,
                        showingButtons: $showingEnergyButtons
                    )
                    .offset(x: getButtonOffset(for: hour), y: -60)
                }
            }
        )
        .overlay(
            // 时间段选择时的状态按钮
            Group {
                if let start = batchStartHour, let end = batchEndHour, !showingEnergyButtons {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            BatchEnergyButtons(
                                startHour: start,
                                endHour: end,
                                selectedEnergyLevel: $selectedEnergyLevel
                            )
                            Spacer()
                        }
                        .padding(.bottom, 20)
                    }
                }
            }
        )
    }
    
    private func getEnergyColor(for hour: Int) -> Color {
        let finalLevel = userState.getFinalEnergyLevel(for: selectedDate, hour: hour)
        return finalLevel.color
    }
    
    private func getCurrentEnergyLevel(for hour: Int) -> EnergyLevel {
        return userState.getFinalEnergyLevel(for: selectedDate, hour: hour)
    }
    
    private func isToday(_ date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }
    
    private func getCurrentHour() -> Int {
        Calendar.current.component(.hour, from: Date())
    }
    
    private func getCurrentTimeOffset(width: CGFloat) -> CGFloat {
        let currentHour = getCurrentHour()
        let hourIndex = max(0, min(currentHour - 6, hours.count - 1))
        let segmentWidth = width / CGFloat(hours.count)
        return segmentWidth * CGFloat(hourIndex) + segmentWidth / 2
    }
    
    // 检查小时是否可选择（不能选择过去的时间）
    private func isHourSelectable(_ hour: Int) -> Bool {
        if isToday(selectedDate) {
            let currentHour = getCurrentHour()
            return hour > currentHour
        }
        return true // 非今天可以选择任意时间
    }
    
    // 获取选择边框颜色
    private func getSelectionStrokeColor(for hour: Int) -> Color {
        if showingBatchSelector {
            if let start = batchStartHour, let end = batchEndHour {
                if hour >= start && hour <= end {
                    return AppTheme.Colors.primary
                }
            } else if batchStartHour == hour {
                return AppTheme.Colors.primary
            }
        } else if selectedHour == hour {
            return AppTheme.Colors.primary
        }
        return Color.clear
    }
    
    // 处理小时点击
    private func handleHourTap(hour: Int) {
        if !isHourSelectable(hour) {
            return
        }
        
        if batchStartHour == nil {
            // 第一次点击，设置开始时间并显示悬浮按钮
            batchStartHour = hour
            selectedHourForButtons = hour
            showingEnergyButtons = true
        } else if batchEndHour == nil {
            if hour > batchStartHour! {
                // 第二次点击，设置结束时间，显示时间段选择按钮
                batchEndHour = hour
                showingEnergyButtons = false
            } else {
                // 如果点击的时间早于开始时间，重新设置开始时间
                batchStartHour = hour
                batchEndHour = nil
                selectedHourForButtons = hour
                showingEnergyButtons = true
            }
        } else {
            // 重新开始选择
            batchStartHour = hour
            batchEndHour = nil
            selectedHourForButtons = hour
            showingEnergyButtons = true
        }
    }
    
    // 格式化日期
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月d日"
        return formatter.string(from: date)
    }
    
    // 获取按钮偏移量
    private func getButtonOffset(for hour: Int) -> CGFloat {
        let hourIndex = hour - 6
        let segmentWidth = UIScreen.main.bounds.width - (AppTheme.Spacing.lg * 2) - (AppTheme.Spacing.lg * 2)
        let segmentWidthPerHour = segmentWidth / CGFloat(hours.count)
        let baseOffset = segmentWidthPerHour * CGFloat(hourIndex) + segmentWidthPerHour / 2 - 30
        
        // 确保按钮不会被屏幕边缘挡住
        let screenWidth = UIScreen.main.bounds.width
        let buttonWidth: CGFloat = 120 // 三个按钮的总宽度
        let minOffset: CGFloat = 20
        let maxOffset = screenWidth - buttonWidth - 20
        
        return max(minOffset, min(maxOffset, baseOffset))
    }
}

// MARK: - 能量状态选择器
struct EnergyLevelSelector: View {
    @Binding var selectedEnergyLevel: EnergyLevel?
    let hour: Int?
    let isBatchMode: Bool
    let startHour: Int?
    let endHour: Int?
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            if isBatchMode, let start = startHour, let end = endHour {
                Text("选择 \(start):00 - \(end):00 的能量状态")
                    .font(.system(size: AppTheme.FontSize.headline, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.primary)
            } else if let hour = hour {
                Text("选择 \(hour):00 的能量状态")
                    .font(.system(size: AppTheme.FontSize.headline, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.primary)
            }
            
            HStack(spacing: AppTheme.Spacing.md) {
                ForEach(EnergyLevel.allCases, id: \.self) { level in
                    Button(action: {
                        selectedEnergyLevel = level
                    }) {
                        VStack(spacing: AppTheme.Spacing.sm) {
                            ZStack {
                                Circle()
                                    .fill(level.color.opacity(0.2))
                                    .frame(width: 60, height: 60)
                                
                                Text(level.rawValue)
                                    .font(.system(size: 24))
                            }
                            
                            Text(level.description)
                                .font(.system(size: AppTheme.FontSize.caption, weight: .medium))
                                .foregroundColor(AppTheme.Colors.text)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .overlay(
                        Circle()
                            .stroke(selectedEnergyLevel == level ? level.color : Color.clear, lineWidth: 3)
                            .frame(width: 60, height: 60)
                    )
                }
            }
        }
        .padding(AppTheme.Spacing.lg)
        .background(AppTheme.Colors.cardBg)
        .cornerRadius(AppTheme.Radius.large)
        .shadow(color: AppTheme.Shadows.card, radius: 6, x: 0, y: 3)
    }
}

// MARK: - 保存能量规划按钮
struct SaveEnergyPlanButton: View {
    @EnvironmentObject var userState: UserState
    let date: Date
    let hour: Int?
    let energyLevel: EnergyLevel
    let isBatchMode: Bool
    let startHour: Int?
    let endHour: Int?
    
    var body: some View {
        Button(action: {
            saveEnergyPlan()
        }) {
            Text(isBatchMode ? "批量保存规划" : "保存规划")
                .font(.system(size: AppTheme.FontSize.headline, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppTheme.Spacing.lg)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.large)
                        .fill(AppTheme.Colors.primary)
                        .shadow(
                            color: AppTheme.Colors.primary.opacity(0.3),
                            radius: 8,
                            x: 0,
                            y: 4
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func saveEnergyPlan() {
        let calendar = Calendar.current
        let targetDate = calendar.startOfDay(for: date)
        
        if isBatchMode, let start = startHour, let end = endHour {
            // 批量保存：移除指定时间范围内的旧规划
            userState.energyPlans.removeAll { plan in
                calendar.isDate(plan.date, inSameDayAs: targetDate) && 
                plan.hour >= start && plan.hour <= end
            }
            
            // 批量添加新规划
            for hour in start...end {
                let newPlan = EnergyPlan(
                    date: targetDate,
                    hour: hour,
                    energyLevel: energyLevel,
                    createdAt: Date()
                )
                userState.energyPlans.append(newPlan)
            }
        } else if let hour = hour {
            // 单个保存：移除同一天同一小时的旧规划
            userState.energyPlans.removeAll { plan in
                calendar.isDate(plan.date, inSameDayAs: targetDate) && plan.hour == hour
            }
            
            // 添加新规划
            let newPlan = EnergyPlan(
                date: targetDate,
                hour: hour,
                energyLevel: energyLevel,
                createdAt: Date()
            )
            userState.energyPlans.append(newPlan)
        }
        
        // 按日期和小时排序
        userState.energyPlans.sort { plan1, plan2 in
            if plan1.date != plan2.date {
                return plan1.date < plan2.date
            }
            return plan1.hour < plan2.hour
        }
    }
}

// MARK: - 日历视图（复用心情记录的日历）
struct CalendarView: View {
    @Binding var selectedDate: Date
    let energyPlans: [EnergyPlan]
    
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
                        let hasPlans = hasEnergyPlans(for: date)
                        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
                        
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedDate = date
                            }
                        }) {
                            Text("\(calendar.component(.day, from: date))")
                                .font(.system(size: AppTheme.FontSize.body, weight: .medium))
                                .foregroundColor(AppTheme.Colors.text)
                                .frame(width: 32, height: 32)
                                .background(
                                    Circle()
                                        .fill(isSelected ? AppTheme.Colors.primary : Color.clear)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(hasPlans ? AppTheme.Colors.primary : Color.clear, lineWidth: 1)
                                )
                        }
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
    
    private func hasEnergyPlans(for date: Date) -> Bool {
        return energyPlans.contains { plan in
            calendar.isDate(plan.date, inSameDayAs: date)
        }
    }
}

// MARK: - 历史能量规划时间轴视图
struct HistoricalEnergyTimelinesView: View {
    @EnvironmentObject var userState: UserState
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            Text("历史能量规划")
                .font(.system(size: AppTheme.FontSize.headline, weight: .semibold))
                .foregroundColor(AppTheme.Colors.primary)
            
            if groupedEnergyPlans.isEmpty {
                Text("暂无历史规划")
                    .font(.system(size: AppTheme.FontSize.body))
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, AppTheme.Spacing.xl)
            } else {
                ForEach(groupedEnergyPlans.keys.sorted(by: >), id: \.self) { date in
                    HistoricalEnergyTimelineCard(
                        date: date,
                        energyPlans: groupedEnergyPlans[date] ?? []
                    )
                    .environmentObject(userState)
                }
            }
        }
    }
    
    private var groupedEnergyPlans: [Date: [EnergyPlan]] {
        let calendar = Calendar.current
        var grouped: [Date: [EnergyPlan]] = [:]
        
        for plan in userState.energyPlans {
            let date = calendar.startOfDay(for: plan.date)
            if grouped[date] == nil {
                grouped[date] = []
            }
            grouped[date]?.append(plan)
        }
        
        // 按小时排序每个日期的规划
        for date in grouped.keys {
            grouped[date]?.sort { $0.hour < $1.hour }
        }
        
        return grouped
    }
}

// MARK: - 历史能量规划时间轴卡片
struct HistoricalEnergyTimelineCard: View {
    @EnvironmentObject var userState: UserState
    let date: Date
    let energyPlans: [EnergyPlan]
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM月dd日"
        return formatter
    }()
    
    private let hours = Array(6...22) // 6点到22点
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            // 日期标题
            HStack {
                Text(dateFormatter.string(from: date))
                    .font(.system(size: AppTheme.FontSize.headline, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.primary)
                
                Spacer()
                
                // 规划统计
                let stats = getEnergyStats()
                Text("高\(stats.high) 中\(stats.medium) 低\(stats.low)")
                    .font(.system(size: AppTheme.FontSize.caption))
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .padding(.horizontal, AppTheme.Spacing.sm)
                    .padding(.vertical, 4)
                    .background(AppTheme.Colors.bgMain)
                    .cornerRadius(AppTheme.Radius.small)
            }
            
            // 时间标签
            HStack {
                ForEach(Array(stride(from: 6, through: 22, by: 4)), id: \.self) { hour in
                    Text("\(hour):00")
                        .font(.system(size: AppTheme.FontSize.caption2))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // 能量条
            GeometryReader { geometry in
                HStack(spacing: 0.5) {
                    ForEach(hours, id: \.self) { hour in
                        Rectangle()
                            .fill(getEnergyColor(for: hour))
                            .frame(width: geometry.size.width / CGFloat(hours.count), height: 16)
                            .cornerRadius(1)
                    }
                }
                .background(Color.gray.opacity(0.2))
                .cornerRadius(2)
            }
            .frame(height: 16)
        }
        .padding(AppTheme.Spacing.lg)
        .background(AppTheme.Colors.cardBg)
        .cornerRadius(AppTheme.Radius.large)
        .shadow(color: AppTheme.Shadows.card, radius: 6, x: 0, y: 3)
    }
    
    private func getEnergyColor(for hour: Int) -> Color {
        let finalLevel = userState.getFinalEnergyLevel(for: date, hour: hour)
        return finalLevel.color
    }
    
    private func getEnergyStats() -> (high: Int, medium: Int, low: Int) {
        var high = 0, medium = 0, low = 0
        
        for hour in hours {
            let level = userState.getFinalEnergyLevel(for: date, hour: hour)
            switch level {
            case .high: high += 1
            case .medium: medium += 1
            case .low: low += 1
            }
        }
        
        return (high, medium, low)
    }
}

// MARK: - 悬浮能量状态按钮
struct FloatingEnergyButtons: View {
    let hour: Int
    @Binding var selectedEnergyLevel: EnergyLevel?
    @Binding var showingButtons: Bool
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            ForEach(EnergyLevel.allCases, id: \.self) { level in
                Button(action: {
                    selectedEnergyLevel = level
                    showingButtons = false
                }) {
                    ZStack {
                        Circle()
                            .fill(level.color)
                            .frame(width: 40, height: 40)
                        
                        Text(level.rawValue)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(AppTheme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.large)
                .fill(.ultraThinMaterial)
                .shadow(color: AppTheme.Shadows.card, radius: 8, x: 0, y: 4)
        )
        .onTapGesture {
            // 点击背景区域关闭按钮
            showingButtons = false
        }
    }
}

// MARK: - 批量能量状态按钮
struct BatchEnergyButtons: View {
    let startHour: Int
    let endHour: Int
    @Binding var selectedEnergyLevel: EnergyLevel?
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Text("\(startHour):00 - \(endHour):00")
                .font(.system(size: AppTheme.FontSize.caption, weight: .medium))
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            HStack(spacing: AppTheme.Spacing.sm) {
                ForEach(EnergyLevel.allCases, id: \.self) { level in
                    Button(action: {
                        selectedEnergyLevel = level
                    }) {
                        ZStack {
                            Circle()
                                .fill(level.color)
                                .frame(width: 40, height: 40)
                            
                            Text(level.rawValue)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(AppTheme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.large)
                .fill(.ultraThinMaterial)
                .shadow(color: AppTheme.Shadows.card, radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - 悬浮日历视图
struct FloatingCalendarView: View {
    @Binding var selectedDate: Date
    let energyPlans: [EnergyPlan]
    @Binding var showingCalendar: Bool
    
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
                        let isSelectable = isDateSelectable(date)
                        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
                        let hasPlans = hasEnergyPlans(for: date)
                        
                        Button(action: {
                            if isSelectable {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedDate = date
                                    showingCalendar = false
                                }
                            }
                        }) {
                            Text("\(calendar.component(.day, from: date))")
                                .font(.system(size: AppTheme.FontSize.body, weight: .medium))
                                .foregroundColor(isSelectable ? AppTheme.Colors.text : AppTheme.Colors.textSecondary.opacity(0.3))
                                .frame(width: 32, height: 32)
                                .background(
                                    Circle()
                                        .fill(isSelected ? AppTheme.Colors.primary : Color.clear)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(hasPlans ? AppTheme.Colors.primary : Color.clear, lineWidth: 1)
                                )
                        }
                        .disabled(!isSelectable)
                    } else {
                        Text("")
                            .frame(width: 32, height: 32)
                    }
                }
            }
            .padding(.horizontal, AppTheme.Spacing.lg)
        }
        .padding(.vertical, AppTheme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.large)
                .fill(.ultraThinMaterial)
                .shadow(color: AppTheme.Shadows.card, radius: 12, x: 0, y: 6)
        )
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
    
    private func isDateSelectable(_ date: Date) -> Bool {
        let today = calendar.startOfDay(for: Date())
        let targetDate = calendar.startOfDay(for: date)
        return targetDate >= today
    }
    
    private func hasEnergyPlans(for date: Date) -> Bool {
        return energyPlans.contains { plan in
            calendar.isDate(plan.date, inSameDayAs: date)
        }
    }
}

#Preview {
    EnergyPlanningView()
        .environmentObject(UserState())
}
