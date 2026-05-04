import SwiftUI
import AudioToolbox
import Combine
#if canImport(UIKit)
import UIKit
#endif

// MARK: - GameViewModel
// NOT: @Observable yerine ObservableObject kullanılıyor (iOS 17 makro genişlemesi sorunu).
// View'larda: @State var viewModel = GameViewModel() yerine
//             @StateObject var viewModel = GameViewModel() kullanın.
class GameViewModel: ObservableObject {

    // MARK: - Properties
    @Published var engine: GameEngine
    @Published var selectedCard: Card? = nil          // İki tıklama akışı
    @Published var showContractSummary: Bool = false
    @Published var showGameOver: Bool = false
    @Published var showScorePanel: Bool = false
    @Published var animatingTrick: Bool = false
    @Published var lastTrickWinnerIndex: Int? = nil
    @Published var lastTrickWinnerName: String = ""
    @Published var dealingAnimation: Bool = false
    @Published var message: String = ""
    @Published var messageOpacity: Double = 0
    @Published var shakeCard: Card? = nil             // Geçersiz kart titreşimi

    // Otomatik oynama sayacı
    @Published var autoPlayCountdown: Int = 0
    private var autoPlayTask: Task<Void, Never>? = nil

    // MARK: - Computed
    var gameState: GameState { engine.gameState }
    var players: [Player] { engine.gameState.players }
    var humanPlayer: Player { players.first(where: { $0.isHuman }) ?? players[0] }
    var humanIndex: Int { players.firstIndex(where: { $0.isHuman }) ?? 0 }
    var currentContract: ContractType { gameState.currentContract }
    var trumpSuit: Suit? { gameState.trumpSuit }
    var currentTrick: [PlayedCard] { gameState.currentTrick }
    var phase: GamePhase { gameState.phase }
    var isHumanTurn: Bool { gameState.isHumanTurn }
    var trickCount: Int { gameState.trickCount }

    /// Seçim fazında insan oyuncunun sırası mı?
    var isHumanSelectionTurn: Bool { gameState.isHumanSelectionTurn }

    /// Seçim fazındaki oyuncu
    var selectionPlayer: Player { gameState.selectionPlayer }

    /// Karo 2 rozeti
    var diamondTwoPlayerIndex: Int? {
        guard gameState.trickCount == 0 else { return nil }
        return players.firstIndex(where: { $0.hasDiamondTwo })
    }

    // MARK: - Init
    init() {
        let players = [
            Player(name: "Sen", isHuman: true, isDealer: true, position: .south),
            Player(name: "Batı", isHuman: false, position: .west),
            Player(name: "Kuzey", isHuman: false, position: .north),
            Player(name: "Doğu", isHuman: false, position: .east)
        ]
        self.engine = GameEngine(players: players)
    }

    init(engine: GameEngine) {
        self.engine = engine
    }

    // MARK: - Oyun Akışı

    func startNewGame() {
        // Oyuncuları yeni oyun için sıfırla
        let players = [
            Player(name: "Sen", isHuman: true, isDealer: true, position: .south),
            Player(name: "Batı", isHuman: false, position: .west),
            Player(name: "Kuzey", isHuman: false, position: .north),
            Player(name: "Doğu", isHuman: false, position: .east)
        ]
        // Koz/ceza hakları Player.init ile zaten ayarlanır (kozHaklari:2, cezaHaklari:3)
        _ = players
        engine = GameEngine(players: [
            Player(name: "Sen", isHuman: true, isDealer: true, position: .south),
            Player(name: "Batı", isHuman: false, position: .west),
            Player(name: "Kuzey", isHuman: false, position: .north),
            Player(name: "Doğu", isHuman: false, position: .east)
        ])
        startNewContract()
    }

    func startNewContract() {
        stopAutoPlayTimer()
        selectedCard = nil
        engine.startNewRound()
        dealingAnimation = true

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.2))
            dealingAnimation = false

            // Seçim fazına gir
            await handleSelectionPhase()
        }
    }

    // MARK: - Seçim Fazı

    @MainActor
    func handleSelectionPhase() async {
        // Seçim sırası gelene kadar AI oyuncular seçim yapacak
        while phase == .selection {
            let selIdx = gameState.selectionTurnIndex
            let selPlayer = gameState.players[selIdx]

            if selPlayer.isHuman {
                // İnsan oyuncunun seçim yapması beklenir (UI'da SelectionPhaseView gösterilir)
                return
            } else {
                // AI seçim yapar
                try? await Task.sleep(for: .seconds(0.8))
                let contract = engine.aiSelectContract(playerIndex: selIdx)

                if selPlayer.hasUsedAllRights {
                    engine.applyForcedTrump(playerIndex: selIdx)
                } else {
                    engine.selectContract(playerIndex: selIdx, contract: contract)
                }
                // Seçim sırası ilerle (oyun fazına geçtiyse döngü bitecek)
            }
        }

        // Oyun fazına geçildi
        if phase == .playing {
            showMessage("\(currentContract.displayName) oyunu başladı!")
            if !gameState.isHumanTurn {
                try? await Task.sleep(for: .seconds(0.5))
                await playAITurns()
            } else {
                startAutoPlayTimer()
            }
        }
    }

    /// İnsan oyuncu koz veya ceza seçti
    func humanSelectContract(_ contract: ContractType) {
        guard isHumanSelectionTurn else { return }
        let player = gameState.players[humanIndex]

        // Zorunlu koz kontrolü
        if player.hasUsedAllRights {
            engine.applyForcedTrump(playerIndex: humanIndex)
        } else {
            let success = engine.selectContract(playerIndex: humanIndex, contract: contract)
            if !success {
                showMessage("Bu seçimi yapamazsınız!")
                return
            }
        }

        Task { @MainActor in
            await handleSelectionPhase()
        }
    }

    // MARK: - Kart Oynama (İki Tıklama Akışı)

    func humanTapCard(_ card: Card) {
        guard isHumanTurn else { return }

        if selectedCard == card {
            // İkinci tıklama: oynat
            playHumanCard(card)
        } else {
            // Birinci tıklama: seç
            if engine.isValidPlay(card: card, by: humanIndex) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selectedCard = card
                }
                if hapticsEnabled {
                    #if canImport(UIKit)
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    #endif
                }
                if soundEnabled {
                    AudioServicesPlaySystemSound(1104) // Klavye tock sesi
                }
            } else {
                // Geçersiz kart: titret
                shakeCard = card
                if hapticsEnabled {
                    #if canImport(UIKit)
                    UINotificationFeedbackGenerator().notificationOccurred(.warning)
                    #endif
                }
                if soundEnabled {
                    AudioServicesPlaySystemSound(1053) // Hata sesi
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.shakeCard = nil
                }
                showMessage("Bu kartı şu an oynayamazsınız!")
            }
        }
    }

    private func playHumanCard(_ card: Card) {
        stopAutoPlayTimer()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            selectedCard = nil
        }
        if hapticsEnabled {
            #if canImport(UIKit)
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            #endif
        }
        if soundEnabled {
            AudioServicesPlaySystemSound(1104)
        }

        let success = engine.playCard(playerIndex: humanIndex, card: card)
        guard success else { return }

        Task { @MainActor in
            if gameState.isTrickComplete || gameState.phase == .scoring {
                await completeTrick()
            } else {
                try? await Task.sleep(for: .seconds(0.3))
                await playAITurns()
            }
        }
    }

    func isCardPlayable(_ card: Card) -> Bool {
        guard isHumanTurn else { return false }
        return engine.isValidPlay(card: card, by: humanIndex)
    }

    // MARK: - Otomatik Oynama Zamanlayıcısı

    func startAutoPlayTimer() {
        guard isHumanTurn else { return }
        autoPlayCountdown = Int(gameState.autoPlayTimeout)

        autoPlayTask = Task { @MainActor in
            while autoPlayCountdown > 0 {
                try? await Task.sleep(for: .seconds(1))
                autoPlayCountdown -= 1

                // Son 3 saniye: haptic uyarı
                if autoPlayCountdown <= 3 && autoPlayCountdown > 0 {
                    #if canImport(UIKit)
                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                    #endif
                }
            }
            // Süre doldu: otomatik oyna
            if isHumanTurn {
                engine.autoPlay(for: humanIndex)
                selectedCard = nil
                await completeTrick()
            }
        }
    }

    func stopAutoPlayTimer() {
        autoPlayTask?.cancel()
        autoPlayTask = nil
        autoPlayCountdown = 0
    }

    // MARK: - AI Oyun Döngüsü

    @MainActor
    func playAITurns() async {
        while phase == .playing && !gameState.currentPlayer.isHuman {
            let delay = Double.random(in: 0.5...1.5)
            try? await Task.sleep(for: .seconds(delay))

            let aiIndex = gameState.currentPlayerIndex
            let aiPlayer = gameState.players[aiIndex]
            let card = AIPlayer.chooseCard(for: aiPlayer, in: gameState)

            engine.playCard(playerIndex: aiIndex, card: card)

            if gameState.isTrickComplete || gameState.phase == .scoring {
                await completeTrick()
                return
            }
        }

        // İnsan sırası geldi
        if phase == .playing && gameState.isHumanTurn {
            startAutoPlayTimer()
        }
    }

    @AppStorage("soundEnabled") private var soundEnabled = true
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    
    // MARK: - El Tamamlama

    @MainActor
    func completeTrick() async {
        stopAutoPlayTimer()
        animatingTrick = true

        let winnerID = engine.evaluateTrick()
        if let winnerIdx = players.firstIndex(where: { $0.id == winnerID }) {
            lastTrickWinnerIndex = winnerIdx
            lastTrickWinnerName = players[winnerIdx].name
        }

        // King yapma kontrolü
        if let king = engine.checkKingMade() {
            try? await Task.sleep(for: .seconds(1.5))
            animatingTrick = false
            let finalWinner = lastTrickWinnerIndex ?? 0
            lastTrickWinnerIndex = nil
            showMessage("🎉 \(king.name) KING yaptı!")
            try? await Task.sleep(for: .seconds(1.5))
            engine.gameState.phase = .scoring
            await handleContractEnd()
            return
        }

        // Kız almaz eşit dağılım
        if engine.checkKizEqualDistribution() {
            try? await Task.sleep(for: .seconds(1.5))
            animatingTrick = false
            lastTrickWinnerIndex = nil
            showMessage("Eşit dağılım! Tur tekrarlanıyor...")
            try? await Task.sleep(for: .seconds(1.5))
            startNewContract()
            return
        }

        try? await Task.sleep(for: .seconds(1.4))
        animatingTrick = false
        
        let finalWinner = lastTrickWinnerIndex ?? 0
        lastTrickWinnerIndex = nil

        // Rıfkı anında bitiş veya normal lead ilerleme
        if gameState.phase == .scoring {
            await handleContractEnd()
        } else {
            engine.advanceLead(winnerIndex: finalWinner)

            if gameState.phase == .scoring {
                await handleContractEnd()
            } else {
                if gameState.isHumanTurn {
                    startAutoPlayTimer()
                } else {
                    try? await Task.sleep(for: .seconds(0.3))
                    await playAITurns()
                }
            }
        }
    }

    // MARK: - Kontrat Sonu

    @MainActor
    func handleContractEnd() async {
        let _ = engine.finalizeContractScores()
        showContractSummary = true
    }

    func proceedAfterContractSummary() {
        showContractSummary = false
        selectedCard = nil

        // Oyun bitti mi?
        if engine.checkGameOver() {
            showGameOver = true
            return
        }

        // Seçim sırasını ilerlet (bir sonraki oyuncuya geç)
        engine.advanceSelectionTurn()
        startNewContract()
    }

    // MARK: - Puan Bilgisi

    func scoreForPlayer(_ playerID: UUID) -> Int {
        players.first(where: { $0.id == playerID })?.score ?? 0
    }

    func roundScoreForPlayer(_ playerID: UUID) -> Int {
        gameState.roundScores[playerID] ?? 0
    }

    func getContractSummary() -> [PlayerScoreDetail] {
        ScoreCalculator.detailedReport(for: players, contract: currentContract)
    }

    func getGameResults() -> [PlayerResult] {
        engine.getGameResults()
    }

    // MARK: - Yardımcılar

    func showMessage(_ text: String) {
        message = text
        withAnimation(.easeIn(duration: 0.3)) { messageOpacity = 1 }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2.5))
            withAnimation(.easeOut(duration: 0.5)) { messageOpacity = 0 }
        }
    }

    func saveGame() { engine.saveGame() }

    func continueGame() -> Bool {
        if let loadedEngine = GameEngine.loadGame() {
            engine = loadedEngine
            return true
        }
        return false
    }

    @MainActor
    func resumeGame() async {
        if gameState.phase == .selection {
            await handleSelectionPhase()
        } else if gameState.phase == .playing {
            if gameState.isHumanTurn {
                startAutoPlayTimer()
            } else {
                await playAITurns()
            }
        }
    }

    func playerAt(_ position: PlayerPosition) -> Player? {
        players.first(where: { $0.position == position })
    }

    func playerIndexAt(_ position: PlayerPosition) -> Int? {
        players.firstIndex(where: { $0.position == position })
    }
}
