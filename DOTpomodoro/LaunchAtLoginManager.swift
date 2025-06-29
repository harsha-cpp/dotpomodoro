import Foundation
import ServiceManagement

class LaunchAtLoginManager: ObservableObject {
    static let shared = LaunchAtLoginManager()
    
    @Published var isEnabled: Bool = false {
        didSet {
            if isEnabled != oldValue {
                setLaunchAtLogin(isEnabled)
            }
        }
    }
    
    private init() {
        // Check current state without triggering the didSet observer
        let currentStatus = getLaunchAtLoginStatus()
        
        // Set the initial value directly to the backing storage
        // This prevents the didSet from being called during initialization
        self._isEnabled = Published(initialValue: currentStatus)
    }
    
    private func getLaunchAtLoginStatus() -> Bool {
        if #available(macOS 13.0, *) {
            // Use modern SMAppService for macOS 13+
            guard let bundleIdentifier = Bundle.main.bundleIdentifier else {
                return false
            }
            
            let service = SMAppService.mainApp
            return service.status == .enabled
        } else {
            // Fallback for older macOS versions
            guard let bundleIdentifier = Bundle.main.bundleIdentifier else {
                return false
            }
            
            let jobs = SMCopyAllJobDictionaries(kSMDomainUserLaunchd)?.takeRetainedValue() as? [[String: Any]]
            
            return jobs?.contains { job in
                job["Label"] as? String == bundleIdentifier
            } ?? false
        }
    }
    
    private func setLaunchAtLogin(_ enabled: Bool) {
        if #available(macOS 13.0, *) {
            // Use modern SMAppService for macOS 13+
            let service = SMAppService.mainApp
            
            do {
                if enabled {
                    if service.status == .enabled {
                        print("Launch at login already enabled")
                        return
                    }
                    try service.register()
                    print("Successfully enabled launch at login")
                } else {
                    if service.status == .notRegistered {
                        print("Launch at login already disabled")
                        return
                    }
                    try service.unregister()
                    print("Successfully disabled launch at login")
                }
            } catch {
                print("Failed to \(enabled ? "enable" : "disable") launch at login: \(error)")
            }
        } else {
            // Fallback for older macOS versions
            guard let bundleIdentifier = Bundle.main.bundleIdentifier else {
                print("Could not get bundle identifier")
                return
            }
            
            let success: Bool
            if enabled {
                success = SMLoginItemSetEnabled(bundleIdentifier as CFString, true)
            } else {
                success = SMLoginItemSetEnabled(bundleIdentifier as CFString, false)
            }
            
            if !success {
                print("Failed to \(enabled ? "enable" : "disable") launch at login")
            } else {
                print("Successfully \(enabled ? "enabled" : "disabled") launch at login")
            }
        }
        
        // Save preference
        UserDefaults.standard.set(enabled, forKey: "launchAtLogin")
    }
    
    func toggle() {
        isEnabled.toggle()
    }
    
    // Helper method to check if the feature is available
    var isAvailable: Bool {
        if #available(macOS 13.0, *) {
            return true
        } else {
            // Check if the legacy method is available
            return Bundle.main.bundleIdentifier != nil
        }
    }
    
    // Get human readable status
    var statusText: String {
        if #available(macOS 13.0, *) {
            let service = SMAppService.mainApp
            switch service.status {
            case .enabled:
                return "Enabled"
            case .requiresApproval:
                return "Requires Approval"
            case .notRegistered:
                return "Disabled"
            case .notFound:
                return "Not Available"
            @unknown default:
                return "Unknown"
            }
        } else {
            return isEnabled ? "Enabled" : "Disabled"
        }
    }
} 