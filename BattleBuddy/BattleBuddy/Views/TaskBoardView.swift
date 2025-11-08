//
//  TaskBoardView.swift
//  BattleBuddy
//
//  Task management board with CRUD operations
//

import SwiftUI
import CoreData

struct TaskBoardView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \TaskEntity.isCompleted, ascending: true),
            NSSortDescriptor(keyPath: \TaskEntity.createdAt, ascending: false)
        ],
        animation: .default)
    private var tasks: FetchedResults<TaskEntity>

    @State private var showingAddTask = false
    @State private var newTaskTitle = ""
    @State private var selectedPriority = "Medium"

    var body: some View {
        NavigationView {
            ZStack {
                Color.bbBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Task sections
                    if tasks.isEmpty {
                        EmptyTasksView()
                    } else {
                        List {
                            // High priority tasks
                            if !highPriorityTasks.isEmpty {
                                Section(header: Text("High Priority").foregroundColor(.red)) {
                                    ForEach(highPriorityTasks) { task in
                                        TaskRow(task: task)
                                    }
                                }
                            }

                            // Medium priority tasks
                            if !mediumPriorityTasks.isEmpty {
                                Section(header: Text("Medium Priority").foregroundColor(.bbWarning)) {
                                    ForEach(mediumPriorityTasks) { task in
                                        TaskRow(task: task)
                                    }
                                }
                            }

                            // Low priority tasks
                            if !lowPriorityTasks.isEmpty {
                                Section(header: Text("Low Priority").foregroundColor(.bbAccent)) {
                                    ForEach(lowPriorityTasks) { task in
                                        TaskRow(task: task)
                                    }
                                }
                            }

                            // Completed tasks
                            if !completedTasks.isEmpty {
                                Section(header: Text("Completed").foregroundColor(.bbSuccess)) {
                                    ForEach(completedTasks) { task in
                                        TaskRow(task: task)
                                    }
                                }
                            }
                        }
                        .listStyle(.insetGrouped)
                        .scrollContentBackground(.hidden)
                    }
                }

                // Floating add button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            showingAddTask = true
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
            .navigationTitle("Tasks")
            .sheet(isPresented: $showingAddTask) {
                AddTaskSheet(isPresented: $showingAddTask)
            }
        }
    }

    // Task filtering
    private var highPriorityTasks: [TaskEntity] {
        tasks.filter { $0.priority == "High" && !$0.isCompleted }
    }

    private var mediumPriorityTasks: [TaskEntity] {
        tasks.filter { $0.priority == "Medium" && !$0.isCompleted }
    }

    private var lowPriorityTasks: [TaskEntity] {
        tasks.filter { $0.priority == "Low" && !$0.isCompleted }
    }

    private var completedTasks: [TaskEntity] {
        tasks.filter { $0.isCompleted }
    }
}

// MARK: - Task Row
struct TaskRow: View {
    @ObservedObject var task: TaskEntity
    @Environment(\.managedObjectContext) private var viewContext

    var body: some View {
        HStack(spacing: 12) {
            // Complete button
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    task.isCompleted.toggle()
                    PersistenceController.shared.save()
                }
            }) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(task.isCompleted ? .bbSuccess : .bbSecondary)
                    .scaleEffect(task.isCompleted ? 1.0 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: task.isCompleted)
            }
            .buttonStyle(PlainButtonStyle())

            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.bbTextPrimary)
                    .strikethrough(task.isCompleted)
                    .opacity(task.isCompleted ? 0.6 : 1.0)
                    .animation(.easeInOut(duration: 0.3), value: task.isCompleted)

                if let dueDate = task.dueDate {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.system(size: 12))
                        Text(dueDate, style: .date)
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.bbTextSecondary)
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                deleteTask(task)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .listRowBackground(Color.bbCardBackground)
    }

    private func deleteTask(_ task: TaskEntity) {
        withAnimation {
            viewContext.delete(task)
            PersistenceController.shared.save()
        }
    }
}

// MARK: - Empty State
struct EmptyTasksView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 64))
                .foregroundColor(.bbSecondary)

            Text("No Tasks Yet")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.bbTextPrimary)

            Text("Tap the + button to add your first task")
                .font(.system(size: 16))
                .foregroundColor(.bbTextSecondary)
        }
    }
}

// MARK: - Add Task Sheet
struct AddTaskSheet: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var isPresented: Bool

    @State private var title = ""
    @State private var priority = "Medium"
    @State private var hasDueDate = false
    @State private var dueDate = Date()

    let priorities = ["High", "Medium", "Low"]

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Task Details")) {
                    TextField("Task title", text: $title)
                        .foregroundColor(.bbTextPrimary)

                    Picker("Priority", selection: $priority) {
                        ForEach(priorities, id: \.self) { priority in
                            Text(priority).tag(priority)
                        }
                    }
                }

                Section(header: Text("Due Date")) {
                    Toggle("Set due date", isOn: $hasDueDate)

                    if hasDueDate {
                        DatePicker("Due date", selection: $dueDate, displayedComponents: [.date])
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.bbBackground)
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addTask()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }

    private func addTask() {
        let task = TaskEntity(
            context: viewContext,
            title: title,
            priority: priority,
            dueDate: hasDueDate ? dueDate : nil
        )

        PersistenceController.shared.save()
        isPresented = false
    }
}

#Preview {
    TaskBoardView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
