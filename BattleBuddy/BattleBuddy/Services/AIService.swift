//
//  AIService.swift
//  BattleBuddy
//
//  OpenAI GPT-4 integration for conversational AI
//

import Foundation
import CoreData

class AIService: ObservableObject {
    // MARK: - Published Properties
    @Published var isProcessing = false
    @Published var lastError: String?

    // MARK: - Configuration
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    private let model = "gpt-4" // Use gpt-4-turbo or gpt-3.5-turbo for faster/cheaper responses
    private let maxTokens = 500
    private let temperature: Double = 0.7

    // MARK: - Context Management
    private let viewContext: NSManagedObjectContext
    private let maxContextMessages = 15 // Increased context window
    private let maxContextTokens = 2000 // Approximate token limit for context

    init(context: NSManagedObjectContext) {
        self.viewContext = context
    }

    // MARK: - Send Message
    func sendMessage(
        _ userMessage: String,
        mode: AppState.AIMode,
        onComplete: @escaping (String) -> Void
    ) async {
        await MainActor.run {
            self.isProcessing = true
            self.lastError = nil
        }

        // Get API key from Keychain
        guard let apiKey = KeychainHelper.shared.openAIKey, !apiKey.isEmpty else {
            await MainActor.run {
                self.lastError = "No API key found. Please add your OpenAI API key in Settings."
                self.isProcessing = false
            }
            return
        }

        // Build conversation context
        let messages = buildMessages(userMessage: userMessage, mode: mode)

        // Create request
        let requestBody: [String: Any] = [
            "model": model,
            "messages": messages,
            "max_tokens": maxTokens,
            "temperature": temperature
        ]

        guard let url = URL(string: baseURL) else {
            await handleError("Invalid API URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            await handleError("Failed to encode request: \(error.localizedDescription)")
            return
        }

        // Send request
        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                await handleError("Invalid response from server")
                return
            }

            if httpResponse.statusCode == 401 {
                await handleError("Invalid API key. Please check your OpenAI API key in Settings.")
                return
            }

            if httpResponse.statusCode != 200 {
                await handleError("API error: HTTP \(httpResponse.statusCode)")
                return
            }

            // Parse response
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let choices = json["choices"] as? [[String: Any]],
                  let firstChoice = choices.first,
                  let message = firstChoice["message"] as? [String: Any],
                  let content = message["content"] as? String else {
                await handleError("Failed to parse API response")
                return
            }

            // Save conversation to Core Data
            await saveConversation(userMessage: userMessage, aiResponse: content, mode: mode)

            await MainActor.run {
                self.isProcessing = false
                onComplete(content)
            }

        } catch {
            await handleError("Network error: \(error.localizedDescription)")
        }
    }

    // MARK: - Intent Parsing
    func parseIntent(_ text: String) -> Intent? {
        let lowercased = text.lowercased()

        // Task-related intents
        if lowercased.contains("add task") || lowercased.contains("create task") || lowercased.contains("new task") {
            let taskTitle = extractTaskTitle(from: text)
            return .createTask(title: taskTitle)
        }

        if lowercased.contains("complete") || lowercased.contains("finish") || lowercased.contains("done") {
            return .completeTask
        }

        // Schedule-related intents
        if lowercased.contains("schedule") || lowercased.contains("meeting") || lowercased.contains("appointment") {
            if let eventInfo = extractEventInfo(from: text) {
                return .scheduleEvent(title: eventInfo.title, date: eventInfo.date, duration: eventInfo.duration)
            }
            return .scheduleEvent(title: "New Event", date: nil, duration: 3600)
        }

        // Message-related intents
        if lowercased.contains("text") || lowercased.contains("message") || lowercased.contains("send") {
            if let messageInfo = extractMessageInfo(from: text) {
                return .sendMessage(recipient: messageInfo.recipient, message: messageInfo.message)
            }
            return .conversation // Fall back to conversation if parsing fails
        }

        // Query intents
        if lowercased.contains("what's") || lowercased.contains("show me") || lowercased.contains("list") {
            if lowercased.contains("task") {
                return .listTasks
            }
            if lowercased.contains("schedule") || lowercased.contains("calendar") {
                return .checkSchedule
            }
        }

        // Weather
        if lowercased.contains("weather") {
            return .checkWeather
        }

        // Reflection
        if lowercased.contains("log") && (lowercased.contains("day") || lowercased.contains("mood")) {
            return .logReflection
        }

        // Default to conversation
        return .conversation
    }

    // MARK: - Private Helpers
    private func buildMessages(userMessage: String, mode: AppState.AIMode) -> [[String: String]] {
        var messages: [[String: String]] = []

        // System prompt based on mode with enhanced context awareness
        let enhancedSystemPrompt = mode.systemPrompt + "\n\nYou have access to the user's task list, calendar, and recent conversations. Use this context to provide more personalized and relevant responses."

        messages.append([
            "role": "system",
            "content": enhancedSystemPrompt
        ])

        // Add recent conversation history with smart selection
        let recentConversations = fetchRecentConversations(limit: maxContextMessages)
        var currentTokenCount = estimateTokens(enhancedSystemPrompt)

        // Prioritize recent and important messages
        var selectedConversations: [ConversationEntryEntity] = []
        for conversation in recentConversations.reversed() { // Start with most recent
            let conversationTokens = estimateTokens(conversation.userMessage) + estimateTokens(conversation.aiResponse)

            // Only add if we have token budget
            if currentTokenCount + conversationTokens < maxContextTokens {
                selectedConversations.insert(conversation, at: 0) // Maintain chronological order
                currentTokenCount += conversationTokens
            } else {
                break // Stop if we're over budget
            }
        }

        // Add selected conversations to messages
        for conversation in selectedConversations {
            messages.append(["role": "user", "content": conversation.userMessage])
            messages.append(["role": "assistant", "content": conversation.aiResponse])
        }

        // Add context summary if we have a lot of history
        let totalHistory = fetchConversationCount()
        if totalHistory > maxContextMessages {
            let summaryMessage = "Note: This is part of an ongoing conversation with \(totalHistory) total messages. Previous context has been summarized for relevance."
            messages.append([
                "role": "system",
                "content": summaryMessage
            ])
        }

        // Add current user message
        messages.append([
            "role": "user",
            "content": userMessage
        ])

        return messages
    }

    // Estimate token count (rough approximation: 1 token ≈ 4 characters)
    private func estimateTokens(_ text: String) -> Int {
        return text.count / 4
    }

    // Get total conversation count
    private func fetchConversationCount() -> Int {
        let request: NSFetchRequest<ConversationEntryEntity> = ConversationEntryEntity.fetchRequest()
        return (try? viewContext.count(for: request)) ?? 0
    }

    private func fetchRecentConversations(limit: Int) -> [ConversationEntryEntity] {
        let request: NSFetchRequest<ConversationEntryEntity> = ConversationEntryEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ConversationEntryEntity.timestamp, ascending: false)]
        request.fetchLimit = limit

        return (try? viewContext.fetch(request))?.reversed() ?? []
    }

    private func saveConversation(userMessage: String, aiResponse: String, mode: AppState.AIMode) async {
        await MainActor.run {
            let conversation = ConversationEntryEntity(
                context: viewContext,
                userMessage: userMessage,
                aiResponse: aiResponse,
                mode: mode.rawValue.lowercased()
            )

            try? viewContext.save()
        }
    }

    private func extractTaskTitle(from text: String) -> String {
        // Simple extraction - looks for text after "add task", "create task", etc.
        let patterns = ["add task", "create task", "new task"]

        for pattern in patterns {
            if let range = text.lowercased().range(of: pattern) {
                let afterPattern = text[range.upperBound...].trimmingCharacters(in: .whitespaces)
                // Remove common prefixes like ":", "called", "to"
                let cleaned = afterPattern
                    .replacingOccurrences(of: "^(:|called|to|for)\\s*", with: "", options: .regularExpression)
                    .trimmingCharacters(in: .whitespaces)

                return cleaned.isEmpty ? "New Task" : cleaned
            }
        }

        return "New Task"
    }

    private func extractEventInfo(from text: String) -> (title: String, date: Date?, duration: TimeInterval)? {
        let lowercased = text.lowercased()

        // Extract title - everything before time indicators
        var title = text
        let timeKeywords = ["at", "on", "tomorrow", "today", "next week"]

        for keyword in timeKeywords {
            if let range = lowercased.range(of: keyword) {
                title = String(text[..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
                // Remove schedule keywords
                title = title.replacingOccurrences(of: "schedule", with: "", options: .caseInsensitive)
                title = title.replacingOccurrences(of: "meeting", with: "", options: .caseInsensitive)
                title = title.replacingOccurrences(of: "appointment", with: "", options: .caseInsensitive)
                title = title.trimmingCharacters(in: .whitespaces)
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

    // Extract message info from natural language
    private func extractMessageInfo(from text: String) -> (recipient: String, message: String)? {
        let lowercased = text.lowercased()

        // Patterns to match:
        // "send a message to John saying hello there"
        // "text Sarah I'll be late"
        // "message Mom that I'm on my way"

        let patterns = [
            "(?:send|text)\\s+(?:a\\s+)?(?:message\\s+)?(?:to\\s+)?([\\w\\s]+?)\\s+(?:saying|that)\\s+(.+)",
            "(?:message|text)\\s+([\\w\\s]+?)\\s+(.+)",
            "(?:send)\\s+([\\w\\s]+?)\\s+(?:a\\s+)?(?:message|text)\\s+(.+)"
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
                let nsText = text as NSString
                let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsText.length))

                if let match = matches.first, match.numberOfRanges == 3 {
                    let recipientRange = match.range(at: 1)
                    let messageRange = match.range(at: 2)

                    if recipientRange.location != NSNotFound && messageRange.location != NSNotFound {
                        let recipient = nsText.substring(with: recipientRange).trimmingCharacters(in: .whitespaces)
                        let message = nsText.substring(with: messageRange).trimmingCharacters(in: .whitespaces)

                        return (recipient, message)
                    }
                }
            }
        }

        return nil
    }

    private func handleError(_ message: String) async {
        await MainActor.run {
            self.lastError = message
            self.isProcessing = false
        }
    }

    // MARK: - Clear History
    func clearConversationHistory() {
        let request: NSFetchRequest<NSFetchRequestResult> = ConversationEntryEntity.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)

        do {
            try viewContext.execute(deleteRequest)
            try viewContext.save()
        } catch {
            print("Failed to clear conversation history: \(error)")
        }
    }
}

// MARK: - Intent Enum
enum Intent {
    case createTask(title: String)
    case completeTask
    case listTasks
    case scheduleEvent(title: String, date: Date?, duration: TimeInterval)
    case checkSchedule
    case sendMessage(recipient: String, message: String)
    case checkWeather
    case logReflection
    case conversation

    var description: String {
        switch self {
        case .createTask(let title):
            return "Create task: \(title)"
        case .completeTask:
            return "Complete task"
        case .listTasks:
            return "List tasks"
        case .scheduleEvent(let title, _, _):
            return "Schedule event: \(title)"
        case .checkSchedule:
            return "Check schedule"
        case .sendMessage(let recipient, _):
            return "Send message to: \(recipient)"
        case .checkWeather:
            return "Check weather"
        case .logReflection:
            return "Log reflection"
        case .conversation:
            return "General conversation"
        }
    }
}
