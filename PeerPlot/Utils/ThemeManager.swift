//
//  ThemeManager.swift
//  PeerPlot
//
//  Created for PeerPlot
//

import SwiftUI

/// Central theme manager for consistent styling across the app
enum AppTheme {
    // MARK: - Color Palette
    struct Colors {
        static let primary = Color(red: 0.2, green: 0.5, blue: 0.5) // Muted teal
        static let subtleBackground = Color(red: 0.96, green: 0.96, blue: 0.94) // Warm off-white
        static let textPrimary = Color(red: 0.2, green: 0.2, blue: 0.25) // Deep slate
        static let textSecondary = Color(red: 0.4, green: 0.4, blue: 0.45) // Medium slate
        static let accentLight = Color(red: 0.85, green: 0.9, blue: 0.9) // Light teal
        static let divider = primary.opacity(0.2)
    }
    
    // MARK: - Typography
    struct Typography {
        // Headers
        static let title = Font.system(.title2, design: .serif)
        static let headline = Font.system(.headline, design: .serif)
        static let subheadline = Font.system(.subheadline, design: .serif)
        
        // Content
        static let body = Font.system(.body, design: .serif)
        static let caption = Font.system(.caption, design: .serif)
        static let caption2 = Font.system(.caption2, design: .serif)
    }
    
    // MARK: - Layout
    struct Layout {
        static let standardPadding: CGFloat = 16
        static let tightPadding: CGFloat = 8
        static let loosePadding: CGFloat = 24
        static let cornerRadius: CGFloat = 12
        static let smallCornerRadius: CGFloat = 8
    }
    
    // MARK: - Modifiers
    struct Modifiers {
        // Button style for primary actions
        struct PrimaryButtonStyle: ButtonStyle {
            func makeBody(configuration: Configuration) -> some View {
                configuration.label
                    .font(Typography.body)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Colors.primary.opacity(configuration.isPressed ? 0.8 : 1))
                    .foregroundColor(.white)
                    .cornerRadius(Layout.smallCornerRadius)
            }
        }
        
        // Button style for secondary actions
        struct SecondaryButtonStyle: ButtonStyle {
            func makeBody(configuration: Configuration) -> some View {
                configuration.label
                    .font(Typography.body)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Colors.textSecondary.opacity(configuration.isPressed ? 0.15 : 0.1))
                    .foregroundColor(Colors.textPrimary)
                    .cornerRadius(Layout.smallCornerRadius)
            }
        }
        
        // Text field modifier
        struct TextFieldModifier: ViewModifier {
            func body(content: Content) -> some View {
                content
                    .font(Typography.body)
                    .padding()
                    .background(Colors.subtleBackground)
                    .cornerRadius(Layout.smallCornerRadius)
            }
        }
        
        // Card modifier
        struct CardModifier: ViewModifier {
            func body(content: Content) -> some View {
                content
                    .padding()
                    .background(Colors.subtleBackground)
                    .cornerRadius(Layout.cornerRadius)
            }
        }
    }
}

// MARK: - View Extensions
extension View {
    func styledTextField() -> some View {
        self.modifier(AppTheme.Modifiers.TextFieldModifier())
    }
    
    func styledCard() -> some View {
        self.modifier(AppTheme.Modifiers.CardModifier())
    }
}

// MARK: - Button Style Extensions
extension ButtonStyle where Self == AppTheme.Modifiers.PrimaryButtonStyle {
    static var primary: AppTheme.Modifiers.PrimaryButtonStyle { AppTheme.Modifiers.PrimaryButtonStyle() }
}

extension ButtonStyle where Self == AppTheme.Modifiers.SecondaryButtonStyle {
    static var secondary: AppTheme.Modifiers.SecondaryButtonStyle { AppTheme.Modifiers.SecondaryButtonStyle() }
}

extension AppTheme.Modifiers {
    // Custom back button modifier
    struct CustomBackButtonModifier: ViewModifier {
        let action: () -> Void
        
        func body(content: Content) -> some View {
            content
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: action) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                            }
                            .foregroundColor(AppTheme.Colors.primary)
                        }
                    }
                }
                .navigationBarBackButtonHidden()
        }
    }
}

// Extension for easier use
extension View {
    func withCustomBackButton(action: @escaping () -> Void) -> some View {
        self.modifier(AppTheme.Modifiers.CustomBackButtonModifier(action: action))
    }
}
