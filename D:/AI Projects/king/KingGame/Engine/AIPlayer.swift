import Foundation

// MARK: - AIPlayer (Yapay Zeka Oyuncu)
struct AIPlayer {

    static func chooseCard(for player: Player, in gameState: GameState) -> Card {
        let validCards = getValidCards(for: player, in: gameState)
        guard !validCards.isEmpty else { return player.hand.first! }
        return applyStrategy(validCards: validCards, player: player, gameState: gameState)
    }

    static func getValidCards(for player: Player, in gameState: GameState) -> [Card] {
        // Tüm kartları kontrol et, geçerli olanları döndür
        let engine = GameEngine(gameState: gameState)
        let playerIndex = gameState.players.firstIndex(where: { $0.id == player.id }) ?? 0
        let valid = player.hand.filter { engine.isValidPlay(card: $0, by: playerIndex) }
        if valid.isEmpty { return player.hand }
        return valid
    }

    private static func applyStrategy(validCards: [Card], player: Player, gameState: GameState) -> Card {
        switch gameState.currentContract {

        // Koz oyunları: en fazla eli almaya çalış (yüksek kart oyna)
        case .trumpSpades, .trumpHearts, .trumpDiamonds, .trumpClubs:
            return playHigh(validCards, gameState)

        // El almaz: en az değerli kartı oyna
        case .elAlmaz, .sonIki:
            return playLow(validCards, gameState)

        // Kupa almaz: kupalardan kaçın
        case .kupaAlmaz:
            return avoidSuit(validCards, .hearts, gameState)

        // Kız almaz: kızlardan kaçın, varsa at
        case .kizAlmaz:
            return avoidRank(validCards, .queen, gameState)

        // Erkek almaz: vale ve papazlardan kaçın
        case .erkekAlmaz:
            return avoidMales(validCards, gameState)

        // Rıfkı: ♥K'yı at fırsatın varsa
        case .rifki:
            return avoidRifki(validCards, gameState)
        }
    }

    // MARK: - Strateji Yardımcıları

    private static func playHigh(_ cards: [Card], _ gs: GameState) -> Card {
        if let ls = gs.leadSuit {
            let sc = cards.filter { $0.suit == ls }
            if !sc.isEmpty { return sc.max(by: { $0.rank < $1.rank })! }
        }
        return cards.max(by: { $0.rank < $1.rank }) ?? cards[0]
    }

    private static func playLow(_ cards: [Card], _ gs: GameState) -> Card {
        if let ls = gs.leadSuit {
            let sc = cards.filter { $0.suit == ls }
            if !sc.isEmpty { return sc.min(by: { $0.rank < $1.rank })! }
            // Lead suit yok: cezasız kart at
            let noPenalty = cards.filter { !$0.isPenaltyCard(for: gs.currentContract) }
            if !noPenalty.isEmpty { return noPenalty.max(by: { $0.rank < $1.rank })! }
        }
        return cards.min(by: { $0.rank < $1.rank }) ?? cards[0]
    }

    private static func avoidRank(_ cards: [Card], _ rank: Rank, _ gs: GameState) -> Card {
        if let ls = gs.leadSuit {
            let sc = cards.filter { $0.suit == ls }
            if !sc.isEmpty { return sc.min(by: { $0.rank < $1.rank })! }
            // Lead suit yok: penalty kartı at
            let penalty = cards.filter { $0.rank == rank }
            if !penalty.isEmpty { return penalty[0] }
        }
        let safe = cards.filter { $0.rank != rank }
        return (safe.isEmpty ? cards : safe).min(by: { $0.rank < $1.rank })!
    }

    private static func avoidSuit(_ cards: [Card], _ suit: Suit, _ gs: GameState) -> Card {
        if let ls = gs.leadSuit {
            let sc = cards.filter { $0.suit == ls }
            if !sc.isEmpty { return sc.min(by: { $0.rank < $1.rank })! }
            let dumps = cards.filter { $0.suit == suit }
            if !dumps.isEmpty { return dumps.max(by: { $0.rank < $1.rank })! }
        }
        let safe = cards.filter { $0.suit != suit }
        return (safe.isEmpty ? cards : safe).min(by: { $0.rank < $1.rank })!
    }

    private static func avoidMales(_ cards: [Card], _ gs: GameState) -> Card {
        if let ls = gs.leadSuit {
            let sc = cards.filter { $0.suit == ls }
            if !sc.isEmpty { return sc.min(by: { $0.rank < $1.rank })! }
            let males = cards.filter { $0.isMale }
            if !males.isEmpty { return males[0] }
        }
        let safe = cards.filter { !$0.isMale }
        return (safe.isEmpty ? cards : safe).min(by: { $0.rank < $1.rank })!
    }

    private static func avoidRifki(_ cards: [Card], _ gs: GameState) -> Card {
        if let ls = gs.leadSuit {
            let sc = cards.filter { $0.suit == ls }
            if !sc.isEmpty { return sc.min(by: { $0.rank < $1.rank })! }
            // Rıfkı'yı at fırsatı
            if let rifki = cards.first(where: { $0.isRifki }) { return rifki }
        }
        let safe = cards.filter { !$0.isRifki }
        return (safe.isEmpty ? cards : safe).min(by: { $0.rank < $1.rank })!
    }
}
