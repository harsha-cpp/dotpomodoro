import Foundation
import AVFoundation

class SoundManager: ObservableObject {
    static let shared = SoundManager()
    
    private var audioPlayers: [String: AVAudioPlayer] = [:]
    
    @Published var soundsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(soundsEnabled, forKey: "soundsEnabled")
        }
    }
    
    private init() {
        self.soundsEnabled = UserDefaults.standard.object(forKey: "soundsEnabled") as? Bool ?? true
        setupAudioPlayers()
    }
    
    private func setupAudioPlayers() {
        // Setup start/resume sound
        if let startSoundURL = Bundle.main.url(forResource: "new-notification-010-352755", withExtension: "mp3") {
            do {
                let startPlayer = try AVAudioPlayer(contentsOf: startSoundURL)
                startPlayer.prepareToPlay()
                audioPlayers["start"] = startPlayer
            } catch {
                print("Error loading start sound: \(error)")
            }
        }
        
        // Setup completion/level-up sound
        if let completeSoundURL = Bundle.main.url(forResource: "level-up-191997", withExtension: "mp3") {
            do {
                let completePlayer = try AVAudioPlayer(contentsOf: completeSoundURL)
                completePlayer.prepareToPlay()
                audioPlayers["complete"] = completePlayer
            } catch {
                print("Error loading complete sound: \(error)")
            }
        }
    }
    
    func playStartSound() {
        guard soundsEnabled else { return }
        audioPlayers["start"]?.play()
    }
    
    func playCompleteSound() {
        guard soundsEnabled else { return }
        audioPlayers["complete"]?.play()
    }
    
    func toggleSounds() {
        soundsEnabled.toggle()
    }
} 