//
//  SettingsView.swift
//  BattleBuddy
//
//  User preferences and app settings
//

import SwiftUI
import CoreData
import UserNotifications

struct SettingsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var appState: AppState

    @State private var preferences: UserPreferencesEntity?
    @State private var name = ""
    @State private var openAIKey = ""
    @State private var weatherAPIKey = ""
    @State private var morningBriefTime = Date()
    @State private var eveningReflectionTime = Date()
    @State private var notificationsEnabled = false

    @StateObject private var notificationService = NotificationService()

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
                    // Permission status
                    HStack {
                        Text("Status")
                        Spacer()
                        Text(notificationStatusText)
                            .foregroundColor(notificationStatusColor)
                    }

                    if notificationService.authorizationStatus != .authorized {
                        Button(action: {
                            requestNotificationPermission()
                        }) {
                            HStack {
                                Image(systemName: "bell.badge")
                                Text("Enable Notifications")
                            }
                            .foregroundColor(.bbAccent)
                        }
                    }

                    if notificationService.authorizationStatus == .authorized {
                        Toggle("Daily Notifications", isOn: $notificationsEnabled)
                            .onChange(of: notificationsEnabled) { enabled in
                                updateNotificationSchedule()
                            }

                        if notificationsEnabled {
                            DatePicker("Morning Brief", selection: $morningBriefTime, displayedComponents: .hourAndMinute)
                                .onChange(of: morningBriefTime) { _ in
                                    updateNotificationSchedule()
                                }

                            DatePicker("Evening Reflection", selection: $eveningReflectionTime, displayedComponents: .hourAndMinute)
                                .onChange(of: eveningReflectionTime) { _ in
                                    updateNotificationSchedule()
                                }
                        }
                    }
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

                    VStack(alignment: .leading, spacing: 8) {
                        Text("OpenWeather API Key")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.bbTextPrimary)

                        SecureField("Enter API key", text: $weatherAPIKey)
                            .textContentType(.password)
                            .autocapitalization(.none)
                            .foregroundColor(.bbTextPrimary)

                        Text("Required for weather in daily brief. Get your free key at openweathermap.org")
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
                        Text("4.0.0 (MVP)")
                            .foregroundColor(.bbTextSecondary)
                    }

                    HStack {
                        Text("Phase")
                        Spacer()
                        Text("Phase 4 - Intelligence")
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
            .onChange(of: weatherAPIKey) { _ in saveWeatherAPIKey() }
            .onChange(of: appState.currentMode) { _ in savePreferences() }
        }
    }

    // MARK: - Notification Helpers
    private var notificationStatusText: String {
        switch notificationService.authorizationStatus {
        case .authorized:
            return "Enabled"
        case .denied:
            return "Denied"
        case .notDetermined:
            return "Not Set"
        case .provisional:
            return "Provisional"
        case .ephemeral:
            return "Ephemeral"
        @unknown default:
            return "Unknown"
        }
    }

    private var notificationStatusColor: Color {
        switch notificationService.authorizationStatus {
        case .authorized:
            return .bbSuccess
        case .denied:
            return .red
        case .notDetermined:
            return .bbTextSecondary
        default:
            return .bbTextSecondary
        }
    }

    private func requestNotificationPermission() {
        Task {
            let granted = await notificationService.requestAuthorization()
            if granted {
                await MainActor.run {
                    notificationsEnabled = true
                    updateNotificationSchedule()
                }
            }
        }
    }

    private func updateNotificationSchedule() {
        guard notificationsEnabled else {
            notificationService.cancelMorningBrief()
            notificationService.cancelEveningReflection()
            return
        }

        Task {
            // Schedule morning brief
            let morningSuccess = await notificationService.scheduleMorningBrief(time: morningBriefTime)
            if morningSuccess {
                print("Morning brief scheduled for \(morningBriefTime)")
            }

            // Schedule evening reflection
            let eveningSuccess = await notificationService.scheduleEveningReflection(time: eveningReflectionTime)
            if eveningSuccess {
                print("Evening reflection scheduled for \(eveningReflectionTime)")
            }

            // Save preferences
            await MainActor.run {
                savePreferences()
            }
        }
    }

    private func loadPreferences() {
        let prefs = UserPreferencesEntity.fetchOrCreate(context: viewContext)
        preferences = prefs
        name = prefs.name

        // Load API keys from Keychain (secure storage)
        openAIKey = KeychainHelper.shared.openAIKey ?? ""
        weatherAPIKey = KeychainHelper.shared.retrieve(forKey: "openweather_api_key") ?? ""

        morningBriefTime = prefs.morningBriefTime
        eveningReflectionTime = prefs.eveningReflectionTime

        // Set app state mode from preferences
        if let mode = AppState.AIMode(rawValue: prefs.defaultMode.capitalized) {
            appState.currentMode = mode
        }

        // Check notification status
        notificationService.checkAuthorizationStatus()

        // Load notification preferences
        Task {
            let pendingNotifications = await notificationService.getPendingNotifications()
            await MainActor.run {
                notificationsEnabled = !pendingNotifications.isEmpty
            }
        }
    }

    private func savePreferences() {
        guard let prefs = preferences else { return }

        prefs.name = name

        // Save OpenAI API key to Keychain (secure storage)
        KeychainHelper.shared.openAIKey = openAIKey.isEmpty ? nil : openAIKey

        prefs.morningBriefTime = morningBriefTime
        prefs.eveningReflectionTime = eveningReflectionTime
        prefs.defaultMode = appState.currentMode.rawValue.lowercased()

        PersistenceController.shared.save()
    }

    private func saveWeatherAPIKey() {
        if weatherAPIKey.isEmpty {
            _ = KeychainHelper.shared.delete(forKey: "openweather_api_key")
        } else {
            _ = KeychainHelper.shared.save(weatherAPIKey, forKey: "openweather_api_key")
        }
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
