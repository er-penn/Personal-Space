//
//  BreathingAnimationView.swift
//  Personal Space
//
//  Created by Penn on 2025/1/27.
//

import SwiftUI
import AVFoundation
import Combine

struct BreathingAnimationView: View {
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 0.3
    @State private var currentPhase: BreathingPhase = .inhale
    @State private var timer: Timer?
    @State private var phaseProgress: Double = 0.0
    @State private var isRunning = false
    @State private var selectedPattern: BreathingPattern = .box_4_4_4_4

    // 音频管理器（用于播放引导音效）
    @StateObject private var audioManager = AudioManager()

    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            // 呼吸动画
            breathingAnimationSection
            
            // 控制按钮
            controlButtonsSection
            
            // 模式说明
            patternDescriptionSection
        }
        .padding(AppTheme.Spacing.lg)
    }
    
    // MARK: - 视图组件
    private var breathingAnimationSection: some View {
        ZStack {
            // 多层呼吸圆环
            breathingCircles
            
            // 中央文字提示
            centerTextOverlay
        }
        .frame(width: 250, height: 250)
        .onAppear {
            startBreathing()
        }
        .onDisappear {
            stopBreathing()
        }
    }
    
    private var breathingCircles: some View {
        ForEach(0..<3, id: \.self) { index in
            Circle()
                .stroke(getPhaseColor(), lineWidth: CGFloat(3 - index))
                .scaleEffect(scale * (1.0 + Double(index) * 0.3))
                .opacity(opacity * (1.0 - Double(index) * 0.2))
                .animation(.easeInOut(duration: getCurrentPhaseDuration()), value: scale)
                .animation(.easeInOut(duration: getCurrentPhaseDuration()), value: opacity)
                .animation(.easeInOut(duration: getCurrentPhaseDuration()), value: currentPhase)
        }
    }
    
    private var centerTextOverlay: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Text(getPhaseText())
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(getPhaseColor())
            
            Text(getPhaseDescription())
                .font(.system(size: 16))
                .foregroundColor(getPhaseColor().opacity(0.7))
                .multilineTextAlignment(.center)
                .frame(maxWidth: 200)
            
            // 进度条
            ProgressView(value: phaseProgress)
                .progressViewStyle(LinearProgressViewStyle(tint: getPhaseColor()))
                .frame(width: 200)
        }
    }
    
    private var controlButtonsSection: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // 播放/暂停按钮
            playPauseButton
            
            // 呼吸模式选择
            patternPicker
        }
    }
    
    private var playPauseButton: some View {
        Button(action: {
            if isRunning {
                pauseBreathing()
            } else {
                startBreathing()
            }
        }) {
            HStack {
                Image(systemName: isRunning ? "pause.fill" : "play.fill")
                    .font(.system(size: 20))
                Text(isRunning ? "暂停" : "开始")
                    .font(.system(size: AppTheme.FontSize.headline, weight: .medium))
            }
            .foregroundColor(.white)
            .padding(.horizontal, AppTheme.Spacing.lg)
            .padding(.vertical, AppTheme.Spacing.md)
            .background(getPhaseColor())
            .cornerRadius(AppTheme.Radius.large)
            .shadow(color: getPhaseColor().opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var patternPicker: some View {
        HStack {
            Spacer()
            HStack(spacing: AppTheme.Spacing.sm) {
            ForEach(BreathingPattern.allCases, id: \.self) { pattern in
                    Button(action: {
                        // 切换呼吸模式
                        selectedPattern = pattern
                        // 如果正在运行，重启呼吸
            if isRunning {
                stopBreathing()
                startBreathing()
            }
                    }) {
                        Text(getPatternShortName(pattern))
                            .font(.system(size: AppTheme.FontSize.caption, weight: .medium))
                            .foregroundColor(selectedPattern == pattern ? .white : AppTheme.Colors.text)
                            .padding(.horizontal, AppTheme.Spacing.md)
                            .padding(.vertical, AppTheme.Spacing.sm)
                            .background(
                                RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                                    .fill(selectedPattern == pattern ? AppTheme.Colors.primary : AppTheme.Colors.cardBg)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                                    .stroke(selectedPattern == pattern ? AppTheme.Colors.primary : Color.clear, lineWidth: 1)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            Spacer()
        }
    }
    
    // 获取呼吸法的简短名称（用于按钮显示）
    private func getPatternShortName(_ pattern: BreathingPattern) -> String {
        switch pattern {
        case .box_4_4_4_4:
            return "方形"
        case .triangle_4_7_8:
            return "三角"
        case ._4_7_8:
            return "放松"
        case ._7_11:
            return "深度"
        }
    }
    
    private var patternDescriptionSection: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Text("当前：\(selectedPattern.rawValue)")
                .font(.system(size: AppTheme.FontSize.subheadline, weight: .medium))
                .foregroundColor(AppTheme.Colors.text)
            
            Text("节奏：\(selectedPattern.description)")
                .font(.system(size: AppTheme.FontSize.body))
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
        .padding()
        .background(AppTheme.Colors.cardBg.opacity(0.5))
        .cornerRadius(AppTheme.Radius.medium)
    }

    // MARK: - 呼吸控制方法
    private func startBreathing() {
        isRunning = true
        moveToPhase(.inhale)
        playPhaseSound()
    }

    private func pauseBreathing() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }

    private func stopBreathing() {
        pauseBreathing()
        // 重置到吸气阶段
        currentPhase = .inhale
        scale = 1.0
        opacity = 0.3
        phaseProgress = 0.0
    }

    private func moveToPhase(_ phase: BreathingPhase) {
        // 停止之前的定时器
        timer?.invalidate()
        timer = nil
        
        currentPhase = phase

        // 播放阶段对应的音效
        playPhaseSound()

        // 重置进度
            phaseProgress = 0.0
        
        // 根据阶段更新动画参数
        updateAnimationForPhase(phase)

        // 启动进度动画和阶段切换定时器
        startProgressAnimation()
    }

    private func moveToNextPhase() {
        guard isRunning else { return }
        
        switch currentPhase {
        case .inhale:
            // 如果 holdTime 为 0，跳过屏息阶段
            if selectedPattern.holdTime > 0 {
            moveToPhase(.hold)
            } else {
                moveToPhase(.exhale)
            }
        case .hold:
            moveToPhase(.exhale)
        case .exhale:
            // 如果 restTime > 0，进入休息阶段，否则直接进入下一轮吸气
            if selectedPattern.restTime > 0 {
                moveToPhase(.rest)
            } else {
                moveToPhase(.inhale)
            }
        case .rest:
            moveToPhase(.inhale)
        }
    }

    private func startProgressAnimation() {
        let duration = getCurrentPhaseDuration()
        
        // 如果阶段时长为 0，立即切换到下一阶段
        guard duration > 0 else {
            moveToNextPhase()
            return
        }
        
        // 使用类来存储 elapsedTime，以便在闭包中修改
        class TimeTracker {
            var elapsedTime: TimeInterval = 0.0
        }
        let timeTracker = TimeTracker()
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            guard self.isRunning else {
                timer.invalidate()
                return
            }
            
            timeTracker.elapsedTime += 0.1
            
            // 更新进度
            withAnimation(.linear(duration: 0.1)) {
                self.phaseProgress = min(timeTracker.elapsedTime / duration, 1.0)
            }
            
            // 当阶段时间到达时，切换到下一阶段
            if timeTracker.elapsedTime >= duration {
                timer.invalidate()
                self.moveToNextPhase()
            }
        }
    }
    
    private func updateAnimationForPhase(_ phase: BreathingPhase) {
        let duration = getCurrentPhaseDuration()
        
        switch phase {
        case .inhale:
            // 吸气：放大并增加不透明度
            withAnimation(.easeInOut(duration: duration)) {
                scale = 1.5
                opacity = 0.8
            }
        case .hold:
            // 屏息：保持当前状态
            // scale 和 opacity 保持不变
            break
        case .exhale:
            // 呼气：缩小并降低不透明度
            withAnimation(.easeInOut(duration: duration)) {
                scale = 1.0
                opacity = 0.3
            }
        case .rest:
            // 休息：保持最小状态
            withAnimation(.easeInOut(duration: duration)) {
                scale = 1.0
                opacity = 0.3
            }
        }
    }

    // MARK: - 辅助方法
    private func getCurrentPhaseDuration() -> TimeInterval {
        switch currentPhase {
        case .inhale:
            return selectedPattern.inhaleTime
        case .hold:
            return selectedPattern.holdTime
        case .exhale:
            return selectedPattern.exhaleTime
        case .rest:
            return selectedPattern.restTime
        }
    }

    private func getPhaseColor() -> Color {
        switch currentPhase {
        case .inhale:
            return .blue
        case .hold:
            return .blue.opacity(0.8)
        case .exhale:
            return .green
        case .rest:
            return .green.opacity(0.6)
        }
    }

    private func getPhaseText() -> String {
        switch currentPhase {
        case .inhale:
            return "吸气"
        case .hold:
            return "屏息"
        case .exhale:
            return "呼气"
        case .rest:
            return "暂停呼吸"
        }
    }

    private func getPhaseDescription() -> String {
        switch currentPhase {
        case .inhale:
            return "通过鼻子缓慢吸气"
        case .hold:
            return "保持呼吸"
        case .exhale:
            return "通过嘴巴慢慢呼气"
        case .rest:
            return "呼气后暂停呼吸，自然停顿"
        }
    }

    private func playPhaseSound() {
        // 这里可以播放对应的音效
        // 目前使用简单的触觉反馈
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
}

// MARK: - 呼吸阶段枚举
enum BreathingPhase: String {
    case inhale
    case hold
    case exhale
    case rest
}

// MARK: - 音频管理器（简化版）
class AudioManager: ObservableObject {
    private var audioPlayer: AVAudioPlayer?

    func playSound(_ fileName: String) {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "mp3") else {
            print("无法找到音频文件: \(fileName)")
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
        } catch {
            print("播放音频失败: \(error)")
        }
    }
}

// MARK: - 预览
#Preview {
    VStack(spacing: 30) {
        Text("呼吸动画演示")
            .font(.system(size: 24, weight: .bold))
            .foregroundColor(.blue)

        BreathingAnimationView()
            .frame(width: 300, height: 400)
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(20)
    }
    .padding()
}