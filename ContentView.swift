// ContentView.swift
import SwiftUI
import Combine
import AVFoundation
// -----------------------------
// Simple Link-Game (8x14) - SwiftUI
// -----------------------------
enum GameMode: Equatable {
    case classicEasy
    case classicHard
    case practice(startLevel: Int)
    case endless
}
struct ContentView: View {
    let mode: GameMode
    
    @StateObject private var game: LinkGameModel
    @Environment(\.dismiss) private var dismiss
    
    // UI animation state for hint pulse
    @State private var hintPulse: Bool = false
    
    init(mode: GameMode) {
        self.mode = mode
        _game = StateObject(wrappedValue: LinkGameModel(mode: mode))
    }
    
    var body: some View {
        ZStack {
            Image("back002")
                .resizable()
                .ignoresSafeArea()
                .opacity(0.5)
            VStack(spacing: 10) {
                Color.clear.frame(height: 54)
                
                VStack(spacing: 6) {
                    HStack {
                        Text("第 \(game.level) 關")
                            .font(.headline)
                        Text(game.currentModeName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        HStack(spacing: 6) {
                            Text("提示:")
                                .font(.subheadline)
                            Text("\(game.hintsRemaining)")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(hintPulse ? .orange : .primary)
                                .scaleEffect(hintPulse ? 1.2 : 1.0)
                                .animation(.spring(response: 0.25, dampingFraction: 0.6, blendDuration: 0.1), value: hintPulse)
                        }
                        Button("提示") { game.useHint() }
                            .disabled(game.hintsRemaining == 0 || game.timeRemaining == 0 || game.isPaused || game.levelCleared || game.levelFailed)
                        if !game.isPauseDisabled {
                            Button(game.isPaused ? "繼續" : "暫停") { game.togglePause() }
                                .disabled(game.timeRemaining == 0 || game.levelCleared || game.levelFailed)
                        }
                    }
                    ProgressView(value: game.progress)
                        .progressViewStyle(.linear)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(.ultraThinMaterial)
                .cornerRadius(10)
                .padding(.top, -10)
                
                if let msg = game.message {
                    Text(msg)
                        .foregroundColor(.red)
                        .padding(.vertical, 4)
                }
                
                GeometryReader { geo in
                    let cellScale: CGFloat = 1.1
                    let gridPadding: CGFloat = 10
                    let cellSpacing: CGFloat = 4
                    let pathPadding: CGFloat = 12
                    
                    let availableWidth = geo.size.width - gridPadding * 2 - pathPadding * 2
                    let availableHeight = geo.size.height - gridPadding * 2 - pathPadding * 2
                    let cellSizeByWidth = (availableWidth - CGFloat(game.cols - 1) * cellSpacing) / CGFloat(game.cols)
                    let cellSizeByHeight = (availableHeight - CGFloat(game.rows - 1) * cellSpacing) / CGFloat(game.rows)
                    let cellSize = max(8, min(cellSizeByWidth, cellSizeByHeight)) * cellScale
                    
                    let gridContentWidth = CGFloat(game.cols) * cellSize + CGFloat(game.cols - 1) * cellSpacing
                    let gridContentHeight = CGFloat(game.rows) * cellSize + CGFloat(game.rows - 1) * cellSpacing
                    let framedWidth = gridContentWidth + gridPadding*2 + pathPadding*2
                    let framedHeight = gridContentHeight + gridPadding*2 + pathPadding*2
                    
                    let hideTilesForOverlay = game.levelCleared || game.levelFailed
                    
                    ZStack(alignment: .topLeading) {
                        LazyVGrid(columns: Array(repeating: GridItem(.fixed(cellSize), spacing: cellSpacing), count: game.cols), spacing: cellSpacing) {
                            ForEach(0..<(game.rows * game.cols), id: \.self) { idx in
                                let r = idx / game.cols
                                let c = idx % game.cols
                                
                                if !hideTilesForOverlay {
                                    TileView(imageName: game.imageNameAt(row: r+1, col: c+1),
                                             isSelected: game.isSelected(row: r+1, col: c+1),
                                             isHinted: game.isHinted(row: r+1, col: c+1),
                                             isPaused: game.isPaused,
                                             size: cellSize)
                                    .onTapGesture {
                                        game.handleTap(row: r+1, col: c+1)
                                    }
                                } else {
                                    Color.clear
                                        .frame(width: cellSize, height: cellSize)
                                }
                            }
                        }
                        .padding(.init(top: gridPadding + pathPadding, leading: gridPadding + pathPadding, bottom: gridPadding + pathPadding, trailing: gridPadding + pathPadding))
                        .frame(width: framedWidth, height: framedHeight, alignment: .topLeading)
                        .position(x: geo.size.width / 2, y: geo.size.height / 2)
                        
                        if !game.currentPath.isEmpty && !hideTilesForOverlay {
                            Canvas { context, _ in
                                var path = Path()
                                func pointFor(paddedRow r: Int, paddedCol c: Int) -> CGPoint {
                                    let step = cellSize + cellSpacing
                                    let originX = pathPadding + gridPadding + cellSize / 2
                                    let originY = pathPadding + gridPadding + cellSize / 2
                                    var x = originX + CGFloat(c - 1) * step
                                    var y = originY + CGFloat(r - 1) * step
                                    let edgeInset = min(cellSize * 0.35, 10)
                                    let halfCellStride = (step - cellSpacing) / 2
                                    if c == 0 { x += halfCellStride - edgeInset }
                                    if c == game.cols + 1 { x -= halfCellStride - edgeInset }
                                    if r == 0 { y += halfCellStride - edgeInset }
                                    if r == game.rows + 1 { y -= halfCellStride - edgeInset }
                                    return CGPoint(x: x, y: y)
                                }
                                var started = false
                                for (r, c) in game.currentPath {
                                    let p = pointFor(paddedRow: r, paddedCol: c)
                                    if !started {
                                        path.move(to: p)
                                        started = true
                                    } else {
                                        path.addLine(to: p)
                                    }
                                }
                                context.stroke(path, with: .color(.blue), lineWidth: 4)
                                context.stroke(path, with: .color(.white.opacity(0.8)), lineWidth: 2)
                            }
                            .frame(width: framedWidth, height: framedHeight, alignment: .topLeading)
                            .allowsHitTesting(false)
                            .position(x: geo.size.width / 2, y: geo.size.height / 2)
                        }
                        
                        if game.levelCleared {
                            VStack {
                                if (mode == .classicEasy || mode == .classicHard), game.level >= 10 {
                                    Button { dismiss() } label: {
                                        Text("🎉 恭喜通關！回到首頁")
                                            .font(.system(size: 24, weight: .bold))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 24)
                                            .padding(.vertical, 16)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(Color.green)
                                                    .shadow(radius: 8)
                                            )
                                    }
                                } else {
                                    Button {
                                        switch mode {
                                        case .practice:
                                            game.restartAccordingToMode()
                                        default:
                                            game.advanceToNextLevel()
                                        }
                                    } label: {
                                        Text(game.advanceButtonTitle)
                                            .font(.system(size: 24, weight: .bold))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 24)
                                            .padding(.vertical, 16)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(Color.accentColor)
                                                    .shadow(radius: 8)
                                            )
                                    }
                                }
                            }
                            .frame(width: geo.size.width, height: geo.size.height)
                            .contentShape(Rectangle())
                        }

                        if game.levelFailed {
                            VStack {
                                Button {
                                    game.restartAccordingToMode()
                                } label: {
                                    Text("重新開始")
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 24)
                                        .padding(.vertical, 16)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color.red)
                                                .shadow(radius: 8)
                                        )
                                }
                            }
                            .frame(width: geo.size.width, height: geo.size.height)
                            .contentShape(Rectangle())
                        }
                    }
                }
            }
            
            VStack {
                HStack {
                    Button { dismiss() } label: {
                        Label("Home", systemImage: "chevron.backward")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.purple.opacity(0.7)]),
                                               startPoint: .topLeading,
                                               endPoint: .bottomTrailing)
                                    .cornerRadius(8)
                                    .shadow(radius: 3)
                            )
                    }
                    Spacer()
                    Text("分數: \(game.score)")
                        .font(.title3.weight(.bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 10).fill(Color(white: 0.15, opacity: 0.001))
                        )
                    Spacer()
                    Button { game.restartAccordingToMode() } label: {
                        Label("Restart", systemImage: "arrow.clockwise")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                LinearGradient(gradient: Gradient(colors: [Color.orange.opacity(0.7), Color.red.opacity(0.7)]),
                                               startPoint: .topLeading,
                                               endPoint: .bottomTrailing)
                                    .cornerRadius(8)
                                    .shadow(radius: 3)
                            )
                    }
                    .disabled(false)
                }
                .padding(.horizontal)
                .padding(.top, 8)
                Spacer()
            }
            .allowsHitTesting(!(game.levelCleared || game.levelFailed))
        }
        .onAppear { game.start() }
        .onDisappear { game.stopTimer() }
        .onChange(of: game.autoShuffleHintTick) { _, _ in
            withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
                hintPulse = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                withAnimation(.easeOut(duration: 0.2)) {
                    hintPulse = false
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

struct TileView: View {
    let imageName: String?
    let isSelected: Bool
    let isHinted: Bool
    let isPaused: Bool
    let size: CGFloat
    
    private var cornerRadius: CGFloat { 6 }
    
    private var borderColor: Color {
        if isSelected { return .blue }
        if isHinted { return .red }
        return .gray.opacity(0.7)
    }
    
    private var borderWidth: CGFloat {
        if isSelected { return 4 }
        if isHinted { return 3.5 }
        return 1.25
    }
    
    private var glowColor: Color? {
        if isSelected { return Color.blue.opacity(0.6) }
        if isHinted { return Color.red.opacity(0.6) }
        return nil
    }
    
    private var glowRadius: CGFloat {
        (isSelected || isHinted) ? 4.5 : 0
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color.white.opacity(0.28))
                .frame(width: size, height: size)
            if let name = imageName, !isPaused {
                Image(name)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius - 0.5))
            } else if isPaused {
                Image(systemName: "eye.slash")
                    .font(.system(size: max(10, size * 0.3)))
                    .foregroundColor(.secondary)
            }
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(borderColor, lineWidth: borderWidth)
                .frame(width: size, height: size)
                .shadow(color: glowColor ?? .clear, radius: glowRadius, x: 0, y: 0)
        }
    }
}

// -----------------------------
// Game Model
// -----------------------------
class LinkGameModel: ObservableObject {
    let rows = 7
    let cols = 16
    
    enum FallStyle: CaseIterable {
        case none, down, up, left, right, splitLR, splitUD, center
    }
    
    @Published var grid: [[String?]] = []
    @Published var level: Int = 1
    @Published var timeRemaining: Int = 60
    @Published var message: String?
    @Published var pairsLeft: Int = 0
    @Published var hintsRemaining: Int = 3
    @Published var isPaused: Bool = false
    @Published var score: Int = 0
    @Published var hintPair: ((Int,Int),(Int,Int))?
    @Published var currentPath: [(Int,Int)] = []
    @Published var endlessBestLevel: Int = 0
    @Published var endlessBestScore: Int = 0
    @Published var levelCleared: Bool = false
    @Published var levelFailed: Bool = false
    @Published var autoShuffleHintTick: Int = 0
    
    var firstSelection: (r: Int, c: Int)?
    var timer: Timer?
    let bonusPerMatch = 3
    var bonusPerMatchPub: Int { bonusPerMatch }
    
    private(set) var currentBaseTime: Int = 60
    var progress: Double {
        guard currentBaseTime > 0 else { return 0 }
        return Double(timeRemaining.clamped(to: 0...currentBaseTime)) / Double(currentBaseTime)
    }
    
    var imageNames: [String] = (1...35).map { String(format: "檔案_%03d", $0) }
    
    let mode: GameMode
    var isPauseDisabled: Bool {
        if case .endless = mode { return true }
        return false
    }
    private var endlessFallStyle: FallStyle = .none
    
    private let bestLevelKey = "EndlessBestLevelKey"
    private let bestScoreKey = "EndlessBestScoreKey"
    
    private func loadEndlessBests() {
        let ud = UserDefaults.standard
        endlessBestLevel = ud.integer(forKey: bestLevelKey)
        endlessBestScore = ud.integer(forKey: bestScoreKey)
    }
    private func saveEndlessBests() {
        let ud = UserDefaults.standard
        ud.set(endlessBestLevel, forKey: bestLevelKey)
        ud.set(endlessBestScore, forKey: bestScoreKey)
    }
    
    init(mode: GameMode) {
        self.mode = mode
        resetEmptyGrid()
        loadEndlessBests()
    }
    
    func start() {
        switch mode {
        case .classicEasy, .classicHard:
            level = 1; score = 0; hintsRemaining = 3
            setupLevel(level); startTimer()
        case .practice(let startLevel):
            level = startLevel; score = 0; hintsRemaining = 3
            setupLevel(level); startTimer()
        case .endless:
            level = 1; score = 0; hintsRemaining = 3
            loadEndlessBests()
            setupLevel(level); startTimer()
        }
    }
    
    func restartAccordingToMode() {
        stopTimer()
        firstSelection = nil
        message = nil
        isPaused = false
        hintPair = nil
        currentPath = []
        levelCleared = false
        levelFailed = false
        
        switch mode {
        case .classicEasy, .classicHard:
            level = 1; score = 0; hintsRemaining = 3
        case .practice(let startLevel):
            level = startLevel; score = 0; hintsRemaining = 3
        case .endless:
            level = 1; score = 0; hintsRemaining = 3
            loadEndlessBests()
        }
        setupLevel(level)
        startTimer()
    }
    
    func advanceToNextLevel() {
        if case .classicEasy = mode, level >= 10 { return }
        if case .classicHard = mode, level >= 10 { return }
        level += 1
        firstSelection = nil
        hintPair = nil
        currentPath = []
        levelCleared = false
        levelFailed = false
        message = nil
        
        switch mode {
        case .classicEasy, .practice, .endless:
            hintsRemaining = 3
        case .classicHard:
            hintsRemaining += 2
        }
        setupLevel(level)
        startTimer()
        objectWillChange.send()
    }
    
    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    func startTimer() {
        stopTimer()
        currentBaseTime = baseTimeForLevel(level)
        timeRemaining = currentBaseTime
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            DispatchQueue.main.async { self?.timeTick() }
        }
    }
    func timeTick() {
        guard !isPaused else { return }
        guard !levelCleared else { return }
        timeRemaining -= 1
        if timeRemaining <= 0 {
            timeRemaining = 0
            stopTimer()
            message = nil
            levelFailed = true
            if case .endless = mode { updateEndlessBestsOnFail() }
        }
    }
    func baseTimeForLevel(_ lvl: Int) -> Int {
        max(30, 120 - (lvl - 1) * 5)
    }
    
    func resetEmptyGrid() {
        grid = Array(repeating: Array(repeating: nil, count: cols + 2), count: rows + 2)
    }
    func imageNameAt(row: Int, col: Int) -> String? {
        guard row >= 1 && row <= rows && col >= 1 && col <= cols else { return nil }
        return grid[row][col]
    }
    func isSelected(row: Int, col: Int) -> Bool {
        guard let s = firstSelection else { return false }
        return s.r == row && s.c == col
    }
    func isHinted(row: Int, col: Int) -> Bool {
        guard let pair = hintPair else { return false }
        return (pair.0.0 == row && pair.0.1 == col) || (pair.1.0 == row && pair.1.1 == col)
    }
    
    func setupLevel(_ lvl: Int) {
        resetEmptyGrid()
        firstSelection = nil
        message = nil
        hintPair = nil
        currentPath = []
        levelCleared = false
        levelFailed = false
        
        if case .endless = mode {
            endlessFallStyle = FallStyle.allCases.randomElement() ?? .none
        }
        
        if lvl == 9 {
            fillBoardForUltimatePairs()
        } else {
            imageNames = (1...35).map { String(format: "檔案_%03d", $0) }
            fillBoard(cluster: (lvl == 1))
        }
        
        pairsLeft = (rows * cols) / 2
        
        switch mode {
        case .classicEasy, .practice, .endless:
            hintsRemaining = 3
        case .classicHard:
            break
        }
        
        objectWillChange.send()
        if !anyMoveExists() {
            handleNoMovesShuffle()
        }
    }
    
    var levelName: String {
        switch level {
        case 1: return "新手試玩"
        case 2: return "漸入佳境"
        case 3: return "地心引力"
        case 4: return "天空之城"
        case 5: return "心之所向"
        case 6: return "安培的手"
        case 7: return "左右互搏"
        case 8: return "同極相斥"
        case 9: return "終極關卡"
        case 10: return "挑戰關卡"
        default: return "挑戰完成"
        }
    }
    private var fallStyleName: String {
        switch endlessFallStyle {
        case .none: return "新手試玩"
        case .down: return "地心引力"
        case .up: return "天空之城"
        case .left: return "心之所向"
        case .right: return "安培的手"
        case .splitLR: return "左右互搏"
        case .splitUD: return "同極相斥"
        case .center: return "終極關卡"
        }
    }
    var currentModeName: String {
        switch mode {
        case .endless: return fallStyleName
        default: return levelName
        }
    }
    var advanceButtonTitle: String {
        switch mode {
        case .practice:
            return "完成！重新開始本關"
        case .classicEasy, .classicHard:
            return level >= 10 ? "恭喜通關！" : "恭喜過關，進入下一關"
        default:
            return "恭喜過關，進入下一關"
        }
    }
    
    // pairID 與尾碼工具
    private func samePairID(_ a: String, _ b: String) -> Bool {
        func pairKey(_ s: String) -> String? {
            guard s.hasPrefix("pair"), let underscore = s.lastIndex(of: "_") else { return nil }
            return String(s[..<underscore]) // "pairNNN"
        }
        if let ka = pairKey(a), let kb = pairKey(b) { return ka == kb }
        return false
    }
    private func suffixTag(_ s: String) -> String? {
        guard let underscore = s.lastIndex(of: "_") else { return nil }
        return String(s[s.index(after: underscore)...]) // "1" or "2"
    }
    
    func handleTap(row: Int, col: Int) {
        guard timeRemaining > 0 else { return }
        guard !isPaused else { return }
        guard !levelCleared else { return }
        guard let tappedName = grid[row][col] else { return }
        
        hintPair = nil
        
        if firstSelection == nil {
            SoundPlayer.shared.play("clickSound")
            firstSelection = (row, col)
            objectWillChange.send()
            return
        } else {
            if firstSelection!.r == row && firstSelection!.c == col {
                SoundPlayer.shared.play("clickSound")
                firstSelection = nil
                objectWillChange.send()
                return
            }
            let (r1, c1) = firstSelection!
            guard let n1 = grid[r1][c1] else {
                SoundPlayer.shared.play("clickSound")
                firstSelection = (row, col)
                objectWillChange.send()
                return
            }
            
            let isSameGroup: Bool
            if level == 9 {
                // 必須同 pair 且尾碼不同（_1 配 _2）
                if samePairID(n1, tappedName),
                   let s1 = suffixTag(n1),
                   let s2 = suffixTag(tappedName),
                   s1 != s2 {
                    isSameGroup = true
                } else {
                    isSameGroup = false
                }
            } else {
                isSameGroup = (n1 == tappedName)
            }
            guard isSameGroup else {
                SoundPlayer.shared.play("clickSound")
                firstSelection = (row, col)
                objectWillChange.send()
                return
            }
            
            if let path = findPath(from: (r1, c1), to: (row, col)) {
                currentPath = path
                objectWillChange.send()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    SoundPlayer.shared.play("combo")
                    self.removePair((r1, c1), (row, col))
                    self.firstSelection = nil
                    self.pairsLeft -= 1
                    self.score += 10
                    self.timeRemaining = min(self.timeRemaining + self.bonusPerMatch, self.currentBaseTime)
                    self.message = nil
                    self.objectWillChange.send()
                    
                    if self.level != 9 { self.applyLevelFall() } // 第 9 關不位移
                    self.currentPath = []
                    
                    if self.pairsLeft == 0 {
                        self.score += self.timeRemaining
                        self.stopTimer()
                        self.levelCleared = true
                        if case .endless = self.mode { self.updateEndlessBestsOnClear() }
                    } else {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                            if !self.anyMoveExists() {
                                self.handleNoMovesShuffle()
                            }
                        }
                    }
                }
            } else {
                SoundPlayer.shared.play("clickSound")
                firstSelection = (row, col)
            }
            objectWillChange.send()
        }
    }
    
    private func updateEndlessBestsOnClear() {
        if level > endlessBestLevel { endlessBestLevel = level }
        if score > endlessBestScore { endlessBestScore = score }
        saveEndlessBests()
    }
    private func updateEndlessBestsOnFail() {
        let clearedLevel = max(0, level - 1)
        if clearedLevel > endlessBestLevel { endlessBestLevel = clearedLevel }
        if score > endlessBestScore { endlessBestScore = score }
        saveEndlessBests()
    }
    
    func removePair(_ a: (Int,Int), _ b: (Int,Int)) {
        grid[a.0][a.1] = nil
        grid[b.0][b.1] = nil
        objectWillChange.send()
    }
    
    func useHint() {
        guard hintsRemaining > 0 else { return }
        guard timeRemaining > 0 else { return }
        guard !isPaused else { return }
        guard !levelCleared else { return }
        
        if let pair = findAnyConnectablePair() {
            hintPair = pair
            firstSelection = nil
            hintsRemaining -= 1
            message = nil
            objectWillChange.send()
        } else {
            message = "目前無可連線的提示。"
        }
    }
    
    private func findAnyConnectablePair() -> ((Int,Int),(Int,Int))? {
        if level == 9 {
            var positionsByPairKey: [String: [(Int,Int)]] = [:]
            for r in 1...rows {
                for c in 1...cols {
                    if let n = grid[r][c],
                       let key = n.split(separator: "_").first.map(String.init),
                       key.hasPrefix("pair") {
                        positionsByPairKey[key, default: []].append((r, c))
                    }
                }
            }
            for (_, list) in positionsByPairKey {
                if list.count < 2 { continue }
                for i in 0..<(list.count-1) {
                    for j in (i+1)..<list.count {
                        let a = list[i], b = list[j]
                        if let na = grid[a.0][a.1], let nb = grid[b.0][b.1],
                           samePairID(na, nb),
                           let s1 = suffixTag(na), let s2 = suffixTag(nb), s1 != s2,
                           findPath(from: a, to: b) != nil {
                            return (a, b)
                        }
                    }
                }
            }
            return nil
        } else {
            var positionsByName: [String: [(Int,Int)]] = [:]
            for r in 1...rows {
                for c in 1...cols {
                    if let n = grid[r][c] {
                        positionsByName[n, default: []].append((r, c))
                    }
                }
            }
            for (_, list) in positionsByName {
                if list.count < 2 { continue }
                for i in 0..<(list.count-1) {
                    for j in (i+1)..<list.count {
                        if findPath(from: list[i], to: list[j]) != nil { return (list[i], list[j]) }
                    }
                }
            }
            return nil
        }
    }
    
    func togglePause() {
        guard timeRemaining > 0 else { return }
        guard !levelCleared else { return }
        guard !isPauseDisabled else { return }
        isPaused.toggle()
        objectWillChange.send()
    }
    
    func findPath(from: (Int, Int), to: (Int, Int)) -> [(Int, Int)]? {
        if from == to { return nil }
        if grid[from.0][from.1] == nil || grid[to.0][to.1] == nil { return nil }
        
        let R = rows + 2, C = cols + 2
        let dr = [-1, 0, 1, 0], dc = [0, 1, 0, -1]
        
        struct Node { var r:Int; var c:Int; var dir:Int; var turns:Int }
        var parent = Array(repeating: Array(repeating: Array(repeating: (-1,-1,-1), count: 4), count: C), count: R)
        var visited = Array(repeating: Array(repeating: Array(repeating: false, count: 4), count: C), count: R)
        var q = [Node]()
        
        for d in 0..<4 {
            let nr = from.0 + dr[d], nc = from.1 + dc[d]
            if nr < 0 || nr >= R || nc < 0 || nc >= C { continue }
            if (nr, nc) == to { return [from, to] }
            if grid[nr][nc] == nil {
                visited[nr][nc][d] = true
                parent[nr][nc][d] = (from.0, from.1, -1)
                q.append(Node(r: nr, c: nc, dir: d, turns: 0))
            }
        }
        var head = 0
        while head < q.count {
            let node = q[head]; head += 1
            for nd in 0..<4 {
                let nt = node.turns + (nd == node.dir ? 0 : 1)
                if nt > 2 { continue }
                let nr = node.r + dr[nd], nc = node.c + dc[nd]
                if nr < 0 || nr >= R || nc < 0 || nc >= C { continue }
                if (nr, nc) == to {
                    var route: [(Int,Int)] = []
                    route.append(to)
                    var cr = node.r, cc = node.c, cd = node.dir
                    route.append((cr, cc))
                    while true {
                        let p = parent[cr][cc][cd]
                        if p.0 == -1 { break }
                        route.append((p.0, p.1))
                        if p.2 == -1 { break }
                        cr = p.0; cc = p.1; cd = p.2
                    }
                    if let last = route.last, last != from { route.append(from) }
                    route.reverse()
                    return route
                }
                if grid[nr][nc] == nil && !visited[nr][nc][nd] {
                    visited[nr][nc][nd] = true
                    parent[nr][nc][nd] = (node.r, node.c, node.dir)
                    q.append(Node(r: nr, c: nc, dir: nd, turns: nt))
                }
            }
        }
        return nil
    }
    func canConnect(from: (Int, Int), to: (Int, Int)) -> Bool {
        findPath(from: from, to: to) != nil
    }
    
    func anyMoveExists() -> Bool {
        if level == 9 {
            var positionsByPairKey: [String: [(Int,Int)]] = [:]
            for r in 1...rows {
                for c in 1...cols {
                    if let n = grid[r][c],
                       let key = n.split(separator: "_").first.map(String.init),
                       key.hasPrefix("pair") {
                        positionsByPairKey[key, default: []].append((r, c))
                    }
                }
            }
            for (_, list) in positionsByPairKey {
                if list.count < 2 { continue }
                for i in 0..<(list.count-1) {
                    for j in (i+1)..<list.count {
                        let a = list[i], b = list[j]
                        if let na = grid[a.0][a.1], let nb = grid[b.0][b.1],
                           samePairID(na, nb),
                           let s1 = suffixTag(na), let s2 = suffixTag(nb), s1 != s2,
                           canConnect(from: a, to: b) { return true }
                    }
                }
            }
            return false
        } else {
            var positionsByName: [String: [(Int,Int)]] = [:]
            for r in 1...rows {
                for c in 1...cols {
                    if let n = grid[r][c] {
                        positionsByName[n, default: []].append((r, c))
                    }
                }
            }
            for (_, list) in positionsByName {
                if list.count < 2 { continue }
                for i in 0..<(list.count-1) {
                    for j in (i+1)..<list.count {
                        if canConnect(from: list[i], to: list[j]) { return true }
                    }
                }
            }
            return false
        }
    }
    
    func shuffleIfNeeded(force: Bool = false) {
        var nonEmptyPositions: [(Int, Int)] = []
        var values: [String] = []
        for r in 1...rows {
            for c in 1...cols {
                if let e = grid[r][c] {
                    nonEmptyPositions.append((r, c))
                    values.append(e)
                }
            }
        }
        if values.count < 2 { return }
        var attempts = 0
        let maxAttempts = 200
        var success = false
        while attempts < maxAttempts && !success {
            attempts += 1
            values.shuffle()
            for (idx, pos) in nonEmptyPositions.enumerated() {
                grid[pos.0][pos.1] = values[idx]
            }
            if force || anyMoveExists() { success = true }
        }
        objectWillChange.send()
    }
    
    private func handleNoMovesShuffle() {
        switch mode {
        case .classicHard:
            if hintsRemaining > 0 {
                hintsRemaining -= 1
                shuffleIfNeeded(force: true)
                autoShuffleHintTick &+= 1
            } else {
                stopTimer()
                levelFailed = true
                message = "無可配對且提示為 0，遊戲結束"
                if case .endless = mode { updateEndlessBestsOnFail() }
            }
        default:
            shuffleIfNeeded(force: true)
            autoShuffleHintTick &+= 1
        }
        objectWillChange.send()
    }
    
    func applyLevelFall() {
        let style: FallStyle
        if case .endless = mode {
            style = endlessFallStyle
        } else {
            if level == 9 {
                style = .none
            } else {
                switch level {
                case 3: style = .down
                case 4: style = .up
                case 5: style = .left
                case 6: style = .right
                case 7: style = .splitLR
                case 8: style = .splitUD
                case 9: style = .center
                default: style = .none
                }
            }
        }
        switch style {
        case .none: break
        case .down: fallDown()
        case .up: fallUp()
        case .left: fallLeft()
        case .right: fallRight()
        case .splitLR: splitFallLeftRight()
        case .splitUD: splitFallUpDown()
        case .center: fallTowardCenter()
        }
        objectWillChange.send()
    }
    
    func fallDown() { /* unchanged */ 
        for c in 1...cols {
            var write = rows
            for r in stride(from: rows, through: 1, by: -1) {
                if let v = grid[r][c] {
                    grid[write][c] = v
                    if write != r { grid[r][c] = nil }
                    write -= 1
                }
            }
            if write >= 1 {
                for r in stride(from: write, through: 1, by: -1) {
                    grid[r][c] = nil
                }
            }
        }
    }
    func fallUp() { /* unchanged */
        for c in 1...cols {
            var write = 1
            for r in 1...rows {
                if let v = grid[r][c] {
                    grid[write][c] = v
                    if write != r { grid[r][c] = nil }
                    write += 1
                }
            }
            if write <= rows {
                for r in write...rows {
                    grid[r][c] = nil
                }
            }
        }
    }
    func fallLeft() { /* unchanged */
        for r in 1...rows {
            var write = 1
            for c in 1...cols {
                if let v = grid[r][c] {
                    grid[r][write] = v
                    if write != c { grid[r][c] = nil }
                    write += 1
                }
            }
            if write <= cols {
                for c in write...cols {
                    grid[r][c] = nil
                }
            }
        }
    }
    func fallRight() { /* unchanged */
        for r in 1...rows {
            var write = cols
            for c in stride(from: cols, through: 1, by: -1) {
                if let v = grid[r][c] {
                    grid[r][write] = v
                    if write != c { grid[r][c] = nil }
                    write -= 1
                }
            }
            if write >= 1 {
                for c in stride(from: write, through: 1, by: -1) {
                    grid[r][c] = nil
                }
            }
        }
    }
    func splitFallLeftRight() { /* unchanged */
        let mid = cols / 2
        for r in 1...rows {
            var write = 1
            for c in 1...mid {
                if let v = grid[r][c] {
                    grid[r][write] = v
                    if write != c { grid[r][c] = nil }
                    write += 1
                }
            }
            if write <= mid {
                for c in write...mid {
                    grid[r][c] = nil
                }
            }
            var writeR = cols
            for c in stride(from: cols, through: mid+1, by: -1) {
                if let v = grid[r][c] {
                    grid[r][writeR] = v
                    if writeR != c { grid[r][c] = nil }
                    writeR -= 1
                }
            }
            if writeR >= mid+1 {
                for c in stride(from: writeR, through: mid+1, by: -1) {
                    grid[r][c] = nil
                }
            }
        }
    }
    func splitFallUpDown() { /* unchanged */
        let mid = rows / 2
        for c in 1...cols {
            var write = 1
            for r in 1...mid {
                if let v = grid[r][c] {
                    grid[write][c] = v
                    if write != r { grid[r][c] = nil }
                    write += 1
                }
            }
            if write <= mid {
                for r in write...mid {
                    grid[r][c] = nil
                }
            }
            var writeB = rows
            for r in stride(from: rows, through: mid+1, by: -1) {
                if let v = grid[r][c] {
                    grid[writeB][c] = v
                    if writeB != r { grid[r][c] = nil }
                    writeB -= 1
                }
            }
            if writeB >= mid+1 {
                for r in stride(from: writeB, through: mid+1, by: -1) {
                    grid[r][c] = nil
                }
            }
        }
    }
    func fallTowardCenter() { /* unchanged */
        let midRowLow = rows / 2
        let midRowHigh = midRowLow + 1
        for c in 1...cols {
            var items: [String] = []
            for r in 1...rows {
                if let v = grid[r][c] {
                    items.append(v)
                    grid[r][c] = nil
                }
            }
            var down = midRowLow
            var up = midRowHigh
            var i = 0
            while i < items.count {
                if down >= 1 {
                    grid[down][c] = items[i]
                    i += 1
                    down -= 1
                    if i >= items.count { break }
                }
                if up <= rows {
                    grid[up][c] = items[i]
                    i += 1
                    up += 1
                }
            }
        }
        let midColLeft = cols / 2
        let midColRight = midColLeft + 1
        for r in 1...rows {
            var items: [String] = []
            for c in 1...cols {
                if let v = grid[r][c] {
                    items.append(v)
                    grid[r][c] = nil
                }
            }
            var left = midColLeft
            var right = midColRight
            var i = 0
            while i < items.count {
                if left >= 1 {
                    grid[r][left] = items[i]
                    i += 1
                    left -= 1
                    if i >= items.count { break }
                }
                if right <= cols {
                    grid[r][right] = items[i]
                    i += 1
                    right += 1
                }
            }
        }
    }
    
    func fillBoard(cluster: Bool) {
        for r in 1...rows {
            for c in 1...cols { grid[r][c] = nil }
        }
        let total = rows * cols
        precondition(total % 2 == 0, "Board must have an even number of cells")
        let pairCount = total / 2
        var pool: [String] = []
        pool.reserveCapacity(total)
        var idx = 0
        for _ in 0..<pairCount {
            let name = imageNames[idx % imageNames.count]
            pool.append(name); pool.append(name)
            idx += 1
        }
        pool.shuffle()
        if cluster {
            let clusteringRatio: Double = 0.35
            let targetAdjacentPairs = Int(Double(pairCount) * clusteringRatio)
            var adjacentSlots: [[(Int, Int)]] = []
            for r in 1...rows {
                for c in 1..<(cols) { adjacentSlots.append([(r, c), (r, c + 1)]) }
            }
            for r in 1..<(rows) {
                for c in 1...cols { adjacentSlots.append([(r, c), (r + 1, c)]) }
            }
            adjacentSlots.shuffle()
            var occupied = Set<String>()
            func key(_ rc: (Int, Int)) -> String { "\(rc.0),\(rc.1)" }
            var remainingPool = pool
            var placedPairs = 0
            func popNextPair(from arr: inout [String]) -> String? {
                guard !arr.isEmpty else { return nil }
                let val = arr.removeFirst()
                if let mateIndex = arr.firstIndex(of: val) {
                    arr.remove(at: mateIndex)
                    return val
                }
                return nil
            }
            for slot in adjacentSlots where placedPairs < targetAdjacentPairs {
                let a = slot[0], b = slot[1]
                if !occupied.contains(key(a)) && !occupied.contains(key(b)) {
                    if let val = popNextPair(from: &remainingPool) {
                        grid[a.0][a.1] = val
                        grid[b.0][b.1] = val
                        occupied.insert(key(a)); occupied.insert(key(b))
                        placedPairs += 1
                    } else { break }
                }
            }
            var freeCells: [(Int, Int)] = []
            for r in 1...rows {
                for c in 1...cols {
                    if grid[r][c] == nil { freeCells.append((r, c)) }
                }
            }
            freeCells.shuffle()
            var k = 0
            while k < remainingPool.count && k < freeCells.count {
                grid[freeCells[k].0][freeCells[k].1] = remainingPool[k]
                k += 1
            }
        } else {
            var k = 0
            for r in 1...rows {
                for c in 1...cols {
                    grid[r][c] = pool[k]; k += 1
                }
            }
        }
    }
    
    private func fillBoardForUltimatePairs() {
        for r in 1...rows {
            for c in 1...cols { grid[r][c] = nil }
        }
        let total = rows * cols
        precondition(total % 2 == 0, "Board must have an even number of cells")
        let pairNeeded = total / 2
        let allPairBases: [String] = (1...32).map { String(format: "pair%03d", $0) }
        var chosenBases = allPairBases.shuffled()
        if pairNeeded <= 32 {
            chosenBases = Array(chosenBases.prefix(pairNeeded))
        } else {
            var result = chosenBases
            while result.count < pairNeeded {
                if let randomBase = allPairBases.randomElement() { result.append(randomBase) }
            }
            chosenBases = result
        }
        var names: [String] = []
        names.reserveCapacity(total)
        for base in chosenBases {
            names.append("\(base)_1")
            names.append("\(base)_2")
        }
        names.shuffle()
        var k = 0
        for r in 1...rows {
            for c in 1...cols {
                grid[r][c] = names[k]; k += 1
            }
        }
    }
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

final class SoundPlayer {
    static let shared = SoundPlayer()
    private var cache: [String: AVAudioPlayer] = [:]
    private init() {}
    func play(_ name: String, fileExtension: String? = nil) {
        if let player = cache[name] { restart(player); return }
        if let ext = fileExtension, let url = Bundle.main.url(forResource: name, withExtension: ext),
           let player = try? AVAudioPlayer(contentsOf: url) {
            cache[name] = player; restart(player); return
        }
        let exts = ["wav", "mp3", "aiff", "m4a", "caf"]
        for ext in exts {
            if let url = Bundle.main.url(forResource: name, withExtension: ext),
               let player = try? AVAudioPlayer(contentsOf: url) {
                cache[name] = player; restart(player); return
            }
        }
        if let dataAsset = NSDataAsset(name: name),
           let player = try? AVAudioPlayer(data: dataAsset.data) {
            cache[name] = player; restart(player); return
        }
    }
    private func restart(_ player: AVAudioPlayer) {
        player.prepareToPlay()
        player.currentTime = 0
        player.play()
    }
}
