import Foundation
import AVFoundation
import UIKit

final class BackgroundMusicPlayer {
    static let shared = BackgroundMusicPlayer()
    
    private var player: AVAudioPlayer?
    private var fadeTimer: Timer?
    private init() {
        // 讓背景音樂不會因為靜音鍵而完全靜音（如需遵守靜音鍵可改為 .ambient）
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true, options: [])
    }
    
    func play(name: String = "backsound", fileExtension: String? = nil, volume: Float = 0.8, loop: Bool = true) {
        if let p = player {
            // 已有播放器就直接設定
            p.numberOfLoops = loop ? -1 : 0
            p.volume = volume
            if !p.isPlaying { p.play() }
            return
        }
        
        // 依序嘗試載入
        if let ext = fileExtension, let url = Bundle.main.url(forResource: name, withExtension: ext) {
            loadAndPlay(url: url, volume: volume, loop: loop)
            return
        }
        let exts = ["mp3", "m4a", "wav", "aiff", "caf"]
        for ext in exts {
            if let url = Bundle.main.url(forResource: name, withExtension: ext) {
                loadAndPlay(url: url, volume: volume, loop: loop)
                return
            }
        }
        if let dataAsset = NSDataAsset(name: name) {
            if let p = try? AVAudioPlayer(data: dataAsset.data) {
                player = p
                p.numberOfLoops = loop ? -1 : 0
                p.volume = volume
                p.prepareToPlay()
                p.play()
            }
        }
    }
    
    private func loadAndPlay(url: URL, volume: Float, loop: Bool) {
        if let p = try? AVAudioPlayer(contentsOf: url) {
            player = p
            p.numberOfLoops = loop ? -1 : 0
            p.volume = volume
            p.prepareToPlay()
            p.play()
        }
    }
    
    func setVolume(_ volume: Float, animated: Bool = true, duration: TimeInterval = 0.5) {
        guard let p = player else { return }
        fadeTimer?.invalidate()
        if !animated || duration <= 0 {
            p.volume = max(0, min(1, volume))
            return
        }
        let start = p.volume
        let target = max(0, min(1, volume))
        if start == target { return }
        
        let steps = 30
        let interval = duration / Double(steps)
        var currentStep = 0
        fadeTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true, block: { [weak self] t in
            guard let self = self, let player = self.player else {
                t.invalidate()
                return
            }
            currentStep += 1
            let progress = min(1.0, Double(currentStep) / Double(steps))
            let newVolume = Float((1 - progress)) * start + Float(progress) * target
            player.volume = newVolume
            if progress >= 1.0 {
                t.invalidate()
            }
        })
    }
    
    func pause() {
        player?.pause()
    }
    
    func stop() {
        fadeTimer?.invalidate()
        fadeTimer = nil
        player?.stop()
        player = nil
    }
}
