//
//  MessageService.swift
//  BattleBuddy
//
//  iMessage integration for sending texts via voice commands
//

import Foundation
import MessageUI
import Contacts
import Combine

class MessageService: NSObject, ObservableObject {
    // MARK: - Published Properties
    @Published var canSendMessages = false
    @Published var lastError: String?

    // MARK: - Contact Store
    private let contactStore = CNContactStore()

    override init() {
        super.init()
        checkMessagingAvailability()
    }

    // MARK: - Check Availability
    func checkMessagingAvailability() {
        canSendMessages = MFMessageComposeViewController.canSendText()
    }

    // MARK: - Contact Authorization
    func requestContactsPermission() async -> Bool {
        let status = CNContactStore.authorizationStatus(for: .contacts)

        switch status {
        case .authorized:
            return true
        case .notDetermined:
            return await withCheckedContinuation { continuation in
                contactStore.requestAccess(for: .contacts) { granted, error in
                    if let error = error {
                        print("Contacts permission error: \(error.localizedDescription)")
                    }
                    continuation.resume(returning: granted)
                }
            }
        case .denied, .restricted:
            await MainActor.run {
                self.lastError = "Contacts access is required to send messages. Please enable it in Settings."
            }
            return false
        @unknown default:
            return false
        }
    }

    // MARK: - Find Contact
    func findContact(byName name: String) async -> CNContact? {
        // Ensure we have permission
        guard await requestContactsPermission() else {
            return nil
        }

        let keysToFetch: [CNKeyDescriptor] = [
            CNContactGivenNameKey as CNKeyDescriptor,
            CNContactFamilyNameKey as CNKeyDescriptor,
            CNContactPhoneNumbersKey as CNKeyDescriptor,
            CNContactFormatter.descriptorForRequiredKeys(for: .fullName)
        ]

        let searchName = name.lowercased().trimmingCharacters(in: .whitespaces)

        do {
            let predicate = CNContact.predicateForContacts(matchingName: searchName)
            let contacts = try contactStore.unifiedContacts(matching: predicate, keysToFetch: keysToFetch)

            // Return first match
            return contacts.first
        } catch {
            await MainActor.run {
                self.lastError = "Failed to search contacts: \(error.localizedDescription)"
            }
            return nil
        }
    }

    // MARK: - Get Phone Number
    func getPhoneNumber(for contact: CNContact) -> String? {
        guard let phoneNumber = contact.phoneNumbers.first?.value else {
            return nil
        }
        return phoneNumber.stringValue
    }

    // MARK: - Parse Message Command
    func parseMessageCommand(_ text: String) -> (recipient: String, message: String)? {
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

    // MARK: - Send Message (Returns MessageComposeViewController)
    func createMessageComposer(recipient: String, message: String) async -> MFMessageComposeViewController? {
        guard canSendMessages else {
            await MainActor.run {
                self.lastError = "This device cannot send messages"
            }
            return nil
        }

        // Try to find contact by name
        if let contact = await findContact(byName: recipient),
           let phoneNumber = getPhoneNumber(for: contact) {

            let composer = MFMessageComposeViewController()
            composer.recipients = [phoneNumber]
            composer.body = message

            return composer
        } else {
            // Check if recipient is already a phone number
            let cleanedRecipient = recipient.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
            if cleanedRecipient.count >= 10 {
                let composer = MFMessageComposeViewController()
                composer.recipients = [recipient]
                composer.body = message
                return composer
            } else {
                await MainActor.run {
                    self.lastError = "Could not find contact '\(recipient)'"
                }
                return nil
            }
        }
    }

    // MARK: - Format Message for Display
    func formatMessagePreview(recipient: String, message: String) -> String {
        return "To: \(recipient)\nMessage: \(message)"
    }
}

// MARK: - MFMessageComposeViewControllerDelegate
extension MessageService: MFMessageComposeViewControllerDelegate {
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        controller.dismiss(animated: true)

        switch result {
        case .cancelled:
            print("Message cancelled")
        case .sent:
            print("Message sent successfully")
        case .failed:
            Task { @MainActor in
                self.lastError = "Failed to send message"
            }
        @unknown default:
            break
        }
    }
}
