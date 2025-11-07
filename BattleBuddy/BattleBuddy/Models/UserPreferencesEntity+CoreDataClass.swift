//
//  UserPreferencesEntity+CoreDataClass.swift
//  BattleBuddy
//

import Foundation
import CoreData

@objc(UserPreferencesEntity)
public class UserPreferencesEntity: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var morningBriefTime: Date
    @NSManaged public var eveningReflectionTime: Date
    @NSManaged public var defaultMode: String

    // Fetch or create singleton preferences
    static func fetchOrCreate(context: NSManagedObjectContext) -> UserPreferencesEntity {
        let request: NSFetchRequest<UserPreferencesEntity> = UserPreferencesEntity.fetchRequest()
        request.fetchLimit = 1

        if let existing = try? context.fetch(request).first {
            return existing
        }

        // Create default preferences
        let preferences = UserPreferencesEntity(context: context)
        preferences.id = UUID()
        preferences.name = "User"

        // Set default morning brief to 7:00 AM
        var morningComponents = DateComponents()
        morningComponents.hour = 7
        morningComponents.minute = 0
        preferences.morningBriefTime = Calendar.current.date(from: morningComponents) ?? Date()

        // Set default evening reflection to 8:00 PM
        var eveningComponents = DateComponents()
        eveningComponents.hour = 20
        eveningComponents.minute = 0
        preferences.eveningReflectionTime = Calendar.current.date(from: eveningComponents) ?? Date()

        preferences.defaultMode = "companion"

        try? context.save()
        return preferences
    }
}

extension UserPreferencesEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserPreferencesEntity> {
        return NSFetchRequest<UserPreferencesEntity>(entityName: "UserPreferencesEntity")
    }
}
