import Foundation

// MARK: - Player (Oyuncu)
struct Player: Identifiable, Codable {
    let id: UUID
    var name: String
    var hand: [Card]
    var wonTricks: [[Card]]
    var score: Int
    var isHuman: Bool
    var isDealer: Bool
    
    /// Oyuncunun masa pozisyonu (0: güney/insan, 1: batı, 2: kuzey, 3: doğu)
    var position: PlayerPosition
    
    init(
        name: String,
        isHuman: Bool = false,
        isDealer: Bool = false,
        position: PlayerPosition = .south
    ) {
        self.id = UUID()
        self.name = name
        self.hand = []
        self.wonTricks = []
        self.score = 0
        self.isHuman = isHuman
        self.isDealer = isDealer
        self.position = position
    }
    
    /// Eldeki kartları sırala (renk → değer)
    mutating func sortHand() {
        hand.sort { card1, card2 in
            if card1.suit != card2.suit {
                return card1.suit < card2.suit
            }
            return card1.rank < card2.rank
        }
    }
    
    /// Belirli bir renkteki kartlar
    func cardsOfSuit(_ suit: Suit) -> [Card] {
        hand.filter { $0.suit == suit }
    }
    
    /// Elinde belirli bir renk var mı?
    func hasSuit(_ suit: Suit) -> Bool {
        hand.contains { $0.suit == suit }
    }
    
    /// Karo 2 elinde mi?
    var hasDiamondTwo: Bool {
        hand.contains { $0.isDiamondTwo }
    }
    
    /// Elden kart çıkar
    mutating func removeCard(_ card: Card) {
        hand.removeAll { $0 == card }
    }
    
    /// Kazandığı el sayısı
    var trickCount: Int {
        wonTricks.count
    }
    
    /// Yeni kontrat için sıfırla
    mutating func resetForNewContract() {
        hand = []
        wonTricks = []
    }
    
    /// Toplam skoru güncelle
    mutating func addScore(_ points: Int) {
        score += points
    }
}

// MARK: - PlayerPosition (Oyuncu Pozisyonu)
enum PlayerPosition: Int, Codable, CaseIterable {
    case south = 0  // Alt - İnsan oyuncu
    case west = 1   // Sol
    case north = 2  // Üst
    case east = 3   // Sağ
    
    var displayName: String {
        switch self {
        case .south: return "Güney"
        case .west:  return "Batı"
        case .north: return "Kuzey"
        case .east:  return "Doğu"
        }
    }
    
    /// Rotation açısı (kapalı kartlar için)
    var rotationDegrees: Double {
        switch self {
        case .south: return 0
        case .west:  return 90
        case .north: return 0
        case .east:  return -90
        }
    }
}
