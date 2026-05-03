import Foundation

// MARK: - Suit (Kart Rengi)
enum Suit: String, CaseIterable, Codable, Comparable, Identifiable {
    case hearts = "hearts"       // Kupa ♥
    case diamonds = "diamonds"   // Karo ♦
    case clubs = "clubs"         // Sinek ♣
    case spades = "spades"       // Maça ♠
    
    var id: String { rawValue }
    
    /// Kart sembolü
    var symbol: String {
        switch self {
        case .hearts:   return "♥"
        case .diamonds: return "♦"
        case .clubs:    return "♣"
        case .spades:   return "♠"
        }
    }
    
    /// Renk (kırmızı/siyah)
    var isRed: Bool {
        self == .hearts || self == .diamonds
    }
    
    /// Türkçe ad
    var displayName: String {
        switch self {
        case .hearts:   return "Kupa"
        case .diamonds: return "Karo"
        case .clubs:    return "Sinek"
        case .spades:   return "Maça"
        }
    }
    
    /// Sıralama için (Comparable)
    private var sortOrder: Int {
        switch self {
        case .spades:   return 0
        case .hearts:   return 1
        case .diamonds: return 2
        case .clubs:    return 3
        }
    }
    
    static func < (lhs: Suit, rhs: Suit) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }
}

// MARK: - Rank (Kart Değeri)
enum Rank: Int, CaseIterable, Codable, Comparable, Identifiable {
    case two = 2
    case three = 3
    case four = 4
    case five = 5
    case six = 6
    case seven = 7
    case eight = 8
    case nine = 9
    case ten = 10
    case jack = 11
    case queen = 12
    case king = 13
    case ace = 14
    
    var id: Int { rawValue }
    
    /// Kart üzerindeki gösterim
    var symbol: String {
        switch self {
        case .two:   return "2"
        case .three: return "3"
        case .four:  return "4"
        case .five:  return "5"
        case .six:   return "6"
        case .seven: return "7"
        case .eight: return "8"
        case .nine:  return "9"
        case .ten:   return "10"
        case .jack:  return "J"
        case .queen: return "Q"
        case .king:  return "K"
        case .ace:   return "A"
        }
    }
    
    /// Türkçe ad
    var displayName: String {
        switch self {
        case .two:   return "İki"
        case .three: return "Üç"
        case .four:  return "Dört"
        case .five:  return "Beş"
        case .six:   return "Altı"
        case .seven: return "Yedi"
        case .eight: return "Sekiz"
        case .nine:  return "Dokuz"
        case .ten:   return "On"
        case .jack:  return "Vale"
        case .queen: return "Kız"
        case .king:  return "Papaz"
        case .ace:   return "As"
        }
    }
    
    static func < (lhs: Rank, rhs: Rank) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// MARK: - Card (Kart)
struct Card: Identifiable, Hashable, Codable {
    let id: UUID
    let suit: Suit
    let rank: Rank
    var isVisible: Bool
    
    init(suit: Suit, rank: Rank, isVisible: Bool = false) {
        self.id = UUID()
        self.suit = suit
        self.rank = rank
        self.isVisible = isVisible
    }
    
    /// Koz kartı mı kontrolü
    func isTrump(_ trumpSuit: Suit?) -> Bool {
        guard let trump = trumpSuit else { return false }
        return suit == trump
    }
    
    /// Gösterim adı (ör. "Karo İki")
    var displayName: String {
        "\(suit.displayName) \(rank.displayName)"
    }
    
    /// Kısa gösterim (ör. "♦2")
    var shortName: String {
        "\(suit.symbol)\(rank.symbol)"
    }
    
    /// VoiceOver erişilebilirlik etiketi
    func accessibilityName(trumpSuit: Suit?) -> String {
        let base = "\(suit.displayName) \(rank.displayName)"
        if isTrump(trumpSuit) {
            return "\(base) — koz kartı"
        }
        return base
    }
    
    /// Karo 2 mi?
    var isDiamondTwo: Bool {
        suit == .diamonds && rank == .two
    }
    
    // MARK: - Hashable (id bazlı değil, suit+rank bazlı eşleştirme)
    func hash(into hasher: inout Hasher) {
        hasher.combine(suit)
        hasher.combine(rank)
    }
    
    static func == (lhs: Card, rhs: Card) -> Bool {
        lhs.suit == rhs.suit && lhs.rank == rhs.rank
    }
}
