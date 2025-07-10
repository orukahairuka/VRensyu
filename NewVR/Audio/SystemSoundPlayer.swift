import AudioToolbox

// システムサウンドプレイヤー（フォールバック用）
class SystemSoundPlayer {
    private let soundID: SystemSoundID
    
    init(soundID: SystemSoundID) {
        self.soundID = soundID
    }
    
    func play() {
        AudioServicesPlaySystemSound(soundID)
    }
}