import Foundation

// MARK: - GameEngine (Ana Oyun Motoru)
class GameEngine: ObservableObject {
    
    @Published var gameState: GameState
    let contractManager = ContractManager()
    
    // MARK: - Init
    init(players: [Player]) {
        self.gameState = GameState(players: players, trumpMode: .dealerChooses)
    }
    
    init(gameState: GameState) {
        self.gameState = gameState
        contractManager.setContract(at: gameState.contractIndex)
    }
    
    // MARK: - Yeni Tur Başlat
    func startNewRound() {
        // Oyuncuları kontrat için sıfırla
        for i in 0..<gameState.players.count {
            gameState.players[i].resetForNewContract()
        }
        
        // Deste oluştur ve karıştır
        var deck = Deck.newShuffledDeck()
        
        // Kartları dağıt (13'er)
        deck.deal(to: &gameState.players, count: 13)
        
        // Kartları sırala
        for i in 0..<gameState.players.count {
            gameState.players[i].sortHand()
        }
        
        // Kontratı ayarla
        gameState.currentContract = contractManager.currentContract
        gameState.trickNumber = 0
        gameState.currentTrick = []
        gameState.leadSuit = nil
        gameState.openingRuleApplied = false
        gameState.roundScores = [:]
        for player in gameState.players {
            gameState.roundScores[player.id] = 0
        }
        
        // İlk el: karo 2 sahibi açar
        if !gameState.openingRuleApplied {
            findOpeningPlayer()
        }
        
        gameState.phase = .choosingTrump
    }
    
    // MARK: - Karo 2 Bulma
    func findOpeningPlayer() {
        for (index, player) in gameState.players.enumerated() {
            if player.hasDiamondTwo {
                gameState.currentLeadPlayerIndex = index
                gameState.currentPlayerIndex = index
                gameState.openingRuleApplied = true
                return
            }
        }
        // Karo 2 bulunamadıysa (olmamalı), dağıtıcıdan sonraki
        gameState.currentLeadPlayerIndex = (gameState.dealerIndex + 1) % 4
        gameState.currentPlayerIndex = gameState.currentLeadPlayerIndex
    }
    
    // MARK: - Koz Belirleme
    func setTrump(_ suit: Suit) {
        gameState.trumpSuit = suit
        gameState.phase = .playing
    }
    
    // AI için rastgele koz seçimi
    func aiChooseTrump() -> Suit {
        // AI en çok kartı olan rengi koz seçer
        let dealer = gameState.dealer
        var suitCounts: [Suit: Int] = [:]
        for suit in Suit.allCases {
            suitCounts[suit] = dealer.cardsOfSuit(suit).count
        }
        return suitCounts.max(by: { $0.value < $1.value })?.key ?? .spades
    }
    
    // MARK: - Kart Oynama
    func playCard(playerIndex: Int, card: Card) -> Bool {
        guard isValidPlay(card: card, by: playerIndex) else { return false }
        
        let player = gameState.players[playerIndex]
        
        // İlk kart ise lead suit belirle
        if gameState.currentTrick.isEmpty {
            gameState.leadSuit = card.suit
        }
        
        // Kartı oynanan kartlara ekle
        let playedCard = PlayedCard(
            playerID: player.id,
            card: card,
            playerPosition: player.position
        )
        gameState.currentTrick.append(playedCard)
        
        // Kartı oyuncunun elinden çıkar
        gameState.players[playerIndex].removeCard(card)
        
        // Sıradaki oyuncuya geç
        if gameState.currentTrick.count < 4 {
            gameState.currentPlayerIndex = (gameState.currentPlayerIndex + 1) % 4
        } else {
            // El tamamlandı
            gameState.phase = .trickComplete
        }
        
        return true
    }
    
    // MARK: - Geçerlilik Kontrolü
    func isValidPlay(card: Card, by playerIndex: Int) -> Bool {
        let player = gameState.players[playerIndex]
        
        // Oyuncu sırası mı?
        guard playerIndex == gameState.currentPlayerIndex else { return false }
        
        // Kart oyuncunun elinde mi?
        guard player.hand.contains(card) else { return false }
        
        // İlk kart ise her şey geçerli
        guard let leadSuit = gameState.leadSuit else { return true }
        
        // Oyuncunun elinde lead suit var mı?
        if player.hasSuit(leadSuit) {
            // Lead suit oynamak zorunda
            return card.suit == leadSuit
        }
        
        // Lead suit yoksa herhangi kart (koz dahil) oynanabilir
        return true
    }
    
    // MARK: - El Değerlendirme
    func evaluateTrick() -> UUID {
        guard let leadSuit = gameState.leadSuit else {
            fatalError("Lead suit belirlenmemiş")
        }
        
        let winnerID = TrickEvaluator.evaluate(
            trick: gameState.currentTrick,
            leadSuit: leadSuit,
            trumpSuit: gameState.trumpSuit
        )
        
        // Kazanan oyuncuya kartları ekle
        let trickCards = gameState.currentTrick.map { $0.card }
        if let winnerIndex = gameState.players.firstIndex(where: { $0.id == winnerID }) {
            gameState.players[winnerIndex].wonTricks.append(trickCards)
            
            // Puan hesapla (kontrata göre)
            let penalty = PenaltyConfig.calculatePenalty(
                for: trickCards,
                contract: gameState.currentContract,
                trickIndex: gameState.trickNumber,
                totalTricks: 13
            )
            gameState.roundScores[winnerID, default: 0] += penalty
        }
        
        return winnerID
    }
    
    // MARK: - Sonraki El
    /// Kazanan oyuncu bir sonraki eli açar (standart trick oyunu kuralı).
    func advanceToNextTrick(leadingWinnerID winnerID: UUID) {
        if let idx = gameState.players.firstIndex(where: { $0.id == winnerID }) {
            gameState.currentLeadPlayerIndex = idx
            gameState.currentPlayerIndex = idx
        }
        
        // El bilgilerini sıfırla
        gameState.currentTrick = []
        gameState.leadSuit = nil
        gameState.trickNumber += 1
        
        // 13 el tamamlandı mı?
        if gameState.trickNumber >= 13 {
            gameState.phase = .scoring
        } else {
            gameState.phase = .playing
        }
    }
    
    // MARK: - Kontrat Sonu Puanlama
    func finalizeContractScores() -> [UUID: Int] {
        let scores = gameState.roundScores
        
        // Puanları genel skora ekle
        for (playerID, score) in scores {
            if let index = gameState.players.firstIndex(where: { $0.id == playerID }) {
                gameState.players[index].addScore(score)
                // Kontrat bazlı kayıt
                if gameState.contractScores[playerID] == nil {
                    gameState.contractScores[playerID] = [:]
                }
                gameState.contractScores[playerID]?[gameState.currentContract] = score
            }
        }
        
        return scores
    }
    
    // MARK: - Sonraki Kontrat
    func advanceToNextContract() -> Bool {
        contractManager.advanceToNextContract()
        gameState.contractIndex += 1
        
        // Dağıtıcı sırası ilerle
        gameState.dealerIndex = (gameState.dealerIndex + 1) % 4
        for i in 0..<gameState.players.count {
            gameState.players[i].isDealer = (i == gameState.dealerIndex)
        }
        
        if contractManager.isComplete {
            gameState.phase = .gameOver
            return false
        }
        
        return true
    }
    
    // MARK: - Oyun Sonu
    func getGameResults() -> [PlayerResult] {
        gameState.players
            .map { player in
                PlayerResult(
                    playerID: player.id,
                    playerName: player.name,
                    totalScore: player.score,
                    contractScores: gameState.contractScores[player.id] ?? [:]
                )
            }
            .sorted(by: { $0.totalScore > $1.totalScore })
    }
    
    // MARK: - Kaydetme
    func saveGame() {
        gameState.saveToDisk()
    }
    
    static func loadGame() -> GameEngine? {
        guard let state = GameState.loadFromDisk() else { return nil }
        return GameEngine(gameState: state)
    }
}

// MARK: - PlayerResult
struct PlayerResult: Identifiable {
    let id = UUID()
    let playerID: UUID
    let playerName: String
    let totalScore: Int
    let contractScores: [ContractType: Int]
    
    var isWinner: Bool { false } // ViewModel tarafında belirlenir
}
