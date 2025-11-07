//
//  ReflectionLogEntity+CoreDataClass.swift
//  BattleBuddy
//

import Foundation
import CoreData

@objc(ReflectionLogEntity)
public class ReflectionLogEntity: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID
    @NSManaged public var date: Date
    @NSManaged public var mood: String
    @NSManaged public var note: String?

    convenience init(context: NSManagedObjectContext, mood: String, note: String? = nil) {
        self.init(context: context)
        self.id = UUID()
        self.date = Date()
        self.mood = mood
        self.note = note
    }

    var moodEmoji: String {
        switch mood {
        case "great": return "😄"
        case "good": return "🙂"
        case "rough": return "😕"
        case "tough": return "😓"
        default: return "😐"
        }
    }
}

extension ReflectionLogEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ReflectionLogEntity> {
        return NSFetchRequest<ReflectionLogEntity>(entityName: "ReflectionLogEntity")
    }
}
