import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject private var timer: PomodoroTimer
    @StateObject private var soundManager = SoundManager.shared
    @State private var showingSettings = false
    @State private var showingStats = false
    @State private var showingSessionStats = false
    @State private var sessionStats: (workSessions: Int, breakSessions: Int, totalFocusTime: TimeInterval, duration: TimeInterval)?
    @State private var showingTakeBreak = false
    
    // Custom colors
    private let primaryColor = Color(hex: "F07167") // Orange-red
    private let textColor = Color(hex: "FDFCDC")    // Cream
    
    var body: some View {
        ZStack {
            // Main content
            VStack(spacing: 0) {
                if showingSettings {
                    TimerSettingsView(
                        isPresented: $showingSettings,
                        timer: timer,
                        primaryColor: primaryColor,
                        textColor: textColor,
                        soundManager: soundManager
                    )
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.95, anchor: .center)),
                        removal: .opacity.combined(with: .scale(scale: 0.95, anchor: .center))
                    ))
                    .animation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0.3), value: showingSettings)
                } else if showingStats {
                    StatsView()
                        .frame(width: 380, height: 600)
                        .background(Color(.windowBackgroundColor))
                        .overlay(alignment: .topTrailing) {
                            Button(action: { 
                                withAnimation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0.3)) {
                                    showingStats = false
                                }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                                    .font(.title2)
                            }
                            .buttonStyle(.plain)
                            .padding()
                        }
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.96, anchor: .center)),
                        removal: .opacity.combined(with: .scale(scale: 0.96, anchor: .center))
                    ))
                    .animation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0.3), value: showingStats)
            } else {
                // Header with circular timer
                VStack(spacing: 16) {
                    // Settings and Stats buttons
                    HStack {
                        Button(action: { 
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0.3)) {
                                showingStats = true
                            }
                        }) {
                            Image(systemName: "chart.bar.fill")
                                .foregroundColor(textColor.opacity(0.8))
                                .font(.title3)
                        }
                        .buttonStyle(.plain)
                        
                        Spacer()
                        
                        Text(timer.sessionTypeText)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(textColor.opacity(0.8))
                        
                        Spacer()
                        
                        Button(action: { 
                            if timer.masterSessionStartTime == nil {
                                withAnimation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0.3)) {
                                    showingSettings = true
                                }
                            }
                        }) {
                            Image(systemName: "gearshape.fill")
                                .foregroundColor(timer.masterSessionStartTime != nil ? textColor.opacity(0.3) : textColor.opacity(0.8))
                                .font(.title3)
                        }
                        .buttonStyle(.plain)
                        .disabled(timer.masterSessionStartTime != nil)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    
                    // Circular Timer
                    ZStack {
                        // Background circle
                        Circle()
                            .stroke(textColor.opacity(0.3), lineWidth: 6)
                            .frame(width: 140, height: 140)
                        
                        // Progress circle
                        Circle()
                            .trim(from: 0, to: timer.progress)
                            .stroke(
                                textColor,
                                style: StrokeStyle(lineWidth: 6, lineCap: .round)
                            )
                            .frame(width: 140, height: 140)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut(duration: 0.2), value: timer.progress)
                        
                        // Timer text
                        VStack(spacing: 6) {
                            Text(timer.timeString)
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(textColor)
                            
                            if timer.isRunning {
                                Circle()
                                    .fill(textColor)
                                    .frame(width: 4, height: 4)
                                    .scaleEffect(timer.isRunning ? 1.2 : 0.8)
                                    .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: timer.isRunning)
                            }
                        }
                    }
                    
                    // Timer controls
                    HStack(spacing: 16) {
                        // Start/Pause button
                        ResponsiveTimerButton(
                            isRunning: timer.isRunning,
                            isPaused: timer.isPaused,
                            primaryColor: primaryColor,
                            textColor: textColor,
                            action: { timer.isRunning ? timer.pause() : timer.start() }
                        )
                        .keyboardShortcut(.space, modifiers: [])
                        
                        // Reset button
                        Button(action: timer.reset) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(textColor)
                                .padding(12)
                                .background(primaryColor.opacity(0.3))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        
                        // Skip Break button (only shows during break time)
                        if timer.isBreakTime && (timer.isRunning || timer.isPaused) {
                            Button(action: timer.skipBreak) {
                                Image(systemName: "forward.end.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(textColor)
                                    .padding(12)
                                    .background(Color.blue.opacity(0.8))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    // Take a Break section  
                    if timer.masterSessionStartTime != nil && timer.isPaused && !timer.isBreakTime {
                        VStack(spacing: 12) {
                            Button(action: {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                    showingTakeBreak.toggle()
                                }
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "cup.and.saucer.fill")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(textColor)
                                    
                                    Text("Take a Break")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(textColor)
                                    
                                    Image(systemName: showingTakeBreak ? "chevron.up" : "chevron.down")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(textColor.opacity(0.7))
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(textColor.opacity(0.15))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(textColor.opacity(0.3), lineWidth: 1)
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                            
                            if showingTakeBreak {
                                VStack(spacing: 8) {
                                    Text("Quick Break Presets")
                                        .font(.caption)
                                        .foregroundColor(textColor.opacity(0.8))
                                    
                                    HStack(spacing: 8) {
                                        ForEach([5, 10, 15, 20], id: \.self) { minutes in
                                            QuickBreakButton(
                                                minutes: minutes,
                                                action: {
                                                    timer.setQuickBreak(minutes: minutes)
                                                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                                        showingTakeBreak = false
                                                    }
                                                }
                                            )
                                        }
                                    }
                                }
                                .padding(.horizontal, 4)
                                .transition(.asymmetric(
                                    insertion: .opacity.combined(with: .scale(scale: 0.95, anchor: .top)),
                                    removal: .opacity.combined(with: .scale(scale: 0.95, anchor: .top))
                                ))
                            }
                        }
                        .padding(.bottom, 8)
                    }
                    
                    // Focus Sessions Display
                    VStack(spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "flame.fill")
                                .foregroundColor(textColor.opacity(0.8))
                            Text(timer.focusSessionsText)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(textColor)
                        }
                        
                        // Master Stop Session button (only shows when session is active)
                        if timer.masterSessionStartTime != nil {
                            Button(action: {
                                let stats = timer.endMasterSession()
                                sessionStats = stats
                                showingSessionStats = true
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "stop.circle.fill")
                                    Text("End Session")
                                }
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(textColor)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.red.opacity(0.8))
                                .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                            .keyboardShortcut("s", modifiers: [.shift])
                        }
                    }
                    .padding(.bottom, 16)
                }
                .frame(maxWidth: .infinity)
                .background(primaryColor)
            }
        }
            .transition(.asymmetric(
                insertion: .opacity.combined(with: .scale(scale: 0.99, anchor: .center)),
                removal: .opacity.combined(with: .scale(scale: 0.99, anchor: .center))
            ))
            .animation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0.3), value: showingSettings)
            .animation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0.3), value: showingStats)
            .frame(width: 380)
            .background(Color(.windowBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            // Session stats modal - at ZStack level to avoid clipping
            if showingSessionStats, let stats = sessionStats {
                // Single elegant card with blur effect
                SessionStatsView(
                    workSessions: stats.workSessions,
                    breakSessions: stats.breakSessions,
                    totalFocusTime: stats.totalFocusTime,
                    sessionDuration: stats.duration,
                    onDismiss: {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            showingSessionStats = false
                            sessionStats = nil
                        }
                    }
                )
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.25), radius: 24, x: 0, y: 12)
                .scaleEffect(showingSessionStats ? 1.0 : 0.8)
                .opacity(showingSessionStats ? 1.0 : 0.0)
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showingSessionStats)
                .onTapGesture {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        showingSessionStats = false
                        sessionStats = nil
                    }
                }
            }
        }
        .onAppear {
            // Only show settings on very first launch
            let hasLaunchedBefore = UserDefaults.standard.bool(forKey: "hasLaunchedBefore")
            
            if !hasLaunchedBefore && !timer.isRunning {
                // First launch - show settings if using default values and timer is not running
                if timer.workDuration == PomodoroTimer.defaultDuration && timer.breakDuration == 5 * 60 {
                    showingSettings = true
                }
                UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
            }
            
            // Setup notification observers
            NotificationCenter.default.addObserver(
                forName: .toggleTimer,
                object: nil,
                queue: .main
            ) { _ in
                timer.isRunning ? timer.pause() : timer.start()
            }
            
            NotificationCenter.default.addObserver(
                forName: .endSession,
                object: nil,
                queue: .main
            ) { _ in
                if timer.masterSessionStartTime != nil {
                    let stats = timer.endMasterSession()
                    sessionStats = stats
                    showingSessionStats = true
                }
            }
            
            NotificationCenter.default.addObserver(
                forName: .skipBreak,
                object: nil,
                queue: .main
            ) { _ in
                if timer.isBreakTime {
                    timer.skipBreak()
                }
            }
            
            NotificationCenter.default.addObserver(
                forName: .showStats,
                object: nil,
                queue: .main
            ) { _ in
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0.3)) {
                    showingStats = true
                }
            }
            
            NotificationCenter.default.addObserver(
                forName: .showMenuBar,
                object: nil,
                queue: .main
            ) { _ in
                // Activate the app to show the menu bar
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }
}

// MARK: - Supporting Views

struct TimerSettingsView: View {
    @Binding var isPresented: Bool
    let timer: PomodoroTimer
    let primaryColor: Color
    let textColor: Color
    @ObservedObject var soundManager: SoundManager
    
    @State private var selectedWorkDuration: Int
    @State private var selectedBreakDuration: Int
    @State private var selectedLongBreakDuration: Int
    @State private var sessionsUntilLongBreak: Int
    @State private var autoStartBreaks: Bool
    @State private var autoStartWork: Bool
    @State private var notificationsEnabled: Bool
    
    init(isPresented: Binding<Bool>, timer: PomodoroTimer, primaryColor: Color, textColor: Color, soundManager: SoundManager) {
        self._isPresented = isPresented
        self.timer = timer
        self.primaryColor = primaryColor
        self.textColor = textColor
        self.soundManager = soundManager
        
        // Initialize @State variables with actual timer values to prevent flash
        self._selectedWorkDuration = State(initialValue: Int(timer.workDuration / 60))
        self._selectedBreakDuration = State(initialValue: Int(timer.breakDuration / 60))
        self._selectedLongBreakDuration = State(initialValue: Int(timer.longBreakDuration / 60))
        self._sessionsUntilLongBreak = State(initialValue: timer.sessionsUntilLongBreak)
        self._autoStartBreaks = State(initialValue: timer.autoStartBreaks)
        self._autoStartWork = State(initialValue: timer.autoStartWork)
        self._notificationsEnabled = State(initialValue: timer.notificationsEnabled)
    }
    
    private let workPresets = [
        TimerPreset(name: "Short Focus", minutes: 15),
        TimerPreset(name: "Pomodoro", minutes: 25),
        TimerPreset(name: "Deep Work", minutes: 45),
        TimerPreset(name: "Long Focus", minutes: 60)
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 20) {
                HStack {
                    Button("Cancel") {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0.3)) {
                            isPresented = false
                        }
                    }
                    .foregroundColor(textColor.opacity(0.8))
                    
                    Spacer()
                    
                    Text("Timer Settings")
                        .font(.headline)
                        .foregroundColor(textColor)
                    
                    Spacer()
                    
                    Button("Done") {
                        // Convert minutes to seconds for normal operation
                        let workTime = TimeInterval(selectedWorkDuration * 60)
                        let breakTime = TimeInterval(selectedBreakDuration * 60)
                        let longBreakTime = TimeInterval(selectedLongBreakDuration * 60)
                        
                        timer.setDurations(
                            work: workTime,
                            break: breakTime,
                            longBreak: longBreakTime
                        )
                        timer.setAutoStart(breaks: autoStartBreaks, work: autoStartWork)
                        timer.setNotifications(enabled: notificationsEnabled)
                        timer.sessionsUntilLongBreak = sessionsUntilLongBreak
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0.3)) {
                            isPresented = false
                        }
                    }
                    .foregroundColor(textColor)
                    .fontWeight(.semibold)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                
                Text("Set your perfect focus session")
                    .font(.subheadline)
                    .foregroundColor(textColor.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            .padding(.bottom, 30)
            .background(primaryColor)
            
            // Scrollable content
            ScrollView {
                VStack(spacing: 30) {
                    // Preview
                    VStack(spacing: 8) {
                        Text("Preview")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        VStack(spacing: 4) {
                            Text("\(selectedWorkDuration)m work → \(selectedBreakDuration)m break")
                                .font(.subheadline)
                                .foregroundColor(primaryColor)
                            
                            Text("Long break: \(selectedLongBreakDuration)m after \(sessionsUntilLongBreak) sessions")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(primaryColor.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .padding(.horizontal, 20)
                    
                    Divider()
                        .padding(.horizontal, 20)
                    
                    // Work duration presets
                    VStack(spacing: 16) {
                        Text("Work Duration")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                            ForEach(workPresets, id: \.minutes) { preset in
                                TimerPresetCard(
                                    preset: preset,
                                    isSelected: preset.minutes == selectedWorkDuration,
                                    primaryColor: primaryColor,
                                    textColor: textColor
                                ) {
                                    selectedWorkDuration = preset.minutes
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    

                    
                    Divider()
                        .padding(.horizontal, 20)
                    
                    // Break duration presets
                    VStack(spacing: 16) {
                        Text("Short Break Duration")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        // Big time display with controls
                        VStack(spacing: 12) {
                            // Main time display
                            HStack(spacing: 16) {
                                Button(action: {
                                    if selectedBreakDuration > 1 {
                                        selectedBreakDuration -= 1
                                    }
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(primaryColor)
                                }
                                .buttonStyle(.plain)
                                
                                Text("\(selectedBreakDuration)")
                                    .font(.system(size: 36, weight: .bold, design: .rounded))
                                    .foregroundColor(primaryColor)
                                    .frame(minWidth: 60)
                                
                                Button(action: {
                                    if selectedBreakDuration < 60 {
                                        selectedBreakDuration += 1
                                    }
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(primaryColor)
                                }
                                .buttonStyle(.plain)
                            }
                            
                            Text("minutes")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            // Quick shortcuts
                            HStack(spacing: 8) {
                                ForEach([5, 10, 15], id: \.self) { minutes in
                                    Button(action: {
                                        selectedBreakDuration = minutes
                                    }) {
                                        Text("\(minutes)")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(selectedBreakDuration == minutes ? textColor : primaryColor)
                                            .frame(width: 40, height: 32)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(selectedBreakDuration == minutes ? primaryColor : primaryColor.opacity(0.1))
                                            )
                                    }
                                    .buttonStyle(.plain)
                                    .scaleEffect(selectedBreakDuration == minutes ? 1.05 : 1.0)
                                    .animation(.easeInOut(duration: 0.2), value: selectedBreakDuration)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .padding(.horizontal, 20)
                    
                    Divider()
                        .padding(.horizontal, 20)
                    
                    // Long break duration
                    VStack(spacing: 16) {
                        Text("Long Break Duration")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        VStack(spacing: 12) {
                            HStack(spacing: 16) {
                                Button(action: {
                                    if selectedLongBreakDuration > 5 {
                                        selectedLongBreakDuration -= 5
                                    }
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.title3)
                                        .foregroundColor(primaryColor)
                                }
                                .buttonStyle(.plain)
                                
                                Text("\(selectedLongBreakDuration)")
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundColor(primaryColor)
                                    .frame(minWidth: 50)
                                
                                Button(action: {
                                    if selectedLongBreakDuration < 60 {
                                        selectedLongBreakDuration += 5
                                    }
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title3)
                                        .foregroundColor(primaryColor)
                                }
                                .buttonStyle(.plain)
                            }
                            
                            Text("minutes")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 8) {
                                ForEach([15, 20, 30], id: \.self) { minutes in
                                    Button(action: {
                                        selectedLongBreakDuration = minutes
                                    }) {
                                        Text("\(minutes)")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(selectedLongBreakDuration == minutes ? textColor : primaryColor)
                                            .frame(width: 40, height: 32)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(selectedLongBreakDuration == minutes ? primaryColor : primaryColor.opacity(0.1))
                                            )
                                    }
                                    .buttonStyle(.plain)
                                    .scaleEffect(selectedLongBreakDuration == minutes ? 1.05 : 1.0)
                                    .animation(.easeInOut(duration: 0.2), value: selectedLongBreakDuration)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Divider()
                        .padding(.horizontal, 20)
                    
                    // Auto-start settings
                    VStack(spacing: 16) {
                        Text("Automation")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        VStack(spacing: 12) {
                            Toggle("Auto-start breaks", isOn: $autoStartBreaks)
                                .toggleStyle(.switch)
                                .tint(Color(hex: "DBF9B8"))
                            
                            Toggle("Auto-start work sessions", isOn: $autoStartWork)
                                .toggleStyle(.switch)
                                .tint(Color(hex: "DBF9B8"))
                            
                            HStack {
                                Text("Long break after")
                                    .font(.subheadline)
                                
                                Picker("Sessions", selection: $sessionsUntilLongBreak) {
                                    ForEach(2...8, id: \.self) { count in
                                        Text("\(count) sessions").tag(count)
                                    }
                                }
                                .pickerStyle(.menu)
                                .frame(maxWidth: 120)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Divider()
                        .padding(.horizontal, 20)
                    
                    // Sound settings
                    VStack(spacing: 16) {
                        Text("Sound Effects")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        VStack(spacing: 12) {
                            Toggle("Play sounds", isOn: $soundManager.soundsEnabled)
                                .toggleStyle(.switch)
                                .tint(Color(hex: "DBF9B8"))
                            
                            if soundManager.soundsEnabled {
                                Text("Start sound plays when timer begins • Complete sound plays when sessions finish")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.top, 4)
                                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .animation(.easeInOut(duration: 0.3), value: soundManager.soundsEnabled)
                    
                    Divider()
                        .padding(.horizontal, 20)
                    
                    // Notification settings
                    VStack(spacing: 16) {
                        Text("Notifications")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        VStack(spacing: 12) {
                            Toggle("Show notifications", isOn: $notificationsEnabled)
                                .toggleStyle(.switch)
                                .tint(Color(hex: "DBF9B8"))
                            
                            if notificationsEnabled {
                                VStack(spacing: 8) {
                                    Text("Get notified when sessions complete")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                    
                                    Text("Notifications auto-clear after 5 seconds")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                        .opacity(0.8)
                                }
                                .padding(.top, 4)
                                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .animation(.easeInOut(duration: 0.3), value: notificationsEnabled)
                    
                    // Footer
                    VStack(spacing: 4) {
                        Divider()
                            .padding(.horizontal, 20)
                            .padding(.top, 30)
                        
                        VStack(spacing: 2) {
                            Text("DOT Pomodoro")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            Text("Developed with ❤️ for focused productivity")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            Text("© 2025 All rights reserved")
                                .font(.caption2)
                                .foregroundColor(.secondary.opacity(0.8))
                        }
                                                 .padding(.vertical, 12)
                     }
                }
                .padding(.top, 30)
                .padding(.bottom, 20)
            }
            .background(Color(.controlBackgroundColor))
        }
        .frame(width: 380)
        .frame(minHeight: 650, maxHeight: 750)
    }
}

struct TimerPreset {
    let name: String
    let minutes: Int
}

struct TimerPresetCard: View {
    let preset: TimerPreset
    let isSelected: Bool
    let primaryColor: Color
    let textColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(preset.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isSelected ? primaryColor : .primary)
                    .lineLimit(1)
                
                Text("\(preset.minutes)")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(isSelected ? primaryColor : .primary)
                
                Text("minutes")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(isSelected ? primaryColor.opacity(0.8) : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? textColor : Color(.controlBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? primaryColor : Color.gray.opacity(0.2), lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// Responsive Timer Button Component
struct ResponsiveTimerButton: View {
    let isRunning: Bool
    let isPaused: Bool
    let primaryColor: Color
    let textColor: Color
    let action: () -> Void
    
    @State private var isPressed = false
    
    private var buttonText: String {
        isRunning ? "Pause" : (isPaused ? "Resume" : "Start")
    }
    
    private var iconName: String {
        isRunning ? "pause.fill" : "play.fill"
    }
    
    var body: some View {
        Button(action: {
            // Immediate visual feedback
            withAnimation(.easeOut(duration: 0.06)) {
                isPressed = true
            }
            
            // Execute action after brief feedback
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
                action()
                withAnimation(.easeOut(duration: 0.1)) {
                    isPressed = false
                }
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: iconName)
                    .font(.system(size: 16, weight: .semibold))
                    .contentTransition(.symbolEffect(.replace))
                
                Text(buttonText)
                    .font(.system(size: 16, weight: .semibold))
                    .contentTransition(.opacity)
            }
            .foregroundColor(primaryColor)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(textColor)
            .clipShape(Capsule())
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.12), value: isRunning)
        .animation(.easeInOut(duration: 0.12), value: isPaused)
        .animation(.easeOut(duration: 0.06), value: isPressed)
    }
}

// Custom Quick Break Button Component
struct QuickBreakButton: View {
    let minutes: Int
    let action: () -> Void
    @State private var isHovered = false
    @State private var isPressed = false
    
    // Using app's color scheme
    private let primaryColor = Color(hex: "F07167")
    private let textColor = Color.white
    
    var body: some View {
        Button(action: {
            withAnimation(.easeOut(duration: 0.1)) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                action()
                withAnimation(.easeOut(duration: 0.1)) {
                    isPressed = false
                }
            }
        }) {
            VStack(spacing: 4) {
                Text("\(minutes)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(isHovered ? primaryColor : textColor)
                
                Text("min")
                    .font(.caption2)
                    .foregroundColor(isHovered ? primaryColor.opacity(0.8) : textColor.opacity(0.7))
            }
            .frame(width: 50, height: 40)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isHovered ? textColor : textColor.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isHovered ? textColor : textColor.opacity(0.3), lineWidth: 1)
                    )
            )
            .scaleEffect(isPressed ? 0.95 : (isHovered ? 1.05 : 1.0))
            .shadow(color: isHovered ? textColor.opacity(0.4) : .clear, radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
    }
}

#Preview {
    MenuBarView()
        .environmentObject(PomodoroTimer())
}
