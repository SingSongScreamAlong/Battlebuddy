//
//  UserProfileEntity+CoreDataClass.swift
//  BattleBuddy
//
//  Phase 6: Extended user profile and stats tracking
//

import Foundation
import CoreData

@objc(UserProfileEntity)
public class UserProfileEntity: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var totalTasksCompleted: Int32
    @NSManaged public var currentStreak: Int16
    @NSManaged public var longestStreak: Int16
    @NSManaged public var lastActivityDate: Date?
    @NSManaged public var totalConversations: Int32
    @NSManaged public var totalGoalsCompleted: Int32
    @NSManaged public var monthlyBudget: Double
    @NSManaged public var workStartTime: Date?
    @NSManaged public var workEndTime: Date?
    @NSManaged public var preferredEnergyPeakTime: String?
    @NSManaged public var onboardingCompleted: Bool

    // Update streak tracking
    func updateStreak() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if let lastActivity = lastActivityDate {
            let lastActivityDay = calendar.startOfDay(for: lastActivity)
            let daysDifference = calendar.dateComponents([.day], from: lastActivityDay, to: today).day ?? 0

            if daysDifference == 1 {
                // Consecutive day
                currentStreak += 1
                if currentStreak > longestStreak {
                    longestStreak = currentStreak
                }
            } else if daysDifference > 1 {
                // Streak broken
                currentStreak = 1
            }
            // If same day, don't update
        } else {
            // First activity
            currentStreak = 1
            longestStreak = 1
        }

        lastActivityDate = Date()
    }

    // Check if currently in work hours
    var isWorkHours: Bool {
        guard let workStart = workStartTime,
              let workEnd = workEndTime else { return false }

        let calendar = Calendar.current
        let now = Date()
        let nowComponents = calendar.dateComponents([.hour, .minute], from: now)
        let startComponents = calendar.dateComponents([.hour, .minute], from: workStart)
        let endComponents = calendar.dateComponents([.hour, .minute], from: workEnd)

        guard let nowMinutes = nowComponents.hour?.advanced(by: 0) * 60 + (nowComponents.minute ?? 0),
              let startMinutes = startComponents.hour?.advanced(by: 0) * 60 + (startComponents.minute ?? 0),
              let endMinutes = endComponents.hour?.advanced(by: 0) * 60 + (endComponents.minute ?? 0) else {
            return false
        }

        return nowMinutes >= startMinutes && nowMinutes <= endMinutes
    }
}

extension UserProfileEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserProfileEntity> {
        return NSFetchRequest<UserProfileEntity>(entityName: "UserProfileEntity")
    }

    // Fetch or create singleton profile
    static func fetchOrCreate(context: NSManagedObjectContext) -> UserProfileEntity {
        let request: NSFetchRequest<UserProfileEntity> = UserProfileEntity.fetchRequest()
        request.fetchLimit = 1

        if let existing = try? context.fetch(request).first {
            return existing
        }

        // Create default profile
        let profile = UserProfileEntity(context: context)
        profile.id = UUID()
        profile.totalTasksCompleted = 0
        profile.currentStreak = 0
        profile.longestStreak = 0
        profile.totalConversations = 0
        profile.totalGoalsCompleted = 0
        profile.monthlyBudget = 20.0
        profile.onboardingCompleted = false

        // Set default work hours (9 AM - 5 PM)
        var startComponents = DateComponents()
        startComponents.hour = 9
        startComponents.minute = 0
        profile.workStartTime = Calendar.current.date(from: startComponents)

        var endComponents = DateComponents()
        endComponents.hour = 17
        endComponents.minute = 0
        profile.workEndTime = Calendar.current.date(from: endComponents)

        profile.preferredEnergyPeakTime = "morning"

        try? context.save()
        return profile
    }
}
