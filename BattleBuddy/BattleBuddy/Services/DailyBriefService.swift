//
//  DailyBriefService.swift
//  BattleBuddy
//
//  Generates intelligent daily briefs combining weather, tasks, and calendar
//

import Foundation
import CoreData
import EventKit

class DailyBriefService {
    // MARK: - Properties
    private let viewContext: NSManagedObjectContext
    private let weatherService: WeatherService
    private let calendarService: CalendarService
    private let taskService: TaskService

    init(context: NSManagedObjectContext) {
        self.viewContext = context
        self.weatherService = WeatherService()
        self.calendarService = CalendarService()
        self.taskService = TaskService(context: context)
    }

    // MARK: - Generate Daily Brief
    func generateBrief(for date: Date = Date()) async -> DailyBrief {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date

        // Fetch all data in parallel
        async let weatherData = weatherService.fetchWeather()
        async let events = fetchEvents(from: startOfDay, to: endOfDay)
        async let tasks = fetchTasks()

        let weather = await weatherData
        let upcomingEvents = await events
        let incompleteTasks = await tasks

        // Generate brief components
        let greeting = generateGreeting()
        let weatherSummary = generateWeatherSummary(weather: weather)
        let taskSummary = generateTaskSummary(tasks: incompleteTasks)
        let scheduleSummary = generateScheduleSummary(events: upcomingEvents)
        let motivationalMessage = generateMotivationalMessage()

        return DailyBrief(
            greeting: greeting,
            weatherSummary: weatherSummary,
            taskSummary: taskSummary,
            scheduleSummary: scheduleSummary,
            motivationalMessage: motivationalMessage,
            upcomingEvents: upcomingEvents,
            incompleteTasks: incompleteTasks,
            weather: weather,
            timestamp: Date()
        )
    }

    // MARK: - Generate Brief Text for Notifications
    func generateBriefText() async -> String {
        let brief = await generateBrief()
        return brief.formattedText
    }

    // MARK: - Private Helpers
    private func fetchEvents(from startDate: Date, to endDate: Date) async -> [EKEvent] {
        return await withCheckedContinuation { continuation in
            let events = calendarService.fetchEvents(from: startDate, to: endDate)
            continuation.resume(returning: events)
        }
    }

    private func fetchTasks() async -> [TaskEntity] {
        return await withCheckedContinuation { continuation in
            let tasks = taskService.fetchTasks(completed: false)
            continuation.resume(returning: tasks)
        }
    }

    private func generateGreeting() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        let preferences = UserPreferencesEntity.fetchOrCreate(context: viewContext)
        let name = preferences.userName.isEmpty ? "there" : preferences.userName

        switch hour {
        case 0..<12:
            return "Good morning, \(name)!"
        case 12..<17:
            return "Good afternoon, \(name)!"
        case 17..<21:
            return "Good evening, \(name)!"
        default:
            return "Hello, \(name)!"
        }
    }

    private func generateWeatherSummary(weather: WeatherData?) -> String {
        guard let weather = weather else {
            return "Weather information unavailable"
        }

        let temp = Int(weather.temperature)
        let condition = weather.description

        // Weather advice
        var advice = ""
        if temp < 40 {
            advice = " Bundle up, it's cold out there!"
        } else if temp > 85 {
            advice = " Stay hydrated, it's hot today!"
        } else if weather.condition.lowercased().contains("rain") {
            advice = " Don't forget your umbrella!"
        }

        return "It's \(temp)°F and \(condition) in \(weather.cityName).\(advice)"
    }

    private func generateTaskSummary(tasks: [TaskEntity]) -> String {
        let taskCount = tasks.count

        if taskCount == 0 {
            return "Your task list is clear. Great job!"
        }

        let highPriorityTasks = tasks.filter { $0.priority == "High" }

        if highPriorityTasks.count > 0 {
            let priorityText = highPriorityTasks.count == 1 ? "1 high-priority task" : "\(highPriorityTasks.count) high-priority tasks"
            return "You have \(taskCount) tasks today, including \(priorityText)."
        }

        let taskText = taskCount == 1 ? "1 task" : "\(taskCount) tasks"
        return "You have \(taskText) on your list today."
    }

    private func generateScheduleSummary(events: [EKEvent]) -> String {
        let eventCount = events.count

        if eventCount == 0 {
            return "Your calendar is clear today."
        }

        // Find next event
        let now = Date()
        let upcomingEvents = events.filter { $0.startDate > now }.sorted { $0.startDate < $1.startDate }

        if let nextEvent = upcomingEvents.first {
            let formatter = DateFormatter()
            formatter.timeStyle = .short

            let timeString = formatter.string(from: nextEvent.startDate)
            let eventTitle = nextEvent.title ?? "Untitled event"

            if eventCount == 1 {
                return "You have 1 event today: \(eventTitle) at \(timeString)."
            } else {
                return "You have \(eventCount) events today. Next up: \(eventTitle) at \(timeString)."
            }
        }

        let eventText = eventCount == 1 ? "1 event" : "\(eventCount) events"
        return "You have \(eventText) on your calendar today."
    }

    private func generateMotivationalMessage() -> String {
        let messages = [
            "Let's make today count!",
            "You've got this!",
            "Ready to crush your goals?",
            "Time to execute!",
            "Stay focused and make it happen.",
            "Another day, another victory.",
            "Let's get after it!",
            "Mission ready. Let's go!",
            "Time to dominate the day.",
            "Focus on what matters most."
        ]

        return messages.randomElement() ?? "Have a great day!"
    }
}

// MARK: - Daily Brief Model
struct DailyBrief {
    let greeting: String
    let weatherSummary: String
    let taskSummary: String
    let scheduleSummary: String
    let motivationalMessage: String
    let upcomingEvents: [EKEvent]
    let incompleteTasks: [TaskEntity]
    let weather: WeatherData?
    let timestamp: Date

    var formattedText: String {
        """
        \(greeting)

        \(weatherSummary)

        \(scheduleSummary)

        \(taskSummary)

        \(motivationalMessage)
        """
    }

    var hasContent: Bool {
        !upcomingEvents.isEmpty || !incompleteTasks.isEmpty || weather != nil
    }
}
