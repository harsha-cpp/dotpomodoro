import Cocoa
import Carbon

class GlobalHotKeyManager: ObservableObject {
    static let shared = GlobalHotKeyManager()
    private var hotKeyId: EventHotKeyID = EventHotKeyID()
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    
    // Hot key configuration  
    private let showAppKeyCode: UInt32 = 2 // 'D' key
    private let showAppModifiers: UInt32 = UInt32(cmdKey) // Cmd
    
    private init() {
        setupGlobalHotKeys()
    }
    
    deinit {
        cleanup()
    }
    
    private func setupGlobalHotKeys() {
        // Request accessibility permissions if needed
        if !AXIsProcessTrusted() {
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true]
            AXIsProcessTrustedWithOptions(options as CFDictionary)
        }
        
        // Set up hot key ID
        hotKeyId.signature = OSType("POMD".fourCharCode)
        hotKeyId.id = 1
        
        // Register hot key (Cmd + D to show app)
        let status = RegisterEventHotKey(
            showAppKeyCode,
            showAppModifiers,
            hotKeyId,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        
        if status != noErr {
            print("Failed to register hot key: \(status)")
            return
        }
        
        // Set up event handler
        var eventTypes = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                      eventKind: OSType(kEventHotKeyPressed))
        
        let callback: EventHandlerUPP = { (nextHandler, theEvent, userData) -> OSStatus in
            return GlobalHotKeyManager.shared.handleHotKeyEvent(theEvent)
        }
        
        InstallEventHandler(GetApplicationEventTarget(),
                           callback,
                           1,
                           &eventTypes,
                           nil,
                           &eventHandler)
    }
    
    private func handleHotKeyEvent(_ event: EventRef?) -> OSStatus {
        var hotKeyId = EventHotKeyID()
        let status = GetEventParameter(event,
                                      EventParamName(kEventParamDirectObject),
                                      EventParamType(typeEventHotKeyID),
                                      nil,
                                      MemoryLayout<EventHotKeyID>.size,
                                      nil,
                                      &hotKeyId)
        
        if status == noErr && hotKeyId.id == 1 {
            // Show the menu bar app
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .showMenuBar, object: nil)
            }
        }
        
        return noErr
    }
    
    private func cleanup() {
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }
        
        if let eventHandler = eventHandler {
            RemoveEventHandler(eventHandler)
        }
    }
}

extension String {
    var fourCharCode: FourCharCode {
        assert(self.count == 4)
        var result: FourCharCode = 0
        for char in self.utf8 {
            result = (result << 8) + FourCharCode(char)
        }
        return result
    }
} 