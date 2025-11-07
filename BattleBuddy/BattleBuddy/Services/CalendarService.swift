//
//  CalendarService.swift
//  BattleBuddy
//
//  EventKit integration for iOS Calendar management
//

import Foundation
import EventKit
import SwiftUI

class CalendarService: ObservableObject {
    // MARK: - Published Properties
    @Published var authorizationStatus: EKAuthorizationStatus = .notDetermined
    @Published var events: [EKEvent] = []
    @Published var lastError: String?

    // MARK: - EventKit
    private let eventStore = EKEventStore()

    // MARK: - Initialization
    init() {
        checkAuthorizationStatus()
    }

    // MARK: - Authorization
    func checkAuthorizationStatus() {
        authorizationStatus = EKEventStore.authorizationStatus(for: .event)
    }

    func requestAccess() async -> Bool {
        do {
            let granted = try await eventStore.requestAccess(to: .event)
            await MainActor.run {
                self.authorizationStatus = granted ? .authorized : .denied
            }
            return granted
        } catch {
            await MainActor.run {
                self.lastError = "Failed to request calendar access: \(error.localizedDescription)"
                self.authorizationStatus = .denied
            }
            return false
        }
    }

    // MARK: - Fetch Events
    func fetchEvents(from startDate: Date, to endDate: Date) -> [EKEvent] {
        guard authorizationStatus == .authorized else {
            lastError = "Calendar access not authorized"
            return []
        }

        let calendars = eventStore.calendars(for: .event)
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: calendars)

        let fetchedEvents = eventStore.events(matching: predicate)

        DispatchQueue.main.async {
            self.events = fetchedEvents
        }

        return fetchedEvents
    }

    func fetchEventsForToday() -> [EKEvent] {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay) ?? Date()

        return fetchEvents(from: startOfDay, to: endOfDay)
    }

    func fetchEventsForWeek() -> [EKEvent] {
        let startOfWeek = Calendar.current.startOfDay(for: Date())
        let endOfWeek = Calendar.current.date(byAdding: .day, value: 7, to: startOfWeek) ?? Date()

        return fetchEvents(from: startOfWeek, to: endOfWeek)
    }

    // MARK: - Create Event
    func createEvent(
        title: String,
        startDate: Date,
        endDate: Date,
        location: String? = nil,
        notes: String? = nil,
        calendar: EKCalendar? = nil
    ) async -> Bool {
        guard authorizationStatus == .authorized else {
            await MainActor.run {
                self.lastError = "Calendar access not authorized"
            }
            return false
        }

        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.startDate = startDate
        event.endDate = endDate
        event.location = location
        event.notes = notes
        event.calendar = calendar ?? eventStore.defaultCalendarForNewEvents

        do {
            try eventStore.save(event, span: .thisEvent)

            // Refresh events
            await MainActor.run {
                _ = self.fetchEventsForToday()
            }

            return true
        } catch {
            await MainActor.run {
                self.lastError = "Failed to create event: \(error.localizedDescription)"
            }
            return false
        }
    }

    // MARK: - Update Event
    func updateEvent(_ event: EKEvent) async -> Bool {
        guard authorizationStatus == .authorized else {
            await MainActor.run {
                self.lastError = "Calendar access not authorized"
            }
            return false
        }

        do {
            try eventStore.save(event, span: .thisEvent)

            // Refresh events
            await MainActor.run {
                _ = self.fetchEventsForToday()
            }

            return true
        } catch {
            await MainActor.run {
                self.lastError = "Failed to update event: \(error.localizedDescription)"
            }
            return false
        }
    }

    // MARK: - Delete Event
    func deleteEvent(_ event: EKEvent) async -> Bool {
        guard authorizationStatus == .authorized else {
            await MainActor.run {
                self.lastError = "Calendar access not authorized"
            }
            return false
        }

        do {
            try eventStore.remove(event, span: .thisEvent)

            // Refresh events
            await MainActor.run {
                _ = self.fetchEventsForToday()
            }

            return true
        } catch {
            await MainActor.run {
                self.lastError = "Failed to delete event: \(error.localizedDescription)"
            }
            return false
        }
    }

    // MARK: - Conflict Detection
    func checkForConflicts(startDate: Date, endDate: Date, excludeEvent: EKEvent? = nil) -> [EKEvent] {
        let events = fetchEvents(from: startDate, to: endDate)

        return events.filter { event in
            // Exclude the event being edited
            if let excludeEvent = excludeEvent, event.eventIdentifier == excludeEvent.eventIdentifier {
                return false
            }

            // Check for overlap
            let eventStart = event.startDate ?? Date()
            let eventEnd = event.endDate ?? Date()

            return (startDate < eventEnd && endDate > eventStart)
        }
    }

    // MARK: - Natural Language Parsing
    func parseEventFromText(_ text: String) -> (title: String, date: Date?, duration: TimeInterval)? {
        let lowercased = text.lowercased()

        // Extract title - everything before time indicators
        var title = text
        let timeKeywords = ["at", "on", "tomorrow", "today", "next week"]

        for keyword in timeKeywords {
            if let range = lowercased.range(of: keyword) {
                title = String(text[..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
                break
            }
        }

        // Parse date/time
        var eventDate: Date?
        var duration: TimeInterval = 3600 // Default 1 hour

        // Check for "tomorrow"
        if lowercased.contains("tomorrow") {
            eventDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())
        }

        // Check for "today"
        if lowercased.contains("today") {
            eventDate = Date()
        }

        // Check for specific time (e.g., "at 3pm", "at 15:00")
        let timePatterns = [
            "(at )?(\\d{1,2})(:|\\s)?(\\d{2})?(\\s)?(am|pm)?",
            "(at )?(\\d{1,2})(am|pm)"
        ]

        for pattern in timePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: lowercased, range: NSRange(lowercased.startIndex..., in: lowercased)) {

                // Extract hour
                if let hourRange = Range(match.range(at: 2), in: lowercased),
                   let hour = Int(lowercased[hourRange]) {

                    var adjustedHour = hour

                    // Check for AM/PM
                    if let ampmRange = Range(match.range(at: 6), in: lowercased) {
                        let ampm = String(lowercased[ampmRange])
                        if ampm == "pm" && hour < 12 {
                            adjustedHour += 12
                        } else if ampm == "am" && hour == 12 {
                            adjustedHour = 0
                        }
                    }

                    // Extract minutes if present
                    var minute = 0
                    if let minuteRange = Range(match.range(at: 4), in: lowercased),
                       let min = Int(lowercased[minuteRange]) {
                        minute = min
                    }

                    // Create date with time
                    let calendar = Calendar.current
                    var components = calendar.dateComponents([.year, .month, .day], from: eventDate ?? Date())
                    components.hour = adjustedHour
                    components.minute = minute

                    if let date = calendar.date(from: components) {
                        eventDate = date
                    }
                }

                break
            }
        }

        // Check for duration hints
        if lowercased.contains("30 min") || lowercased.contains("half hour") {
            duration = 1800
        } else if lowercased.contains("2 hour") {
            duration = 7200
        }

        guard !title.isEmpty else { return nil }

        return (title: title, date: eventDate, duration: duration)
    }

    // MARK: - Helpers
    func getDefaultCalendar() -> EKCalendar? {
        return eventStore.defaultCalendarForNewEvents
    }

    func getAvailableCalendars() -> [EKCalendar] {
        return eventStore.calendars(for: .event)
    }
}
