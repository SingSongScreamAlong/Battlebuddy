//
//  CostDashboardView.swift
//  BattleBuddy
//
//  Phase 6: API usage monitoring and budget management
//

import SwiftUI
import CoreData

struct CostDashboardView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var costService: CostTrackingService
    @FetchRequest(sortDescriptors: []) private var userProfile: FetchedResults<UserProfileEntity>
    @State private var showingBudgetSettings = false

    init(context: NSManagedObjectContext) {
        _costService = StateObject(wrappedValue: CostTrackingService(context: context))
    }

    var body: some View {
        ZStack {
            Color.battleBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // Budget overview
                    budgetCard

                    // Spending chart
                    spendingChartCard

                    // Insights
                    insightsCard

                    // Breakdown
                    breakdownCard

                    // Tips
                    tipsCard
                }
                .padding(.vertical)
            }
        }
        .navigationTitle("Cost Tracking")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingBudgetSettings = true }) {
                    Image(systemName: "slider.horizontal.3")
                }
            }
        }
        .sheet(isPresented: $showingBudgetSettings) {
            BudgetSettingsSheet(costService: costService, isPresented: $showingBudgetSettings)
        }
    }

    private var budgetCard: some View {
        VStack(spacing: 16) {
            // Monthly spending
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("This Month")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)

                    Text("$\(costService.monthlySpend, specifier: "%.2f")")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(costService.isOverBudget() ? .red : .textPrimary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Budget")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)

                    if let profile = userProfile.first {
                        Text("$\(profile.monthlyBudget, specifier: "%.2f")")
                            .font(.title3.bold())
                            .foregroundColor(.textSecondary)
                    }
                }
            }

            // Progress bar
            if let profile = userProfile.first {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.secondaryGray.opacity(0.3))
                            .frame(height: 12)

                        Rectangle()
                            .fill(getBudgetColor())
                            .frame(width: min(geometry.size.width, geometry.size.width * CGFloat(costService.monthlySpend / profile.monthlyBudget)), height: 12)
                    }
                    .cornerRadius(6)
                }
                .frame(height: 12)

                HStack {
                    Text("\(Int(costService.getBudgetUsagePercentage()))% used")
                        .font(.caption)
                        .foregroundColor(.textSecondary)

                    Spacer()

                    Text("$\(costService.budgetRemaining, specifier: "%.2f") remaining")
                        .font(.caption)
                        .foregroundColor(costService.isOverBudget() ? .red : .successGreen)
                }
            }

            // Today's spending
            HStack {
                Text("Today")
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)

                Spacer()

                Text("$\(costService.todaySpend, specifier: "%.2f")")
                    .font(.headline)
                    .foregroundColor(.accentBlue)
            }
            .padding(.top, 8)

            // Projected spending
            let projected = costService.getProjectedMonthlyCost()
            HStack {
                Text("Projected End of Month")
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)

                Spacer()

                Text("$\(projected, specifier: "%.2f")")
                    .font(.headline)
                    .foregroundColor(projected > (userProfile.first?.monthlyBudget ?? 0) ? .warningOrange : .textPrimary)
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(16)
        .padding(.horizontal)
    }

    private var spendingChartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Last 30 Days")
                .font(.title3.bold())
                .foregroundColor(.textPrimary)

            let dailySpending = costService.getDailySpending()

            if !dailySpending.isEmpty {
                HStack(alignment: .bottom, spacing: 2) {
                    ForEach(dailySpending.indices, id: \.self) { index in
                        let spending = dailySpending[index]
                        let maxSpending = dailySpending.map { $0.cost }.max() ?? 1.0
                        let height = maxSpending > 0 ? (spending.cost / maxSpending) * 100 : 1.0

                        Rectangle()
                            .fill(Color.accentBlue)
                            .frame(height: max(height, 1))
                            .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 100)

                HStack {
                    Text("30 days ago")
                        .font(.caption2)
                        .foregroundColor(.textSecondary)

                    Spacer()

                    Text("Today")
                        .font(.caption2)
                        .foregroundColor(.textSecondary)
                }
            } else {
                Text("No usage data yet")
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(16)
        .padding(.horizontal)
    }

    private var insightsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Insights")
                .font(.title3.bold())
                .foregroundColor(.textPrimary)

            let insights = costService.getInsights()

            if !insights.isEmpty {
                ForEach(insights, id: \.self) { insight in
                    HStack(alignment: .top, spacing: 8) {
                        Text(insight)
                            .font(.subheadline)
                            .foregroundColor(.textPrimary)

                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            } else {
                Text("✅ You're on track! Keep up the good usage habits.")
                    .font(.subheadline)
                    .foregroundColor(.successGreen)
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(16)
        .padding(.horizontal)
    }

    private var breakdownCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Service Breakdown")
                .font(.title3.bold())
                .foregroundColor(.textPrimary)

            let breakdown = costService.getSpendingByService()

            if !breakdown.isEmpty {
                ForEach(Array(breakdown.keys.sorted()), id: \.self) { service in
                    if let cost = breakdown[service] {
                        HStack {
                            Text(service.capitalized)
                                .font(.subheadline)
                                .foregroundColor(.textPrimary)

                            Spacer()

                            Text("$\(cost, specifier: "%.2f")")
                                .font(.subheadline.bold())
                                .foregroundColor(.accentBlue)
                        }
                        .padding(.vertical, 4)
                    }
                }

                Divider()

                HStack {
                    Text("Success Rate")
                        .font(.subheadline)
                        .foregroundColor(.textPrimary)

                    Spacer()

                    Text("\(Int(costService.getSuccessRate()))%")
                        .font(.subheadline.bold())
                        .foregroundColor(.successGreen)
                }
            } else {
                Text("No usage data yet")
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(16)
        .padding(.horizontal)
    }

    private var tipsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cost-Saving Tips")
                .font(.title3.bold())
                .foregroundColor(.textPrimary)

            let tips = costService.getCostSavingTips()

            ForEach(tips, id: \.self) { tip in
                HStack(alignment: .top, spacing: 8) {
                    Text(tip)
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)

                    Spacer()
                }
                .padding(.vertical, 2)
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(16)
        .padding(.horizontal)
    }

    private func getBudgetColor() -> Color {
        let percentage = costService.getBudgetUsagePercentage()
        if percentage >= 100 {
            return .red
        } else if percentage >= 80 {
            return .warningOrange
        } else {
            return .accentBlue
        }
    }
}

struct BudgetSettingsSheet: View {
    let costService: CostTrackingService
    @Binding var isPresented: Bool
    @FetchRequest(sortDescriptors: []) private var userProfile: FetchedResults<UserProfileEntity>
    @Environment(\.managedObjectContext) private var viewContext
    @State private var budgetAmount: String = ""

    var body: some View {
        NavigationView {
            ZStack {
                Color.battleBackground.ignoresSafeArea()

                Form {
                    Section {
                        HStack {
                            Text("$")
                                .foregroundColor(.textSecondary)

                            TextField("Monthly Budget", text: $budgetAmount)
                                .keyboardType(.decimalPad)
                        }
                    } header: {
                        Text("Monthly Budget")
                    } footer: {
                        Text("Set a monthly spending limit for API usage. You'll get alerts when approaching the limit.")
                    }

                    Section {
                        if let profile = userProfile.first {
                            HStack {
                                Text("Current Budget")
                                Spacer()
                                Text("$\(profile.monthlyBudget, specifier: "%.2f")")
                                    .foregroundColor(.textSecondary)
                            }

                            HStack {
                                Text("This Month's Spend")
                                Spacer()
                                Text("$\(costService.monthlySpend, specifier: "%.2f")")
                                    .foregroundColor(costService.isOverBudget() ? .red : .textSecondary)
                            }
                        }
                    } header: {
                        Text("Current Status")
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Budget Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let budget = Double(budgetAmount), budget > 0 {
                            costService.updateBudget(budget)
                            isPresented = false
                        }
                    }
                    .disabled(budgetAmount.isEmpty)
                }
            }
            .onAppear {
                if let profile = userProfile.first {
                    budgetAmount = String(format: "%.2f", profile.monthlyBudget)
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        CostDashboardView(context: PersistenceController.preview.container.viewContext)
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
