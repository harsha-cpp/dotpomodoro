import SwiftUI
import SwiftData

@main
struct DOTpomodoroApp: App {
    @StateObject private var timer = PomodoroTimer()
    @State private var menuBarTitle = "Pomodoro"
    
    // Initialize global managers
    private let globalHotKeyManager = GlobalHotKeyManager.shared
    private let launchAtLoginManager = LaunchAtLoginManager.shared
    
    // Create a shared model container
    let modelContainer: ModelContainer = {
        let schema = Schema([TaskItem.self, PomodoroSession.self, ProductivityStats.self, TaskCompletion.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    init() {
        // Initialize menu bar title
        _menuBarTitle = State(initialValue: "Pomodoro")
        
        // Initialize global services
        _ = globalHotKeyManager  // This ensures the global hotkey manager is initialized
        _ = launchAtLoginManager // This ensures the launch at login manager is initialized
    }

    var body: some Scene {
        MenuBarExtra(menuBarTitle, systemImage: "timer") {
            MenuBarView()
                .environmentObject(timer)
                .onAppear {
                    // Inject modelContext into timer
                    timer.modelContext = modelContainer.mainContext
                    updateMenuBarTitle()
                    
                    // Clean up old completed tasks on app start
                    cleanupOldTasks()
                }
        }
        .menuBarExtraStyle(.window)
        .modelContainer(modelContainer)
        .onChange(of: timer.timeString) { _, newValue in
            updateMenuBarTitle()
        }
        .onChange(of: timer.isRunning) { _, newValue in
            updateMenuBarTitle()
        }
        .onChange(of: timer.isBreakTime) { _, newValue in
            updateMenuBarTitle()
        }
        
        // Add commands for keyboard shortcuts
        .commands {
            PomodoroCommands()
        }
        
        // Add Settings window for configuration
        Settings {
            AppSettingsView()
                .environmentObject(timer)
        }
    }
    
    // Update the menu bar title based on timer state
    private func updateMenuBarTitle() {
        if timer.isRunning {
            let emoji = timer.sessionTypeEmoji
            menuBarTitle = "\(emoji) \(timer.timeString)"
        } else if timer.isPaused {
            // Show paused indicator
            menuBarTitle = "⏸ \(timer.timeString)"
        } else {
            // Show app name when idle
            menuBarTitle = "Pomodoro"
        }
    }
    
    // Clean up completed tasks older than 24 hours
    private func cleanupOldTasks() {
        let context = modelContainer.mainContext
        let calendar = Calendar.current
        let now = Date()
        let cutoffDate = calendar.date(byAdding: .hour, value: -24, to: now) ?? now
        
        do {
            // Fetch completed tasks older than 24 hours
            let descriptor = FetchDescriptor<TaskItem>(
                predicate: #Predicate<TaskItem> { task in
                    task.isDone && task.completedAt != nil && task.completedAt! < cutoffDate
                }
            )
            
            let oldTasks = try context.fetch(descriptor)
            
            // Delete old completed tasks
            for task in oldTasks {
                context.delete(task)
            }
            
            if !oldTasks.isEmpty {
                try context.save()
                print("Cleaned up \(oldTasks.count) completed tasks older than 24 hours")
            }
        } catch {
            print("Error cleaning up old tasks: \(error)")
        }
    }
}

