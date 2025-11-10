//
//  OnboardingView.swift
//  BattleBuddy
//
//  Phase 6: Interactive onboarding with voice command guide
//

import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) var dismiss
    @State private var currentPage = 0
    @FetchRequest(sortDescriptors: []) private var userProfile: FetchedResults<UserProfileEntity>
    @Environment(\.managedObjectContext) private var viewContext

    let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "Welcome to BattleBuddy",
            description: "Your AI tactical companion for daily life. Let me be your wingman for productivity, planning, and personal growth.",
            icon: "person.2.fill",
            color: .blue
        ),
        OnboardingPage(
            title: "Voice-First Interface",
            description: "Tap and hold the mic button to speak. I understand natural language - just talk to me like a friend.",
            icon: "mic.fill",
            color: .green
        ),
        OnboardingPage(
            title: "Voice Commands",
            description: "Try these:\n• 'Add task buy groceries'\n• 'Schedule meeting tomorrow at 3pm'\n• 'What's on my schedule?'\n• 'Text Sarah I'll be late'",
            icon: "waveform",
            color: .purple
        ),
        OnboardingPage(
            title: "Three AI Modes",
            description: "Operator (concise), Companion (supportive), or Strategist (analytical). Switch anytime in Settings.",
            icon: "brain.head.profile",
            color: .orange
        ),
        OnboardingPage(
            title: "I Learn & Adapt",
            description: "I remember your preferences, track your goals, and adapt to your mood. The more we talk, the better I understand you.",
            icon: "sparkles",
            color: .pink
        ),
        OnboardingPage(
            title: "Setup Required",
            description: "You'll need an OpenAI API key to use the AI features. Get one from platform.openai.com (it's free to start).",
            icon: "key.fill",
            color: .yellow
        )
    ]

    var body: some View {
        ZStack {
            Color.battleBackground.ignoresSafeArea()

            VStack(spacing: 30) {
                // Page indicator
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? Color.accentBlue : Color.secondaryGray)
                            .frame(width: 8, height: 8)
                            .animation(.spring(), value: currentPage)
                    }
                }
                .padding(.top, 50)

                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Navigation buttons
                HStack(spacing: 20) {
                    if currentPage > 0 {
                        Button(action: { withAnimation { currentPage -= 1 } }) {
                            Text("Back")
                                .font(.headline)
                                .foregroundColor(.secondaryGray)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.cardBackground)
                                .cornerRadius(12)
                        }
                    }

                    Button(action: {
                        if currentPage < pages.count - 1 {
                            withAnimation { currentPage += 1 }
                        } else {
                            completeOnboarding()
                        }
                    }) {
                        Text(currentPage == pages.count - 1 ? "Get Started" : "Next")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentBlue)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 50)
            }
        }
    }

    private func completeOnboarding() {
        let profile = UserProfileEntity.fetchOrCreate(context: viewContext)
        profile.onboardingCompleted = true
        try? viewContext.save()
        dismiss()
    }
}

struct OnboardingPage {
    let title: String
    let description: String
    let icon: String
    let color: Color
}

struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: page.icon)
                .font(.system(size: 80))
                .foregroundColor(page.color)
                .shadow(color: page.color.opacity(0.3), radius: 20)

            Text(page.title)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.textPrimary)
                .multilineTextAlignment(.center)

            Text(page.description)
                .font(.system(size: 18))
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .padding(.horizontal, 40)
        }
    }
}

#Preview {
    OnboardingView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
