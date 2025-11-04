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
                .animation(
                    Animation.easeInOut(duration: getCurrentPhaseDuration())
                    .repeatForever(autoreverses: false),
                    value: scale
                )
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
        Picker("呼吸模式", selection: $selectedPattern) {
            ForEach(BreathingPattern.allCases, id: \.self) { pattern in
                Text(pattern.rawValue)
                    .font(.system(size: AppTheme.FontSize.body))
                    .tag(pattern)
            }
        }
        .pickerStyle(MenuPickerStyle())
        .foregroundColor(AppTheme.Colors.text)
        .onChange(of: selectedPattern) { _ in
            if isRunning {
                stopBreathing()
                startBreathing()
            }
        }
    }
    
    private var patternDescriptionSection: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Text("推荐：\(selectedPattern.rawValue)")
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
        currentPhase = phase

        // 播放阶段对应的音效
        playPhaseSound()

        // 重置进度
        withAnimation(.linear(duration: 0.2)) {
            phaseProgress = 0.0
        }

        // 启动下一阶段的定时器
        timer = Timer.scheduledTimer(withTimeInterval: getCurrentPhaseDuration(), repeats: false) { _ in
            moveToNextPhase()
        }

        // 启动进度动画
        startProgressAnimation()
    }

    private func moveToNextPhase() {
        switch currentPhase {
        case .inhale:
            moveToPhase(.hold)
        case .hold:
            moveToPhase(.exhale)
        case .exhale:
            moveToPhase(selectedPattern.restTime > 0 ? .rest : .inhale)
        case .rest:
            moveToPhase(.inhale)
        }
    }

    private func startProgressAnimation() {
        timer?.invalidate()
        timer = nil

        let duration = getCurrentPhaseDuration()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            withAnimation(.linear(duration: 0.1)) {
                phaseProgress = min(phaseProgress + 0.1 / duration, 1.0)
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
            return "休息"
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
            return "放松休息"
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