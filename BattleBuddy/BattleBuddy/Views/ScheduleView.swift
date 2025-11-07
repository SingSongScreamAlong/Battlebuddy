//
//  ScheduleView.swift
//  BattleBuddy
//
//  Calendar integration and event display (placeholder for Phase 3)
//

import SwiftUI

struct ScheduleView: View {
    @State private var selectedDate = Date()

    var body: some View {
        NavigationView {
            ZStack {
                Color.bbBackground.ignoresSafeArea()

                VStack(spacing: 20) {
                    // Calendar picker
                    DatePicker("Select Date", selection: $selectedDate, displayedComponents: [.date])
                        .datePickerStyle(.graphical)
                        .padding()
                        .background(Color.bbCardBackground)
                        .cornerRadius(16)
                        .padding(.horizontal)

                    // Events list placeholder
                    VStack(spacing: 12) {
                        HStack {
                            Text("Events for \(selectedDate, style: .date)")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.bbTextPrimary)

                            Spacer()
                        }
                        .padding(.horizontal)

                        // Placeholder
                        VStack(spacing: 12) {
                            Image(systemName: "calendar.badge.clock")
                                .font(.system(size: 48))
                                .foregroundColor(.bbSecondary)

                            Text("Calendar Integration Coming Soon")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.bbTextPrimary)

                            Text("Phase 3 will add EventKit integration")
                                .font(.system(size: 14))
                                .foregroundColor(.bbTextSecondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.bbCardBackground)
                        .cornerRadius(16)
                        .padding(.horizontal)
                    }

                    Spacer()
                }
                .padding(.top)
            }
            .navigationTitle("Schedule")
        }
    }
}

#Preview {
    ScheduleView()
}
