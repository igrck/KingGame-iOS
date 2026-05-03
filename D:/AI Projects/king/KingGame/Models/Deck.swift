import Foundation

// MARK: - Deck (Deste)
struct Deck {
    /// Destedeki kartlar
    private(set) var cards: [Card]
    
    /// 52 kartlık yeni deste oluştur
    init() {
        var newCards: [Card] = []
        for suit in Suit.allCases {
            for rank in Rank.allCases {
                newCards.append(Card(suit: suit, rank: rank))
            }
        }
        self.cards = newCards
    }
    
    /// Desteyi karıştır (Fisher-Yates — Swift built-in)
    mutating func shuffle() {
        cards.shuffle()
    }
    
    /// Her oyuncuya belirtilen sayıda kart dağıt
    /// - Parameters:
    ///   - players: Kart dağıtılacak oyuncular
    ///   - count: Her oyuncuya verilecek kart sayısı (varsayılan 13)
    /// - Returns: Kartları dağıtılmış oyuncular
    mutating func deal(to players: inout [Player], count: Int = 13) {
        for i in 0..<count {
            for j in 0..<players.count {
                let cardIndex = i * players.count + j
                guard cardIndex < cards.count else { return }
                var card = cards[cardIndex]
                // İnsan oyuncunun kartları görünür
                card.isVisible = players[j].isHuman
                players[j].hand.append(card)
            }
        }
        // Dağıtılan kartları desteden çıkar
        let dealtCount = min(count * players.count, cards.count)
        cards.removeFirst(dealtCount)
    }
    
    /// Yeni deste oluştur ve karıştır
    static func newShuffledDeck() -> Deck {
        var deck = Deck()
        deck.shuffle()
        return deck
    }
    
    /// Destedeki kart sayısı
    var count: Int {
        cards.count
    }
    
    /// Deste boş mu?
    var isEmpty: Bool {
        cards.isEmpty
    }
}
