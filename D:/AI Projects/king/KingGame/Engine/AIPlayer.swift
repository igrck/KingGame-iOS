import Foundation

// MARK: - AIPlayer (Yapay Zeka Oyuncu)
struct AIPlayer {
    
    static func chooseCard(for player: Player, in gameState: GameState) -> Card {
        let validCards = getValidCards(for: player, in: gameState)
        guard !validCards.isEmpty else { return player.hand.first! }
        return applyStrategy(validCards: validCards, player: player, gameState: gameState)
    }
    
    static func getValidCards(for player: Player, in gameState: GameState) -> [Card] {
        guard let leadSuit = gameState.leadSuit else { return player.hand }
        let suitCards = player.cardsOfSuit(leadSuit)
        return suitCards.isEmpty ? player.hand : suitCards
    }
    
    private static func applyStrategy(validCards: [Card], player: Player, gameState: GameState) -> Card {
        switch gameState.currentContract {
        case .noTricks, .noLastTwo:
            return playLow(validCards, gameState)
        case .noQueens:
            return avoidRank(validCards, .queen, gameState)
        case .noKings:
            return avoidRank(validCards, .king, gameState)
        case .noJacks:
            return avoidRank(validCards, .jack, gameState)
        case .noHearts:
            return avoidSuit(validCards, .hearts, gameState)
        case .noKingOfHearts:
            return avoidSpecific(validCards, .hearts, .king, gameState)
        case .king:
            return playLow(validCards, gameState)
        }
    }
    
    private static func playLow(_ cards: [Card], _ gs: GameState) -> Card {
        if gs.leadSuit == nil {
            return cards.min(by: { $0.rank < $1.rank }) ?? cards[0]
        }
        if let ls = gs.leadSuit {
            let sc = cards.filter { $0.suit == ls }
            if !sc.isEmpty { return sc.min(by: { $0.rank < $1.rank })! }
            let nt = cards.filter { !$0.isTrump(gs.trumpSuit) }
            if !nt.isEmpty { return nt.max(by: { $0.rank < $1.rank })! }
        }
        return cards.min(by: { $0.rank < $1.rank }) ?? cards[0]
    }
    
    private static func avoidRank(_ cards: [Card], _ rank: Rank, _ gs: GameState) -> Card {
        if gs.leadSuit == nil {
            let safe = cards.filter { $0.rank != rank }
            return (safe.isEmpty ? cards : safe).min(by: { $0.rank < $1.rank })!
        }
        if let ls = gs.leadSuit {
            let sc = cards.filter { $0.suit == ls }
            if !sc.isEmpty { return sc.min(by: { $0.rank < $1.rank })! }
            let penalty = cards.filter { $0.rank == rank }
            if !penalty.isEmpty { return penalty[0] }
        }
        return cards.max(by: { $0.rank < $1.rank }) ?? cards[0]
    }
    
    private static func avoidSuit(_ cards: [Card], _ suit: Suit, _ gs: GameState) -> Card {
        if gs.leadSuit == nil {
            let safe = cards.filter { $0.suit != suit }
            return (safe.isEmpty ? cards : safe).min(by: { $0.rank < $1.rank })!
        }
        if let ls = gs.leadSuit {
            let sc = cards.filter { $0.suit == ls }
            if !sc.isEmpty { return sc.min(by: { $0.rank < $1.rank })! }
            let dumps = cards.filter { $0.suit == suit }
            if !dumps.isEmpty { return dumps.max(by: { $0.rank < $1.rank })! }
        }
        return cards.max(by: { $0.rank < $1.rank }) ?? cards[0]
    }
    
    private static func avoidSpecific(_ cards: [Card], _ s: Suit, _ r: Rank, _ gs: GameState) -> Card {
        if gs.leadSuit == nil {
            let safe = cards.filter { !($0.suit == s && $0.rank == r) }
            return (safe.isEmpty ? cards : safe).min(by: { $0.rank < $1.rank })!
        }
        if let ls = gs.leadSuit {
            let sc = cards.filter { $0.suit == ls }
            if !sc.isEmpty { return sc.min(by: { $0.rank < $1.rank })! }
            if let target = cards.first(where: { $0.suit == s && $0.rank == r }) { return target }
        }
        return cards.max(by: { $0.rank < $1.rank }) ?? cards[0]
    }
}
