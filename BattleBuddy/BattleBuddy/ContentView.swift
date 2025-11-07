//
//  ContentView.swift
//  BattleBuddy
//
//  Main navigation container with TabView
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.managedObjectContext) private var viewContext

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

            // Schedule Tab
            ScheduleView()
                .tabItem {
                    Label("Schedule", systemImage: "calendar")
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
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(AppState())
}
