//
//  GoalDashboardView.swift
//  BattleBuddy
//
//  Phase 6: Goal tracking with progress visualization and achievements
//

import SwiftUI
import CoreData

struct GoalDashboardView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var goalService: GoalService
    @State private var showingAddGoal = false
    @State private var showingAchievements = false

    init(context: NSManagedObjectContext) {
        _goalService = StateObject(wrappedValue: GoalService(context: context))
    }

    var body: some View {
        ZStack {
            Color.battleBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // Header with stats
                    goalStatsCard

                    // Active goals
                    if !goalService.activeGoals.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Active Goals")
                                .font(.title2.bold())
                                .foregroundColor(.textPrimary)
                                .padding(.horizontal)

                            ForEach(goalService.activeGoals, id: \.id) { goal in
                                GoalCard(goal: goal, goalService: goalService)
                            }
                        }
                    }

                    // Completed goals
                    if !goalService.completedGoals.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Completed")
                                .font(.title3.bold())
                                .foregroundColor(.textSecondary)
                                .padding(.horizontal)

                            ForEach(goalService.completedGoals.prefix(3), id: \.id) { goal in
                                CompletedGoalCard(goal: goal)
                            }
                        }
                    }

                    // Achievements teaser
                    achievementsCard
                }
                .padding(.vertical)
            }

            // Floating add button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: { showingAddGoal = true }) {
                        Image(systemName: "plus")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(Color.accentBlue)
                            .clipShape(Circle())
                            .shadow(color: .accentBlue.opacity(0.5), radius: 10)
                    }
                    .padding()
                }
            }
        }
        .sheet(isPresented: $showingAddGoal) {
            AddGoalSheet(goalService: goalService, isPresented: $showingAddGoal)
        }
        .sheet(isPresented: $showingAchievements) {
            AchievementsSheet(goalService: goalService)
        }
    }

    private var goalStatsCard: some View {
        HStack(spacing: 20) {
            StatBox(value: "\(goalService.activeGoals.count)", label: "Active", color: .blue)
            StatBox(value: "\(goalService.completedGoals.count)", label: "Complete", color: .green)
            StatBox(value: "\(Int(goalService.getCompletionRate()))%", label: "Success", color: .purple)
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(16)
        .padding(.horizontal)
    }

    private var achievementsCard: some View {
        Button(action: { showingAchievements = true }) {
            HStack {
                Image(systemName: "trophy.fill")
                    .font(.largeTitle)
                    .foregroundColor(.yellow)

                VStack(alignment: .leading) {
                    Text("Achievements")
                        .font(.headline)
                        .foregroundColor(.textPrimary)

                    let progress = goalService.getAchievementProgress()
                    Text("\(progress.unlocked) / \(progress.total) Unlocked")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.textSecondary)
            }
            .padding()
            .background(Color.cardBackground)
            .cornerRadius(16)
            .padding(.horizontal)
        }
    }
}

struct GoalCard: View {
    let goal: GoalEntity
    let goalService: GoalService
    @State private var showingEdit = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.title)
                        .font(.headline)
                        .foregroundColor(.textPrimary)

                    if let description = goal.goalDescription {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                            .lineLimit(2)
                    }
                }

                Spacer()

                if goal.isOverdue {
                    Text("OVERDUE")
                        .font(.caption.bold())
                        .foregroundColor(.warningOrange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.warningOrange.opacity(0.2))
                        .cornerRadius(6)
                }
            }

            // Progress bar
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("\(Int(goal.progressPercentage))%")
                        .font(.caption.bold())
                        .foregroundColor(.accentBlue)

                    Spacer()

                    if let targetDate = goal.targetDate {
                        Text(targetDate, style: .date)
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.secondaryGray.opacity(0.3))
                            .frame(height: 8)

                        Rectangle()
                            .fill(Color.accentBlue)
                            .frame(width: geometry.size.width * CGFloat(goal.progressPercentage / 100), height: 8)
                    }
                    .cornerRadius(4)
                }
                .frame(height: 8)
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(16)
        .padding(.horizontal)
        .contextMenu {
            Button(action: { showingEdit = true }) {
                Label("Edit Progress", systemImage: "slider.horizontal.3")
            }
            Button(action: { goalService.completeGoal(goal) }) {
                Label("Mark Complete", systemImage: "checkmark.circle")
            }
            Button(role: .destructive, action: { goalService.deleteGoal(goal) }) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

struct CompletedGoalCard: View {
    let goal: GoalEntity

    var body: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.successGreen)

            VStack(alignment: .leading) {
                Text(goal.title)
                    .font(.headline)
                    .foregroundColor(.textSecondary)
                    .strikethrough()

                if let completedAt = goal.completedAt {
                    Text("Completed \(completedAt, style: .date)")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
            }

            Spacer()
        }
        .padding()
        .background(Color.cardBackground.opacity(0.5))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct StatBox: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title.bold())
                .foregroundColor(color)

            Text(label)
                .font(.caption)
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct AddGoalSheet: View {
    let goalService: GoalService
    @Binding var isPresented: Bool
    @State private var title = ""
    @State private var description = ""
    @State private var category = "personal"
    @State private var hasTargetDate = false
    @State private var targetDate = Date()
    @State private var priority = "Medium"

    let categories = ["work", "personal", "health", "learning"]
    let priorities = ["High", "Medium", "Low"]

    var body: some View {
        NavigationView {
            ZStack {
                Color.battleBackground.ignoresSafeArea()

                Form {
                    Section {
                        TextField("Goal Title", text: $title)
                        TextField("Description (optional)", text: $description)
                    }

                    Section {
                        Picker("Category", selection: $category) {
                            ForEach(categories, id: \.self) { cat in
                                Text(cat.capitalized).tag(cat)
                            }
                        }

                        Picker("Priority", selection: $priority) {
                            ForEach(priorities, id: \.self) { pri in
                                Text(pri).tag(pri)
                            }
                        }
                    }

                    Section {
                        Toggle("Set Target Date", isOn: $hasTargetDate)

                        if hasTargetDate {
                            DatePicker("Target Date", selection: $targetDate, displayedComponents: .date)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("New Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        goalService.createGoal(
                            title: title,
                            description: description.isEmpty ? nil : description,
                            category: category,
                            targetDate: hasTargetDate ? targetDate : nil,
                            priority: priority
                        )
                        isPresented = false
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}

struct AchievementsSheet: View {
    let goalService: GoalService
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Color.battleBackground.ignoresSafeArea()

                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(goalService.getAllAchievements(), id: \.id) { achievement in
                            AchievementCard(achievement: achievement)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Achievements")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct AchievementCard: View {
    let achievement: AchievementEntity

    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: achievement.icon)
                .font(.largeTitle)
                .foregroundColor(achievement.isUnlocked ? .yellow : .secondaryGray)
                .frame(width: 60)

            VStack(alignment: .leading, spacing: 4) {
                Text(achievement.title)
                    .font(.headline)
                    .foregroundColor(achievement.isUnlocked ? .textPrimary : .textSecondary)

                Text(achievement.achievementDescription)
                    .font(.caption)
                    .foregroundColor(.textSecondary)

                if let unlockedAt = achievement.unlockedAt {
                    Text("Unlocked \(unlockedAt, style: .date)")
                        .font(.caption2)
                        .foregroundColor(.successGreen)
                }
            }

            Spacer()

            if achievement.isUnlocked {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(.successGreen)
            } else {
                Image(systemName: "lock.fill")
                    .foregroundColor(.secondaryGray)
            }
        }
        .padding()
        .background(achievement.isUnlocked ? Color.cardBackground : Color.cardBackground.opacity(0.5))
        .cornerRadius(12)
        .opacity(achievement.isUnlocked ? 1.0 : 0.6)
    }
}

#Preview {
    GoalDashboardView(context: PersistenceController.preview.container.viewContext)
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
