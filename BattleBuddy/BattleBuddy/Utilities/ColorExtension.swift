//
//  ColorExtension.swift
//  BattleBuddy
//
//  Color utilities and theme colors
//

import SwiftUI

extension Color {
    // Initialize from hex string
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    // BattleBuddy theme colors
    static let bbBackground = Color(hex: "#1a1a1a")
    static let bbCardBackground = Color(hex: "#2d2d2d")
    static let bbAccent = Color(hex: "#3b82f6")
    static let bbSecondary = Color(hex: "#6b7280")
    static let bbTextPrimary = Color.white
    static let bbTextSecondary = Color(hex: "#9ca3af")
    static let bbSuccess = Color(hex: "#10b981")
    static let bbWarning = Color(hex: "#f59e0b")

    // Phase 6: Additional color aliases for consistency
    static let battleBackground = bbBackground
    static let cardBackground = bbCardBackground
    static let accentBlue = bbAccent
    static let secondaryGray = bbSecondary
    static let textPrimary = bbTextPrimary
    static let textSecondary = bbTextSecondary
    static let successGreen = bbSuccess
    static let warningOrange = bbWarning
}
