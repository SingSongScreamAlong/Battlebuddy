//
//  GoalService.swift
//  BattleBuddy
//
//  Phase 6: Goal tracking, progress visualization, and achievement system
//

import Foundation
import CoreData

class GoalService: ObservableObject {
    private let context: NSManagedObjectContext
    @Published var activeGoals: [GoalEntity] = []
    @Published var completedGoals: [GoalEntity] = []
    @Published var recentAchievements: [AchievementEntity] = []

    init(context: NSManagedObjectContext) {
        self.context = context
        initializeAchievements()
        loadGoals()
    }

    // MARK: - Goal Management

    /// Create a new goal
    func createGoal(title: String, description: String?, category: String, targetDate: Date?, priority: String) -> GoalEntity {
        let goal = GoalEntity.create(
            context: context,
            title: title,
            description: description,
            category: category,
            targetDate: targetDate,
            priority: priority
        )

        loadGoals()
        checkAchievement("goal_first")

        return goal
    }

    /// Update goal progress
    func updateProgress(goal: GoalEntity, progress: Int) {
        goal.currentProgress = Int16(progress)

        // Auto-complete if reached target
        if progress >= goal.targetProgress && !goal.isCompleted {
            completeGoal(goal)
        } else {
            try? context.save()
        }
    }

    /// Complete a goal
    func completeGoal(_ goal: GoalEntity) {
        goal.isCompleted = true
        goal.completedAt = Date()
        goal.currentProgress = goal.targetProgress

        // Update user profile
        let profile = UserProfileEntity.fetchOrCreate(context: context)
        profile.totalGoalsCompleted += 1

        try? context.save()
        loadGoals()

        // Check achievements
        checkAchievement("goal_completed")
        checkGoalMilestones(profile.totalGoalsCompleted)
    }

    /// Delete a goal
    func deleteGoal(_ goal: GoalEntity) {
        context.delete(goal)
        try? context.save()
        loadGoals()
    }

    /// Load all goals
    func loadGoals() {
        let activeRequest: NSFetchRequest<GoalEntity> = GoalEntity.fetchRequest()
        activeRequest.predicate = NSPredicate(format: "isCompleted == NO")
        activeRequest.sortDescriptors = [
            NSSortDescriptor(keyPath: \GoalEntity.priority, ascending: true),
            NSSortDescriptor(keyPath: \GoalEntity.createdAt, ascending: false)
        ]

        let completedRequest: NSFetchRequest<GoalEntity> = GoalEntity.fetchRequest()
        completedRequest.predicate = NSPredicate(format: "isCompleted == YES")
        completedRequest.sortDescriptors = [NSSortDescriptor(keyPath: \GoalEntity.completedAt, ascending: false)]

        activeGoals = (try? context.fetch(activeRequest)) ?? []
        completedGoals = (try? context.fetch(completedRequest)) ?? []
    }

    /// Get goals by category
    func getGoals(byCategory category: String) -> [GoalEntity] {
        let request: NSFetchRequest<GoalEntity> = GoalEntity.fetchRequest()
        request.predicate = NSPredicate(format: "category == %@", category)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \GoalEntity.createdAt, ascending: false)]

        return (try? context.fetch(request)) ?? []
    }

    // MARK: - Achievement System

    /// Initialize default achievements
    private func initializeAchievements() {
        AchievementEntity.initializeDefaults(context: context)
        loadRecentAchievements()
    }

    /// Check and unlock achievement
    @discardableResult
    func checkAchievement(_ key: String) -> Bool {
        let unlocked = AchievementEntity.unlock(context: context, key: key)
        if unlocked {
            loadRecentAchievements()
        }
        return unlocked
    }

    /// Check goal milestones
    private func checkGoalMilestones(_ totalCompleted: Int32) {
        if totalCompleted >= 5 {
            checkAchievement("goal_5")
        }
        if totalCompleted >= 10 {
            checkAchievement("goal_10")
        }
        if totalCompleted >= 25 {
            checkAchievement("goal_25")
        }
    }

    /// Load recent achievements (last 7 days)
    func loadRecentAchievements() {
        let sevenDaysAgo = Date().addingTimeInterval(-7 * 24 * 3600)
        let request: NSFetchRequest<AchievementEntity> = AchievementEntity.fetchRequest()
        request.predicate = NSPredicate(format: "isUnlocked == YES AND unlockedAt >= %@", sevenDaysAgo as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \AchievementEntity.unlockedAt, ascending: false)]

        recentAchievements = (try? context.fetch(request)) ?? []
    }

    /// Get all achievements
    func getAllAchievements() -> [AchievementEntity] {
        let request: NSFetchRequest<AchievementEntity> = AchievementEntity.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \AchievementEntity.category, ascending: true),
            NSSortDescriptor(keyPath: \AchievementEntity.isUnlocked, ascending: false)
        ]

        return (try? context.fetch(request)) ?? []
    }

    /// Get achievement progress
    func getAchievementProgress() -> (unlocked: Int, total: Int) {
        let request: NSFetchRequest<AchievementEntity> = AchievementEntity.fetchRequest()
        let total = (try? context.count(for: request)) ?? 0

        let unlockedRequest: NSFetchRequest<AchievementEntity> = AchievementEntity.fetchRequest()
        unlockedRequest.predicate = NSPredicate(format: "isUnlocked == YES")
        let unlocked = (try? context.count(for: unlockedRequest)) ?? 0

        return (unlocked, total)
    }

    // MARK: - Statistics

    /// Get goal completion rate
    func getCompletionRate() -> Double {
        let allRequest: NSFetchRequest<GoalEntity> = GoalEntity.fetchRequest()
        let total = (try? context.count(for: allRequest)) ?? 0

        let completedRequest: NSFetchRequest<GoalEntity> = GoalEntity.fetchRequest()
        completedRequest.predicate = NSPredicate(format: "isCompleted == YES")
        let completed = (try? context.count(for: completedRequest)) ?? 0

        guard total > 0 else { return 0 }
        return Double(completed) / Double(total) * 100
    }

    /// Get average goal completion time (in days)
    func getAverageCompletionTime() -> Double? {
        let request: NSFetchRequest<GoalEntity> = GoalEntity.fetchRequest()
        request.predicate = NSPredicate(format: "isCompleted == YES AND completedAt != nil")

        guard let goals = try? context.fetch(request), !goals.isEmpty else { return nil }

        var totalDays = 0.0
        var count = 0

        for goal in goals {
            if let completedAt = goal.completedAt {
                let days = completedAt.timeIntervalSince(goal.createdAt) / (24 * 3600)
                totalDays += days
                count += 1
            }
        }

        guard count > 0 else { return nil }
        return totalDays / Double(count)
    }

    /// Get goals by status
    func getGoalStats() -> (active: Int, completed: Int, overdue: Int) {
        let activeCount = activeGoals.count
        let completedCount = completedGoals.count
        let overdueCount = activeGoals.filter { $0.isOverdue }.count

        return (activeCount, completedCount, overdueCount)
    }

    /// Get category breakdown
    func getCategoryBreakdown() -> [String: Int] {
        let request: NSFetchRequest<GoalEntity> = GoalEntity.fetchRequest()
        guard let goals = try? context.fetch(request) else { return [:] }

        var breakdown: [String: Int] = [:]
        for goal in goals {
            breakdown[goal.category, default: 0] += 1
        }

        return breakdown
    }

    // MARK: - AI Integration

    /// Get goal context for AI
    func getGoalContextForAI() -> String {
        guard !activeGoals.isEmpty else { return "" }

        var context = "ACTIVE GOALS:\n"

        for goal in activeGoals.prefix(5) {
            let progress = Int(goal.progressPercentage)
            context += "- \(goal.title) (\(progress)% complete"

            if let targetDate = goal.targetDate {
                let formatter = DateFormatter()
                formatter.dateStyle = .short
                context += ", due \(formatter.string(from: targetDate))"
            }

            context += ")\n"
        }

        return context
    }

    /// Suggest goal based on patterns
    func suggestGoal(based on: String) -> String? {
        // This could be enhanced with ML in the future
        let suggestions = [
            "fitness": "Complete 30 days of exercise",
            "learning": "Learn a new skill this month",
            "productivity": "Finish all high-priority tasks this week",
            "health": "Establish a consistent sleep schedule",
            "mindfulness": "Meditate for 10 days straight"
        ]

        return suggestions[on.lowercased()]
    }
}
