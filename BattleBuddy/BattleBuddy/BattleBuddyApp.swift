//
//  BattleBuddyApp.swift
//  BattleBuddy
//
//  Created by Claude Code on 2025-11-07.
//

import SwiftUI

@main
struct BattleBuddyApp: App {
    // Core Data persistence controller
    @StateObject private var persistenceController = PersistenceController.shared

    // App-wide state
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(appState)
                .preferredColorScheme(.dark) // Force dark mode for tactical aesthetic
        }
    }
}

// MARK: - App State
class AppState: ObservableObject {
    @Published var currentMode: AIMode = .companion
    @Published var isListening: Bool = false
    @Published var conversationHistory: [ConversationEntry] = []

    enum AIMode: String, CaseIterable {
        case operator = "Operator"
        case companion = "Companion"
        case strategist = "Strategist"

        var systemPrompt: String {
            switch self {
            case .operator:
                return "You are BattleBuddy in Operator Mode. Be concise, tactical, and efficient. Give direct answers with minimal fluff. Use military-style brevity."
            case .companion:
                return "You are BattleBuddy in Companion Mode. Be warm, supportive, and conversational. Show empathy and encouragement while helping with tasks."
            case .strategist:
                return "You are BattleBuddy in Strategist Mode. Be analytical and planning-focused. Think ahead, consider options, and provide strategic advice."
            }
        }

        var accentColor: Color {
            switch self {
            case .operator:
                return Color(hex: "#f59e0b") // Amber
            case .companion:
                return Color(hex: "#3b82f6") // Blue
            case .strategist:
                return Color(hex: "#8b5cf6") // Purple
            }
        }
    }
}

// MARK: - Conversation Entry
struct ConversationEntry: Identifiable {
    let id = UUID()
    let userMessage: String
    let aiResponse: String
    let timestamp: Date
    let mode: AppState.AIMode
}
