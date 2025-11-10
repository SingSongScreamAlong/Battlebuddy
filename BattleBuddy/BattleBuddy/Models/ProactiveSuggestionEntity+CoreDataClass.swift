//
//  ProactiveSuggestionEntity+CoreDataClass.swift
//  BattleBuddy
//
//  Phase 6: Proactive intelligence and suggestions
//

import Foundation
import CoreData

@objc(ProactiveSuggestionEntity)
public class ProactiveSuggestionEntity: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var suggestionText: String
    @NSManaged public var suggestionType: String
    @NSManaged public var createdAt: Date
    @NSManaged public var wasShown: Bool
    @NSManaged public var wasAccepted: Bool
    @NSManaged public var priority: Int16
    @NSManaged public var expiresAt: Date?
    @NSManaged public var contextData: String?

    var isExpired: Bool {
        guard let expiresAt = expiresAt else { return false }
        return Date() > expiresAt
    }

    var shouldShow: Bool {
        return !wasShown && !isExpired
    }
}

extension ProactiveSuggestionEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ProactiveSuggestionEntity> {
        return NSFetchRequest<ProactiveSuggestionEntity>(entityName: "ProactiveSuggestionEntity")
    }

    static func create(context: NSManagedObjectContext, text: String, type: String, priority: Int16 = 5, expiresIn: TimeInterval? = nil, contextData: String? = nil) -> ProactiveSuggestionEntity {
        let suggestion = ProactiveSuggestionEntity(context: context)
        suggestion.id = UUID()
        suggestion.suggestionText = text
        suggestion.suggestionType = type
        suggestion.createdAt = Date()
        suggestion.wasShown = false
        suggestion.priority = priority
        suggestion.contextData = contextData

        if let expiresIn = expiresIn {
            suggestion.expiresAt = Date().addingTimeInterval(expiresIn)
        }

        try? context.save()
        return suggestion
    }

    // Get pending suggestions sorted by priority
    static func getPendingSuggestions(context: NSManagedObjectContext) -> [ProactiveSuggestionEntity] {
        let request: NSFetchRequest<ProactiveSuggestionEntity> = ProactiveSuggestionEntity.fetchRequest()
        request.predicate = NSPredicate(format: "wasShown == NO")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ProactiveSuggestionEntity.priority, ascending: false)]

        return (try? context.fetch(request)) ?? []
    }
}
