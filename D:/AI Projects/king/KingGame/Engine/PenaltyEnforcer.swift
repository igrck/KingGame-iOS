import Foundation

// MARK: - PenaltyEnforcer (Ceza Zorunluluk Motoru)
/// Her ceza kontratı için zorunlu kart kurallarını uygular.
/// Rehber §4.3'e göre ayrı sınıf olarak gerçekleştirildi.
struct PenaltyEnforcer {

    /// Aktif ceza kontratta oyuncunun oynamak ZORUNDA olduğu kartları döndürür.
    /// Eğer zorunlu kart yoksa nil döner (serbest seçim).
    static func mandatoryCards(for player: Player, in gameState: GameState) -> [Card]? {
        guard let leadSuit = gameState.leadSuit else { return nil }

        // Oyuncunun elinde lead suit var mı?
        let hasLeadSuit = player.hasSuit(leadSuit)

        // Lead suit varsa → zorunlu kural yok
        if hasLeadSuit { return nil }

        switch gameState.currentContract {

        // MARK: Kupa Almaz
        // Elinde lead suit yoksa kupa atmak zorunda (kupa varsa)
        case .kupaAlmaz:
            let kupalar = player.hand.filter { $0.suit == .hearts }
            return kupalar.isEmpty ? nil : kupalar

        // MARK: Rıfkı
        // Elinde lead suit yoksa ♥K atmak zorunda (varsa)
        case .rifki:
            if let rifki = player.hand.first(where: { $0.isRifki }) {
                return [rifki]
            }
            return nil

        // MARK: Kız Almaz
        // Elinde lead suit yoksa kız atmak zorunda.
        case .kizAlmaz:
            let kizlar = player.hand.filter { $0.rank == .queen }
            return kizlar.isEmpty ? nil : kizlar

        // MARK: Erkek Almaz
        // Elinde lead suit yoksa erkek atmak zorunda (varsa).
        case .erkekAlmaz:
            let erkekler = player.hand.filter { $0.isMale }
            return erkekler.isEmpty ? nil : erkekler

        default:
            return nil
        }
    }

    /// Oyuncunun bu kartı oynamasına ceza kontratı açısından izin var mı?
    static func isCardAllowed(_ card: Card, for player: Player, in gameState: GameState) -> Bool {
        guard let mandatory = mandatoryCards(for: player, in: gameState) else { return true }
        return mandatory.contains(card)
    }

    /// Kupa almaz / Rıfkı için kupa düştü mü? (cupaBroken bayrağı güncelleme yardımcısı)
    static func didHeartFall(in trick: [PlayedCard]) -> Bool {
        trick.contains { $0.card.suit == .hearts }
    }

    /// Rıfkı bu elde alındı mı?
    static func wasRifkiTaken(in trick: [PlayedCard], by winnerID: UUID) -> Bool {
        // Kazanan ID'ye ait kupa papazı oynandıysa
        trick.contains { $0.card.isRifki }
    }
}
