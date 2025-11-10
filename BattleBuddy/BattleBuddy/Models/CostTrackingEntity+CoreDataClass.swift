//
//  CostTrackingEntity+CoreDataClass.swift
//  BattleBuddy
//
//  Phase 6: API usage and cost monitoring
//

import Foundation
import CoreData

@objc(CostTrackingEntity)
public class CostTrackingEntity: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var timestamp: Date
    @NSManaged public var serviceType: String
    @NSManaged public var tokensUsed: Int32
    @NSManaged public var estimatedCost: Double
    @NSManaged public var requestType: String
    @NSManaged public var success: Bool
}

extension CostTrackingEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CostTrackingEntity> {
        return NSFetchRequest<CostTrackingEntity>(entityName: "CostTrackingEntity")
    }

    static func track(context: NSManagedObjectContext, serviceType: String, tokensUsed: Int, cost: Double, requestType: String, success: Bool) -> CostTrackingEntity {
        let tracking = CostTrackingEntity(context: context)
        tracking.id = UUID()
        tracking.timestamp = Date()
        tracking.serviceType = serviceType
        tracking.tokensUsed = Int32(tokensUsed)
        tracking.estimatedCost = cost
        tracking.requestType = requestType
        tracking.success = success

        try? context.save()
        return tracking
    }

    // Calculate total cost for a date range
    static func totalCost(context: NSManagedObjectContext, from startDate: Date, to endDate: Date) -> Double {
        let request: NSFetchRequest<CostTrackingEntity> = CostTrackingEntity.fetchRequest()
        request.predicate = NSPredicate(format: "timestamp >= %@ AND timestamp <= %@", startDate as NSDate, endDate as NSDate)

        guard let results = try? context.fetch(request) else { return 0 }
        return results.reduce(0) { $0 + $1.estimatedCost }
    }

    // Calculate total tokens for a date range
    static func totalTokens(context: NSManagedObjectContext, from startDate: Date, to endDate: Date) -> Int {
        let request: NSFetchRequest<CostTrackingEntity> = CostTrackingEntity.fetchRequest()
        request.predicate = NSPredicate(format: "timestamp >= %@ AND timestamp <= %@", startDate as NSDate, endDate as NSDate)

        guard let results = try? context.fetch(request) else { return 0 }
        return results.reduce(0) { $0 + Int($1.tokensUsed) }
    }
}
