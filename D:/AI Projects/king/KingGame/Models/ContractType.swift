import Foundation

// MARK: - ContractType (Kontrat Türleri)
/// King oyunundaki 8 kontrat — sabit sıra ile oynanır
enum ContractType: Int, CaseIterable, Codable, Identifiable {
    case noTricks = 0       // El alma
    case noQueens = 1       // Kız alma
    case noKings = 2        // Kral alma
    case noJacks = 3        // Erkek alma
    case noHearts = 4       // Kupa alma
    case noKingOfHearts = 5 // Kupa kral alma
    case noLastTwo = 6      // Son iki el
    case king = 7           // King (tüm cezalar aktif)
    
    var id: Int { rawValue }
    
    /// Kontrat adı (Türkçe)
    var displayName: String {
        switch self {
        case .noTricks:       return "El Alma"
        case .noQueens:       return "Kız Alma"
        case .noKings:        return "Kral Alma"
        case .noJacks:        return "Erkek Alma"
        case .noHearts:       return "Kupa Alma"
        case .noKingOfHearts: return "Kupa Kral"
        case .noLastTwo:      return "Son İki El"
        case .king:           return "King"
        }
    }
    
    /// Kontrat açıklaması
    var description: String {
        switch self {
        case .noTricks:       return "Hiç el almamaya çalışın"
        case .noQueens:       return "Kız (Q) kartı almaktan kaçının"
        case .noKings:        return "Kral (K) kartı almaktan kaçının"
        case .noJacks:        return "Vale (J) kartı almaktan kaçının"
        case .noHearts:       return "Kupa kartı almaktan kaçının"
        case .noKingOfHearts: return "Kupa Kralı (♥K) almaktan kaçının"
        case .noLastTwo:      return "Son 2 eli almaktan kaçının"
        case .king:           return "Tüm cezalar aynı anda aktif!"
        }
    }
    
    /// Kontrat ikonu (SF Symbol)
    var iconName: String {
        switch self {
        case .noTricks:       return "hand.raised.slash"
        case .noQueens:       return "crown"
        case .noKings:        return "crown.fill"
        case .noJacks:        return "person.slash"
        case .noHearts:       return "heart.slash"
        case .noKingOfHearts: return "heart.slash.fill"
        case .noLastTwo:      return "arrow.down.to.line"
        case .king:           return "exclamationmark.triangle.fill"
        }
    }
    
    /// Bu kontratta koz aktif mi?
    var isTrumpActive: Bool {
        true // Tüm kontratlarda koz aktif
    }
    
    /// Sabit sıra ile bir sonraki kontrat
    var next: ContractType? {
        ContractType(rawValue: rawValue + 1)
    }
}

// MARK: - PenaltyConfig (Ceza Yapılandırması)
/// Her kontrat için hangi kartların ceza taşıdığını ve puanlarını tanımlar
struct PenaltyConfig {
    
    /// Bir el (trick) içindeki kartlardan ceza puanı hesapla
    static func calculatePenalty(for cards: [Card], contract: ContractType, trickIndex: Int, totalTricks: Int) -> Int {
        switch contract {
        case .noTricks:
            // Her el -50 puan
            return -50
            
        case .noQueens:
            // Her Kız (Q) -100 puan
            let queenCount = cards.filter { $0.rank == .queen }.count
            return queenCount * -100
            
        case .noKings:
            // Her Kral (K) -150 puan
            let kingCount = cards.filter { $0.rank == .king }.count
            return kingCount * -150
            
        case .noJacks:
            // Her Vale (J) -75 puan
            let jackCount = cards.filter { $0.rank == .jack }.count
            return jackCount * -75
            
        case .noHearts:
            // Her Kupa kartı -50 puan
            let heartCount = cards.filter { $0.suit == .hearts }.count
            return heartCount * -50
            
        case .noKingOfHearts:
            // Kupa Kralı (♥K) -200 puan
            let hasKingOfHearts = cards.contains { $0.suit == .hearts && $0.rank == .king }
            return hasKingOfHearts ? -200 : 0
            
        case .noLastTwo:
            // Son 2 el -250 puan
            let isLastTwo = trickIndex >= (totalTricks - 2)
            return isLastTwo ? -250 : 0
            
        case .king:
            // Tüm cezalar birleşik
            var total = 0
            total += -50 // El alma cezası
            total += cards.filter { $0.rank == .queen }.count * -100
            total += cards.filter { $0.rank == .king }.count * -150
            total += cards.filter { $0.rank == .jack }.count * -75
            total += cards.filter { $0.suit == .hearts }.count * -50
            if cards.contains(where: { $0.suit == .hearts && $0.rank == .king }) {
                total += -200
            }
            // Son iki el kontrolü king kontratında da aktif
            let isLastTwo = trickIndex >= (totalTricks - 2)
            if isLastTwo {
                total += -250
            }
            return total
        }
    }
}

// MARK: - TrumpMode (Koz Belirleme Modu)
enum TrumpMode: String, Codable {
    case dealerChooses = "dealerChooses"   // Dağıtıcı seçer (varsayılan)
    case fixed = "fixed"                   // Sabit koz
    case topCard = "topCard"               // Açık kart kozu
}
