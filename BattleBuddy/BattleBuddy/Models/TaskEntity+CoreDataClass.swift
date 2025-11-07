//
//  TaskEntity+CoreDataClass.swift
//  BattleBuddy
//

import Foundation
import CoreData

@objc(TaskEntity)
public class TaskEntity: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID
    @NSManaged public var title: String
    @NSManaged public var priority: String
    @NSManaged public var isCompleted: Bool
    @NSManaged public var createdAt: Date
    @NSManaged public var dueDate: Date?

    // Convenience initializer
    convenience init(context: NSManagedObjectContext, title: String, priority: String = "Medium", dueDate: Date? = nil) {
        self.init(context: context)
        self.id = UUID()
        self.title = title
        self.priority = priority
        self.isCompleted = false
        self.createdAt = Date()
        self.dueDate = dueDate
    }

    // Priority sorting helper
    var priorityValue: Int {
        switch priority {
        case "High": return 0
        case "Medium": return 1
        case "Low": return 2
        default: return 3
        }
    }
}
