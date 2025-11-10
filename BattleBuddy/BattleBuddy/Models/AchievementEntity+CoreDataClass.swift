//
//  AchievementEntity+CoreDataClass.swift
//  BattleBuddy
//
//  Phase 6: Gamification and achievements
//

import Foundation
import CoreData

@objc(AchievementEntity)
public class AchievementEntity: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var achievementKey: String
    @NSManaged public var title: String
    @NSManaged public var achievementDescription: String
    @NSManaged public var unlockedAt: Date?
    @NSManaged public var isUnlocked: Bool
    @NSManaged public var icon: String
    @NSManaged public var category: String
}

extension AchievementEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<AchievementEntity> {
        return NSFetchRequest<AchievementEntity>(entityName: "AchievementEntity")
    }

    static func unlock(context: NSManagedObjectContext, key: String) -> Bool {
        let request: NSFetchRequest<AchievementEntity> = AchievementEntity.fetchRequest()
        request.predicate = NSPredicate(format: "achievementKey == %@", key)
        request.fetchLimit = 1

        guard let achievement = try? context.fetch(request).first else { return false }

        if !achievement.isUnlocked {
            achievement.isUnlocked = true
            achievement.unlockedAt = Date()
            try? context.save()
            return true
        }

        return false
    }

    // Initialize default achievements
    static func initializeDefaults(context: NSManagedObjectContext) {
        let defaults: [(key: String, title: String, description: String, icon: String, category: String)] = [
            ("first_task", "Getting Started", "Complete your first task", "checkmark.circle", "tasks"),
            ("streak_7", "Committed", "Maintain a 7-day completion streak", "flame", "streaks"),
            ("streak_30", "Dedicated", "Maintain a 30-day completion streak", "flame.fill", "streaks"),
            ("task_10", "Productive", "Complete 10 tasks", "list.bullet", "tasks"),
            ("task_50", "Achiever", "Complete 50 tasks", "star", "tasks"),
            ("task_100", "Champion", "Complete 100 tasks", "crown", "tasks"),
            ("goal_first", "Goal Setter", "Create your first goal", "target", "goals"),
            ("goal_completed", "Goal Crusher", "Complete your first goal", "trophy", "goals"),
            ("reflection_7", "Mindful", "Log reflections for 7 days in a row", "brain", "reflection"),
            ("early_bird", "Early Bird", "Complete a task before 8 AM", "sunrise", "tasks"),
            ("night_owl", "Night Owl", "Complete a task after 10 PM", "moon", "tasks"),
            ("voice_10", "Conversationalist", "Have 10 voice conversations", "mic", "voice"),
            ("voice_100", "Chatterbox", "Have 100 voice conversations", "mic.fill", "voice")
        ]

        for achievement in defaults {
            let request: NSFetchRequest<AchievementEntity> = AchievementEntity.fetchRequest()
            request.predicate = NSPredicate(format: "achievementKey == %@", achievement.key)

            if (try? context.fetch(request).isEmpty) == true {
                let newAchievement = AchievementEntity(context: context)
                newAchievement.id = UUID()
                newAchievement.achievementKey = achievement.key
                newAchievement.title = achievement.title
                newAchievement.achievementDescription = achievement.description
                newAchievement.icon = achievement.icon
                newAchievement.category = achievement.category
                newAchievement.isUnlocked = false
            }
        }

        try? context.save()
    }
}
