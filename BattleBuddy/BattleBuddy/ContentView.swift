//
//  ContentView.swift
//  BattleBuddy
//
//  Main navigation container with TabView
//  Phase 6: Added Goals, Insights, and Cost tracking
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(sortDescriptors: []) private var userProfile: FetchedResults<UserProfileEntity>
    @State private var showOnboarding = false

    var body: some View {
        TabView {
            // Home Tab
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            // Voice Interface Tab
            VoiceInterfaceView()
                .tabItem {
                    Label("Voice", systemImage: "mic.fill")
                }

            // Tasks Tab
            TaskBoardView()
                .tabItem {
                    Label("Tasks", systemImage: "checkmark.circle.fill")
                }

            // Goals Tab (Phase 6)
            NavigationView {
                GoalDashboardView(context: viewContext)
            }
            .tabItem {
                Label("Goals", systemImage: "target")
            }

            // Schedule Tab
            ScheduleView()
                .tabItem {
                    Label("Schedule", systemImage: "calendar")
                }

            // Insights Tab (Phase 6)
            NavigationView {
                InsightsView(context: viewContext)
            }
            .tabItem {
                Label("Insights", systemImage: "chart.line.uptrend.xyaxis")
            }

            // Reflection Tab
            ReflectionLogView()
                .tabItem {
                    Label("Reflect", systemImage: "book.fill")
                }

            // Settings Tab
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .accentColor(appState.currentMode.accentColor)
        .sheet(isPresented: $showOnboarding) {
            OnboardingView()
        }
        .onAppear {
            // Show onboarding on first launch
            if let profile = userProfile.first {
                showOnboarding = !profile.onboardingCompleted
            } else {
                showOnboarding = true
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(AppState())
}
