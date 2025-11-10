//
//  GoalEntity+CoreDataClass.swift
//  BattleBuddy
//
//  Phase 6: Goal tracking and progress visualization
//

import Foundation
import CoreData

@objc(GoalEntity)
public class GoalEntity: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var title: String
    @NSManaged public var goalDescription: String?
    @NSManaged public var category: String
    @NSManaged public var targetDate: Date?
    @NSManaged public var currentProgress: Int16
    @NSManaged public var targetProgress: Int16
    @NSManaged public var isCompleted: Bool
    @NSManaged public var createdAt: Date
    @NSManaged public var completedAt: Date?
    @NSManaged public var priority: String

    // Computed properties
    var progressPercentage: Double {
        guard targetProgress > 0 else { return 0 }
        return Double(currentProgress) / Double(targetProgress) * 100
    }

    var isOverdue: Bool {
        guard let targetDate = targetDate else { return false }
        return !isCompleted && targetDate < Date()
    }

    var categoryColor: String {
        switch category.lowercased() {
        case "work": return "blue"
        case "personal": return "green"
        case "health": return "red"
        case "learning": return "purple"
        default: return "gray"
        }
    }
}

extension GoalEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<GoalEntity> {
        return NSFetchRequest<GoalEntity>(entityName: "GoalEntity")
    }

    static func create(context: NSManagedObjectContext, title: String, description: String?, category: String, targetDate: Date?, priority: String) -> GoalEntity {
        let goal = GoalEntity(context: context)
        goal.id = UUID()
        goal.title = title
        goal.goalDescription = description
        goal.category = category
        goal.targetDate = targetDate
        goal.currentProgress = 0
        goal.targetProgress = 100
        goal.isCompleted = false
        goal.createdAt = Date()
        goal.priority = priority

        try? context.save()
        return goal
    }
}
