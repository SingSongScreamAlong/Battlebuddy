//
//  VoiceInterfaceView.swift
//  BattleBuddy
//
//  Voice interface with mic button and conversation history (placeholder for Phase 2)
//

import SwiftUI

struct VoiceInterfaceView: View {
    @EnvironmentObject var appState: AppState
    @State private var isListening = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.bbBackground.ignoresSafeArea()

                VStack(spacing: 24) {
                    // Mode selector
                    Picker("Mode", selection: $appState.currentMode) {
                        ForEach(AppState.AIMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.top)

                    // Conversation history placeholder
                    ScrollView {
                        VStack(spacing: 16) {
                            if appState.conversationHistory.isEmpty {
                                VStack(spacing: 16) {
                                    Image(systemName: "waveform")
                                        .font(.system(size: 64))
                                        .foregroundColor(.bbSecondary)

                                    Text("Ready to chat")
                                        .font(.system(size: 24, weight: .semibold))
                                        .foregroundColor(.bbTextPrimary)

                                    Text("Hold the mic button to speak")
                                        .font(.system(size: 16))
                                        .foregroundColor(.bbTextSecondary)
                                }
                                .padding(.top, 60)
                            } else {
                                ForEach(appState.conversationHistory) { entry in
                                    ConversationBubble(entry: entry)
                                }
                            }
                        }
                        .padding()
                    }

                    Spacer()

                    // Mic button
                    VStack(spacing: 12) {
                        Button(action: {
                            // Tap-and-hold mic action (Phase 2)
                        }) {
                            ZStack {
                                Circle()
                                    .fill(appState.currentMode.accentColor)
                                    .frame(width: 80, height: 80)
                                    .shadow(color: appState.currentMode.accentColor.opacity(0.4), radius: 12, x: 0, y: 4)

                                Image(systemName: isListening ? "stop.fill" : "mic.fill")
                                    .font(.system(size: 32, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }

                        Text("Voice interface coming in Phase 2")
                            .font(.system(size: 14))
                            .foregroundColor(.bbTextSecondary)
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("BattleBuddy")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Conversation Bubble
struct ConversationBubble: View {
    let entry: ConversationEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // User message
            HStack {
                Spacer()
                Text(entry.userMessage)
                    .font(.system(size: 15))
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Color.bbAccent)
                    .cornerRadius(16)
                    .frame(maxWidth: 280, alignment: .trailing)
            }

            // AI response
            HStack {
                Text(entry.aiResponse)
                    .font(.system(size: 15))
                    .foregroundColor(.bbTextPrimary)
                    .padding(12)
                    .background(Color.bbCardBackground)
                    .cornerRadius(16)
                    .frame(maxWidth: 280, alignment: .leading)
                Spacer()
            }
        }
    }
}

#Preview {
    VoiceInterfaceView()
        .environmentObject(AppState())
}
