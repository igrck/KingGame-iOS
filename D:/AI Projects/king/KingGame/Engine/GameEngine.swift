import Foundation

// MARK: - GameEngine (Ana Oyun Motoru)
/// Rehber §4.1 fonksiyon listesini uygular.
class GameEngine: ObservableObject {

    @Published var gameState: GameState

    // MARK: - Init
    init(players: [Player]) {
        self.gameState = GameState(players: players)
    }

    init(gameState: GameState) {
        self.gameState = gameState
    }

    // MARK: - 1. Yeni Tur Başlat
    /// Deste oluştur, karıştır, saatin TERS yönünde dağıt, karo 2'yi bul.
    func startNewRound() {
        // Oyuncuları yeni kontrat için sıfırla
        for i in 0..<gameState.players.count {
            gameState.players[i].resetForNewContract()
        }

        // Bayrakları sıfırla
        gameState.trumpBroken = false
        gameState.cupaBroken = false
        gameState.trumpSuit = nil
        gameState.trickCount = 0
        gameState.currentTrick = []
        gameState.leadSuit = nil
        gameState.openingRuleApplied = false
        gameState.roundScores = [:]
        for player in gameState.players {
            gameState.roundScores[player.id] = 0
        }

        // Deste oluştur ve karıştır
        var deck = Deck.newShuffledDeck()

        // Saatin ters yönünde dağıt (13'er kart)
        deck.deal(to: &gameState.players, count: 13)

        // Kartları sırala
        for i in 0..<gameState.players.count {
            gameState.players[i].sortHand()
        }

        // Karo 2 kuralı SADECE İLK ELDE geçerlidir
        if gameState.contractIndex == 0 {
            findOpeningPlayer()
            gameState.selectionTurnIndex = gameState.currentLeadPlayerIndex
        } else {
            // Sonraki ellerde sıra bir öncekine (saatin tersine) geçmiştir
            // advanceSelectionTurn zaten selectionTurnIndex'i güncelledi.
            // İlk oynamayı (lead) kontratı seçen kişi yapar.
            gameState.currentLeadPlayerIndex = gameState.selectionTurnIndex
            gameState.currentPlayerIndex = gameState.selectionTurnIndex
        }

        gameState.phase = .selection
    }

    // MARK: - 2. Karo 2 Bulma
    func findOpeningPlayer() {
        for (index, player) in gameState.players.enumerated() {
            if player.hasDiamondTwo {
                gameState.currentLeadPlayerIndex = index
                gameState.currentPlayerIndex = index
                gameState.openingRuleApplied = true
                return
            }
        }
        // Fallback (olmamalı)
        gameState.currentLeadPlayerIndex = (gameState.dealerIndex + 1) % 4
        gameState.currentPlayerIndex = gameState.currentLeadPlayerIndex
    }

    // MARK: - 3. Yeniden Dağıtım Kontrolü
    /// Zorunlu kozu olan ve elinde 10'dan büyük kart olmayan oyuncu yeniden dağıtım isteyebilir.
    func canRequestRedeal(player: Player) -> Bool {
        guard player.hasUsedAllRights else { return false }
        return !player.hasHighCard
    }

    // MARK: - 4. Kontrat Seçimi (Koz veya Ceza)
    /// Seçim sırasındaki oyuncu koz veya ceza seçer.
    /// - Returns: Seçim başarılı mı (hak var mı?)
    @discardableResult
    func selectContract(playerIndex: Int, contract: ContractType) -> Bool {
        guard playerIndex == gameState.selectionTurnIndex else { return false }
        var player = gameState.players[playerIndex]

        if contract.isTrumpContract {
            guard player.kozHaklari > 0 else { return false }
            player.kozHaklari -= 1
            gameState.trumpSuit = contract.trumpSuit
        } else {
            guard player.cezaHaklari > 0 else { return false }
            player.cezaHaklari -= 1
            gameState.trumpSuit = nil
        }

        gameState.players[playerIndex] = player
        gameState.currentContract = contract

        // Seçim sırası bitti, oyuna geç
        gameState.phase = .playing
        // currentPlayerIndex karo 2 sahibinden başlar (zaten ayarlı)
        return true
    }

    /// Zorunlu koz: Tüm hakları tüketmiş oyuncu en çok kartı olan rengi koz olarak oynar.
    func applyForcedTrump(playerIndex: Int) {
        let player = gameState.players[playerIndex]
        // En çok kartı olan rengi bul
        var suitCounts: [Suit: Int] = [:]
        for suit in Suit.allCases {
            suitCounts[suit] = player.cardsOfSuit(suit).count
        }
        let bestSuit = suitCounts.max(by: { $0.value < $1.value })?.key ?? .spades
        let contract: ContractType
        switch bestSuit {
        case .spades:   contract = .trumpSpades
        case .hearts:   contract = .trumpHearts
        case .diamonds: contract = .trumpDiamonds
        case .clubs:    contract = .trumpClubs
        }
        gameState.currentContract = contract
        gameState.trumpSuit = bestSuit
        gameState.phase = .playing
    }

    /// AI için kontrat seçimi
    func aiSelectContract(playerIndex: Int) -> ContractType {
        let player = gameState.players[playerIndex]

        if player.kozHaklari > 0 {
            // En çok kartı olan rengi koz seç
            var suitCounts: [Suit: Int] = [:]
            for suit in Suit.allCases {
                suitCounts[suit] = player.cardsOfSuit(suit).count
            }
            let bestSuit = suitCounts.max(by: { $0.value < $1.value })?.key ?? .spades
            switch bestSuit {
            case .spades:   return .trumpSpades
            case .hearts:   return .trumpHearts
            case .diamonds: return .trumpDiamonds
            case .clubs:    return .trumpClubs
            }
        } else if player.cezaHaklari > 0 {
            // Basit: el almaz seç
            return .elAlmaz
        } else {
            // Zorunlu koz durumu
            return .trumpSpades
        }
    }

    // MARK: - 5. Kart Geçerlilik Kontrolü
    func isValidPlay(card: Card, by playerIndex: Int) -> Bool {
        let player = gameState.players[playerIndex]

        // Oyuncu sırası mı?
        guard playerIndex == gameState.currentPlayerIndex else { return false }
        // Kart elde mi?
        guard player.hand.contains(card) else { return false }

        // İlk kart ise: koz kuralı kontrolü
        if gameState.currentTrick.isEmpty {
            // Koz kırılmamışsa koz ile başlanamaz (koz oyunlarında)
            if gameState.currentContract.isTrumpContract,
               let trump = gameState.trumpSuit,
               card.suit == trump,
               !gameState.trumpBroken {
                // Sadece elinde koz dışında kart yoksa koz atabilir
                let nonTrumps = player.hand.filter { $0.suit != trump }
                if !nonTrumps.isEmpty { return false }
            }
            // Kupa almaz/rıfkı: kupa kırılmamışsa kupa ile başlanamaz
            if (gameState.currentContract == .kupaAlmaz || gameState.currentContract == .rifki),
               card.suit == .hearts,
               !gameState.cupaBroken {
                let nonHearts = player.hand.filter { $0.suit != .hearts }
                if !nonHearts.isEmpty { return false }
            }
            return true
        }

        // Lead suit varsa
        guard let leadSuit = gameState.leadSuit else { return true }

        if player.hasSuit(leadSuit) {
            // Lead suit oynamak zorunda
            if card.suit != leadSuit { return false }
            
            // Eğer koz oyunuysa BÜYÜTME ZORUNLULUĞU var
            if gameState.currentContract.isTrumpContract {
                // Yerdeki en büyük lead suit kartını bul
                let playedLeadCards = gameState.currentTrick.filter { $0.card.suit == leadSuit }
                if let maxPlayed = playedLeadCards.max(by: { $0.card.rank < $1.card.rank }) {
                    // Elimizde bu karttan daha büyük bir lead suit kartı var mı?
                    let higherCards = player.hand.filter { $0.suit == leadSuit && $0.rank > maxPlayed.card.rank }
                    if !higherCards.isEmpty {
                        // Eğer varsa, atmak istediğimiz kart bunlardan biri olmak zorunda!
                        return higherCards.contains(card)
                    }
                }
            }
            return true
        }

        // Lead suit yoksa
        if gameState.currentContract.isTrumpContract {
            // Koz kontratı kuralı: Eğer elinde koz varsa, koz ATMAK ZORUNDA
            if let trumpSuit = gameState.trumpSuit, player.hasSuit(trumpSuit) {
                if card.suit != trumpSuit { return false }
                
                // Yerdeki en büyük koz kartını bul
                let playedTrumpCards = gameState.currentTrick.filter { $0.card.suit == trumpSuit }
                if let maxPlayed = playedTrumpCards.max(by: { $0.card.rank < $1.card.rank }) {
                    // Elimizde bu kozdan daha büyük bir koz kartı var mı?
                    let higherTrumps = player.hand.filter { $0.suit == trumpSuit && $0.rank > maxPlayed.card.rank }
                    if !higherTrumps.isEmpty {
                        // Eğer varsa, atmak istediğimiz koz bunlardan biri olmak zorunda!
                        return higherTrumps.contains(card)
                    }
                }
                return true
            }
        } else {
            // Ceza kontratı kuralı: Eğer atabileceği zorunlu bir ceza kartı varsa onu ATMAK ZORUNDA
            if let mandatoryCards = PenaltyEnforcer.mandatoryCards(for: player, in: gameState) {
                return mandatoryCards.contains(card)
            }
        }

        return true
    }

    // MARK: - 6. Kart Oynama
    @discardableResult
    func playCard(playerIndex: Int, card: Card) -> Bool {
        guard isValidPlay(card: card, by: playerIndex) else { return false }

        let player = gameState.players[playerIndex]

        // İlk kart: lead suit belirle
        if gameState.currentTrick.isEmpty {
            gameState.leadSuit = card.suit
        }

        // Koz kırıldı mı? (koz oyununda)
        if gameState.currentContract.isTrumpContract,
           let trump = gameState.trumpSuit,
           card.suit == trump {
            gameState.trumpBroken = true
        }

        // Kupa düştü mü? (kupaAlmaz / rıfkı)
        if card.suit == .hearts {
            gameState.cupaBroken = true
        }

        // Kartı oynanan kartlara ekle
        let playedCard = PlayedCard(
            playerID: player.id,
            card: card,
            playerPosition: player.position
        )
        gameState.currentTrick.append(playedCard)

        // Kartı elinden çıkar
        gameState.players[playerIndex].removeCard(card)

        // Rıfkı kontrolü: ♥K oynandığında anında el biter
        if gameState.currentContract == .rifki && card.isRifki {
            checkRifkiImmediateEnd()
            return true
        }

        // Sıradaki oyuncu (saatin TERS yönünde)
        if gameState.currentTrick.count < 4 {
            gameState.currentPlayerIndex = (gameState.currentPlayerIndex - 1 + 4) % 4
        } else {
            gameState.phase = .trickComplete
        }

        return true
    }

    // MARK: - 7. El Değerlendirme
    func evaluateTrick() -> UUID {
        guard let leadSuit = gameState.leadSuit else {
            fatalError("Lead suit belirlenmemiş")
        }

        let winnerID = TrickEvaluator.evaluate(
            trick: gameState.currentTrick,
            leadSuit: leadSuit,
            trumpSuit: gameState.trumpSuit
        )

        let trickCards = gameState.currentTrick.map { $0.card }
        if let winnerIndex = gameState.players.firstIndex(where: { $0.id == winnerID }) {
            gameState.players[winnerIndex].wonTricks.append(trickCards)

            // Puan hesapla
            let points = PenaltyConfig.calculatePenalty(
                for: trickCards,
                contract: gameState.currentContract,
                trickIndex: gameState.trickCount,
                totalTricks: 13
            )
            gameState.roundScores[winnerID, default: 0] += points
        }

        return winnerID
    }

    // MARK: - 8. Rıfkı Anında Bitiş
    /// ♥K alındığında el anında biter; kalan kartlar oynanmaz.
    func checkRifkiImmediateEnd() {
        // Kalan 4'e tamamlanmamış trick anında bitirilir
        // Rıfkı'nın cezası trick sahibine eklenir
        let trickCards = gameState.currentTrick.map { $0.card }
        guard let leadSuit = gameState.leadSuit else { return }

        let winnerID = TrickEvaluator.evaluate(
            trick: gameState.currentTrick,
            leadSuit: leadSuit,
            trumpSuit: nil
        )
        if let winnerIndex = gameState.players.firstIndex(where: { $0.id == winnerID }) {
            gameState.players[winnerIndex].wonTricks.append(trickCards)
            gameState.roundScores[winnerID, default: 0] += -320
        }

        gameState.phase = .scoring
    }

    // MARK: - 9. King Yapma Kontrolü
    /// 13/13 elin tamamını alan oyuncu King yapmış sayılır.
    func checkKingMade() -> Player? {
        gameState.players.first { $0.wonTricks.count == 13 }
    }

    // MARK: - 10. Kız Almaz Eşit Dağılım
    /// Her oyuncu tam 1 kız aldıysa tur iptal edilir ve yeniden dağıtılır.
    func checkKizEqualDistribution() -> Bool {
        guard gameState.currentContract == .kizAlmaz else { return false }
        let queenCounts = gameState.players.map { player in
            player.wonTricks.flatMap { $0 }.filter { $0.rank == .queen }.count
        }
        return queenCounts.allSatisfy { $0 == 1 }
    }

    // MARK: - 11. Lead İlerleme
    /// Bir sonraki el: lead o eli kazanan oyuncuya geçer
    func advanceLead(winnerIndex: Int) {
        gameState.currentLeadPlayerIndex = winnerIndex
        gameState.currentPlayerIndex = winnerIndex
        gameState.currentTrick = []
        gameState.leadSuit = nil
        gameState.trickCount += 1

        if gameState.trickCount >= 13 {
            gameState.phase = .scoring
        } else {
            gameState.phase = .playing
        }
    }

    // MARK: - 12. Kontrat Sonu Puanlama
    func finalizeContractScores() -> [UUID: Int] {
        let scores = gameState.roundScores

        for (playerID, score) in scores {
            if let index = gameState.players.firstIndex(where: { $0.id == playerID }) {
                gameState.players[index].addScore(score)
                let contractKey = gameState.currentContract.rawValue
                if gameState.contractScores[playerID] == nil {
                    gameState.contractScores[playerID] = [:]
                }
                gameState.contractScores[playerID]?[contractKey] = score
            }
        }

        return scores
    }

    // MARK: - 13. Otomatik Oynama
    /// Süre dolduğunda en az değerli geçerli kartı seçer ve oynar.
    func autoPlay(for playerIndex: Int) {
        let player = gameState.players[playerIndex]
        let validCards = player.hand.filter { isValidPlay(card: $0, by: playerIndex) }
        guard let card = validCards.min(by: { $0.rank < $1.rank }) else { return }
        playCard(playerIndex: playerIndex, card: card)
    }

    // MARK: - 14. Sonraki Kontrat
    /// Seçim sırası bir sonraki oyuncuya geçer (yeni el başlar).
    func advanceSelectionTurn() {
        gameState.selectionTurnIndex = (gameState.selectionTurnIndex - 1 + 4) % 4
        gameState.contractIndex += 1
    }

    // MARK: - 15. Oyun Bitti Kontrolü (20 el = her oyuncu 5 seçim hakkı toplamda)
    func checkGameOver() -> Bool {
        // Tüm oyuncuların koz + ceza hakları tükendi mi
        let allUsed = gameState.players.allSatisfy { $0.kozHaklari == 0 && $0.cezaHaklari == 0 }
        if allUsed {
            gameState.phase = .gameOver
            return true
        }
        return false
    }

    // MARK: - Kaydet / Yükle
    func saveGame() {
        gameState.saveToDisk()
    }

    static func loadGame() -> GameEngine? {
        guard let state = GameState.loadFromDisk() else { return nil }
        return GameEngine(gameState: state)
    }

    // MARK: - Oyun Sonuçları
    func getGameResults() -> [PlayerResult] {
        gameState.players
            .map { player in
                PlayerResult(
                    playerID: player.id,
                    playerName: player.name,
                    totalScore: player.score,
                    contractScores: [:]  // Basit tutuluyor
                )
            }
            .sorted(by: { $0.totalScore > $1.totalScore })
    }
}

// MARK: - PlayerResult
struct PlayerResult: Identifiable {
    let id = UUID()
    let playerID: UUID
    let playerName: String
    let totalScore: Int
    let contractScores: [String: Int]

    var isWinner: Bool { totalScore >= 0 }
}
