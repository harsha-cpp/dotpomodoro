import SwiftUI

struct AppSettingsView: View {
    @EnvironmentObject private var timer: PomodoroTimer
    @StateObject private var launchAtLogin = LaunchAtLoginManager.shared
    @StateObject private var globalHotKeys = GlobalHotKeyManager.shared
    @StateObject private var soundManager = SoundManager.shared
    
    private let primaryColor = Color(hex: "F07167")
    
    var body: some View {
        TabView {
            // General Settings
            GeneralSettingsTab(
                timer: timer,
                launchAtLogin: launchAtLogin,
                primaryColor: primaryColor
            )
            .tabItem {
                Label("General", systemImage: "gear")
            }
            
            // Shortcuts Settings  
            ShortcutsSettingsTab(primaryColor: primaryColor)
            .tabItem {
                Label("Shortcuts", systemImage: "keyboard")
            }
            
            // Sound Settings
            SoundSettingsTab(
                soundManager: soundManager,
                primaryColor: primaryColor
            )
            .tabItem {
                Label("Sounds", systemImage: "speaker.wave.2")
            }
        }
        .frame(width: 450, height: 300)
    }
}

struct GeneralSettingsTab: View {
    @ObservedObject var timer: PomodoroTimer
    @ObservedObject var launchAtLogin: LaunchAtLoginManager
    let primaryColor: Color
    
    var body: some View {
        Form {
            Section("Startup") {
                VStack(alignment: .leading, spacing: 8) {
                    Toggle("Launch at Login", isOn: $launchAtLogin.isEnabled)
                        .help("Automatically start DOTpomodoro when you log in")
                        .disabled(!launchAtLogin.isAvailable)
                    
                    if launchAtLogin.isAvailable {
                        HStack {
                            Text("Status:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(launchAtLogin.statusText)
                                .font(.caption)
                                .foregroundColor(launchAtLogin.statusText == "Requires Approval" ? .orange : 
                                               launchAtLogin.statusText == "Enabled" ? .green : .secondary)
                        }
                        
                        if launchAtLogin.statusText == "Requires Approval" {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("⚠️ Please approve in System Settings > General > Login Items")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                
                                Button("Open System Settings") {
                                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.users.LoginItems") {
                                        NSWorkspace.shared.open(url)
                                    }
                                }
                                .font(.caption)
                                .controlSize(.mini)
                            }
                            .padding(.top, 2)
                        }
                        
                        // Manual alternative
                        Button("Open Login Items Settings") {
                            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.users.LoginItems") {
                                NSWorkspace.shared.open(url)
                            }
                        }
                        .font(.caption)
                        .controlSize(.mini)
                        .help("Manually add DOTpomodoro to login items")
                    } else {
                        Text("Not available on this system")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Section("Timer Settings") {
                HStack {
                    Text("Work Duration:")
                    Spacer()
                    Text("\(Int(timer.workDuration / 60)) min")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Short Break:")
                    Spacer()
                    Text("\(Int(timer.breakDuration / 60)) min")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Long Break:")
                    Spacer()
                    Text("\(Int(timer.longBreakDuration / 60)) min")
                        .foregroundColor(.secondary)
                }
                
                Text("Timer settings can be adjusted in the main menu")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section("Behavior") {
                Toggle("Auto-start Breaks", isOn: $timer.autoStartBreaks)
                    .help("Automatically start break timers after work sessions")
                
                Toggle("Auto-start Work", isOn: $timer.autoStartWork)
                    .help("Automatically start work timers after breaks")
                
                Toggle("Enable Notifications", isOn: $timer.notificationsEnabled)
                    .help("Show system notifications when sessions complete")
            }
        }
        .formStyle(.grouped)
    }
}

struct ShortcutsSettingsTab: View {
    let primaryColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Global Shortcuts")
                .font(.headline)
                .padding(.bottom, 4)
            
            VStack(spacing: 12) {
                ShortcutRow(
                    title: "Toggle Timer",
                    shortcut: "⌘ ⌥ R",
                    description: "Start/pause the timer from anywhere"
                )
                
                ShortcutRow(
                    title: "Toggle Timer (Menu)",
                    shortcut: "Space",
                    description: "Start/pause when menu is open"
                )
                
                ShortcutRow(
                    title: "End Session",
                    shortcut: "⇧ S",
                    description: "End current session when menu is open"
                )
                
                ShortcutRow(
                    title: "Skip Break",
                    shortcut: "⇧ B", 
                    description: "Skip break session when menu is open"
                )
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Note:")
                    .font(.caption)
                    .fontWeight(.semibold)
                
                Text("• Global shortcuts work system-wide")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("• Menu shortcuts only work when the menu is open")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("• Global shortcuts require Accessibility permissions")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
    }
}

struct ShortcutRow: View {
    let title: String
    let shortcut: String
    let description: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(shortcut)
                .font(.system(size: 11, design: .monospaced))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                )
        }
    }
}

struct SoundSettingsTab: View {
    @ObservedObject var soundManager: SoundManager
    let primaryColor: Color
    
    var body: some View {
        Form {
            Section("Sound Effects") {
                Toggle("Enable Sounds", isOn: $soundManager.soundsEnabled)
                    .help("Play sound effects for timer events")
            }
            
            Section("Preview") {
                HStack {
                    Button("Play Start Sound") {
                        soundManager.playStartSound()
                    }
                    .disabled(!soundManager.soundsEnabled)
                    
                    Spacer()
                    
                    Button("Play Complete Sound") {
                        soundManager.playCompleteSound()
                    }
                    .disabled(!soundManager.soundsEnabled)
                }
            }
        }
        .formStyle(.grouped)
    }
}

#Preview {
    AppSettingsView()
        .environmentObject(PomodoroTimer())
} 