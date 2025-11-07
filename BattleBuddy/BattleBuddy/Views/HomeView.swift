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
                    DailyBriefCard()
                        .padding(.horizontal)

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
        }
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
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "sun.max.fill")
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

                Button(action: {
                    // Play daily brief
                }) {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.bbAccent)
                }
            }

            Divider()
                .background(Color.bbSecondary.opacity(0.3))

            // Weather placeholder
            HStack(spacing: 12) {
                Image(systemName: "cloud.sun.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.bbAccent)

                Text("Weather data coming soon")
                    .font(.system(size: 14))
                    .foregroundColor(.bbTextSecondary)
            }

            // Summary
            Text("You have 0 events scheduled today. Ready to tackle your tasks!")
                .font(.system(size: 14))
                .foregroundColor(.bbTextSecondary)
                .lineLimit(3)
        }
        .padding()
        .background(Color.bbCardBackground)
        .cornerRadius(16)
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

#Preview {
    HomeView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(AppState())
}
