//
//  MemoryService.swift
//  BattleBuddy
//
//  Phase 6: Long-term memory and user learning
//  Stores and retrieves user preferences, patterns, and learned information
//

import Foundation
import CoreData

class MemoryService: ObservableObject {
    private let context: NSManagedObjectContext

    // Memory categories
    enum MemoryCategory: String {
        case preference = "preference"      // User preferences (likes/dislikes)
        case pattern = "pattern"            // Behavioral patterns
        case goal = "goal"                  // Life goals and aspirations
        case relationship = "relationship"  // People and relationships
        case habit = "habit"                // Daily habits
        case skill = "skill"                // Skills and learning
        case context = "context"            // Contextual information
    }

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    // MARK: - Memory Management

    /// Store a memory
    func remember(key: String, value: String, category: MemoryCategory, importance: Int = 5) {
        _ = AIMemoryEntity.findOrCreate(context: context, key: key, value: value, category: category.rawValue)
    }

    /// Retrieve a memory
    func recall(key: String) -> String? {
        let request: NSFetchRequest<AIMemoryEntity> = AIMemoryEntity.fetchRequest()
        request.predicate = NSPredicate(format: "memoryKey == %@", key)
        request.fetchLimit = 1

        guard let memory = try? context.fetch(request).first else { return nil }
        memory.recordAccess()
        try? context.save()

        return memory.memoryValue
    }

    /// Search memories by category
    func recallByCategory(_ category: MemoryCategory) -> [String: String] {
        let request: NSFetchRequest<AIMemoryEntity> = AIMemoryEntity.fetchRequest()
        request.predicate = NSPredicate(format: "category == %@", category.rawValue)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \AIMemoryEntity.importance, ascending: false)]

        guard let memories = try? context.fetch(request) else { return [:] }

        var result: [String: String] = [:]
        for memory in memories {
            memory.recordAccess()
            result[memory.memoryKey] = memory.memoryValue
        }

        try? context.save()
        return result
    }

    /// Get most important memories (for AI context)
    func getImportantMemories(limit: Int = 10) -> [String: String] {
        let request: NSFetchRequest<AIMemoryEntity> = AIMemoryEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \AIMemoryEntity.importance, ascending: false)]
        request.fetchLimit = limit

        guard let memories = try? context.fetch(request) else { return [:] }

        var result: [String: String] = [:]
        for memory in memories {
            result[memory.memoryKey] = memory.memoryValue
        }

        return result
    }

    /// Forget a memory
    func forget(key: String) {
        let request: NSFetchRequest<AIMemoryEntity> = AIMemoryEntity.fetchRequest()
        request.predicate = NSPredicate(format: "memoryKey == %@", key)

        guard let memory = try? context.fetch(request).first else { return }
        context.delete(memory)
        try? context.save()
    }

    /// Clean up stale memories (not accessed in 30 days with low importance)
    func cleanupStaleMemories() {
        let request: NSFetchRequest<AIMemoryEntity> = AIMemoryEntity.fetchRequest()
        guard let memories = try? context.fetch(request) else { return }

        var deletedCount = 0
        for memory in memories where memory.isStale {
            context.delete(memory)
            deletedCount += 1
        }

        if deletedCount > 0 {
            try? context.save()
            print("🧹 Cleaned up \(deletedCount) stale memories")
        }
    }

    // MARK: - Pattern Learning

    /// Learn from user behavior
    func learnPattern(description: String, value: String) {
        remember(key: "pattern_\(description)", value: value, category: .pattern, importance: 7)
    }

    /// Check if user dislikes something
    func userDislikes(_ thing: String) -> Bool {
        let key = "dislike_\(thing.lowercased())"
        return recall(key: key) == "true"
    }

    /// Record user dislike
    func recordDislike(_ thing: String) {
        let key = "dislike_\(thing.lowercased())"
        remember(key: key, value: "true", category: .preference, importance: 8)
    }

    /// Check if user likes something
    func userLikes(_ thing: String) -> Bool {
        let key = "like_\(thing.lowercased())"
        return recall(key: key) == "true"
    }

    /// Record user like
    func recordLike(_ thing: String) {
        let key = "like_\(thing.lowercased())"
        remember(key: key, value: "true", category: .preference, importance: 8)
    }

    // MARK: - Contextual Intelligence

    /// Get AI context string (for system prompts)
    func getContextForAI() -> String {
        let preferences = recallByCategory(.preference)
        let patterns = recallByCategory(.pattern)
        let goals = recallByCategory(.goal)

        var context = "USER PROFILE:\n"

        if !preferences.isEmpty {
            context += "\nPreferences:\n"
            for (key, value) in preferences.prefix(5) {
                context += "- \(key.replacingOccurrences(of: "_", with: " ")): \(value)\n"
            }
        }

        if !patterns.isEmpty {
            context += "\nKnown Patterns:\n"
            for (key, value) in patterns.prefix(5) {
                context += "- \(key.replacingOccurrences(of: "pattern_", with: "")): \(value)\n"
            }
        }

        if !goals.isEmpty {
            context += "\nUser's Goals:\n"
            for (key, value) in goals.prefix(3) {
                context += "- \(value)\n"
            }
        }

        return context.isEmpty ? "" : context
    }

    // MARK: - Convenience Methods

    /// Record that user is training for something
    func recordTraining(for activity: String) {
        remember(key: "training_\(activity)", value: Date().ISO8601Format(), category: .goal, importance: 9)
    }

    /// Check if user is training for something
    func isTraining(for activity: String) -> Bool {
        return recall(key: "training_\(activity)") != nil
    }

    /// Record a life goal
    func recordGoal(_ goal: String) {
        let key = "life_goal_\(UUID().uuidString.prefix(8))"
        remember(key: key, value: goal, category: .goal, importance: 10)
    }

    /// Record someone important to user
    func recordImportantPerson(name: String, relationship: String) {
        remember(key: "person_\(name.lowercased())", value: relationship, category: .relationship, importance: 8)
    }

    /// Get relationship info
    func getRelationship(for name: String) -> String? {
        return recall(key: "person_\(name.lowercased())")
    }

    // MARK: - Statistics

    /// Get total memory count
    func getTotalMemoryCount() -> Int {
        let request: NSFetchRequest<AIMemoryEntity> = AIMemoryEntity.fetchRequest()
        return (try? context.count(for: request)) ?? 0
    }

    /// Get memory breakdown by category
    func getMemoryBreakdown() -> [String: Int] {
        var breakdown: [String: Int] = [:]

        for category in [MemoryCategory.preference, .pattern, .goal, .relationship, .habit, .skill, .context] {
            let request: NSFetchRequest<AIMemoryEntity> = AIMemoryEntity.fetchRequest()
            request.predicate = NSPredicate(format: "category == %@", category.rawValue)
            let count = (try? context.count(for: request)) ?? 0
            breakdown[category.rawValue] = count
        }

        return breakdown
    }
}
