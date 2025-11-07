//
//  ConversationEntryEntity+CoreDataClass.swift
//  BattleBuddy
//

import Foundation
import CoreData

@objc(ConversationEntryEntity)
public class ConversationEntryEntity: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID
    @NSManaged public var userMessage: String
    @NSManaged public var aiResponse: String
    @NSManaged public var timestamp: Date
    @NSManaged public var mode: String

    convenience init(context: NSManagedObjectContext, userMessage: String, aiResponse: String, mode: String) {
        self.init(context: context)
        self.id = UUID()
        self.userMessage = userMessage
        self.aiResponse = aiResponse
        self.timestamp = Date()
        self.mode = mode
    }
}

extension ConversationEntryEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ConversationEntryEntity> {
        return NSFetchRequest<ConversationEntryEntity>(entityName: "ConversationEntryEntity")
    }
}
