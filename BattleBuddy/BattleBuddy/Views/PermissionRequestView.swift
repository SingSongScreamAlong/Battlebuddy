//
//  PermissionRequestView.swift
//  BattleBuddy
//
//  Microphone permission request flow
//

import SwiftUI

struct PermissionRequestView: View {
    @Binding var isPresented: Bool
    let onGranted: () -> Void

    @StateObject private var voiceService = VoiceService()
    @State private var isRequesting = false

    var body: some View {
        ZStack {
            Color.bbBackground.ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Icon
                ZStack {
                    Circle()
                        .fill(Color.bbAccent.opacity(0.2))
                        .frame(width: 120, height: 120)

                    Image(systemName: "mic.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.bbAccent)
                }

                VStack(spacing: 16) {
                    Text("Voice Access Required")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.bbTextPrimary)

                    Text("BattleBuddy needs microphone access to listen to your voice commands and have conversations with you.")
                        .font(.system(size: 16))
                        .foregroundColor(.bbTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                VStack(spacing: 16) {
                    PermissionFeature(
                        icon: "waveform",
                        title: "Voice Commands",
                        description: "Create tasks, schedule events, and more with your voice"
                    )

                    PermissionFeature(
                        icon: "message.fill",
                        title: "AI Conversations",
                        description: "Chat naturally with your AI companion"
                    )

                    PermissionFeature(
                        icon: "lock.shield.fill",
                        title: "Privacy First",
                        description: "Audio is processed on-device when possible"
                    )
                }
                .padding(.horizontal, 32)

                Spacer()

                VStack(spacing: 12) {
                    Button(action: {
                        requestPermission()
                    }) {
                        HStack {
                            if isRequesting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Enable Microphone")
                                    .font(.system(size: 17, weight: .semibold))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.bbAccent)
                        .cornerRadius(16)
                    }
                    .disabled(isRequesting)

                    Button(action: {
                        isPresented = false
                    }) {
                        Text("Maybe Later")
                            .font(.system(size: 15))
                            .foregroundColor(.bbTextSecondary)
                    }
                    .padding(.bottom, 8)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
            }
        }
    }

    private func requestPermission() {
        isRequesting = true

        Task {
            let granted = await voiceService.requestPermissions()

            await MainActor.run {
                isRequesting = false

                if granted {
                    isPresented = false
                    onGranted()
                } else {
                    // Show alert to open settings
                    // In a real app, you'd show an alert here
                    isPresented = false
                }
            }
        }
    }
}

// MARK: - Permission Feature Row
struct PermissionFeature: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.bbAccent)
                .frame(width: 40, height: 40)
                .background(Color.bbAccent.opacity(0.2))
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.bbTextPrimary)

                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(.bbTextSecondary)
            }

            Spacer()
        }
    }
}

#Preview {
    PermissionRequestView(isPresented: .constant(true), onGranted: {})
}
