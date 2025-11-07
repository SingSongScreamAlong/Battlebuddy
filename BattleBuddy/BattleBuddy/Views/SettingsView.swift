//
//  SettingsView.swift
//  BattleBuddy
//
//  User preferences and app settings
//

import SwiftUI
import CoreData

struct SettingsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var appState: AppState

    @State private var preferences: UserPreferencesEntity?
    @State private var name = ""
    @State private var openAIKey = ""
    @State private var morningBriefTime = Date()
    @State private var eveningReflectionTime = Date()

    var body: some View {
        NavigationView {
            Form {
                // Profile Section
                Section(header: Text("Profile")) {
                    HStack {
                        Text("Name")
                        Spacer()
                        TextField("Your name", text: $name)
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(.bbTextPrimary)
                    }
                }

                // AI Mode Section
                Section(header: Text("AI Mode")) {
                    Picker("Default Mode", selection: $appState.currentMode) {
                        ForEach(AppState.AIMode.allCases, id: \.self) { mode in
                            HStack {
                                Circle()
                                    .fill(mode.accentColor)
                                    .frame(width: 12, height: 12)
                                Text(mode.rawValue)
                            }
                            .tag(mode)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Current Mode: \(appState.currentMode.rawValue)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.bbTextPrimary)

                        Text(modeDescription(appState.currentMode))
                            .font(.system(size: 12))
                            .foregroundColor(.bbTextSecondary)
                    }
                    .padding(.vertical, 4)
                }

                // Notifications Section
                Section(header: Text("Notifications")) {
                    DatePicker("Morning Brief", selection: $morningBriefTime, displayedComponents: .hourAndMinute)

                    DatePicker("Evening Reflection", selection: $eveningReflectionTime, displayedComponents: .hourAndMinute)
                }

                // API Configuration
                Section(header: Text("API Configuration")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("OpenAI API Key")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.bbTextPrimary)

                        SecureField("sk-...", text: $openAIKey)
                            .textContentType(.password)
                            .autocapitalization(.none)
                            .foregroundColor(.bbTextPrimary)

                        Text("Required for AI conversations. Get your key at platform.openai.com")
                            .font(.system(size: 12))
                            .foregroundColor(.bbTextSecondary)
                    }
                    .padding(.vertical, 4)
                }

                // App Info Section
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0 (MVP)")
                            .foregroundColor(.bbTextSecondary)
                    }

                    HStack {
                        Text("Phase")
                        Spacer()
                        Text("Phase 1 - Foundation")
                            .foregroundColor(.bbTextSecondary)
                    }
                }

                // Data Management
                Section(header: Text("Data")) {
                    Button(action: {
                        // Clear all data
                    }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Clear All Data")
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.bbBackground)
            .navigationTitle("Settings")
            .onAppear {
                loadPreferences()
            }
            .onChange(of: name) { _ in savePreferences() }
            .onChange(of: openAIKey) { _ in savePreferences() }
            .onChange(of: morningBriefTime) { _ in savePreferences() }
            .onChange(of: eveningReflectionTime) { _ in savePreferences() }
            .onChange(of: appState.currentMode) { _ in savePreferences() }
        }
    }

    private func loadPreferences() {
        let prefs = UserPreferencesEntity.fetchOrCreate(context: viewContext)
        preferences = prefs
        name = prefs.name
        openAIKey = prefs.openAIKey ?? ""
        morningBriefTime = prefs.morningBriefTime
        eveningReflectionTime = prefs.eveningReflectionTime

        // Set app state mode from preferences
        if let mode = AppState.AIMode(rawValue: prefs.defaultMode.capitalized) {
            appState.currentMode = mode
        }
    }

    private func savePreferences() {
        guard let prefs = preferences else { return }

        prefs.name = name
        prefs.openAIKey = openAIKey.isEmpty ? nil : openAIKey
        prefs.morningBriefTime = morningBriefTime
        prefs.eveningReflectionTime = eveningReflectionTime
        prefs.defaultMode = appState.currentMode.rawValue.lowercased()

        PersistenceController.shared.save()
    }

    private func modeDescription(_ mode: AppState.AIMode) -> String {
        switch mode {
        case .operator:
            return "Concise and tactical. Direct answers with military-style efficiency."
        case .companion:
            return "Warm and supportive. Your friendly AI companion for daily tasks."
        case .strategist:
            return "Analytical and planning-focused. Strategic thinking for complex decisions."
        }
    }
}

#Preview {
    SettingsView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(AppState())
}
