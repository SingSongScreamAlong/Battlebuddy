//
//  ReflectionLogView.swift
//  BattleBuddy
//
//  Daily reflection and mood tracking (placeholder for Phase 4)
//

import SwiftUI
import CoreData

struct ReflectionLogView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ReflectionLogEntity.date, ascending: false)],
        animation: .default)
    private var reflections: FetchedResults<ReflectionLogEntity>

    @State private var showingAddReflection = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.bbBackground.ignoresSafeArea()

                if reflections.isEmpty {
                    EmptyReflectionsView()
                } else {
                    List {
                        ForEach(reflections) { reflection in
                            ReflectionRow(reflection: reflection)
                                .listRowBackground(Color.bbCardBackground)
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }

                // Floating add button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            showingAddReflection = true
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
            .navigationTitle("Reflections")
            .sheet(isPresented: $showingAddReflection) {
                AddReflectionSheet(isPresented: $showingAddReflection)
            }
        }
    }
}

// MARK: - Reflection Row
struct ReflectionRow: View {
    @ObservedObject var reflection: ReflectionLogEntity

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(reflection.moodEmoji)
                    .font(.system(size: 32))

                VStack(alignment: .leading, spacing: 4) {
                    Text(reflection.mood.capitalized)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.bbTextPrimary)

                    Text(reflection.date, style: .date)
                        .font(.system(size: 14))
                        .foregroundColor(.bbTextSecondary)
                }

                Spacer()
            }

            if let note = reflection.note, !note.isEmpty {
                Text(note)
                    .font(.system(size: 14))
                    .foregroundColor(.bbTextSecondary)
                    .lineLimit(3)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Empty State
struct EmptyReflectionsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "book")
                .font(.system(size: 64))
                .foregroundColor(.bbSecondary)

            Text("No Reflections Yet")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.bbTextPrimary)

            Text("Start logging your daily reflections")
                .font(.system(size: 16))
                .foregroundColor(.bbTextSecondary)
        }
    }
}

// MARK: - Add Reflection Sheet
struct AddReflectionSheet: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var isPresented: Bool

    @State private var selectedMood = "good"
    @State private var note = ""

    let moods = [
        ("great", "😄", "Great"),
        ("good", "🙂", "Good"),
        ("rough", "😕", "Rough"),
        ("tough", "😓", "Tough")
    ]

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("How was your day?")) {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(moods, id: \.0) { mood in
                            MoodButton(
                                emoji: mood.1,
                                label: mood.2,
                                isSelected: selectedMood == mood.0
                            ) {
                                selectedMood = mood.0
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }

                Section(header: Text("Notes (Optional)")) {
                    TextEditor(text: $note)
                        .frame(minHeight: 100)
                        .foregroundColor(.bbTextPrimary)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.bbBackground)
            .navigationTitle("Daily Reflection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveReflection()
                    }
                }
            }
        }
    }

    private func saveReflection() {
        let reflection = ReflectionLogEntity(
            context: viewContext,
            mood: selectedMood,
            note: note.isEmpty ? nil : note
        )

        PersistenceController.shared.save()
        isPresented = false
    }
}

// MARK: - Mood Button
struct MoodButton: View {
    let emoji: String
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(emoji)
                    .font(.system(size: 40))

                Text(label)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isSelected ? .white : .bbTextSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? Color.bbAccent : Color.bbCardBackground)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ReflectionLogView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
