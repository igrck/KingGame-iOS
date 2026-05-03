import Foundation

// MARK: - TrickEvaluator (El Değerlendirici)
/// Kozlu trick değerlendirme algoritması
/// Rehber kuralına göre: koz > lead suit > diğer renkler
struct TrickEvaluator {
    
    /// Bir eli değerlendir ve kazanan oyuncunun ID'sini döndür
    /// - Parameters:
    ///   - trick: Oynanan kartlar (PlayedCard dizisi)
    ///   - leadSuit: Açılan renk
    ///   - trumpSuit: Koz rengi (nil ise kozsuz)
    /// - Returns: Kazanan oyuncunun UUID'si
    static func evaluate(
        trick: [PlayedCard],
        leadSuit: Suit,
        trumpSuit: Suit?
    ) -> UUID {
        guard !trick.isEmpty else {
            fatalError("TrickEvaluator: Boş trick değerlendirilemez")
        }
        
        // Adım 1: Trick içinde koz kartı var mı?
        if let trumpSuit = trumpSuit {
            let trumpCards = trick.filter { $0.card.suit == trumpSuit }
            if !trumpCards.isEmpty {
                // En yüksek kozun sahibi kazanır
                let winner = trumpCards.max(by: { $0.card.rank < $1.card.rank })!
                return winner.playerID
            }
        }
        
        // Adım 2: Koz yoksa → Lead suit içindeki en yüksek kart kazanır
        let leadSuitCards = trick.filter { $0.card.suit == leadSuit }
        if !leadSuitCards.isEmpty {
            let winner = leadSuitCards.max(by: { $0.card.rank < $1.card.rank })!
            return winner.playerID
        }
        
        // Adım 3: Ne koz ne lead suit → Lead oyuncusunun kartı kazanır
        // (Bu durum normalde olmamalı, ama savunma olarak tutuyoruz)
        return trick.first!.playerID
    }
    
    /// Kazanan kartı döndür (animasyon için)
    static func winningCard(
        trick: [PlayedCard],
        leadSuit: Suit,
        trumpSuit: Suit?
    ) -> PlayedCard? {
        guard !trick.isEmpty else { return nil }
        
        let winnerID = evaluate(trick: trick, leadSuit: leadSuit, trumpSuit: trumpSuit)
        return trick.first { $0.playerID == winnerID }
    }
    
    /// Trick içinde koz kullanıldı mı?
    static func wasTrumpPlayed(trick: [PlayedCard], trumpSuit: Suit?) -> Bool {
        guard let trumpSuit = trumpSuit else { return false }
        return trick.contains { $0.card.suit == trumpSuit }
    }
}
