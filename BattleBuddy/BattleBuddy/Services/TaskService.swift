//
//  TaskService.swift
//  BattleBuddy
//
//  Service layer for task management operations
//

import Foundation
import CoreData

class TaskService: ObservableObject {
    private let viewContext: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.viewContext = context
    }

    // MARK: - Create
    func createTask(title: String, priority: String = "Medium", dueDate: Date? = nil) -> TaskEntity {
        let task = TaskEntity(context: viewContext, title: title, priority: priority, dueDate: dueDate)
        save()
        return task
    }

    // MARK: - Read
    func fetchTasks(completed: Bool? = nil) -> [TaskEntity] {
        let request: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()

        if let completed = completed {
            request.predicate = NSPredicate(format: "isCompleted == %@", NSNumber(value: completed))
        }

        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \TaskEntity.isCompleted, ascending: true),
            NSSortDescriptor(keyPath: \TaskEntity.createdAt, ascending: false)
        ]

        return (try? viewContext.fetch(request)) ?? []
    }

    func fetchTasksByPriority(_ priority: String, completed: Bool = false) -> [TaskEntity] {
        let request: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
        request.predicate = NSPredicate(format: "priority == %@ AND isCompleted == %@", priority, NSNumber(value: completed))
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TaskEntity.createdAt, ascending: false)]

        return (try? viewContext.fetch(request)) ?? []
    }

    // MARK: - Update
    func toggleCompletion(_ task: TaskEntity) {
        task.isCompleted.toggle()
        save()
    }

    func updateTask(_ task: TaskEntity, title: String? = nil, priority: String? = nil, dueDate: Date? = nil) {
        if let title = title { task.title = title }
        if let priority = priority { task.priority = priority }
        if let dueDate = dueDate { task.dueDate = dueDate }
        save()
    }

    // MARK: - Delete
    func deleteTask(_ task: TaskEntity) {
        viewContext.delete(task)
        save()
    }

    func deleteCompletedTasks() {
        let tasks = fetchTasks(completed: true)
        tasks.forEach { viewContext.delete($0) }
        save()
    }

    // MARK: - Statistics
    func taskCount(completed: Bool? = nil) -> Int {
        let request: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()

        if let completed = completed {
            request.predicate = NSPredicate(format: "isCompleted == %@", NSNumber(value: completed))
        }

        return (try? viewContext.count(for: request)) ?? 0
    }

    // MARK: - Private
    private func save() {
        if viewContext.hasChanges {
            try? viewContext.save()
        }
    }
}

extension TaskEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<TaskEntity> {
        return NSFetchRequest<TaskEntity>(entityName: "TaskEntity")
    }
}
