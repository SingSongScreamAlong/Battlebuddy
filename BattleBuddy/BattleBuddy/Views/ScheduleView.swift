//
//  ScheduleView.swift
//  BattleBuddy
//
//  Calendar integration with EventKit
//

import SwiftUI
import EventKit

struct ScheduleView: View {
    @StateObject private var calendarService = CalendarService()
    @State private var selectedDate = Date()
    @State private var showingAddEvent = false
    @State private var showPermissionRequest = false
    @State private var events: [EKEvent] = []

    var body: some View {
        NavigationView {
            ZStack {
                Color.bbBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Calendar picker
                    DatePicker("Select Date", selection: $selectedDate, displayedComponents: [.date])
                        .datePickerStyle(.graphical)
                        .padding()
                        .background(Color.bbCardBackground)
                        .cornerRadius(16)
                        .padding()
                        .onChange(of: selectedDate) { _ in
                            loadEvents()
                        }

                    Divider()
                        .background(Color.bbSecondary.opacity(0.3))

                    // Events list
                    if calendarService.authorizationStatus == .authorized {
                        if events.isEmpty {
                            EmptyEventsView(date: selectedDate)
                        } else {
                            ScrollView {
                                VStack(spacing: 12) {
                                    ForEach(events, id: \.eventIdentifier) { event in
                                        EventCard(event: event, onDelete: {
                                            deleteEvent(event)
                                        })
                                    }
                                }
                                .padding()
                            }
                        }
                    } else {
                        CalendarPermissionView {
                            requestPermission()
                        }
                    }
                }

                // Floating add button
                if calendarService.authorizationStatus == .authorized {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button(action: {
                                showingAddEvent = true
                            }) {
                                Image(systemName: "plus")
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(width: 60, height: 60)
                                    .background(Color.bbAccent)
                                    .clipShape(Circle())
                                    .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                            .padding(.trailing, 20)
                            .padding(.bottom, 20)
                        }
                    }
                }
            }
            .navigationTitle("Schedule")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            selectedDate = Date()
                            loadEvents()
                        }) {
                            Label("Today", systemImage: "calendar")
                        }

                        Button(action: {
                            loadEvents()
                        }) {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.bbAccent)
                    }
                }
            }
            .sheet(isPresented: $showingAddEvent) {
                AddEventSheet(
                    isPresented: $showingAddEvent,
                    calendarService: calendarService,
                    selectedDate: selectedDate,
                    onEventCreated: {
                        loadEvents()
                    }
                )
            }
            .onAppear {
                checkPermissionAndLoadEvents()
            }
        }
    }

    private func checkPermissionAndLoadEvents() {
        if calendarService.authorizationStatus == .authorized {
            loadEvents()
        } else if calendarService.authorizationStatus == .notDetermined {
            requestPermission()
        }
    }

    private func requestPermission() {
        Task {
            let granted = await calendarService.requestAccess()
            if granted {
                await MainActor.run {
                    loadEvents()
                }
            }
        }
    }

    private func loadEvents() {
        let startOfDay = Calendar.current.startOfDay(for: selectedDate)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay) ?? selectedDate

        events = calendarService.fetchEvents(from: startOfDay, to: endOfDay)
    }

    private func deleteEvent(_ event: EKEvent) {
        Task {
            let success = await calendarService.deleteEvent(event)
            if success {
                await MainActor.run {
                    loadEvents()
                }
            }
        }
    }
}

// MARK: - Event Card
struct EventCard: View {
    let event: EKEvent
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Time indicator
            VStack(alignment: .leading, spacing: 4) {
                if let startDate = event.startDate {
                    Text(startDate, style: .time)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.bbAccent)

                    if let endDate = event.endDate {
                        Text(endDate, style: .time)
                            .font(.system(size: 12))
                            .foregroundColor(.bbTextSecondary)
                    }
                }
            }
            .frame(width: 60, alignment: .leading)

            Divider()
                .frame(height: 40)
                .background(Color.bbSecondary.opacity(0.3))

            // Event details
            VStack(alignment: .leading, spacing: 6) {
                Text(event.title ?? "Untitled Event")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.bbTextPrimary)

                if let location = event.location, !location.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 11))
                        Text(location)
                            .font(.system(size: 13))
                    }
                    .foregroundColor(.bbTextSecondary)
                }

                if let calendar = event.calendar {
                    Text(calendar.title)
                        .font(.system(size: 12))
                        .foregroundColor(Color(cgColor: calendar.cgColor))
                }
            }

            Spacer()

            // Conflict indicator (if needed)
            if hasConflict(event) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.bbWarning)
                    .font(.system(size: 16))
            }
        }
        .padding()
        .background(Color.bbCardBackground)
        .cornerRadius(12)
        .contextMenu {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private func hasConflict(_ event: EKEvent) -> Bool {
        // Simple conflict detection - can be enhanced
        return false
    }
}

// MARK: - Empty State
struct EmptyEventsView: View {
    let date: Date

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar")
                .font(.system(size: 64))
                .foregroundColor(.bbSecondary)

            Text("No Events")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.bbTextPrimary)

            Text("No events scheduled for \(date, style: .date)")
                .font(.system(size: 16))
                .foregroundColor(.bbTextSecondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

// MARK: - Permission View
struct CalendarPermissionView: View {
    let onRequestPermission: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 64))
                .foregroundColor(.bbAccent)

            Text("Calendar Access Required")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.bbTextPrimary)

            Text("BattleBuddy needs access to your calendar to show and manage your events.")
                .font(.system(size: 16))
                .foregroundColor(.bbTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button(action: onRequestPermission) {
                Text("Grant Access")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.bbAccent)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 32)
        }
    }
}

// MARK: - Add Event Sheet
struct AddEventSheet: View {
    @Binding var isPresented: Bool
    let calendarService: CalendarService
    let selectedDate: Date
    let onEventCreated: () -> Void

    @State private var title = ""
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var location = ""
    @State private var notes = ""
    @State private var isCreating = false

    init(isPresented: Binding<Bool>, calendarService: CalendarService, selectedDate: Date, onEventCreated: @escaping () -> Void) {
        self._isPresented = isPresented
        self.calendarService = calendarService
        self.selectedDate = selectedDate
        self.onEventCreated = onEventCreated

        // Initialize dates
        let calendar = Calendar.current
        var startComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        startComponents.hour = 9
        startComponents.minute = 0

        let start = calendar.date(from: startComponents) ?? selectedDate
        _startDate = State(initialValue: start)
        _endDate = State(initialValue: start.addingTimeInterval(3600)) // 1 hour later
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Event Details")) {
                    TextField("Title", text: $title)
                        .foregroundColor(.bbTextPrimary)

                    TextField("Location (Optional)", text: $location)
                        .foregroundColor(.bbTextPrimary)
                }

                Section(header: Text("Time")) {
                    DatePicker("Starts", selection: $startDate)
                        .onChange(of: startDate) { newStart in
                            if endDate <= newStart {
                                endDate = newStart.addingTimeInterval(3600)
                            }
                        }

                    DatePicker("Ends", selection: $endDate)
                }

                Section(header: Text("Notes (Optional)")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                        .foregroundColor(.bbTextPrimary)
                }

                // Conflict warning
                if !conflicts.isEmpty {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.bbWarning)
                                Text("Schedule Conflict")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.bbWarning)
                            }

                            Text("This event overlaps with \(conflicts.count) other event(s)")
                                .font(.system(size: 13))
                                .foregroundColor(.bbTextSecondary)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.bbBackground)
            .navigationTitle("New Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: createEvent) {
                        if isCreating {
                            ProgressView()
                        } else {
                            Text("Add")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(title.isEmpty || isCreating)
                }
            }
        }
    }

    private var conflicts: [EKEvent] {
        calendarService.checkForConflicts(startDate: startDate, endDate: endDate)
    }

    private func createEvent() {
        isCreating = true

        Task {
            let success = await calendarService.createEvent(
                title: title,
                startDate: startDate,
                endDate: endDate,
                location: location.isEmpty ? nil : location,
                notes: notes.isEmpty ? nil : notes
            )

            await MainActor.run {
                isCreating = false

                if success {
                    onEventCreated()
                    isPresented = false
                }
            }
        }
    }
}

#Preview {
    ScheduleView()
}
