//
//  AppTheme.swift
//  Personal Space
//
//  Created by Penn on 2025/1/27.
//

import SwiftUI

struct AppTheme {
    // MARK: - 颜色方案
    struct Colors {
        static let primary = Color(red: 0.165, green: 0.616, blue: 0.561) // #2A9D8F
        static let primaryLight = Color(red: 0.541, green: 0.714, blue: 0.686) // #8ab6af
        static let text = Color(red: 0.169, green: 0.176, blue: 0.259) // #2b2d42
        static let textSecondary = Color(red: 0.424, green: 0.459, blue: 0.490) // #6c757d
        static let bgMain = Color(red: 0.973, green: 0.980, blue: 0.980) // #f8f9fa
        static let cardBg = Color.white
        static let border = Color(red: 0.914, green: 0.925, blue: 0.937) // #e9ecef
        static let success = Color(red: 0.263, green: 0.667, blue: 0.545) // #43aa8b
        static let warning = Color(red: 0.973, green: 0.588, blue: 0.118) // #f8961e
        static let danger = Color(red: 0.902, green: 0.224, blue: 0.275) // #e63946
    }
    
    // MARK: - 阴影效果
    struct Shadows {
        static let card = Color.black.opacity(0.05)
        static let cardHover = Color.black.opacity(0.08)
        static let floating = Color(red: 0.165, green: 0.616, blue: 0.561).opacity(0.4)
    }
    
    // MARK: - 圆角半径
    struct Radius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let extraLarge: CGFloat = 20
        static let card: CGFloat = 20
    }
    
    // MARK: - 间距
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let xxxl: CGFloat = 32
    }
    
    // MARK: - 字体大小
    struct FontSize {
        static let caption2: CGFloat = 10
        static let caption: CGFloat = 12
        static let body: CGFloat = 14
        static let subheadline: CGFloat = 15
        static let headline: CGFloat = 17
        static let title3: CGFloat = 20
        static let title2: CGFloat = 22
        static let title: CGFloat = 28
        static let largeTitle: CGFloat = 34
    }
}

// MARK: - 渐变背景
struct AppGradient {
    static let background = LinearGradient(
        colors: [
            Color(red: 0.973, green: 0.980, blue: 0.980),
            Color(red: 0.973, green: 0.980, blue: 0.980)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let cardBackground = LinearGradient(
        colors: [
            Color(red: 0.914, green: 0.961, blue: 0.957).opacity(0.8),
            Color(red: 0.980, green: 0.984, blue: 0.988).opacity(0.9)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let primaryGradient = LinearGradient(
        colors: [
            AppTheme.Colors.primary,
            AppTheme.Colors.primaryLight
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - 卡片样式修饰符
struct CardStyle: ViewModifier {
    let isHoverable: Bool
    
    init(isHoverable: Bool = true) {
        self.isHoverable = isHoverable
    }
    
    func body(content: Content) -> some View {
        content
            .background(AppTheme.Colors.cardBg)
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
    }
}

// MARK: - 按钮样式修饰符
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .padding(.horizontal, AppTheme.Spacing.xl)
            .padding(.vertical, AppTheme.Spacing.md)
            .background(AppGradient.primaryGradient)
            .cornerRadius(AppTheme.Radius.medium)
            .shadow(
                color: AppTheme.Shadows.floating,
                radius: 4,
                x: 0,
                y: 2
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - 扩展View以使用主题
extension View {
    func cardStyle(isHoverable: Bool = true) -> some View {
        self.modifier(CardStyle(isHoverable: isHoverable))
    }
    
    func primaryButtonStyle() -> some View {
        self.buttonStyle(PrimaryButtonStyle())
    }
}
