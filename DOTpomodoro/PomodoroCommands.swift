import SwiftUI

struct PomodoroCommands: Commands {
    var body: some Commands {
        // App Menu customization
        CommandGroup(replacing: .appInfo) {
            Button("About DOTpomodoro") {
                NSApplication.shared.orderFrontStandardAboutPanel(nil)
            }
        }
        
        // Main Pomodoro commands
        CommandGroup(after: .appInfo) {
            Divider()
            
            Button("Toggle Timer") {
                NotificationCenter.default.post(name: .toggleTimer, object: nil)
            }
            .keyboardShortcut(" ", modifiers: [])
            
            Button("End Session") {
                NotificationCenter.default.post(name: .endSession, object: nil)
            }
            .keyboardShortcut("s", modifiers: [.shift])
            
            Button("Skip Break") {
                NotificationCenter.default.post(name: .skipBreak, object: nil)
            }
            .keyboardShortcut("b", modifiers: [.shift])
            
            Divider()
            
            Button("Show Stats") {
                NotificationCenter.default.post(name: .showStats, object: nil)
            }
            .keyboardShortcut("s", modifiers: [.command])
        }
        
        // Settings menu
        CommandGroup(replacing: .appSettings) {
            Button("Preferences…") {
                // Open the settings window
                if #available(macOS 14.0, *) {
                    NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                } else {
                    NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
                }
            }
            .keyboardShortcut(",", modifiers: [.command])
        }
        
        // Window menu
        CommandGroup(replacing: .windowArrangement) {
            Button("Show App") {
                NSApp.activate(ignoringOtherApps: true)
            }
            .keyboardShortcut("d", modifiers: [.command])
        }
    }
}

extension Notification.Name {
    static let toggleTimer = Notification.Name("toggleTimer")
    static let endSession = Notification.Name("endSession")
    static let skipBreak = Notification.Name("skipBreak")
    static let showStats = Notification.Name("showStats")
    static let showMenuBar = Notification.Name("showMenuBar")
}

