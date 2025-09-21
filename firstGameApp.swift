//
//  firstGameApp.swift
//  firstGame
//
//  Created by user13 on 2025/9/18.
//

import SwiftUI

@main
struct firstGameApp: App {
    init() {
        // App 啟動即開始播放背景音樂（自動嘗試 backsound 的常見副檔名）
        BackgroundMusicPlayer.shared.play(name: "backsound", fileExtension: nil, volume: 0.0, loop: true)
        // 淡入到正常音量（例如 0.8）
        BackgroundMusicPlayer.shared.setVolume(0.8, animated: true, duration: 0.6)
    }
    
    var body: some Scene {
        WindowGroup {
            HomeView()
        }
    }
}
