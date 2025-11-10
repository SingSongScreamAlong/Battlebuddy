//
//  AIMemoryEntity+CoreDataClass.swift
//  BattleBuddy
//
//  Phase 6: Long-term memory and user learning
//

import Foundation
import CoreData

@objc(AIMemoryEntity)
public class AIMemoryEntity: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var memoryKey: String
    @NSManaged public var memoryValue: String
    @NSManaged public var category: String
    @NSManaged public var importance: Int16
    @NSManaged public var createdAt: Date
    @NSManaged public var lastAccessedAt: Date
    @NSManaged public var accessCount: Int32

    // Update access tracking
    func recordAccess() {
        lastAccessedAt = Date()
        accessCount += 1

        // Importance increases with usage
        if accessCount % 10 == 0 && importance < 10 {
            importance += 1
        }
    }

    // Check if memory is stale (not accessed in 30 days)
    var isStale: Bool {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        return lastAccessedAt < thirtyDaysAgo && importance < 5
    }
}

extension AIMemoryEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<AIMemoryEntity> {
        return NSFetchRequest<AIMemoryEntity>(entityName: "AIMemoryEntity")
    }

    static func create(context: NSManagedObjectContext, key: String, value: String, category: String, importance: Int16 = 5) -> AIMemoryEntity {
        let memory = AIMemoryEntity(context: context)
        memory.id = UUID()
        memory.memoryKey = key
        memory.memoryValue = value
        memory.category = category
        memory.importance = importance
        memory.createdAt = Date()
        memory.lastAccessedAt = Date()
        memory.accessCount = 0

        try? context.save()
        return memory
    }

    static func findOrCreate(context: NSManagedObjectContext, key: String, value: String, category: String) -> AIMemoryEntity {
        let request: NSFetchRequest<AIMemoryEntity> = AIMemoryEntity.fetchRequest()
        request.predicate = NSPredicate(format: "memoryKey == %@", key)
        request.fetchLimit = 1

        if let existing = try? context.fetch(request).first {
            existing.memoryValue = value
            existing.lastAccessedAt = Date()
            try? context.save()
            return existing
        }

        return create(context: context, key: key, value: value, category: category)
    }
}
