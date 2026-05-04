import Foundation

// MARK: - ContractType (Kontrat Türleri)
/// Rehber modeli: Koz oyunları (+puan) + Ceza oyunları (-puan)
enum ContractType: String, CaseIterable, Codable, Identifiable {

    // MARK: Koz Oyunları (her el +50 puan)
    case trumpSpades   = "trumpSpades"   // Maça Koz ♠
    case trumpHearts   = "trumpHearts"   // Kupa Koz ♥
    case trumpDiamonds = "trumpDiamonds" // Karo Koz ♦
    case trumpClubs    = "trumpClubs"    // Sinek Koz ♣

    // MARK: Ceza Oyunları (koz yok)
    case elAlmaz    = "elAlmaz"    // El Almaz   — her el -50
    case kupaAlmaz  = "kupaAlmaz"  // Kupa Almaz — her kupa -30
    case kizAlmaz   = "kizAlmaz"   // Kız Almaz  — her kız  -100
    case erkekAlmaz = "erkekAlmaz" // Erkek Almaz — vale/papaz -60
    case sonIki     = "sonIki"     // Son İki El  — -180/el
    case rifki      = "rifki"      // Rıfkı (♥K) — -320 sabit

    var id: String { rawValue }

    /// Koz mu yoksa ceza mu?
    var isTrumpContract: Bool {
        switch self {
        case .trumpSpades, .trumpHearts, .trumpDiamonds, .trumpClubs: return true
        default: return false
        }
    }

    /// Koz rengi (sadece koz oyunlarında dolu)
    var trumpSuit: Suit? {
        switch self {
        case .trumpSpades:   return .spades
        case .trumpHearts:   return .hearts
        case .trumpDiamonds: return .diamonds
        case .trumpClubs:    return .clubs
        default:             return nil
        }
    }

    /// Türkçe görüntü adı
    var displayName: String {
        switch self {
        case .trumpSpades:   return "Maça Koz ♠"
        case .trumpHearts:   return "Kupa Koz ♥"
        case .trumpDiamonds: return "Karo Koz ♦"
        case .trumpClubs:    return "Sinek Koz ♣"
        case .elAlmaz:       return "El Almaz"
        case .kupaAlmaz:     return "Kupa Almaz"
        case .kizAlmaz:      return "Kız Almaz"
        case .erkekAlmaz:    return "Erkek Almaz"
        case .sonIki:        return "Son İki"
        case .rifki:         return "Rıfkı"
        }
    }

    /// Kısa açıklama
    var description: String {
        switch self {
        case .trumpSpades:   return "Maça kozlu — her el +50 puan"
        case .trumpHearts:   return "Kupa kozlu — her el +50 puan"
        case .trumpDiamonds: return "Karo kozlu — her el +50 puan"
        case .trumpClubs:    return "Sinek kozlu — her el +50 puan"
        case .elAlmaz:       return "Hiç el almamaya çalışın (-50/el)"
        case .kupaAlmaz:     return "Kupa almaktan kaçının (-30/kupa)"
        case .kizAlmaz:      return "Kız (Q) almaktan kaçının (-100/kız)"
        case .erkekAlmaz:    return "Erkek (Vale/Papaz) almaktan kaçının (-60/erkek)"
        case .sonIki:        return "Son 2 eli almaktan kaçının (-180/el)"
        case .rifki:         return "♥K almaktan kaçının (-320 sabit)"
        }
    }

    /// SF Symbol ikonu
    var iconName: String {
        switch self {
        case .trumpSpades:   return "suit.spade.fill"
        case .trumpHearts:   return "suit.heart.fill"
        case .trumpDiamonds: return "suit.diamond.fill"
        case .trumpClubs:    return "suit.club.fill"
        case .elAlmaz:       return "hand.raised.slash"
        case .kupaAlmaz:     return "heart.slash"
        case .kizAlmaz:      return "crown"
        case .erkekAlmaz:    return "person.slash"
        case .sonIki:        return "arrow.down.to.line"
        case .rifki:         return "exclamationmark.triangle.fill"
        }
    }
}

// MARK: - PenaltyConfig (Ceza Hesaplama — Rehber Değerleri)
struct PenaltyConfig {

    /// Koz turu: kazanılan her el için puan
    static let trumpTrickPoints: Int = 50

    /// Bir elde oynanan kartlardan ceza puan hesapla
    /// - Parameters:
    ///   - cards: Elde alınan kartlar
    ///   - contract: Aktif kontrat türü
    ///   - trickIndex: Bu elim kaçıncı el olduğu (0 tabanlı)
    ///   - totalTricks: Toplam el sayısı (13)
    static func calculatePenalty(
        for cards: [Card],
        contract: ContractType,
        trickIndex: Int,
        totalTricks: Int
    ) -> Int {
        switch contract {

        // --- Koz oyunları: pozitif puan ---
        case .trumpSpades, .trumpHearts, .trumpDiamonds, .trumpClubs:
            return trumpTrickPoints  // +50 her el

        // --- El Almaz: her el -50 ---
        case .elAlmaz:
            return -50

        // --- Kupa Almaz: her kupa -30 ---
        case .kupaAlmaz:
            let kupaCount = cards.filter { $0.suit == .hearts }.count
            return kupaCount * -30

        // --- Kız Almaz: her kız -100 ---
        case .kizAlmaz:
            let kizCount = cards.filter { $0.rank == .queen }.count
            return kizCount * -100

        // --- Erkek Almaz: vale veya papaz (♠♥♦♣ hepsi) -60 ---
        case .erkekAlmaz:
            let erkekCount = cards.filter { $0.isMale }.count
            return erkekCount * -60

        // --- Son İki: sadece son 2 el cezalı -180 ---
        case .sonIki:
            let isLastTwo = trickIndex >= (totalTricks - 2)
            return isLastTwo ? -180 : 0

        // --- Rıfkı: ♥K alındığında -320 ---
        case .rifki:
            let hasRifki = cards.contains { $0.isRifki }
            return hasRifki ? -320 : 0
        }
    }
}

// MARK: - TrumpMode (Koz Belirleme Modu)
enum TrumpMode: String, Codable {
    case dealerChooses = "dealerChooses"
    case fixed         = "fixed"
    case topCard       = "topCard"
}
