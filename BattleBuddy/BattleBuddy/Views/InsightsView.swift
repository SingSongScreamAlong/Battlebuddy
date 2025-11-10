//
//  InsightsView.swift
//  BattleBuddy
//
//  Phase 6: Mood trends, patterns, and wellbeing analysis
//

import SwiftUI
import CoreData

struct InsightsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ReflectionLogEntity.date, ascending: false)],
        animation: .default)
    private var reflections: FetchedResults<ReflectionLogEntity>

    @FetchRequest(sortDescriptors: []) private var userProfile: FetchedResults<UserProfileEntity>
    @StateObject private var memoryService: MemoryService

    init(context: NSManagedObjectContext) {
        _memoryService = StateObject(wrappedValue: MemoryService(context: context))
    }

    var body: some View {
        ZStack {
            Color.battleBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // User stats
                    userStatsCard

                    // Mood trend
                    moodTrendCard

                    // Patterns & insights
                    patternsCard

                    // Memory insights
                    memoryCard
                }
                .padding(.vertical)
            }
        }
        .navigationTitle("Insights")
    }

    private var userStatsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Stats")
                .font(.title2.bold())
                .foregroundColor(.textPrimary)

            if let profile = userProfile.first {
                HStack(spacing: 15) {
                    StatPill(icon: "checkmark.circle.fill", value: "\(profile.totalTasksCompleted)", label: "Tasks", color: .successGreen)
                    StatPill(icon: "flame.fill", value: "\(profile.currentStreak)", label: "Streak", color: .warningOrange)
                    StatPill(icon: "bubble.left.and.bubble.right.fill", value: "\(profile.totalConversations)", label: "Chats", color: .accentBlue)
                }
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(16)
        .padding(.horizontal)
    }

    private var moodTrendCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Mood Trend (Last 7 Days)")
                .font(.title3.bold())
                .foregroundColor(.textPrimary)

            if !recentReflections.isEmpty {
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(recentReflections, id: \.id) { reflection in
                        VStack(spacing: 4) {
                            Text(reflection.mood)
                                .font(.largeTitle)

                            Text(reflection.date, style: .date)
                                .font(.caption2)
                                .foregroundColor(.textSecondary)
                                .rotationEffect(.degrees(-45))
                        }
                    }
                }

                // Mood summary
                let moodSummary = analyzeMoodTrend()
                if !moodSummary.isEmpty {
                    Text(moodSummary)
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                        .padding(.top, 8)
                }
            } else {
                Text("Start logging daily reflections to see your mood trends")
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(16)
        .padding(.horizontal)
    }

    private var patternsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Patterns & Habits")
                .font(.title3.bold())
                .foregroundColor(.textPrimary)

            let patterns = memoryService.recallByCategory(.pattern)

            if !patterns.isEmpty {
                ForEach(Array(patterns.keys.sorted()), id: \.self) { key in
                    if let value = patterns[key] {
                        HStack {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .foregroundColor(.accentBlue)

                            Text(key.replacingOccurrences(of: "pattern_", with: "").capitalized)
                                .font(.subheadline)
                                .foregroundColor(.textPrimary)

                            Spacer()

                            Text(value)
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.accentBlue.opacity(0.2))
                                .cornerRadius(6)
                        }
                        .padding(.vertical, 4)
                    }
                }
            } else {
                Text("I'm learning your patterns. Keep using the app to see insights here!")
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(16)
        .padding(.horizontal)
    }

    private var memoryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What I Know About You")
                .font(.title3.bold())
                .foregroundColor(.textPrimary)

            let preferences = memoryService.recallByCategory(.preference)

            if !preferences.isEmpty {
                ForEach(Array(preferences.keys.sorted().prefix(5)), id: \.self) { key in
                    if let value = preferences[key] {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: value == "true" ? "heart.fill" : "heart.slash.fill")
                                .foregroundColor(value == "true" ? .pink : .secondaryGray)
                                .frame(width: 20)

                            Text(key.replacingOccurrences(of: "_", with: " ").capitalized)
                                .font(.subheadline)
                                .foregroundColor(.textPrimary)

                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }

                Text("Total: \(memoryService.getTotalMemoryCount()) memories")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                    .padding(.top, 8)
            } else {
                Text("Talk to me more! I'll learn your preferences as we interact.")
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(16)
        .padding(.horizontal)
    }

    private var recentReflections: [ReflectionLogEntity] {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return reflections.filter { $0.date >= sevenDaysAgo }
    }

    private func analyzeMoodTrend() -> String {
        let moods = recentReflections.map { $0.mood }
        let positive = moods.filter { $0 == "😊" || $0 == "🎉" }.count
        let negative = moods.filter { $0 == "😔" || $0 == "😟" }.count
        let neutral = moods.filter { $0 == "😐" }.count

        if positive > negative && positive >= 3 {
            return "📈 You've been feeling positive lately! Keep it up."
        } else if negative > positive && negative >= 3 {
            return "📉 You've been struggling lately. Want to talk about it?"
        } else if neutral >= 3 {
            return "➡️ Your mood has been steady. Consistency is good!"
        } else {
            return "📊 Your mood is varied - that's normal!"
        }
    }
}

struct StatPill: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.title3.bold())
                .foregroundColor(.textPrimary)

            Text(label)
                .font(.caption)
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.15))
        .cornerRadius(12)
    }
}

#Preview {
    InsightsView(context: PersistenceController.preview.container.viewContext)
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
