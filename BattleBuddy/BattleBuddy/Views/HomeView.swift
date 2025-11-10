//
//  HomeView.swift
//  BattleBuddy
//
//  Main dashboard with daily brief and quick actions
//

import SwiftUI
import CoreData

struct HomeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var appState: AppState

    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \TaskEntity.isCompleted, ascending: true),
            NSSortDescriptor(keyPath: \TaskEntity.createdAt, ascending: false)
        ],
        predicate: NSPredicate(format: "isCompleted == NO"),
        animation: .default)
    private var tasks: FetchedResults<TaskEntity>

    @State private var dailyBrief: DailyBrief?
    @State private var isLoadingBrief = false
    @StateObject private var voiceService = VoiceService()
    @StateObject private var briefService: DailyBriefService
    @StateObject private var proactiveService: ProactiveService
    @StateObject private var costService: CostTrackingService

    init() {
        let context = PersistenceController.shared.container.viewContext
        _briefService = StateObject(wrappedValue: DailyBriefService(context: context))
        _proactiveService = StateObject(wrappedValue: ProactiveService(context: context))
        _costService = StateObject(wrappedValue: CostTrackingService(context: context))
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("BattleBuddy")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.bbTextPrimary)

                            Text(greetingMessage())
                                .font(.system(size: 16))
                                .foregroundColor(.bbTextSecondary)
                        }

                        Spacer()

                        // Mode indicator
                        HStack(spacing: 8) {
                            Circle()
                                .fill(appState.currentMode.accentColor)
                                .frame(width: 8, height: 8)

                            Text(appState.currentMode.rawValue)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.bbTextSecondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.bbCardBackground)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)

                    // Daily Brief Card
                    DailyBriefCard(
                        brief: dailyBrief,
                        isLoading: isLoadingBrief,
                        onRefresh: { loadDailyBrief() },
                        onSpeak: { speakDailyBrief() }
                    )
                    .padding(.horizontal)

                    // Proactive Suggestion (Phase 6)
                    if let suggestion = proactiveService.getTopSuggestion() {
                        ProactiveSuggestionCard(suggestion: suggestion, service: proactiveService)
                            .padding(.horizontal)
                    }

                    // Cost Warning (Phase 6)
                    if costService.isApproachingBudget() || costService.isOverBudget() {
                        NavigationLink(destination: CostDashboardView(context: viewContext)) {
                            HStack {
                                Image(systemName: costService.isOverBudget() ? "exclamationmark.triangle.fill" : "chart.bar.fill")
                                    .foregroundColor(costService.isOverBudget() ? .red : .warningOrange)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(costService.isOverBudget() ? "Over Budget" : "Approaching Budget")
                                        .font(.headline)
                                        .foregroundColor(.bbTextPrimary)

                                    Text("$\(costService.monthlySpend, specifier: "%.2f") spent this month")
                                        .font(.caption)
                                        .foregroundColor(.bbTextSecondary)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .foregroundColor(.bbTextSecondary)
                            }
                            .padding()
                            .background(Color.bbCardBackground)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }

                    // Priority Tasks
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Priority Tasks")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.bbTextPrimary)

                            Spacer()

                            Text("\(tasks.count)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.bbTextSecondary)
                        }

                        if tasks.isEmpty {
                            Text("No tasks for today. You're all clear!")
                                .font(.system(size: 14))
                                .foregroundColor(.bbTextSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(Color.bbCardBackground)
                                .cornerRadius(12)
                        } else {
                            ForEach(tasks.prefix(3)) { task in
                                TaskRowCompact(task: task)
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Quick Actions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Quick Actions")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.bbTextPrimary)

                        HStack(spacing: 12) {
                            QuickActionButton(
                                title: "Add Task",
                                icon: "plus.circle.fill",
                                color: .bbAccent
                            ) {
                                // Quick add task action
                            }

                            QuickActionButton(
                                title: "Voice",
                                icon: "mic.fill",
                                color: appState.currentMode.accentColor
                            ) {
                                // Switch to voice tab
                            }
                        }
                    }
                    .padding(.horizontal)

                    Spacer()
                }
            }
            .background(Color.bbBackground.ignoresSafeArea())
            .onAppear {
                loadDailyBrief()
            }
        }
    }

    private func loadDailyBrief() {
        isLoadingBrief = true

        Task {
            let brief = await briefService.generateBrief()
            await MainActor.run {
                self.dailyBrief = brief
                self.isLoadingBrief = false
            }
        }
    }

    private func speakDailyBrief() {
        guard let brief = dailyBrief else { return }
        voiceService.speak(brief.formattedText)
    }

    private func greetingMessage() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        let greeting: String

        switch hour {
        case 0..<12:
            greeting = "Good morning"
        case 12..<17:
            greeting = "Good afternoon"
        default:
            greeting = "Good evening"
        }

        let preferences = UserPreferencesEntity.fetchOrCreate(context: viewContext)
        return "\(greeting), \(preferences.name)"
    }
}

// MARK: - Daily Brief Card
struct DailyBriefCard: View {
    let brief: DailyBrief?
    let isLoading: Bool
    let onRefresh: () -> Void
    let onSpeak: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: weatherIcon)
                    .foregroundColor(.bbWarning)
                    .font(.system(size: 24))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Today's Brief")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.bbTextPrimary)

                    Text(Date(), style: .date)
                        .font(.system(size: 14))
                        .foregroundColor(.bbTextSecondary)
                }

                Spacer()

                // Refresh button
                Button(action: onRefresh) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .bbAccent))
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 20))
                            .foregroundColor(.bbTextSecondary)
                    }
                }
                .disabled(isLoading)

                // Speak button
                Button(action: onSpeak) {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.bbAccent)
                }
                .disabled(brief == nil)
            }

            Divider()
                .background(Color.bbSecondary.opacity(0.3))

            if let brief = brief {
                // Weather
                if let weather = brief.weather {
                    HStack(spacing: 12) {
                        Image(systemName: weatherIconForCondition(weather.condition))
                            .font(.system(size: 20))
                            .foregroundColor(.bbAccent)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(weather.temperatureString)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.bbTextPrimary)

                            Text(weather.description)
                                .font(.system(size: 14))
                                .foregroundColor(.bbTextSecondary)
                        }

                        Spacer()

                        Text(weather.cityName)
                            .font(.system(size: 12))
                            .foregroundColor(.bbTextSecondary)
                    }
                } else {
                    HStack(spacing: 12) {
                        Image(systemName: "cloud.sun.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.bbSecondary)

                        Text("Weather unavailable")
                            .font(.system(size: 14))
                            .foregroundColor(.bbTextSecondary)
                    }
                }

                Divider()
                    .background(Color.bbSecondary.opacity(0.3))

                // Summary
                VStack(alignment: .leading, spacing: 8) {
                    Text(brief.scheduleSummary)
                        .font(.system(size: 14))
                        .foregroundColor(.bbTextSecondary)

                    Text(brief.taskSummary)
                        .font(.system(size: 14))
                        .foregroundColor(.bbTextSecondary)

                    Text(brief.motivationalMessage)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.bbAccent)
                }
            } else {
                // Loading state
                if isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .bbAccent))
                        Spacer()
                    }
                    .padding()
                } else {
                    Text("Tap refresh to load your daily brief")
                        .font(.system(size: 14))
                        .foregroundColor(.bbTextSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        .padding()
        .background(Color.bbCardBackground)
        .cornerRadius(16)
    }

    private var weatherIcon: String {
        if let weather = brief?.weather {
            return weatherIconForCondition(weather.condition)
        }
        return "sun.max.fill"
    }

    private func weatherIconForCondition(_ condition: String) -> String {
        switch condition.lowercased() {
        case "clear":
            return "sun.max.fill"
        case "clouds":
            return "cloud.fill"
        case "rain", "drizzle":
            return "cloud.rain.fill"
        case "thunderstorm":
            return "cloud.bolt.fill"
        case "snow":
            return "cloud.snow.fill"
        case "mist", "fog", "haze":
            return "cloud.fog.fill"
        default:
            return "cloud.sun.fill"
        }
    }
}

// MARK: - Compact Task Row
struct TaskRowCompact: View {
    @ObservedObject var task: TaskEntity
    @Environment(\.managedObjectContext) private var viewContext

    var body: some View {
        HStack(spacing: 12) {
            // Completion button
            Button(action: {
                withAnimation {
                    task.isCompleted.toggle()
                    PersistenceController.shared.save()
                }
            }) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(task.isCompleted ? .bbSuccess : .bbSecondary)
            }

            // Task info
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.bbTextPrimary)
                    .strikethrough(task.isCompleted)

                if let dueDate = task.dueDate {
                    Text("Due: \(dueDate, style: .date)")
                        .font(.system(size: 12))
                        .foregroundColor(.bbTextSecondary)
                }
            }

            Spacer()

            // Priority indicator
            Circle()
                .fill(priorityColor(task.priority))
                .frame(width: 8, height: 8)
        }
        .padding()
        .background(Color.bbCardBackground)
        .cornerRadius(12)
    }

    private func priorityColor(_ priority: String) -> Color {
        switch priority {
        case "High": return .red
        case "Medium": return .bbWarning
        case "Low": return .bbAccent
        default: return .bbSecondary
        }
    }
}

// MARK: - Quick Action Button
struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(title)
                    .font(.system(size: 15, weight: .medium))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(color)
            .cornerRadius(12)
        }
    }
}

// MARK: - Proactive Suggestion Card (Phase 6)
struct ProactiveSuggestionCard: View {
    let suggestion: ProactiveSuggestionEntity
    let service: ProactiveService

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: suggestionIcon)
                .font(.title2)
                .foregroundColor(.accentBlue)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 6) {
                Text("Suggestion")
                    .font(.caption.bold())
                    .foregroundColor(.textSecondary)

                Text(suggestion.suggestionText)
                    .font(.subheadline)
                    .foregroundColor(.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Button(action: {
                service.dismissSuggestion(suggestion)
            }) {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
        }
        .padding()
        .background(Color.accentBlue.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.accentBlue.opacity(0.3), lineWidth: 1)
        )
        .onAppear {
            service.markAsShown(suggestion)
        }
    }

    private var suggestionIcon: String {
        switch suggestion.suggestionType {
        case "morning_motivation": return "sunrise.fill"
        case "progress_celebration": return "star.circle.fill"
        case "gentle_nudge": return "hand.wave.fill"
        case "break_reminder": return "cup.and.saucer.fill"
        case "goal_check_in": return "target"
        case "deadline_warning": return "exclamationmark.triangle.fill"
        case "wellbeing_check": return "heart.fill"
        case "mood_celebration": return "star.fill"
        case "deadline_reminder": return "clock.fill"
        default: return "lightbulb.fill"
        }
    }
}

#Preview {
    HomeView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(AppState())
}
