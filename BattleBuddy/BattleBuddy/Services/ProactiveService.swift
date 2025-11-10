//
//  ProactiveService.swift
//  BattleBuddy
//
//  Phase 6: Proactive intelligence and suggestions
//  Generates contextual suggestions based on time, tasks, mood, and patterns
//

import Foundation
import CoreData

class ProactiveService: ObservableObject {
    private let context: NSManagedObjectContext
    @Published var currentSuggestions: [ProactiveSuggestionEntity] = []

    init(context: NSManagedObjectContext) {
        self.context = context
        loadPendingSuggestions()
    }

    // MARK: - Suggestion Generation

    /// Analyze current state and generate proactive suggestions
    func generateSuggestions() {
        let calendar = Calendar.current
        let now = Date()
        let hour = calendar.component(.hour, from: now)

        // Check different contexts
        checkMorningRoutine(hour: hour)
        checkTaskProgress()
        checkLongWorkSession()
        checkGoalProgress()
        checkMoodPatterns()
        checkUpcomingDeadlines()

        loadPendingSuggestions()
    }

    // MARK: - Context-Aware Suggestions

    /// Morning routine suggestions
    private func checkMorningRoutine(hour: Int) {
        guard hour >= 6 && hour <= 9 else { return }

        // Check if user has tasks for today
        let taskRequest: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
        taskRequest.predicate = NSPredicate(format: "isCompleted == NO")

        let taskCount = (try? context.count(for: taskRequest)) ?? 0

        if taskCount > 0 {
            let suggestion = createSuggestion(
                text: "Good morning! You have \(taskCount) tasks waiting. Want to knock out the quick ones first?",
                type: "morning_motivation",
                priority: 8,
                expiresIn: 3600 * 3 // 3 hours
            )

            // Add context about high-priority tasks
            let highPriorityRequest: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
            highPriorityRequest.predicate = NSPredicate(format: "isCompleted == NO AND priority == %@", "High")
            let highPriorityCount = (try? context.count(for: highPriorityRequest)) ?? 0

            if highPriorityCount > 0 {
                suggestion.contextData = "high_priority_count:\(highPriorityCount)"
            }
        }
    }

    /// Check task completion progress
    private func checkTaskProgress() {
        let calendar = Calendar.current
        let now = Date()
        let hour = calendar.component(.hour, from: now)

        // Afternoon check-in (2-4 PM)
        guard hour >= 14 && hour <= 16 else { return }

        let taskRequest: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
        taskRequest.predicate = NSPredicate(format: "isCompleted == NO")
        let remainingTasks = (try? context.count(for: taskRequest)) ?? 0

        let completedRequest: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
        completedRequest.predicate = NSPredicate(format: "isCompleted == YES AND createdAt >= %@", calendar.startOfDay(for: now) as NSDate)
        let completedToday = (try? context.count(for: completedRequest)) ?? 0

        if completedToday > 0 && remainingTasks > 0 {
            _ = createSuggestion(
                text: "Nice work! You've completed \(completedToday) tasks today. \(remainingTasks) more to go. Keep the momentum!",
                type: "progress_celebration",
                priority: 7,
                expiresIn: 3600 * 2
            )
        } else if completedToday == 0 && remainingTasks > 0 {
            _ = createSuggestion(
                text: "Haven't tackled any tasks yet today. No pressure, but sometimes starting is the hardest part. Want to pick one?",
                type: "gentle_nudge",
                priority: 6,
                expiresIn: 3600 * 2
            )
        }
    }

    /// Check for long work sessions
    private func checkLongWorkSession() {
        // Check conversation history for continuous work
        let threeHoursAgo = Date().addingTimeInterval(-3 * 3600)
        let conversationRequest: NSFetchRequest<ConversationEntryEntity> = ConversationEntryEntity.fetchRequest()
        conversationRequest.predicate = NSPredicate(format: "timestamp >= %@", threeHoursAgo as NSDate)

        let recentConversations = (try? context.count(for: conversationRequest)) ?? 0

        if recentConversations > 5 {
            _ = createSuggestion(
                text: "You've been working hard for a while now. Time for a quick break? Even 5 minutes helps reset your focus.",
                type: "break_reminder",
                priority: 9,
                expiresIn: 3600
            )
        }
    }

    /// Check goal progress
    private func checkGoalProgress() {
        let goalRequest: NSFetchRequest<GoalEntity> = GoalEntity.fetchRequest()
        goalRequest.predicate = NSPredicate(format: "isCompleted == NO")

        guard let goals = try? context.fetch(goalRequest) else { return }

        for goal in goals {
            // Check if goal has made no progress in a week
            let oneWeekAgo = Date().addingTimeInterval(-7 * 24 * 3600)
            if goal.createdAt < oneWeekAgo && goal.currentProgress == 0 {
                _ = createSuggestion(
                    text: "Your goal '\(goal.title)' hasn't had any progress yet. Want to break it down into smaller steps?",
                    type: "goal_check_in",
                    priority: 7,
                    expiresIn: 24 * 3600
                )
            }

            // Check if goal is near deadline
            if let targetDate = goal.targetDate {
                let daysUntilDeadline = Calendar.current.dateComponents([.day], from: Date(), to: targetDate).day ?? 0

                if daysUntilDeadline <= 3 && daysUntilDeadline > 0 && goal.progressPercentage < 75 {
                    _ = createSuggestion(
                        text: "Goal '\(goal.title)' is due in \(daysUntilDeadline) days and is \(Int(goal.progressPercentage))% complete. Need to prioritize?",
                        type: "deadline_warning",
                        priority: 10,
                        expiresIn: 24 * 3600
                    )
                }
            }
        }
    }

    /// Check mood patterns
    private func checkMoodPatterns() {
        let oneWeekAgo = Date().addingTimeInterval(-7 * 24 * 3600)
        let reflectionRequest: NSFetchRequest<ReflectionLogEntity> = ReflectionLogEntity.fetchRequest()
        reflectionRequest.predicate = NSPredicate(format: "date >= %@", oneWeekAgo as NSDate)
        reflectionRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]

        guard let reflections = try? context.fetch(reflectionRequest) else { return }

        // Count negative moods
        let negativeMoods = reflections.filter { $0.mood == "😔" || $0.mood == "😟" }.count

        if negativeMoods >= 3 && reflections.count >= 5 {
            _ = createSuggestion(
                text: "I've noticed you've been feeling down lately. Want to talk about what's going on? I'm here for you.",
                type: "wellbeing_check",
                priority: 10,
                expiresIn: 48 * 3600
            )
        }

        // Celebrate positive streak
        let recentPositive = reflections.prefix(3).filter { $0.mood == "😊" || $0.mood == "🎉" }.count
        if recentPositive == 3 {
            _ = createSuggestion(
                text: "You've been in a great mood lately! Keep that positive energy flowing. 🎉",
                type: "mood_celebration",
                priority: 6,
                expiresIn: 24 * 3600
            )
        }
    }

    /// Check upcoming deadlines
    private func checkUpcomingDeadlines() {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()

        let taskRequest: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
        taskRequest.predicate = NSPredicate(format: "isCompleted == NO AND dueDate != nil AND dueDate <= %@", tomorrow as NSDate)

        let dueSoon = (try? context.count(for: taskRequest)) ?? 0

        if dueSoon > 0 {
            _ = createSuggestion(
                text: "You have \(dueSoon) task\(dueSoon == 1 ? "" : "s") due tomorrow. Want to review them?",
                type: "deadline_reminder",
                priority: 9,
                expiresIn: 12 * 3600
            )
        }
    }

    // MARK: - Suggestion Management

    /// Create a new suggestion
    @discardableResult
    private func createSuggestion(text: String, type: String, priority: Int16, expiresIn: TimeInterval) -> ProactiveSuggestionEntity {
        // Check if similar suggestion already exists
        let request: NSFetchRequest<ProactiveSuggestionEntity> = ProactiveSuggestionEntity.fetchRequest()
        request.predicate = NSPredicate(format: "suggestionType == %@ AND wasShown == NO", type)

        if let existing = try? context.fetch(request).first {
            return existing // Don't create duplicate
        }

        return ProactiveSuggestionEntity.create(
            context: context,
            text: text,
            type: type,
            priority: priority,
            expiresIn: expiresIn
        )
    }

    /// Load pending suggestions
    func loadPendingSuggestions() {
        currentSuggestions = ProactiveSuggestionEntity.getPendingSuggestions(context: context)
            .filter { !$0.isExpired }
    }

    /// Mark suggestion as shown
    func markAsShown(_ suggestion: ProactiveSuggestionEntity) {
        suggestion.wasShown = true
        try? context.save()
        loadPendingSuggestions()
    }

    /// Mark suggestion as accepted
    func markAsAccepted(_ suggestion: ProactiveSuggestionEntity) {
        suggestion.wasAccepted = true
        try? context.save()
    }

    /// Dismiss suggestion
    func dismissSuggestion(_ suggestion: ProactiveSuggestionEntity) {
        context.delete(suggestion)
        try? context.save()
        loadPendingSuggestions()
    }

    /// Get top priority suggestion
    func getTopSuggestion() -> ProactiveSuggestionEntity? {
        return currentSuggestions.first
    }

    // MARK: - Scheduled Generation

    /// Should be called periodically (e.g., hourly)
    func schedulePeriodicGeneration() {
        // Clean up old suggestions first
        cleanupOldSuggestions()

        // Generate new suggestions
        generateSuggestions()
    }

    /// Clean up expired and shown suggestions older than 24 hours
    private func cleanupOldSuggestions() {
        let oneDayAgo = Date().addingTimeInterval(-24 * 3600)
        let request: NSFetchRequest<ProactiveSuggestionEntity> = ProactiveSuggestionEntity.fetchRequest()
        request.predicate = NSPredicate(format: "createdAt < %@ OR (expiresAt != nil AND expiresAt < %@)", oneDayAgo as NSDate, Date() as NSDate)

        guard let oldSuggestions = try? context.fetch(request) else { return }

        for suggestion in oldSuggestions {
            context.delete(suggestion)
        }

        if !oldSuggestions.isEmpty {
            try? context.save()
        }
    }

    // MARK: - Statistics

    /// Get suggestion acceptance rate
    func getAcceptanceRate() -> Double {
        let allRequest: NSFetchRequest<ProactiveSuggestionEntity> = ProactiveSuggestionEntity.fetchRequest()
        allRequest.predicate = NSPredicate(format: "wasShown == YES")

        let acceptedRequest: NSFetchRequest<ProactiveSuggestionEntity> = ProactiveSuggestionEntity.fetchRequest()
        acceptedRequest.predicate = NSPredicate(format: "wasShown == YES AND wasAccepted == YES")

        let total = (try? context.count(for: allRequest)) ?? 0
        let accepted = (try? context.count(for: acceptedRequest)) ?? 0

        guard total > 0 else { return 0 }
        return Double(accepted) / Double(total) * 100
    }
}
