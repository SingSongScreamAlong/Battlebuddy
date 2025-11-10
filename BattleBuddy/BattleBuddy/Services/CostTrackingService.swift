//
//  CostTrackingService.swift
//  BattleBuddy
//
//  Phase 6: API usage and cost monitoring
//  Tracks OpenAI and OpenWeather API usage with cost estimates
//

import Foundation
import CoreData

class CostTrackingService: ObservableObject {
    private let context: NSManagedObjectContext

    // OpenAI GPT-4 pricing (as of 2024)
    private let gpt4InputPricePerToken = 0.03 / 1000  // $0.03 per 1K tokens
    private let gpt4OutputPricePerToken = 0.06 / 1000 // $0.06 per 1K tokens

    // OpenWeather API is free up to 1000 calls/day
    private let weatherCallCost = 0.0

    @Published var monthlySpend: Double = 0.0
    @Published var todaySpend: Double = 0.0
    @Published var budgetRemaining: Double = 0.0

    init(context: NSManagedObjectContext) {
        self.context = context
        updateSpendingSummary()
    }

    // MARK: - Cost Tracking

    /// Track an API call
    func trackAPICall(service: String, tokensUsed: Int, isInput: Bool = true, requestType: String, success: Bool = true) {
        let cost = calculateCost(service: service, tokens: tokensUsed, isInput: isInput)

        _ = CostTrackingEntity.track(
            context: context,
            serviceType: service,
            tokensUsed: tokensUsed,
            cost: cost,
            requestType: requestType,
            success: success
        )

        updateSpendingSummary()
    }

    /// Calculate cost based on service and tokens
    private func calculateCost(service: String, tokens: Int, isInput: Bool) -> Double {
        switch service.lowercased() {
        case "openai", "gpt-4":
            let pricePerToken = isInput ? gpt4InputPricePerToken : gpt4OutputPricePerToken
            return Double(tokens) * pricePerToken

        case "openweather", "weather":
            return weatherCallCost

        default:
            return 0.0
        }
    }

    /// Update spending summary
    func updateSpendingSummary() {
        let calendar = Calendar.current
        let now = Date()

        // Today's spending
        let startOfDay = calendar.startOfDay(for: now)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? now
        todaySpend = CostTrackingEntity.totalCost(context: context, from: startOfDay, to: endOfDay)

        // Monthly spending
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
        let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth) ?? now
        monthlySpend = CostTrackingEntity.totalCost(context: context, from: startOfMonth, to: endOfMonth)

        // Budget remaining
        let profile = UserProfileEntity.fetchOrCreate(context: context)
        budgetRemaining = profile.monthlyBudget - monthlySpend
    }

    // MARK: - Statistics

    /// Get spending by date range
    func getSpending(from startDate: Date, to endDate: Date) -> Double {
        return CostTrackingEntity.totalCost(context: context, from: startDate, to: endDate)
    }

    /// Get token usage by date range
    func getTokens(from startDate: Date, to endDate: Date) -> Int {
        return CostTrackingEntity.totalTokens(context: context, from: startDate, to: endDate)
    }

    /// Get daily spending for last 30 days
    func getDailySpending() -> [(date: Date, cost: Double)] {
        let calendar = Calendar.current
        let now = Date()
        var results: [(date: Date, cost: Double)] = []

        for daysAgo in 0..<30 {
            let targetDate = calendar.date(byAdding: .day, value: -daysAgo, to: now) ?? now
            let startOfDay = calendar.startOfDay(for: targetDate)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? targetDate

            let cost = getSpending(from: startOfDay, to: endOfDay)
            results.append((startOfDay, cost))
        }

        return results.reversed()
    }

    /// Get spending breakdown by service
    func getSpendingByService() -> [String: Double] {
        let request: NSFetchRequest<CostTrackingEntity> = CostTrackingEntity.fetchRequest()
        guard let records = try? context.fetch(request) else { return [:] }

        var breakdown: [String: Double] = [:]
        for record in records {
            breakdown[record.serviceType, default: 0.0] += record.estimatedCost
        }

        return breakdown
    }

    /// Get request type breakdown
    func getRequestTypeBreakdown() -> [String: Int] {
        let request: NSFetchRequest<CostTrackingEntity> = CostTrackingEntity.fetchRequest()
        guard let records = try? context.fetch(request) else { return [:] }

        var breakdown: [String: Int] = [:]
        for record in records {
            breakdown[record.requestType, default: 0] += 1
        }

        return breakdown
    }

    /// Get success rate
    func getSuccessRate() -> Double {
        let allRequest: NSFetchRequest<CostTrackingEntity> = CostTrackingEntity.fetchRequest()
        let total = (try? context.count(for: allRequest)) ?? 0

        let successRequest: NSFetchRequest<CostTrackingEntity> = CostTrackingEntity.fetchRequest()
        successRequest.predicate = NSPredicate(format: "success == YES")
        let successful = (try? context.count(for: successRequest)) ?? 0

        guard total > 0 else { return 0 }
        return Double(successful) / Double(total) * 100
    }

    // MARK: - Budget Management

    /// Check if over budget
    func isOverBudget() -> Bool {
        return budgetRemaining < 0
    }

    /// Check if approaching budget (80% threshold)
    func isApproachingBudget() -> Bool {
        let profile = UserProfileEntity.fetchOrCreate(context: context)
        return budgetRemaining < (profile.monthlyBudget * 0.2)
    }

    /// Get budget usage percentage
    func getBudgetUsagePercentage() -> Double {
        let profile = UserProfileEntity.fetchOrCreate(context: context)
        guard profile.monthlyBudget > 0 else { return 0 }
        return (monthlySpend / profile.monthlyBudget) * 100
    }

    /// Update monthly budget
    func updateBudget(_ newBudget: Double) {
        let profile = UserProfileEntity.fetchOrCreate(context: context)
        profile.monthlyBudget = newBudget
        try? context.save()
        updateSpendingSummary()
    }

    /// Get projected monthly cost
    func getProjectedMonthlyCost() -> Double {
        let calendar = Calendar.current
        let now = Date()

        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) else {
            return monthlySpend
        }

        let daysInMonth = calendar.range(of: .day, in: .month, for: now)?.count ?? 30
        let currentDay = calendar.component(.day, from: now)

        // Calculate daily average and project
        let dailyAverage = monthlySpend / Double(currentDay)
        return dailyAverage * Double(daysInMonth)
    }

    // MARK: - Insights

    /// Get cost insights and recommendations
    func getInsights() -> [String] {
        var insights: [String] = []

        // Budget insights
        if isOverBudget() {
            insights.append("⚠️ You're over budget by $\(String(format: "%.2f", abs(budgetRemaining)))")
        } else if isApproachingBudget() {
            insights.append("⚡ You're using \(Int(getBudgetUsagePercentage()))% of your monthly budget")
        }

        // Projection insights
        let projected = getProjectedMonthlyCost()
        let profile = UserProfileEntity.fetchOrCreate(context: context)

        if projected > profile.monthlyBudget {
            let overage = projected - profile.monthlyBudget
            insights.append("📊 Projected to exceed budget by $\(String(format: "%.2f", overage)) this month")
        }

        // Usage insights
        let dailySpending = getDailySpending().suffix(7)
        let weeklyAverage = dailySpending.reduce(0.0) { $0 + $1.cost } / Double(dailySpending.count)

        if todaySpend > weeklyAverage * 2 {
            insights.append("📈 Today's spending is higher than usual")
        }

        // Success rate insights
        let successRate = getSuccessRate()
        if successRate < 90 {
            insights.append("⚠️ API success rate is \(Int(successRate))%, check your connection")
        }

        return insights
    }

    /// Get cost-saving tips
    func getCostSavingTips() -> [String] {
        let requestTypes = getRequestTypeBreakdown()
        var tips: [String] = []

        // Analyze request patterns
        let totalRequests = requestTypes.values.reduce(0, +)

        if let conversationRequests = requestTypes["conversation"], totalRequests > 0 {
            let percentage = Double(conversationRequests) / Double(totalRequests) * 100
            if percentage > 60 {
                tips.append("💡 Consider being more concise in conversations to reduce token usage")
            }
        }

        // General tips
        tips.append("💡 Use voice commands for quick tasks instead of long conversations")
        tips.append("💡 Review and delete old conversation history to keep context small")

        if isOverBudget() || isApproachingBudget() {
            tips.append("💡 Consider increasing your monthly budget in Settings")
        }

        return tips
    }

    // MARK: - Data Management

    /// Clear old tracking data (older than 90 days)
    func clearOldData() {
        let ninetyDaysAgo = Date().addingTimeInterval(-90 * 24 * 3600)
        let request: NSFetchRequest<CostTrackingEntity> = CostTrackingEntity.fetchRequest()
        request.predicate = NSPredicate(format: "timestamp < %@", ninetyDaysAgo as NSDate)

        guard let oldRecords = try? context.fetch(request) else { return }

        for record in oldRecords {
            context.delete(record)
        }

        if !oldRecords.isEmpty {
            try? context.save()
            print("🗑️ Cleared \(oldRecords.count) old cost tracking records")
        }
    }
}
