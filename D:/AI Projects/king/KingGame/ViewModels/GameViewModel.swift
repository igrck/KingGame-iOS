import SwiftUI
import Observation

// MARK: - GameViewModel
@Observable
class GameViewModel {
    
    // MARK: - Properties
    var engine: GameEngine
    var showTrumpPicker: Bool = false
    var showContractSummary: Bool = false
    var showGameOver: Bool = false
    var showScorePanel: Bool = false
    var animatingTrick: Bool = false
    var lastTrickWinnerIndex: Int? = nil
    var lastTrickWinnerName: String = ""
    var dealingAnimation: Bool = false
    var trumpRevealAnimation: Bool = false
    var message: String = ""
    var messageOpacity: Double = 0
    
    // Namespace ID for matchedGeometryEffect (view tarafında atanır)
    
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
    var trickNumber: Int { gameState.trickNumber }
    var contractIndex: Int { gameState.contractIndex }
    
    // Karo 2 rozeti gösterilecek oyuncu
    var diamondTwoPlayerIndex: Int? {
        guard !gameState.openingRuleApplied || gameState.trickNumber == 0 else { return nil }
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
        engine = GameEngine(players: [
            Player(name: "Sen", isHuman: true, isDealer: true, position: .south),
            Player(name: "Batı", isHuman: false, position: .west),
            Player(name: "Kuzey", isHuman: false, position: .north),
            Player(name: "Doğu", isHuman: false, position: .east)
        ])
        startNewContract()
    }
    
    func startNewContract() {
        engine.startNewRound()
        dealingAnimation = true
        
        // Dağıtım animasyonu sonrası
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.5))
            dealingAnimation = false
            
            // Koz seçimi
            if gameState.dealer.isHuman {
                showTrumpPicker = true
            } else {
                // AI koz seçer
                let trump = engine.aiChooseTrump()
                selectTrump(trump)
            }
        }
    }
    
    func selectTrump(_ suit: Suit) {
        showTrumpPicker = false
        engine.setTrump(suit)
        
        // Koz açıklama animasyonu
        trumpRevealAnimation = true
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.2))
            trumpRevealAnimation = false
            showMessage("Koz: \(suit.symbol) \(suit.displayName)")
            
            // AI sırası ise başlat
            if !gameState.isHumanTurn {
                try? await Task.sleep(for: .seconds(0.5))
                await playAITurns()
            }
        }
    }
    
    // MARK: - Kart Oynama
    
    func humanPlayCard(_ card: Card) {
        guard isHumanTurn else { return }
        guard engine.isValidPlay(card: card, by: humanIndex) else {
            showMessage("Bu kartı oynayamazsınız!")
            return
        }
        
        let success = engine.playCard(playerIndex: humanIndex, card: card)
        guard success else { return }
        
        // El tamamlandıysa değerlendir, yoksa AI oynasın
        Task { @MainActor in
            if gameState.isTrickComplete {
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
    
    // MARK: - AI Oyun Döngüsü
    
    @MainActor
    func playAITurns() async {
        while phase == .playing && !gameState.currentPlayer.isHuman {
            // AI düşünme gecikmesi
            let delay = Double.random(in: 0.6...1.2)
            try? await Task.sleep(for: .seconds(delay))
            
            let aiIndex = gameState.currentPlayerIndex
            let aiPlayer = gameState.players[aiIndex]
            let card = AIPlayer.chooseCard(for: aiPlayer, in: gameState)
            
            let _ = engine.playCard(playerIndex: aiIndex, card: card)
            
            if gameState.isTrickComplete {
                await completeTrick()
                return
            }
        }
    }
    
    // MARK: - El Tamamlama
    
    @MainActor
    func completeTrick() async {
        animatingTrick = true
        
        let winnerID = engine.evaluateTrick()
        if let winnerIdx = players.firstIndex(where: { $0.id == winnerID }) {
            lastTrickWinnerIndex = winnerIdx
            lastTrickWinnerName = players[winnerIdx].name
        }
        
        // Kazanma animasyonu
        try? await Task.sleep(for: .seconds(1.5))
        
        animatingTrick = false
        lastTrickWinnerIndex = nil
        
        engine.advanceToNextTrick()
        
        if gameState.phase == .scoring {
            // Kontrat bitti
            try? await Task.sleep(for: .seconds(0.5))
            await handleContractEnd()
        } else {
            // Sonraki el
            if !gameState.isHumanTurn {
                try? await Task.sleep(for: .seconds(0.3))
                await playAITurns()
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
        
        if engine.advanceToNextContract() {
            // Sonraki kontrat
            startNewContract()
        } else {
            // Oyun bitti
            showGameOver = true
        }
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
            try? await Task.sleep(for: .seconds(2))
            withAnimation(.easeOut(duration: 0.5)) { messageOpacity = 0 }
        }
    }
    
    // Kaydet
    func saveGame() { engine.saveGame() }
    
    // Devam et
    func continueGame() -> Bool {
        if let loadedEngine = GameEngine.loadGame() {
            engine = loadedEngine
            return true
        }
        return false
    }
    
    // Oyuncu pozisyonuna göre bul
    func playerAt(_ position: PlayerPosition) -> Player? {
        players.first(where: { $0.position == position })
    }
    
    func playerIndexAt(_ position: PlayerPosition) -> Int? {
        players.firstIndex(where: { $0.position == position })
    }
}
