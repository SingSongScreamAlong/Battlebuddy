//
//  NotificationService.swift
//  BattleBuddy
//
//  Local notification management for daily brief and reminders
//

import Foundation
import UserNotifications
import SwiftUI

class NotificationService: ObservableObject {
    // MARK: - Published Properties
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published var isScheduled = false

    // MARK: - Notification Center
    private let notificationCenter = UNUserNotificationCenter.current()

    // MARK: - Notification Identifiers
    enum NotificationIdentifier: String {
        case morningBrief = "com.battlebuddy.morning-brief"
        case eveningReflection = "com.battlebuddy.evening-reflection"
        case taskReminder = "com.battlebuddy.task-reminder"
        case meetingReminder = "com.battlebuddy.meeting-reminder"
        case breakReminder = "com.battlebuddy.break-reminder"
    }

    init() {
        checkAuthorizationStatus()
    }

    // MARK: - Authorization
    func checkAuthorizationStatus() {
        notificationCenter.getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.authorizationStatus = settings.authorizationStatus
            }
        }
    }

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])

            await MainActor.run {
                self.authorizationStatus = granted ? .authorized : .denied
            }

            return granted
        } catch {
            print("Failed to request notification authorization: \(error)")
            return false
        }
    }

    // MARK: - Schedule Morning Brief
    func scheduleMorningBrief(time: Date) async -> Bool {
        guard authorizationStatus == .authorized else {
            print("Notifications not authorized")
            return false
        }

        // Remove existing morning brief notification
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [NotificationIdentifier.morningBrief.rawValue])

        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Good Morning!"
        content.body = "Your daily brief is ready. Tap to see what's ahead today."
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "MORNING_BRIEF"

        // Extract time components
        let components = Calendar.current.dateComponents([.hour, .minute], from: time)

        // Create trigger
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        // Create request
        let request = UNNotificationRequest(
            identifier: NotificationIdentifier.morningBrief.rawValue,
            content: content,
            trigger: trigger
        )

        do {
            try await notificationCenter.add(request)
            await MainActor.run {
                self.isScheduled = true
            }
            return true
        } catch {
            print("Failed to schedule morning brief: \(error)")
            return false
        }
    }

    // MARK: - Schedule Evening Reflection
    func scheduleEveningReflection(time: Date) async -> Bool {
        guard authorizationStatus == .authorized else {
            print("Notifications not authorized")
            return false
        }

        // Remove existing evening reflection notification
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [NotificationIdentifier.eveningReflection.rawValue])

        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Time to Reflect"
        content.body = "How was your day? Take a moment to log your thoughts."
        content.sound = .default
        content.categoryIdentifier = "EVENING_REFLECTION"

        // Extract time components
        let components = Calendar.current.dateComponents([.hour, .minute], from: time)

        // Create trigger
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        // Create request
        let request = UNNotificationRequest(
            identifier: NotificationIdentifier.eveningReflection.rawValue,
            content: content,
            trigger: trigger
        )

        do {
            try await notificationCenter.add(request)
            return true
        } catch {
            print("Failed to schedule evening reflection: \(error)")
            return false
        }
    }

    // MARK: - Schedule Task Reminder
    func scheduleTaskReminder(for task: String, date: Date) async -> Bool {
        guard authorizationStatus == .authorized else { return false }

        let content = UNMutableNotificationContent()
        content.title = "Task Reminder"
        content.body = task
        content.sound = .default
        content.categoryIdentifier = "TASK_REMINDER"

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date),
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "\(NotificationIdentifier.taskReminder.rawValue)-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        do {
            try await notificationCenter.add(request)
            return true
        } catch {
            print("Failed to schedule task reminder: \(error)")
            return false
        }
    }

    // MARK: - Schedule Meeting Reminder
    func scheduleMeetingReminder(for event: String, date: Date, minutesBefore: Int = 15) async -> Bool {
        guard authorizationStatus == .authorized else { return false }

        let reminderDate = Calendar.current.date(byAdding: .minute, value: -minutesBefore, to: date) ?? date

        let content = UNMutableNotificationContent()
        content.title = "Upcoming Meeting"
        content.body = "\(event) in \(minutesBefore) minutes"
        content.sound = .default
        content.categoryIdentifier = "MEETING_REMINDER"

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate),
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "\(NotificationIdentifier.meetingReminder.rawValue)-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        do {
            try await notificationCenter.add(request)
            return true
        } catch {
            print("Failed to schedule meeting reminder: \(error)")
            return false
        }
    }

    // MARK: - Schedule Break Reminder
    func scheduleBreakReminder(after minutes: Int) async -> Bool {
        guard authorizationStatus == .authorized else { return false }

        let content = UNMutableNotificationContent()
        content.title = "Take a Break"
        content.body = "You've been working for \(minutes) minutes. Time to stretch and recharge!"
        content.sound = .default
        content.categoryIdentifier = "BREAK_REMINDER"

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(minutes * 60), repeats: false)

        let request = UNNotificationRequest(
            identifier: "\(NotificationIdentifier.breakReminder.rawValue)-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        do {
            try await notificationCenter.add(request)
            return true
        } catch {
            print("Failed to schedule break reminder: \(error)")
            return false
        }
    }

    // MARK: - Send Immediate Notification
    func sendImmediateNotification(title: String, body: String) async -> Bool {
        guard authorizationStatus == .authorized else { return false }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // Immediate delivery
        )

        do {
            try await notificationCenter.add(request)
            return true
        } catch {
            print("Failed to send immediate notification: \(error)")
            return false
        }
    }

    // MARK: - Cancel Notifications
    func cancelMorningBrief() {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [NotificationIdentifier.morningBrief.rawValue])
    }

    func cancelEveningReflection() {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [NotificationIdentifier.eveningReflection.rawValue])
    }

    func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
    }

    // MARK: - Get Pending Notifications
    func getPendingNotifications() async -> [UNNotificationRequest] {
        return await notificationCenter.pendingNotificationRequests()
    }

    // MARK: - Badge Management
    func setBadgeCount(_ count: Int) {
        UNUserNotificationCenter.current().setBadgeCount(count)
    }

    func clearBadge() {
        setBadgeCount(0)
    }
}
