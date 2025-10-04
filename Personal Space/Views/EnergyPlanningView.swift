//
//  EnergyPlanningView.swift
//  Personal Space
//
//  Created by Penn on 2025/1/27.
//

import SwiftUI

// MARK: - 指针组件
struct PointerView: View {
    let hour: Int
    let minute: Int
    let isLeft: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // 时间标签
            Text(String(format: "%02d:%02d", hour, minute))
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(isLeft ? .blue : .orange)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white)
                        .shadow(radius: 2)
                )
            
            // 指针线条（朝下）
            Rectangle()
                .fill(isLeft ? Color.blue : Color.orange)
                .frame(width: 2, height: 20)
            
            // 把手（朝下）- 3倍指针宽度
            RoundedRectangle(cornerRadius: 1)
                .fill(isLeft ? Color.blue : Color.orange)
                .frame(width: 6, height: 16) // 3倍指针宽度(2px) = 6px
                .overlay(
                    RoundedRectangle(cornerRadius: 1)
                        .stroke(Color.white, lineWidth: 0.5)
                )
        }
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - 分钟级能量块
struct MinuteLevelEnergyBlock: View {
    let hour: Int
    let width: CGFloat
    let height: CGFloat
    @ObservedObject var userState: UserState
    let selectedDate: Date
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<60, id: \.self) { minute in
                Rectangle()
                    .fill(getEnergyColor(for: hour, minute: minute))
                    .frame(width: width / 60, height: height)
            }
        }
        .cornerRadius(2)
    }
    
    private func getEnergyColor(for hour: Int, minute: Int) -> Color {
        let energyLevel = userState.getFinalEnergyLevel(for: selectedDate, hour: hour, minute: minute)
        return energyLevel.color
    }
}

// MARK: - 时间选择器
struct TimePickerView: View {
    @Binding var selectedHour: Int
    @Binding var selectedMinute: Int
    @Binding var isLeft: Bool
    let minHour: Int
    let minMinute: Int
    let maxHour: Int
    let maxMinute: Int
    let onConfirm: (Int, Int) -> Void
    let onCancel: () -> Void
    
    @Environment(\.presentationMode) var presentationMode
    
    // 计算分钟范围
    private func getMinuteRange() -> [Int] {
        if selectedHour == minHour {
            // 如果选择的是最小小时，分钟范围从minMinute到59
            return Array(minMinute..<60)
        } else if selectedHour == maxHour {
            // 如果选择的是最大小时，分钟范围从0到maxMinute
            return Array(0...maxMinute)
        } else {
            // 其他情况，分钟范围是0到59
            return Array(0..<60)
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // 标题
            Text("选择\(isLeft ? "左" : "右")指针时间")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
                .onAppear {
                    print("TimePickerView: isLeft=\(isLeft), 标题=选择\(isLeft ? "左" : "右")指针时间")
                }
            
            // 时间选择器
            HStack(spacing: 20) {
                // 小时选择器
                VStack {
                    Text("小时")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Picker("小时", selection: $selectedHour) {
                        ForEach(minHour...maxHour, id: \.self) { hour in
                            Text(String(format: "%02d", hour))
                                .tag(hour)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .frame(width: 80, height: 120)
                }
                
                // 分钟选择器
                VStack {
                    Text("分钟")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Picker("分钟", selection: $selectedMinute) {
                        ForEach(getMinuteRange(), id: \.self) { minute in
                            Text(String(format: "%02d", minute))
                                .tag(minute)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .frame(width: 80, height: 120)
                }
            }
            
            // 按钮
            HStack(spacing: 20) {
                Button("取消") {
                    onCancel()
                    presentationMode.wrappedValue.dismiss()
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
                .frame(width: 80, height: 44)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
                
                Button("确认") {
                    onConfirm(selectedHour, selectedMinute)
                    presentationMode.wrappedValue.dismiss()
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 80, height: 44)
                .background(isLeft ? Color.blue : Color.orange)
                .cornerRadius(8)
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
        .onAppear {
            // 确保选择的时间在有效范围内
            selectedHour = max(minHour, min(maxHour, selectedHour))
            if selectedHour == minHour {
                selectedMinute = max(minMinute, selectedMinute)
            } else if selectedHour == maxHour {
                selectedMinute = min(maxMinute, selectedMinute)
            }
        }
    }
}

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
    @State private var showingEnergyButtons = false
    @State private var selectedHourForButtons: Int? = nil
    @State private var showingUnselectableHint = false
    
    // 指针相关状态
    @State private var leftPointerHour: Int? = nil
    @State private var leftPointerMinute: Int? = nil
    @State private var rightPointerHour: Int? = nil
    @State private var rightPointerMinute: Int? = nil
    @State private var showingPointers = false
    @State private var showingTimePicker = false
    @State private var isLeftPointerSelected = false
    @State private var timePickerHour = 0
    @State private var timePickerMinute = 0
    @State private var timePickerMinHour = 7
    @State private var timePickerMinMinute = 0
    @State private var timePickerMaxHour = 23
    @State private var timePickerMaxMinute = 59
    
    private let hours = Array(7...23) // 7点到23点
    
    // MARK: - 指针相关方法
    private func onPointerTap(isLeft: Bool) {
        print("onPointerTap: isLeft=\(isLeft)")
        isLeftPointerSelected = isLeft
        print("设置后 isLeftPointerSelected=\(isLeftPointerSelected)")
        
        if isLeft {
            timePickerHour = leftPointerHour ?? 0
            timePickerMinute = leftPointerMinute ?? 0
        } else {
            timePickerHour = rightPointerHour ?? 0
            timePickerMinute = rightPointerMinute ?? 0
        }
        
        // 立即计算并设置限制参数
        let minStartTime = getMinAllowedStartTime()
        let maxStartTime = getMaxAllowedStartTime()
        let minEndTime = getMinAllowedEndTime()
        let maxEndTime = getMaxAllowedEndTime()
        
        if isLeft {
            timePickerMinHour = minStartTime.0
            timePickerMinMinute = minStartTime.1
            timePickerMaxHour = maxStartTime.0
            timePickerMaxMinute = maxStartTime.1
        } else {
            timePickerMinHour = minEndTime.0
            timePickerMinMinute = minEndTime.1
            timePickerMaxHour = maxEndTime.0
            timePickerMaxMinute = maxEndTime.1
        }
        
        print("立即设置限制参数: min=\(timePickerMinHour):\(timePickerMinMinute), max=\(timePickerMaxHour):\(timePickerMaxMinute)")
        
        // 立即显示时间选择器
        showingTimePicker = true
    }
    
    private func onTimePickerConfirm(hour: Int, minute: Int) {
        print("=== onTimePickerConfirm ===")
        print("isLeftPointerSelected: \(isLeftPointerSelected)")
        print("设置指针: \(hour):\(minute)")
        print("更新前状态: showingPointers=\(showingPointers)")
        print("更新前指针: left=\(leftPointerHour ?? -1):\(leftPointerMinute ?? -1), right=\(rightPointerHour ?? -1):\(rightPointerMinute ?? -1)")
        
        if isLeftPointerSelected {
            leftPointerHour = hour
            leftPointerMinute = minute
            print("左指针更新为: \(hour):\(minute)")
        } else {
            rightPointerHour = hour
            rightPointerMinute = minute
            print("右指针更新为: \(hour):\(minute)")
        }
        
        // 确保showingPointers保持为true
        showingPointers = true
        print("更新后状态: showingPointers=\(showingPointers)")
        print("更新后指针: left=\(leftPointerHour ?? -1):\(leftPointerMinute ?? -1), right=\(rightPointerHour ?? -1):\(rightPointerMinute ?? -1)")
        
        showingTimePicker = false
    }
    
    private func clearPointers() {
        leftPointerHour = nil
        leftPointerMinute = nil
        rightPointerHour = nil
        rightPointerMinute = nil
        showingPointers = false
        showingTimePicker = false
    }
    
    private func handleHourTap(hour: Int) {
        print("点击了小时: \(hour), 是否可选择: \(isHourSelectable(hour))")
        
        if !isHourSelectable(hour) {
            showingUnselectableHint = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                showingUnselectableHint = false
            }
            return
        }
        
        // 判断当前状态
        let isCurrentlySingleBlock = (selectedHour != nil && batchStartHour == nil && batchEndHour == nil)
        let isCurrentlyMultiBlock = (batchStartHour != nil && batchEndHour != nil)
        
        if isCurrentlySingleBlock {
            // 当前是单个块模式，点击不同块进入多块模式
            if hour != selectedHour {
                // 选择不同的块，进入多块模式
                if hour > selectedHour! {
                    batchStartHour = selectedHour
                    batchEndHour = hour + 1
                } else {
                    batchStartHour = hour
                    batchEndHour = selectedHour! + 1
                }
                selectedHour = nil
                selectedHourForButtons = nil
                showingEnergyButtons = false
                setupPointers(startHour: batchStartHour!, endHour: batchEndHour!)
            } else {
                // 点击相同块，保持单个块模式
                print("点击了相同的块，保持当前状态")
            }
        } else if isCurrentlyMultiBlock {
            // 当前是多块模式，点击任何块都进入单个块模式
            selectedHour = hour
            batchStartHour = nil
            batchEndHour = nil
            selectedHourForButtons = hour
            showingEnergyButtons = true
            // 从多块模式切换到单块模式时，强制重新设置指针位置
            setupPointers(startHour: hour, endHour: hour + 1)
        } else {
            // 初始状态，第一次选择 - 单个块
            selectedHour = hour
            batchStartHour = nil
            batchEndHour = nil
            selectedHourForButtons = hour
            showingEnergyButtons = true
            setupPointers(startHour: hour, endHour: hour + 1)
        }
    }
    
    // 获取左指针的最小允许时间
    private func getMinAllowedStartTime() -> (hour: Int, minute: Int) {
        let now = Date()
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)
        
        // 如果是今天，左指针的左极限为7点或者当前时间+5分钟（取较大的一方）
        if calendar.isDateInToday(selectedDate) {
            let currentTimePlus5 = currentMinute + 5
            let currentTimePlus5Hour = currentTimePlus5 >= 60 ? currentHour + 1 : currentHour
            let currentTimePlus5Minute = currentTimePlus5 >= 60 ? currentTimePlus5 - 60 : currentTimePlus5
            
            // 比较7:00和当前时间+5分钟，取较大的一方
            if currentTimePlus5Hour > 7 || (currentTimePlus5Hour == 7 && currentTimePlus5Minute > 0) {
                return (currentTimePlus5Hour, currentTimePlus5Minute)
            } else {
                return (7, 0)
            }
        }
        
        // 如果是未来日期，左指针的左极限为7点
        return (7, 0)
    }
    
    // 获取左指针的最大允许时间
    private func getMaxAllowedStartTime() -> (hour: Int, minute: Int) {
        guard let rightHour = rightPointerHour, let rightMinute = rightPointerMinute else {
            return (23, 0)
        }
        
        // 左指针的右极限为右指针的时间-5分钟
        let leftMaxMinute = rightMinute - 5
        if leftMaxMinute < 0 {
            return (rightHour - 1, leftMaxMinute + 60)
        } else {
            return (rightHour, leftMaxMinute)
        }
    }
    
    // 获取右指针的最小允许时间
    private func getMinAllowedEndTime() -> (hour: Int, minute: Int) {
        guard let leftHour = leftPointerHour, let leftMinute = leftPointerMinute else {
            print("getMinAllowedEndTime: 无左指针，返回7:00")
            return (7, 0)
        }
        
        // 右指针的左极限为max(7:00, 左指针+5分钟)
        let rightMinMinute = leftMinute + 5
        let rightMinHour = rightMinMinute >= 60 ? leftHour + 1 : leftHour
        let rightMinMinuteAdjusted = rightMinMinute >= 60 ? rightMinMinute - 60 : rightMinMinute
        
        print("getMinAllowedEndTime: 左指针=\(leftHour):\(leftMinute)")
        print("getMinAllowedEndTime: 左指针+5分钟=\(rightMinHour):\(rightMinMinuteAdjusted)")
        
        // 比较7:00和左指针+5分钟，取较大的一方
        if rightMinHour > 7 || (rightMinHour == 7 && rightMinMinuteAdjusted > 0) {
            print("getMinAllowedEndTime: 返回左指针+5分钟=\(rightMinHour):\(rightMinMinuteAdjusted)")
            return (rightMinHour, rightMinMinuteAdjusted)
        } else {
            print("getMinAllowedEndTime: 返回7:00")
            return (7, 0)
        }
    }
    
    // 获取右指针的最大允许时间
    private func getMaxAllowedEndTime() -> (hour: Int, minute: Int) {
        // 右指针的右极限为23:59
        return (23, 59)
    }
    
    private func isHourSelectable(_ hour: Int) -> Bool {
        let now = Date()
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)
        
        // 如果是今天，不能选择过去的时间
        if calendar.isDateInToday(selectedDate) {
            // 基本检查：不能选择过去的时间
            if hour < currentHour {
                return false
            }
            
            // 特殊检查：如果当前时间大于23:50，不允许选择23:00-24:00的块
            // 因为左指针的最小允许时间（当前时间+5分钟）会超过24:00
            if currentHour == 23 && currentMinute > 50 {
                // 如果当前时间大于23:50，不允许选择23:00-24:00的块
                if hour == 23 {
                    return false
                }
            }
            
            // 如果当前时间大于23:55，不允许选择任何24:00的块
            if currentHour == 23 && currentMinute > 55 {
                if hour >= 23 {
                    return false
                }
            }
            
            return true
        }
        
        // 未来日期可以选择任何时间
        return true
    }
    
    private func setupPointers(startHour: Int, endHour: Int) {
        let minTime = getMinAllowedStartTime()
        
        // 设置左指针 - 应该卡在选中范围的开始块的左边界
        if startHour > minTime.hour || (startHour == minTime.hour && 0 >= minTime.minute) {
            leftPointerHour = startHour
            leftPointerMinute = 0  // 卡在块的左边界
        } else {
            leftPointerHour = minTime.hour
            leftPointerMinute = minTime.minute
        }
        
        // 设置右指针 - 应该卡在选中范围的结束块的右边界
        // 右指针应该显示在选中范围的最后一个块的右边界（即下一个块的左边界）
        rightPointerHour = endHour
        rightPointerMinute = 0  // 卡在下一个块的左边界
        
        showingPointers = true
        print("设置指针: 左指针=\(leftPointerHour ?? 0):\(leftPointerMinute ?? 0), 右指针=\(rightPointerHour ?? 0):\(rightPointerMinute ?? 0)")
        print("实际选择范围: \(startHour):00 - \(endHour):00 (影响 \(endHour - startHour) 个块)")
    }
    
    // 方法：创建时间选择器视图
    private func createTimePickerView() -> some View {
        print("=== createTimePickerView ===")
        print("isLeftPointerSelected: \(isLeftPointerSelected)")
        print("使用预计算的限制参数: min=\(timePickerMinHour):\(timePickerMinMinute), max=\(timePickerMaxHour):\(timePickerMaxMinute)")
        
        return TimePickerView(
            selectedHour: $timePickerHour,
            selectedMinute: $timePickerMinute,
            isLeft: $isLeftPointerSelected,
            minHour: timePickerMinHour,
            minMinute: timePickerMinMinute,
            maxHour: timePickerMaxHour,
            maxMinute: timePickerMaxMinute,
            onConfirm: onTimePickerConfirm,
            onCancel: {
                showingTimePicker = false
            }
        )
    }
    
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
                        // 当前编辑日期的能量规划时间轴
                        EnergyTimelineView(
                            selectedDate: $selectedDate,
                            selectedHour: $selectedHour,
                            selectedEnergyLevel: $selectedEnergyLevel,
                            batchStartHour: $batchStartHour,
                            batchEndHour: $batchEndHour,
                            showingBatchSelector: $showingBatchSelector,
                            showingCalendar: $showingCalendar,
                            showingEnergyButtons: $showingEnergyButtons,
                            selectedHourForButtons: $selectedHourForButtons,
                            showingUnselectableHint: $showingUnselectableHint,
                            leftPointerHour: $leftPointerHour,
                            leftPointerMinute: $leftPointerMinute,
                            rightPointerHour: $rightPointerHour,
                            rightPointerMinute: $rightPointerMinute,
                            showingPointers: $showingPointers,
                            onPointerTap: onPointerTap,
                            onTimePickerConfirm: onTimePickerConfirm,
                            clearPointers: clearPointers,
                            handleHourTap: handleHourTap,
                            isLeftPointerSelected: $isLeftPointerSelected,
                            timePickerHour: $timePickerHour,
                            timePickerMinute: $timePickerMinute,
                            showingTimePicker: $showingTimePicker
                        )
                        .environmentObject(userState)
                        
                        
                        // 其他有规划的日期（只读显示）
                        let plannedDates = userState.getPlannedDates().filter { 
                            !Calendar.current.isDate($0, inSameDayAs: selectedDate) 
                        }
                        
                        if !plannedDates.isEmpty {
                            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                                HStack {
                                    Text("其他规划日期")
                                        .font(.system(size: AppTheme.FontSize.headline, weight: .semibold))
                                        .foregroundColor(AppTheme.Colors.primary)
                                    
                                    Spacer()
                                    
                                    Text("点击切换编辑")
                                        .font(.system(size: AppTheme.FontSize.caption))
                                        .foregroundColor(AppTheme.Colors.textSecondary)
                                        .padding(.horizontal, AppTheme.Spacing.sm)
                                        .padding(.vertical, 4)
                                        .background(AppTheme.Colors.bgMain)
                                        .cornerRadius(AppTheme.Radius.small)
                                }
                                .padding(.horizontal, AppTheme.Spacing.lg)
                                
                                ForEach(plannedDates, id: \.self) { date in
                                    ReadOnlyEnergyTimelineView(
                                        date: date,
                                        onDateSelected: { selectedDate in
                                            withAnimation(.easeInOut(duration: 0.3)) {
                                                self.selectedDate = selectedDate
                                                // 重置选择状态
                                                self.selectedHour = nil
                                                self.selectedEnergyLevel = nil
                                                self.batchStartHour = nil
                                                self.batchEndHour = nil
                                                self.showingBatchSelector = false
                                                self.showingEnergyButtons = false
                                                self.selectedHourForButtons = nil
                                            }
                                        }
                                    )
                                    .environmentObject(userState)
                                }
                            }
                        } else {
                            // 当没有其他规划日期时，显示提示信息
                            VStack(spacing: AppTheme.Spacing.md) {
                                Image(systemName: "calendar.badge.plus")
                                    .font(.system(size: 48))
                                    .foregroundColor(AppTheme.Colors.textSecondary.opacity(0.5))
                                
                                Text("暂无其他规划日期")
                                    .font(.system(size: AppTheme.FontSize.body))
                                    .foregroundColor(AppTheme.Colors.textSecondary)
                                
                                Text("使用右上角的日期选择器添加新的规划")
                                    .font(.system(size: AppTheme.FontSize.caption))
                                    .foregroundColor(AppTheme.Colors.textSecondary.opacity(0.7))
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.vertical, AppTheme.Spacing.xl)
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal, AppTheme.Spacing.lg)
                    .padding(.top, AppTheme.Spacing.lg)
                }
            }
            
            // 悬浮日历
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
                            FloatingCalendarView(
                                selectedDate: $selectedDate,
                                energyPlans: userState.energyPlans,
                                showingCalendar: $showingCalendar
                            )
                            .padding(.horizontal, AppTheme.Spacing.lg)
                            .padding(.bottom, AppTheme.Spacing.xl)
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    )
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingTimePicker) {
            createTimePickerView()
        }
        .sheet(isPresented: $showingHistory) {
            HistoricalEnergyTimelinesView()
                .environmentObject(userState)
        }
        .onTapGesture {
            // 点击背景区域取消操作
            if showingEnergyButtons && !showingTimePicker {
                showingEnergyButtons = false
                batchStartHour = nil
                batchEndHour = nil
                selectedHourForButtons = nil
                clearPointers()
            }
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
    @Binding var showingEnergyButtons: Bool
    @Binding var selectedHourForButtons: Int?
    @Binding var showingUnselectableHint: Bool
    @Binding var leftPointerHour: Int?
    @Binding var leftPointerMinute: Int?
    @Binding var rightPointerHour: Int?
    @Binding var rightPointerMinute: Int?
    @Binding var showingPointers: Bool
    let onPointerTap: (Bool) -> Void
    let onTimePickerConfirm: (Int, Int) -> Void
    let clearPointers: () -> Void
    let handleHourTap: (Int) -> Void
    @Binding var isLeftPointerSelected: Bool
    @Binding var timePickerHour: Int
    @Binding var timePickerMinute: Int
    @Binding var showingTimePicker: Bool
    
    private let hours = Array(7...23) // 7点到23点
    
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
            
            // 时间标签和竖标 - 使用GeometryReader精确定位
            GeometryReader { geometry in
                ZStack {
                    // 时间标签：7点、10点、14点、18点、22点
                    ForEach([7, 10, 14, 18, 22], id: \.self) { hour in
                        VStack(spacing: 0) {
                            // 时间标签
                            Text("\(hour):00")
                                .font(.system(size: AppTheme.FontSize.caption2))
                                .foregroundColor(AppTheme.Colors.textSecondary)
                            
                            // 竖标：从标签延伸到能量块左边缘
                            Rectangle()
                                .fill(AppTheme.Colors.textSecondary.opacity(0.3))
                                .frame(width: 1, height: 8)
                        }
                        .position(
                            x: getTimeLabelPosition(for: hour, in: geometry.size.width),
                            y: 10 // 时间标签的垂直位置
                        )
                    }
                }
            }
            .frame(height: 20)
            
            // 能量条
            GeometryReader { geometry in
                ZStack {
                    HStack(spacing: 0.5) {
                        ForEach(hours, id: \.self) { hour in
                            EnergyHourButton(
                                hour: hour,
                                width: geometry.size.width / CGFloat(hours.count),
                                height: 20,
                                showingPointers: showingPointers,
                                userState: userState,
                                selectedDate: selectedDate,
                                onTap: { handleHourTap(hour) },
                                batchStartHour: batchStartHour,
                                batchEndHour: batchEndHour,
                                selectedHour: selectedHour,
                                showingBatchSelector: showingBatchSelector
                            )
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
                    
                    // 指针显示
                    if showingPointers {
                        // 左指针
                        if let leftHour = leftPointerHour, let leftMinute = leftPointerMinute {
                            PointerView(
                                hour: leftHour,
                                minute: leftMinute,
                                isLeft: true,
                                onTap: {
                                    onPointerTap(true)
                                }
                            )
                            .position(
                                x: getPointerOffset(hour: leftHour, minute: leftMinute, width: geometry.size.width),
                                y: 10 // 指针在时间轴中心
                            )
                            .zIndex(1000) // 确保指针在最上层
                            .onAppear {
                                print("EnergyTimelineView: 左指针显示 - 位置=\(leftHour):\(leftMinute), 偏移=\(getPointerOffset(hour: leftHour, minute: leftMinute, width: geometry.size.width))")
                            }
                        }
                        
                        // 右指针
                        if let rightHour = rightPointerHour, let rightMinute = rightPointerMinute {
                            PointerView(
                                hour: rightHour,
                                minute: rightMinute,
                                isLeft: false,
                                onTap: {
                                    onPointerTap(false)
                                }
                            )
                            .position(
                                x: getPointerOffset(hour: rightHour, minute: rightMinute, width: geometry.size.width),
                                y: 10 // 指针在时间轴中心
                            )
                            .zIndex(1000) // 确保指针在最上层
                            .onAppear {
                                print("EnergyTimelineView: 右指针显示 - 位置=\(rightHour):\(rightMinute), 偏移=\(getPointerOffset(hour: rightHour, minute: rightMinute, width: geometry.size.width))")
                            }
                        }
                    }
                }
            }
            .frame(height: 20)
            
            // 当前时间指示器文本（今天显示时间，其他日期显示空白占位）
            HStack {
                Spacer()
                if isToday(selectedDate) {
                    let currentTime = getCurrentTime()
                    Text("当前：\(String(format: "%02d:%02d", currentTime.hour, currentTime.minute))")
                        .font(.system(size: AppTheme.FontSize.caption))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                } else {
                    Text("")
                        .font(.system(size: AppTheme.FontSize.caption))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                Spacer()
            }
            
            // 选择状态提示
            if let start = batchStartHour, let end = batchEndHour {
                // 时间段选择提示
                HStack {
                    if showingPointers, let leftHour = leftPointerHour, let leftMinute = leftPointerMinute,
                       let rightHour = rightPointerHour, let rightMinute = rightPointerMinute {
                        // 显示指针的精确位置
                        Text("已选择：\(String(format: "%02d:%02d", leftHour, leftMinute)) - \(String(format: "%02d:%02d", rightHour, rightMinute))")
                            .font(.system(size: AppTheme.FontSize.caption))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .onAppear {
                                print("显示指针精确位置: \(leftHour):\(leftMinute) - \(rightHour):\(rightMinute)")
                            }
                    } else {
                        // 显示小时级选择
                        Text("已选择：\(start):00 - \(end):00")
                            .font(.system(size: AppTheme.FontSize.caption))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .onAppear {
                                print("显示小时级选择: \(start):00 - \(end):00")
                                print("showingPointers: \(showingPointers)")
                                print("leftPointerHour: \(leftPointerHour ?? -1), leftPointerMinute: \(leftPointerMinute ?? -1)")
                                print("rightPointerHour: \(rightPointerHour ?? -1), rightPointerMinute: \(rightPointerMinute ?? -1)")
                            }
                    }
                    
                    Spacer()
                    
                    Button("取消选择") {
                        batchStartHour = nil
                        batchEndHour = nil
                        selectedHour = nil
                        selectedEnergyLevel = nil
                        showingBatchSelector = false
                        selectedHourForButtons = nil
                        showingEnergyButtons = false
                        
                        // 隐藏指针
                        leftPointerHour = nil
                        leftPointerMinute = nil
                        rightPointerHour = nil
                        rightPointerMinute = nil
                        showingPointers = false
                    }
                    .font(.system(size: AppTheme.FontSize.caption))
                    .foregroundColor(AppTheme.Colors.primary)
                }
            } else if let hour = selectedHour {
                // 单个时间段选择提示
                HStack {
                    if showingPointers, let leftHour = leftPointerHour, let leftMinute = leftPointerMinute,
                       let rightHour = rightPointerHour, let rightMinute = rightPointerMinute {
                        // 显示指针的精确位置
                        Text("已选择：\(String(format: "%02d:%02d", leftHour, leftMinute)) - \(String(format: "%02d:%02d", rightHour, rightMinute))")
                            .font(.system(size: AppTheme.FontSize.caption))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .onAppear {
                                print("单块模式显示指针精确位置: \(leftHour):\(leftMinute) - \(rightHour):\(rightMinute)")
                            }
                    } else {
                        // 显示小时级选择
                        Text("已选择：\(hour):00-\(hour+1):00")
                            .font(.system(size: AppTheme.FontSize.caption))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .onAppear {
                                print("单块模式显示小时级选择: \(hour):00-\(hour+1):00")
                                print("单块模式showingPointers: \(showingPointers)")
                                print("单块模式指针: left=\(leftPointerHour ?? -1):\(leftPointerMinute ?? -1), right=\(rightPointerHour ?? -1):\(rightPointerMinute ?? -1)")
                            }
                    }
                    
                    Spacer()
                    
                    Button("取消选择") {
                        selectedHour = nil
                        selectedEnergyLevel = nil
                        showingEnergyButtons = false
                        selectedHourForButtons = nil
                        batchStartHour = nil
                        batchEndHour = nil
                        showingBatchSelector = false
                        
                        // 隐藏指针
                        leftPointerHour = nil
                        leftPointerMinute = nil
                        rightPointerHour = nil
                        rightPointerMinute = nil
                        showingPointers = false
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
            EnergyTimelineOverlay(
                showingEnergyButtons: showingEnergyButtons,
                showingUnselectableHint: showingUnselectableHint,
                selectedEnergyLevel: $selectedEnergyLevel,
                showingButtons: $showingEnergyButtons,
                selectedDate: $selectedDate,
                selectedHour: $selectedHour,
                batchStartHour: $batchStartHour,
                batchEndHour: $batchEndHour,
                showingBatchSelector: $showingBatchSelector,
                selectedHourForButtons: $selectedHourForButtons,
                leftPointerHour: $leftPointerHour,
                leftPointerMinute: $leftPointerMinute,
                rightPointerHour: $rightPointerHour,
                rightPointerMinute: $rightPointerMinute,
                showingPointers: $showingPointers
            )
        )
    }
    
    private func getEnergyColor(for hour: Int) -> Color {
        let finalLevel = userState.getFinalEnergyLevel(for: selectedDate, hour: hour, minute: 0)
        return finalLevel.color
    }
    
    private func getCurrentEnergyLevel(for hour: Int) -> EnergyLevel {
        return userState.getFinalEnergyLevel(for: selectedDate, hour: hour, minute: 0)
    }
    
    private func isToday(_ date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }
    
    private func getCurrentHour() -> Int {
        Calendar.current.component(.hour, from: Date())
    }
    
    private func getCurrentTime() -> (hour: Int, minute: Int) {
        let now = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)
        return (hour, minute)
    }
    
    private func getCurrentTimeOffset(width: CGFloat) -> CGFloat {
        let currentTime = getCurrentTime()
        let hourIndex = max(0, min(currentTime.hour - 7, hours.count - 1))
        let segmentWidth = width / CGFloat(hours.count)
        
        // 计算在当前小时内的分钟偏移
        let minuteOffset = CGFloat(currentTime.minute) / 60.0 * segmentWidth
        
        return segmentWidth * CGFloat(hourIndex) + minuteOffset
    }
    
    // 计算时间标签的位置（居中对齐到对应时间块）
    private func getTimeLabelPosition(for hour: Int, in totalWidth: CGFloat) -> CGFloat {
        let hourIndex = hour - 7 // 7点对应索引0
        let blockWidth = totalWidth / CGFloat(hours.count)
        let spacing: CGFloat = 0.5 // 块之间的间距
        return blockWidth * CGFloat(hourIndex) + spacing * CGFloat(hourIndex)
    }
    
    // 计算指针的位置（支持分钟级精度）
    private func getPointerOffset(hour: Int, minute: Int, width: CGFloat) -> CGFloat {
        let hourIndex = hour - 7 // 7点对应索引0
        let blockWidth = width / CGFloat(hours.count)
        let spacing: CGFloat = 0.5 // 块之间的间距
        
        // 计算指针应该位于的时间块边界位置
        // 考虑块之间的间距
        let blockStartOffset = blockWidth * CGFloat(hourIndex) + spacing * CGFloat(hourIndex)
        
        // 如果分钟为0，指针位于块的左边界
        // 如果分钟不为0，指针位于块内的相应位置
        let minuteOffset = (CGFloat(minute) / 60.0) * blockWidth
        
        let totalOffset = blockStartOffset + minuteOffset
        
        // 确保指针精确对齐到像素边界
        return round(totalOffset)
    }
    
    
    // 检查小时是否可选择（不能选择过去的时间）
    private func isHourSelectable(_ hour: Int) -> Bool {
        let now = Date()
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)
        
        // 如果是今天，不能选择过去的时间
        if calendar.isDateInToday(selectedDate) {
            // 基本检查：不能选择过去的时间
            if hour < currentHour {
                return false
            }
            
            // 特殊检查：如果当前时间大于23:50，不允许选择23:00-24:00的块
            // 因为左指针的最小允许时间（当前时间+5分钟）会超过24:00
            if currentHour == 23 && currentMinute > 50 {
                // 如果当前时间大于23:50，不允许选择23:00-24:00的块
                if hour == 23 {
                    return false
                }
            }
            
            // 如果当前时间大于23:55，不允许选择任何24:00的块
            if currentHour == 23 && currentMinute > 55 {
                if hour >= 23 {
                    return false
                }
            }
            
            return true
        }
        
        // 未来日期可以选择任何时间
        return true
    }
    
    // 获取最小允许开始时间
    // 获取左指针的最小允许时间
    private func getMinAllowedStartTime() -> (hour: Int, minute: Int) {
        let now = Date()
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)
        
        // 如果是今天，左指针的左极限为7点或者当前时间+5分钟（取较大的一方）
        if calendar.isDateInToday(selectedDate) {
            let currentTimePlus5 = currentMinute + 5
            let currentTimePlus5Hour = currentTimePlus5 >= 60 ? currentHour + 1 : currentHour
            let currentTimePlus5Minute = currentTimePlus5 >= 60 ? currentTimePlus5 - 60 : currentTimePlus5
            
            // 比较7:00和当前时间+5分钟，取较大的一方
            if currentTimePlus5Hour > 7 || (currentTimePlus5Hour == 7 && currentTimePlus5Minute > 0) {
                return (currentTimePlus5Hour, currentTimePlus5Minute)
            } else {
                return (7, 0)
            }
        }
        
        // 如果是未来日期，左指针的左极限为7点
        return (7, 0)
    }
    
    // 获取左指针的最大允许时间
    private func getMaxAllowedStartTime() -> (hour: Int, minute: Int) {
        guard let rightHour = rightPointerHour, let rightMinute = rightPointerMinute else {
            return (23, 0)
        }
        
        // 左指针的右极限为右指针的时间-5分钟
        let leftMaxMinute = rightMinute - 5
        if leftMaxMinute < 0 {
            return (rightHour - 1, leftMaxMinute + 60)
        } else {
            return (rightHour, leftMaxMinute)
        }
    }
    
    // 获取右指针的最小允许时间
    private func getMinAllowedEndTime() -> (hour: Int, minute: Int) {
        guard let leftHour = leftPointerHour, let leftMinute = leftPointerMinute else {
            print("getMinAllowedEndTime: 无左指针，返回7:00")
            return (7, 0)
        }
        
        // 右指针的左极限为max(7:00, 左指针+5分钟)
        let rightMinMinute = leftMinute + 5
        let rightMinHour = rightMinMinute >= 60 ? leftHour + 1 : leftHour
        let rightMinMinuteAdjusted = rightMinMinute >= 60 ? rightMinMinute - 60 : rightMinMinute
        
        print("getMinAllowedEndTime: 左指针=\(leftHour):\(leftMinute)")
        print("getMinAllowedEndTime: 左指针+5分钟=\(rightMinHour):\(rightMinMinuteAdjusted)")
        
        // 比较7:00和左指针+5分钟，取较大的一方
        if rightMinHour > 7 || (rightMinHour == 7 && rightMinMinuteAdjusted > 0) {
            print("getMinAllowedEndTime: 返回左指针+5分钟=\(rightMinHour):\(rightMinMinuteAdjusted)")
            return (rightMinHour, rightMinMinuteAdjusted)
        } else {
            print("getMinAllowedEndTime: 返回7:00")
            return (7, 0)
        }
    }
    
    // 获取右指针的最大允许时间
    private func getMaxAllowedEndTime() -> (hour: Int, minute: Int) {
        // 右指针的右极限为23:59
        return (23, 59)
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
    
    
    // MARK: - 指针相关方法
    
    
    // 格式化日期
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月d日"
        return formatter.string(from: date)
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
                Text("选择 \(start):00 - \(end+1):00 的能量状态")
                    .font(.system(size: AppTheme.FontSize.headline, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.primary)
            } else if let hour = hour {
                Text("选择 \(hour):00-\(hour+1):00 的能量状态")
                    .font(.system(size: AppTheme.FontSize.headline, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.primary)
            }
            
            // 固定高度的按钮容器
            HStack(spacing: AppTheme.Spacing.md) {
                // 三个能量状态选项
                ForEach(EnergyLevel.allCases.filter { $0 != .unplanned }, id: \.self) { level in
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
                
                // 取消规划选项
                Button(action: {
                    selectedEnergyLevel = .unplanned
                }) {
                    VStack(spacing: AppTheme.Spacing.sm) {
                        ZStack {
                            Circle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 60, height: 60)
                            
                            Text("⚪")
                                .font(.system(size: 24))
                        }
                        
                        Text("取消规划")
                            .font(.system(size: AppTheme.FontSize.caption, weight: .medium))
                            .foregroundColor(AppTheme.Colors.text)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .overlay(
                    Circle()
                        .stroke(selectedEnergyLevel == .unplanned ? Color.gray : Color.clear, lineWidth: 3)
                        .frame(width: 60, height: 60)
                )
            }
            .frame(height: 100) // 固定高度，确保一致性
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
            
            // 如果不是取消规划，则添加分钟级规划
            if energyLevel != .unplanned {
                for hour in start...end {
                    for minute in 0..<60 {
                        let newPlan = EnergyPlan(
                            date: targetDate,
                            hour: hour,
                            minute: minute,
                            energyLevel: energyLevel,
                            createdAt: Date()
                        )
                        userState.energyPlans.append(newPlan)
                    }
                }
            }
        } else if let hour = hour {
            // 单个保存：移除同一天同一小时的旧规划
            userState.energyPlans.removeAll { plan in
                calendar.isDate(plan.date, inSameDayAs: targetDate) && plan.hour == hour
            }
            
            // 如果不是取消规划，则添加分钟级规划
            if energyLevel != .unplanned {
                for minute in 0..<60 {
                    let newPlan = EnergyPlan(
                        date: targetDate,
                        hour: hour,
                        minute: minute,
                        energyLevel: energyLevel,
                        createdAt: Date()
                    )
                    userState.energyPlans.append(newPlan)
                }
            }
        }
        
        // 按日期、小时和分钟排序
        userState.energyPlans.sort { plan1, plan2 in
            if plan1.date != plan2.date {
                return plan1.date < plan2.date
            }
            if plan1.hour != plan2.hour {
                return plan1.hour < plan2.hour
            }
            return plan1.minute < plan2.minute
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

// MARK: - 历史能量记录时间轴视图
struct HistoricalEnergyTimelinesView: View {
    @EnvironmentObject var userState: UserState
    
    var body: some View {
        NavigationView {
            ZStack {
                AppGradient.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                        Text("历史能量记录")
                            .font(.system(size: AppTheme.FontSize.headline, weight: .semibold))
                            .foregroundColor(AppTheme.Colors.primary)
                        
                        if groupedEnergyRecords.isEmpty {
                            VStack(spacing: AppTheme.Spacing.md) {
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.system(size: 48))
                                    .foregroundColor(AppTheme.Colors.textSecondary.opacity(0.5))
                                
                                Text("暂无历史记录")
                                    .font(.system(size: AppTheme.FontSize.body))
                                    .foregroundColor(AppTheme.Colors.textSecondary)
                                
                                Text("开始记录您的能量状态，建立个人能量档案")
                                    .font(.system(size: AppTheme.FontSize.caption))
                                    .foregroundColor(AppTheme.Colors.textSecondary.opacity(0.7))
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, AppTheme.Spacing.xl)
                        } else {
                            ForEach(groupedEnergyRecords.keys.sorted(by: >), id: \.self) { date in
                                HistoricalEnergyTimelineCard(
                                    date: date,
                                    energyRecords: groupedEnergyRecords[date] ?? []
                                )
                                .environmentObject(userState)
                            }
                        }
                    }
                    .padding(.horizontal, AppTheme.Spacing.lg)
                    .padding(.top, AppTheme.Spacing.lg)
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    private var groupedEnergyRecords: [Date: [ActualEnergyRecord]] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var grouped: [Date: [ActualEnergyRecord]] = [:]
        
        // 只获取今天之前的实际能量记录
        for record in userState.actualEnergyRecords {
            let date = calendar.startOfDay(for: record.date)
            // 只包含今天之前的日期
            if date < today {
                if grouped[date] == nil {
                    grouped[date] = []
                }
                grouped[date]?.append(record)
            }
        }
        
        // 按小时排序每个日期的记录
        for date in grouped.keys {
            grouped[date]?.sort { $0.hour < $1.hour }
        }
        
        return grouped
    }
}

// MARK: - 历史能量记录时间轴卡片
struct HistoricalEnergyTimelineCard: View {
    @EnvironmentObject var userState: UserState
    let date: Date
    let energyRecords: [ActualEnergyRecord]
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM月dd日"
        return formatter
    }()
    
    private let hours = Array(7...23) // 7点到23点
    
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
            
            // 时间标签和竖标 - 使用GeometryReader精确定位
            GeometryReader { geometry in
                ZStack {
                    // 时间标签：7点、10点、14点、18点、22点
                    ForEach([7, 10, 14, 18, 22], id: \.self) { hour in
                        VStack(spacing: 0) {
                            // 时间标签
                            Text("\(hour):00")
                                .font(.system(size: AppTheme.FontSize.caption2))
                                .foregroundColor(AppTheme.Colors.textSecondary)
                            
                            // 竖标：从标签延伸到能量块左边缘
                            Rectangle()
                                .fill(AppTheme.Colors.textSecondary.opacity(0.3))
                                .frame(width: 1, height: 8)
                        }
                        .position(
                            x: getTimeLabelPosition(for: hour, in: geometry.size.width),
                            y: 10 // 时间标签的垂直位置
                        )
                    }
                }
            }
            .frame(height: 20)
            
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
        // 查找该小时的实际能量记录
        if let record = energyRecords.first(where: { $0.hour == hour }) {
            return record.energyLevel.color
        }
        // 如果没有记录，显示为灰色（未记录）
        return Color.gray.opacity(0.2)
    }
    
    private func getEnergyStats() -> (high: Int, medium: Int, low: Int) {
        var high = 0, medium = 0, low = 0
        
        for record in energyRecords {
            switch record.energyLevel {
            case .high: high += 1
            case .medium: medium += 1
            case .low: low += 1
            case .unplanned: 
                // 待规划状态不计入统计
                break
            }
        }
        
        return (high, medium, low)
    }
    
    // 计算时间标签的位置（居中对齐到对应时间块）
    private func getTimeLabelPosition(for hour: Int, in totalWidth: CGFloat) -> CGFloat {
        let hourIndex = hour - 7 // 7点对应索引0
        let blockWidth = totalWidth / CGFloat(hours.count)
        let spacing: CGFloat = 0.5 // 块之间的间距
        return blockWidth * CGFloat(hourIndex) + spacing * CGFloat(hourIndex)
    }
}

// MARK: - 不可选择提示视图
struct UnselectableHintView: View {
    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 16))
                .foregroundColor(.orange)
            
            Text("不可选择此时间段")
                .font(.system(size: AppTheme.FontSize.caption, weight: .medium))
                .foregroundColor(AppTheme.Colors.text)
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                .fill(.ultraThinMaterial)
                .shadow(color: AppTheme.Shadows.card, radius: 6, x: 0, y: 3)
        )
    }
}

// MARK: - 小型电池图标组件
struct SmallBatteryIconView: View {
    let energyLevel: EnergyLevel
    
    var body: some View {
        ZStack {
            // 电池外框
            RoundedRectangle(cornerRadius: 3)
                .stroke(energyLevel.color, lineWidth: 2)
                .frame(width: 25, height: 14)
            
            // 电池正极
            RoundedRectangle(cornerRadius: 2)
                .fill(energyLevel.color)
                .frame(width: 3, height: 8)
                .offset(x: 14)
            
            // 电池电量
            HStack(spacing: 1) {
                ForEach(0..<getBatterySegments(), id: \.self) { _ in
                    Rectangle()
                        .fill(energyLevel.color)
                        .frame(width: 4, height: 10)
                        .cornerRadius(1)
                }
            }
            .offset(x: -2)
            
            // 省电模式图标（黄色时显示）
            if energyLevel == .medium {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 6))
                    .foregroundColor(.green)
                    .offset(x: 11, y: -6)
            }
        }
    }
    
    private func getBatterySegments() -> Int {
        switch energyLevel {
        case .high:
            return 4  // 满电：4格
        case .medium:
            return 2  // 半满：2格
        case .low:
            return 1  // 低电量：1格
        case .unplanned:
            return 0  // 待规划：0格
        }
    }
}

// MARK: - 悬浮能量状态按钮
struct FloatingEnergyButtons: View {
    @EnvironmentObject var userState: UserState
    let hour: Int
    @Binding var selectedEnergyLevel: EnergyLevel?
    @Binding var showingButtons: Bool
    @Binding var selectedDate: Date
    @Binding var selectedHour: Int?
    @Binding var batchStartHour: Int?
    @Binding var batchEndHour: Int?
    @Binding var showingBatchSelector: Bool
    @Binding var selectedHourForButtons: Int?
    @Binding var leftPointerHour: Int?
    @Binding var leftPointerMinute: Int?
    @Binding var rightPointerHour: Int?
    @Binding var rightPointerMinute: Int?
    @Binding var showingPointers: Bool
    
    var body: some View {
        HStack(spacing: 10) {
            // 三个能量状态按钮
            ForEach(EnergyLevel.allCases.filter { $0 != .unplanned }, id: \.self) { level in
                Button(action: {
                    print("=== 电池按钮被点击 ===")
                    print("点击的能量级别: \(level)")
                    print("当前状态: showingPointers=\(showingPointers)")
                    print("当前状态: leftPointerHour=\(leftPointerHour ?? -1), leftPointerMinute=\(leftPointerMinute ?? -1)")
                    print("当前状态: rightPointerHour=\(rightPointerHour ?? -1), rightPointerMinute=\(rightPointerMinute ?? -1)")
                    print("当前状态: hour=\(hour)")
                    print("即将调用saveMinuteLevelPlan")
                    
                    selectedEnergyLevel = level
                    saveMinuteLevelPlan(energyLevel: level)
                    
                    print("saveMinuteLevelPlan调用完成")
                    
                    // 强制刷新UI
                    DispatchQueue.main.async {
                        print("强制刷新UI")
                        clearSelectionState()
                        showingButtons = false
                    }
                }) {
                    SmallBatteryIconView(energyLevel: level)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // 取消规划按钮
            Button(action: {
                selectedEnergyLevel = .unplanned
                saveMinuteLevelPlan(energyLevel: .unplanned)
                clearSelectionState()
                showingButtons = false
            }) {
                SmallBatteryIconView(energyLevel: .unplanned)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .frame(width: 140, height: 24) // 电池高度14 + 10 = 24
        .padding(.horizontal, 4)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.large)
                .fill(.ultraThinMaterial)
                .shadow(color: AppTheme.Shadows.card, radius: 8, x: 0, y: 4)
        )
        .position(x: 220, y: 160) // 绝对定位，在"已选择"文字右边，"取消选择"按钮左边
        .onAppear {
            print("FloatingEnergyButtons显示: hour=\(hour), showingPointers=\(showingPointers)")
        }
        .onTapGesture {
            // 点击背景区域取消选择并关闭按钮
            clearSelectionState()
            showingButtons = false
        }
    }
    
    
    // 清除选择状态
    private func clearSelectionState() {
        selectedHour = nil
        batchStartHour = nil
        batchEndHour = nil
        showingBatchSelector = false
        selectedEnergyLevel = nil
        selectedHourForButtons = nil
        showingButtons = false
        
        // 隐藏指针
        leftPointerHour = nil
        leftPointerMinute = nil
        rightPointerHour = nil
        rightPointerMinute = nil
        showingPointers = false
    }
}

// MARK: - 批量能量状态按钮
struct BatchEnergyButtons: View {
    @EnvironmentObject var userState: UserState
    let startHour: Int
    let endHour: Int
    @Binding var selectedEnergyLevel: EnergyLevel?
    @Binding var selectedDate: Date
    @Binding var batchStartHour: Int?
    @Binding var batchEndHour: Int?
    @Binding var selectedHour: Int?
    @Binding var showingBatchSelector: Bool
    @Binding var selectedHourForButtons: Int?
    @Binding var showingButtons: Bool
    @Binding var leftPointerHour: Int?
    @Binding var leftPointerMinute: Int?
    @Binding var rightPointerHour: Int?
    @Binding var rightPointerMinute: Int?
    @Binding var showingPointers: Bool
    
    var body: some View {
        HStack(spacing: 10) {
            // 三个能量状态按钮
            ForEach(EnergyLevel.allCases.filter { $0 != .unplanned }, id: \.self) { level in
                Button(action: {
                    selectedEnergyLevel = level
                    saveBatchMinuteLevelPlan(startHour: startHour, endHour: endHour, energyLevel: level)
                    clearSelectionState()
                }) {
                    SmallBatteryIconView(energyLevel: level)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // 取消规划按钮
            Button(action: {
                selectedEnergyLevel = .unplanned
                saveBatchMinuteLevelPlan(startHour: startHour, endHour: endHour, energyLevel: .unplanned)
                clearSelectionState()
            }) {
                SmallBatteryIconView(energyLevel: .unplanned)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .frame(width: 140, height: 24) // 电池高度14 + 10 = 24
        .padding(.horizontal, 4)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.large)
                .fill(.ultraThinMaterial)
                .shadow(color: AppTheme.Shadows.card, radius: 8, x: 0, y: 4)
        )
    }
    
    private func saveBatchMinuteLevelPlan(startHour: Int, endHour: Int, energyLevel: EnergyLevel) {
        print("=== saveBatchMinuteLevelPlan 方法被调用 ===")
        let calendar = Calendar.current
        let targetDate = calendar.startOfDay(for: selectedDate)
        
        print("批量保存范围: \(startHour):00 - \(endHour):59")
        print("能量级别: \(energyLevel)")
        
        // 移除指定时间范围内的旧规划
        let removedCount = userState.energyPlans.count
        userState.energyPlans.removeAll { plan in
            calendar.isDate(plan.date, inSameDayAs: targetDate) && 
            plan.hour >= startHour && plan.hour <= endHour
        }
        print("移除了 \(removedCount - userState.energyPlans.count) 个旧规划")
        
        // 如果不是取消规划，则批量添加分钟级规划
        if energyLevel != .unplanned {
            print("开始创建批量分钟级规划...")
            var planCount = 0
            
            for hour in startHour...endHour {
                for minute in 0..<60 {
                    let newPlan = EnergyPlan(
                        date: targetDate,
                        hour: hour,
                        minute: minute,
                        energyLevel: energyLevel,
                        createdAt: Date()
                    )
                    userState.energyPlans.append(newPlan)
                    planCount += 1
                }
            }
            
            print("总共创建了 \(planCount) 个分钟级规划")
        }
    }
    
    
    // 清除选择状态
    private func clearSelectionState() {
        selectedHour = nil
        batchStartHour = nil
        batchEndHour = nil
        showingBatchSelector = false
        selectedEnergyLevel = nil
        selectedHourForButtons = nil
        showingButtons = false
        
        // 隐藏指针
        leftPointerHour = nil
        leftPointerMinute = nil
        rightPointerHour = nil
        rightPointerMinute = nil
        showingPointers = false
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

// MARK: - 只读能量时间轴视图
struct ReadOnlyEnergyTimelineView: View {
    @EnvironmentObject var userState: UserState
    let date: Date
    let onDateSelected: (Date) -> Void
    
    private let hours = Array(7...23) // 7点到23点
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            // 日期标题
            HStack {
                Text(formatDate(date))
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
            
            // 时间标签和竖标 - 使用GeometryReader精确定位
            GeometryReader { geometry in
                ZStack {
                    // 时间标签：7点、10点、14点、18点、22点
                    ForEach([7, 10, 14, 18, 22], id: \.self) { hour in
                        VStack(spacing: 0) {
                            // 时间标签
                            Text("\(hour):00")
                                .font(.system(size: AppTheme.FontSize.caption2))
                                .foregroundColor(AppTheme.Colors.textSecondary)
                            
                            // 竖标：从标签延伸到能量块左边缘
                            Rectangle()
                                .fill(AppTheme.Colors.textSecondary.opacity(0.3))
                                .frame(width: 1, height: 8)
                        }
                        .position(
                            x: getTimeLabelPosition(for: hour, in: geometry.size.width),
                            y: 10 // 时间标签的垂直位置
                        )
                    }
                }
            }
            .frame(height: 20)
            
            // 能量条
            GeometryReader { geometry in
                HStack(spacing: 0.5) {
                    ForEach(hours, id: \.self) { hour in
                        MinuteLevelEnergyBlock(
                            hour: hour,
                            width: geometry.size.width / CGFloat(hours.count),
                            height: 16,
                            userState: userState,
                            selectedDate: date
                        )
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
        .onTapGesture {
            onDateSelected(date)
        }
    }
    
    private func getEnergyColor(for hour: Int) -> Color {
        // 获取该日期的能量预规划
        let finalLevel = userState.getFinalEnergyLevel(for: date, hour: hour, minute: 0)
        return finalLevel.color
    }
    
    private func getEnergyStats() -> (high: Int, medium: Int, low: Int) {
        var high = 0, medium = 0, low = 0
        
        for hour in hours {
            let level = userState.getFinalEnergyLevel(for: date, hour: hour, minute: 0)
            switch level {
            case .high: high += 1
            case .medium: medium += 1
            case .low: low += 1
            case .unplanned: 
                // 待规划状态不计入统计
                break
            }
        }
        
        return (high, medium, low)
    }
    
    // 计算时间标签的位置（居中对齐到对应时间块）
    private func getTimeLabelPosition(for hour: Int, in totalWidth: CGFloat) -> CGFloat {
        let hourIndex = hour - 7 // 7点对应索引0
        let blockWidth = totalWidth / CGFloat(hours.count)
        let spacing: CGFloat = 0.5 // 块之间的间距
        return blockWidth * CGFloat(hourIndex) + spacing * CGFloat(hourIndex)
    }
    
    // 格式化日期
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月d日"
        return formatter.string(from: date)
    }
}

// MARK: - 分钟级规划保存方法
extension FloatingEnergyButtons {
    func saveMinuteLevelPlan(energyLevel: EnergyLevel) {
        print("=== saveMinuteLevelPlan 方法被调用 ===")
        let calendar = Calendar.current
        let targetDate = calendar.startOfDay(for: selectedDate)
        
        print("=== saveMinuteLevelPlan 开始 ===")
        print("showingPointers: \(showingPointers)")
        print("leftPointerHour: \(leftPointerHour ?? -1), leftPointerMinute: \(leftPointerMinute ?? -1)")
        print("rightPointerHour: \(rightPointerHour ?? -1), rightPointerMinute: \(rightPointerMinute ?? -1)")
        print("energyLevel: \(energyLevel)")
        
        // 如果有指针，使用分钟级规划
        print("检查条件: showingPointers=\(showingPointers)")
        print("检查条件: leftPointerHour=\(leftPointerHour ?? -1), leftPointerMinute=\(leftPointerMinute ?? -1)")
        print("检查条件: rightPointerHour=\(rightPointerHour ?? -1), rightPointerMinute=\(rightPointerMinute ?? -1)")
        
        let hasLeftPointer = leftPointerHour != nil && leftPointerMinute != nil
        let hasRightPointer = rightPointerHour != nil && rightPointerMinute != nil
        print("指针检查: hasLeftPointer=\(hasLeftPointer), hasRightPointer=\(hasRightPointer)")
        
        if showingPointers, let leftHour = leftPointerHour, let leftMinute = leftPointerMinute,
           let rightHour = rightPointerHour, let rightMinute = rightPointerMinute {
            print("进入分钟级保存分支")
            print("使用指针位置: 左指针=\(leftHour):\(leftMinute), 右指针=\(rightHour):\(rightMinute)")
            
            // 计算实际影响范围
            let startHour = leftHour
            let startMinute = leftMinute
            let endHour = rightHour
            let endMinute = rightMinute
            
            print("实际影响范围: \(startHour):\(startMinute) - \(endHour):\(endMinute)")
            
            print("开始移除旧规划...")
            print("移除条件: 日期=\(targetDate), 左边界=\(startHour):\(startMinute), 右边界=\(endHour):\(endMinute)")
            
            let removedCount = userState.energyPlans.count
            // 移除指定时间范围内的旧规划
            userState.energyPlans.removeAll { plan in
                let isSameDate = calendar.isDate(plan.date, inSameDayAs: targetDate)
                let isInRange: Bool
                
                if startHour == endHour {
                    // 同一小时内
                    isInRange = plan.hour == startHour && plan.minute >= startMinute && plan.minute < endMinute
                } else {
                    // 跨小时
                    if plan.hour == startHour {
                        isInRange = plan.minute >= startMinute
                    } else if plan.hour == endHour {
                        isInRange = plan.minute < endMinute
                    } else {
                        isInRange = plan.hour > startHour && plan.hour < endHour
                    }
                }
                
                let shouldRemove = isSameDate && isInRange
                
                if shouldRemove {
                    print("移除规划: \(plan.hour):\(plan.minute) - \(plan.energyLevel)")
                }
                return shouldRemove
            }
            print("移除了 \(removedCount - userState.energyPlans.count) 个旧规划")
            
            // 如果不是取消规划，则添加分钟级规划
            if energyLevel != .unplanned {
                print("开始创建分钟级规划...")
                print("创建范围: \(startHour):\(startMinute) - \(endHour):\(endMinute)")
                
                // 按分钟级创建规划
                var currentHour = startHour
                var currentMinute = startMinute
                var planCount = 0
                
                while currentHour < endHour || (currentHour == endHour && currentMinute < endMinute) {
                    let newPlan = EnergyPlan(
                        date: targetDate,
                        hour: currentHour,
                        minute: currentMinute,
                        energyLevel: energyLevel,
                        createdAt: Date()
                    )
                    userState.energyPlans.append(newPlan)
                    planCount += 1
                    
                    print("创建规划: \(String(format: "%02d:%02d", currentHour, currentMinute)) - \(energyLevel)")
                    
                    // 增加1分钟
                    currentMinute += 1
                    if currentMinute >= 60 {
                        currentMinute = 0
                        currentHour += 1
                        print("分钟重置，小时增加到: \(currentHour)")
                    }
                }
                
                print("总共创建了 \(planCount) 个规划")
                
                // 验证保存的数据
                print("=== 验证保存的数据 ===")
                let verifyPlans = userState.energyPlans.filter { plan in
                    calendar.isDate(plan.date, inSameDayAs: targetDate) && 
                    plan.hour == startHour
                }.sorted { $0.minute < $1.minute }
                print("小时\(startHour)的规划数量: \(verifyPlans.count)")
                if verifyPlans.count > 0 {
                    print("前5个规划: \(verifyPlans.prefix(5).map { "\($0.hour):\($0.minute)-\($0.energyLevel)" })")
                }
            }
        } else {
            // 没有指针，使用分钟级规划保存整个小时
            print("进入无指针分钟级保存分支")
            print("原因: showingPointers=\(showingPointers), hasLeftPointer=\(hasLeftPointer), hasRightPointer=\(hasRightPointer)")
            print("保存整个小时: hour=\(hour), energyLevel=\(energyLevel)")
            
            let calendar = Calendar.current
            let targetDate = calendar.startOfDay(for: selectedDate)
            
            // 移除该小时的旧规划
            userState.energyPlans.removeAll { plan in
                calendar.isDate(plan.date, inSameDayAs: targetDate) && plan.hour == hour
            }
            
            // 如果不是取消规划，则添加分钟级规划
            if energyLevel != .unplanned {
                for minute in 0..<60 {
                    let newPlan = EnergyPlan(
                        date: targetDate,
                        hour: hour,
                        minute: minute,
                        energyLevel: energyLevel,
                        createdAt: Date()
                    )
                    userState.energyPlans.append(newPlan)
                }
                print("为该小时创建了60个分钟级规划")
            }
        }
        
        // 按日期、小时和分钟排序
        userState.energyPlans.sort { plan1, plan2 in
            if plan1.date != plan2.date {
                return plan1.date < plan2.date
            }
            if plan1.hour != plan2.hour {
                return plan1.hour < plan2.hour
            }
            return plan1.minute < plan2.minute
        }
    }
}

// MARK: - EnergyTimelineOverlay
struct EnergyTimelineOverlay: View {
    let showingEnergyButtons: Bool
    let showingUnselectableHint: Bool
    
    @Binding var selectedEnergyLevel: EnergyLevel?
    @Binding var showingButtons: Bool
    @Binding var selectedDate: Date
    @Binding var selectedHour: Int?
    @Binding var batchStartHour: Int?
    @Binding var batchEndHour: Int?
    @Binding var showingBatchSelector: Bool
    @Binding var selectedHourForButtons: Int?
    @Binding var leftPointerHour: Int?
    @Binding var leftPointerMinute: Int?
    @Binding var rightPointerHour: Int?
    @Binding var rightPointerMinute: Int?
    @Binding var showingPointers: Bool
    
    var body: some View {
        Group {
            if showingEnergyButtons, let hour = selectedHourForButtons {
                // 悬浮显示电池图标，不占用空间
                FloatingEnergyButtons(
                    hour: hour,
                    selectedEnergyLevel: $selectedEnergyLevel,
                    showingButtons: $showingButtons,
                    selectedDate: $selectedDate,
                    selectedHour: $selectedHour,
                    batchStartHour: $batchStartHour,
                    batchEndHour: $batchEndHour,
                    showingBatchSelector: $showingBatchSelector,
                    selectedHourForButtons: $selectedHourForButtons,
                    leftPointerHour: $leftPointerHour,
                    leftPointerMinute: $leftPointerMinute,
                    rightPointerHour: $rightPointerHour,
                    rightPointerMinute: $rightPointerMinute,
                    showingPointers: $showingPointers
                )
                .allowsHitTesting(true)
                .zIndex(1000) // 确保在最上层
            } else if let start = batchStartHour, let end = batchEndHour, !showingEnergyButtons {
                // 多块选择时，如果有指针，使用FloatingEnergyButtons；否则使用BatchEnergyButtons
                if showingPointers {
                    // 有指针时，使用FloatingEnergyButtons实现分钟级精确控制
                    FloatingEnergyButtons(
                        hour: start, // 使用起始小时作为标识
                        selectedEnergyLevel: $selectedEnergyLevel,
                        showingButtons: $showingButtons,
                        selectedDate: $selectedDate,
                        selectedHour: $selectedHour,
                        batchStartHour: $batchStartHour,
                        batchEndHour: $batchEndHour,
                        showingBatchSelector: $showingBatchSelector,
                        selectedHourForButtons: $selectedHourForButtons,
                        leftPointerHour: $leftPointerHour,
                        leftPointerMinute: $leftPointerMinute,
                        rightPointerHour: $rightPointerHour,
                        rightPointerMinute: $rightPointerMinute,
                        showingPointers: $showingPointers
                    )
                    .allowsHitTesting(true)
                    .position(x: 185, y: 90) //
                    .zIndex(1000) // 确保在最上层
                } else {
                    // 没有指针时，使用BatchEnergyButtons
                    BatchEnergyButtons(
                        startHour: start,
                        endHour: end,
                        selectedEnergyLevel: $selectedEnergyLevel,
                        selectedDate: $selectedDate,
                        batchStartHour: $batchStartHour,
                        batchEndHour: $batchEndHour,
                        selectedHour: $selectedHour,
                        showingBatchSelector: $showingBatchSelector,
                        selectedHourForButtons: $selectedHourForButtons,
                        showingButtons: $showingButtons,
                        leftPointerHour: $leftPointerHour,
                        leftPointerMinute: $leftPointerMinute,
                        rightPointerHour: $rightPointerHour,
                        rightPointerMinute: $rightPointerMinute,
                        showingPointers: $showingPointers
                    )
                    .allowsHitTesting(true)
                    .position(x: 220, y: 160) // 
                    .zIndex(1000) // 确保在最上层
                }
            }
            
            if showingUnselectableHint {
                UnselectableHintView()
                    .allowsHitTesting(true)
                    .zIndex(1000) // 确保在最上层
            }
        }
    }
    
    // 清除选择状态（包括隐藏指针）
    private func clearSelectionState() {
        selectedHour = nil
        batchStartHour = nil
        batchEndHour = nil
        showingBatchSelector = false
        selectedEnergyLevel = nil
        selectedHourForButtons = nil
        showingButtons = false
        
        // 隐藏指针
        leftPointerHour = nil
        leftPointerMinute = nil
        rightPointerHour = nil
        rightPointerMinute = nil
        showingPointers = false
    }
}

// MARK: - EnergyHourButton
struct EnergyHourButton: View {
    let hour: Int
    let width: CGFloat
    let height: CGFloat
    let showingPointers: Bool
    @ObservedObject var userState: UserState
    let selectedDate: Date
    let onTap: () -> Void
    let batchStartHour: Int?
    let batchEndHour: Int?
    let selectedHour: Int?
    let showingBatchSelector: Bool
    
    var body: some View {
        Button(action: onTap) {
            // 始终使用分钟级颜色分割显示
            MinuteLevelEnergyBlock(
                hour: hour,
                width: width,
                height: height,
                userState: userState,
                selectedDate: selectedDate
            )
        }
        .overlay(
            Rectangle()
                .stroke(getSelectionStrokeColor(for: hour), lineWidth: 2)
        )
        .overlay(
            // 过去时间的灰色覆盖层
            Rectangle()
                .fill(Color.black.opacity(0.6))
                .frame(width: width, height: height)
                .cornerRadius(2)
                .opacity(isHourSelectable(hour) ? 0 : 1)
        )
        .buttonStyle(PlainButtonStyle())
    }
    
    private func getEnergyColor(for hour: Int) -> Color {
        let finalLevel = userState.getFinalEnergyLevel(for: selectedDate, hour: hour, minute: 0)
        return finalLevel.color
    }
    
    private func isHourSelectable(_ hour: Int) -> Bool {
        let now = Date()
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)
        
        // 如果是今天，不能选择过去的时间
        if calendar.isDateInToday(selectedDate) {
            // 基本检查：不能选择过去的时间
            if hour < currentHour {
                return false
            }
            
            // 特殊检查：如果当前时间大于23:50，不允许选择23:00-24:00的块
            // 因为左指针的最小允许时间（当前时间+5分钟）会超过24:00
            if currentHour == 23 && currentMinute > 50 {
                // 如果当前时间大于23:50，不允许选择23:00-24:00的块
                if hour == 23 {
                    return false
                }
            }
            
            // 如果当前时间大于23:55，不允许选择任何24:00的块
            if currentHour == 23 && currentMinute > 55 {
                if hour >= 23 {
                    return false
                }
            }
            
            return true
        }
        
        // 未来日期可以选择任何时间
        return true
    }
    
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
}

#Preview {
    EnergyPlanningView()
        .environmentObject(UserState())
}
