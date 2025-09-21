import SwiftUI

struct HomeView: View {
    private let buttonSize = CGSize(width: 160, height: 60)
    
    @State private var showEasyDesc = false
    @State private var showHardDesc = false
    @State private var showEndlessDesc = false
    @State private var showPracticeDesc = false
    
    // Endless bests (read from UserDefaults)
    @State private var endlessBestLevel: Int = 0
    @State private var endlessBestScore: Int = 0
    
    // Keys must match the ones used in LinkGameModel
    private let bestLevelKey = "EndlessBestLevelKey"
    private let bestScoreKey = "EndlessBestScoreKey"
    
    var body: some View {
        NavigationStack {
            ZStack {
                Image("back001")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    Spacer()
                    // 修改這一行的文字為你想要的遊戲名稱
                    Text("來玩連連看吧！")
                        .font(.system(size: 50, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.4), radius: 4, x: 0, y: 2)
                    
                    VStack(spacing: 10) {
                        HStack(spacing: 4) {
                            NavigationLink { ContentView(mode: .classicEasy) } label: { Text("經典模式（簡單）") }
                                .buttonStyle(UniformWhiteButtonStyle(size: buttonSize))
                            ModeInfoIcon { showEasyDesc = true }
                            Spacer(minLength: 1)
                            ModeInfoIcon { showHardDesc = true }
                            NavigationLink { ContentView(mode: .classicHard) } label: { Text("經典模式（困難）") }
                                .buttonStyle(UniformWhiteButtonStyle(size: buttonSize))
                        }
                        
                        // 無盡模式 + 下方顯示最高紀錄
                        VStack(spacing: 6) {
                            HStack(spacing: 4) {
                                NavigationLink { ContentView(mode: .endless) } label: { Text("無盡模式") }
                                    .buttonStyle(UniformWhiteButtonStyle(size: buttonSize))
                                ModeInfoIcon { showEndlessDesc = true }
                                Spacer(minLength: 1)
                                ModeInfoIcon { showPracticeDesc = true }
                                NavigationLink { LevelSelectView() } label: { Text("練習關卡") }
                                    .buttonStyle(UniformWhiteButtonStyle(size: buttonSize))
                            }
                            
                            // Endless bests display under the Endless button row
                            HStack {
                                Text("無盡模式 最高 關卡: \(endlessBestLevel)  分數: \(endlessBestScore)")
                                    .font(.footnote.weight(.semibold))
                                    .foregroundColor(.yellow)
                                Spacer()
                            }
                            .padding(.horizontal, 6)
                        }
                    }
                    .padding(.top, 4)
                    .padding(.horizontal, 16)
                    
                    Spacer()
                }
                .padding()
                
                // 模式說明浮層
                if showEasyDesc {
                    ModeDescriptionView(
                        title: "經典模式（簡單）",
                        lines: [
                            "從第 1 關開始，逐關挑戰。",
                            "每關提示數固定為 3。",
                            "若無可配對將自動洗牌，不扣提示。"
                        ],
                        onClose: { showEasyDesc = false }
                    )
                }
                
                if showHardDesc {
                    ModeDescriptionView(
                        title: "經典模式（困難）",
                        lines: [
                            "從第 1 關開始，逐關挑戰。",
                            "每關提示次數+2",
                            "若無可配對將自動洗牌，但會扣 1 次提示。",
                            "當提示為 0 且無可配對時，遊戲結束。",
                            "",
                            "tips: 請在簡單的關卡盡量保留提示次數喔～。"
                        ],
                        onClose: { showHardDesc = false }
                    )
                }
                
                if showEndlessDesc {
                    ModeDescriptionView(
                        title: "無盡模式",
                        lines: [
                            "每關隨機掉落風格，持續闖關。",
                            "無法暫停，節奏更緊湊。",
                            "每關提示數固定為 3。"
                        ],
                        onClose: { showEndlessDesc = false }
                    )
                }
                
                if showPracticeDesc {
                    ModeDescriptionView(
                        title: "練習關卡",
                        lines: [
                            "自由選擇任一關卡開始遊玩。",
                            "每次進入該關卡都會重置分數與提示。",
                            "終極關卡：找出成對的圖案進行消除，眼力大考驗！"
                        ],
                        onClose: { showPracticeDesc = false }
                    )
                }
            }
        }
        .onAppear {
            // 回到主選單/選關畫面時，確保背景音量回到正常（例如 0.8）
            BackgroundMusicPlayer.shared.setVolume(0.8, animated: true, duration: 0.4)
            
            // Refresh bests whenever we come back to Home
            let ud = UserDefaults.standard
            endlessBestLevel = ud.integer(forKey: bestLevelKey)
            endlessBestScore = ud.integer(forKey: bestScoreKey)
        }
    }
}

// 小圓形資訊按鈕
private struct ModeInfoIcon: View {
    var action: () -> Void
    private let size: CGFloat = 34
    
    var body: some View {
        Button(action: action) {
            Image("檔案_013")
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .background(.thinMaterial)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color.white.opacity(0.7), lineWidth: 1))
        .shadow(color: .black.opacity(0.18), radius: 4, x: 0, y: 2)
        .padding(.horizontal, 2)
    }
}

// 毛玻璃統一按鈕樣式
struct UniformWhiteButtonStyle: ButtonStyle {
    let size: CGSize
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: size.width, height: size.height)
            .font(.system(size: 18, weight: .semibold))
            .foregroundColor(.white)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.25), radius: 6, x: 0, y: 3)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct LevelSelectView: View {
    private let levels: [(Int, String)] = [
        (1, "新手試玩"), (2, "漸入佳境"), (3, "地心引力"),
        (4, "天空之城"), (5, "心之所向"), (6, "安培的手"),
        (7, "左右互搏"), (8, "同極相斥"), (9, "終極關卡")
    ]
    
    var body: some View {
        ZStack {
            // 背景圖 back003
            Image("back003")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            
            List {
                Section() {
                    ForEach(levels, id: \.0) { item in
                        NavigationLink {
                            ContentView(mode: .practice(startLevel: item.0))
                        } label: {
                            HStack {
                                Text("第 \(item.0) 關")
                                Spacer()
                                Text(item.1)
                                    .foregroundColor(.secondary)
                            }
                        }
                        // 改每一行的背景顏色
                        .listRowBackground(Color(hex: "#C1FFE4").opacity(0.5))
                    }
                }
            }
            .scrollContentBackground(.hidden) // 隱藏 List 原背景
        }
        .navigationTitle("選擇關卡")
    }
}

// 延伸支援 HEX 顏色
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
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}



// 半透明模式說明浮層 (文字置中，X 按鈕在下方)
private struct ModeDescriptionView: View {
    let title: String
    let lines: [String]
    var onClose: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture { onClose() }
            
            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    Text(title)
                        .font(.title2.weight(.bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    ForEach(lines, id: \.self) { line in
                        Text("\(line)")
                            .font(.body)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding(24)
            .background(.ultraThinMaterial)
            .cornerRadius(16)
            .padding(32)
            .shadow(radius: 12)
        }
        .transition(.opacity.combined(with: .scale))
        .animation(.easeInOut, value: UUID())
    }
}
