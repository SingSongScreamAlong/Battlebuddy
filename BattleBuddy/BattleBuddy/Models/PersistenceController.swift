//
//  PersistenceController.swift
//  BattleBuddy
//
//  Core Data stack management
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "BattleBuddy")

        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Core Data failed to load: \(error.localizedDescription)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    // Preview helper
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let viewContext = controller.container.viewContext

        // Create sample data for previews
        for i in 0..<5 {
            let task = TaskEntity(context: viewContext)
            task.id = UUID()
            task.title = "Sample Task \(i)"
            task.priority = i < 2 ? "High" : i < 4 ? "Medium" : "Low"
            task.isCompleted = false
            task.createdAt = Date()
        }

        do {
            try viewContext.save()
        } catch {
            fatalError("Failed to create preview data: \(error.localizedDescription)")
        }

        return controller
    }()

    // Save context helper
    func save() {
        let context = container.viewContext

        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                print("Error saving context: \(nsError), \(nsError.userInfo)")
            }
        }
    }
}
