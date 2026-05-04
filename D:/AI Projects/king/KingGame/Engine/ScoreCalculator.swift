import Foundation

// MARK: - ScoreCalculator (Puan Hesaplayıcı)
/// Rehber §1.7 puan sistemi esas alınarak yeniden yazıldı.
struct ScoreCalculator {

    /// Kontrat sonunda tüm oyuncuların puan raporunu hazırla
    static func detailedReport(
        for players: [Player],
        contract: ContractType
    ) -> [PlayerScoreDetail] {
        var details: [PlayerScoreDetail] = []

        for player in players {
            var penalties: [PenaltyDetail] = []
            var totalScore = 0

            switch contract {

            // MARK: Koz Oyunları (+50/el)
            case .trumpSpades, .trumpHearts, .trumpDiamonds, .trumpClubs:
                let trickCount = player.wonTricks.count
                if trickCount > 0 {
                    let points = trickCount * 50
                    penalties.append(PenaltyDetail(description: "\(trickCount) el aldı", points: points))
                    totalScore += points
                }

            // MARK: El Almaz (-50/el)
            case .elAlmaz:
                let trickCount = player.wonTricks.count
                if trickCount > 0 {
                    let penalty = trickCount * -50
                    penalties.append(PenaltyDetail(description: "\(trickCount) el aldı", points: penalty))
                    totalScore += penalty
                }

            // MARK: Kupa Almaz (-30/kupa)
            case .kupaAlmaz:
                var kupaCount = 0
                for trick in player.wonTricks {
                    kupaCount += trick.filter { $0.suit == .hearts }.count
                }
                if kupaCount > 0 {
                    let penalty = kupaCount * -30
                    penalties.append(PenaltyDetail(description: "\(kupaCount) kupa aldı", points: penalty))
                    totalScore += penalty
                }

            // MARK: Kız Almaz (-100/kız)
            case .kizAlmaz:
                var kizCount = 0
                for trick in player.wonTricks {
                    kizCount += trick.filter { $0.rank == .queen }.count
                }
                if kizCount > 0 {
                    let penalty = kizCount * -100
                    penalties.append(PenaltyDetail(description: "\(kizCount) kız aldı", points: penalty))
                    totalScore += penalty
                }

            // MARK: Erkek Almaz (-60/erkek: vale veya papaz)
            case .erkekAlmaz:
                var erkekCount = 0
                for trick in player.wonTricks {
                    erkekCount += trick.filter { $0.isMale }.count
                }
                if erkekCount > 0 {
                    let penalty = erkekCount * -60
                    penalties.append(PenaltyDetail(description: "\(erkekCount) erkek (vale/papaz) aldı", points: penalty))
                    totalScore += penalty
                }

            // MARK: Son İki (-180/el — sadece son 2 el)
            case .sonIki:
                // wonTricks sıralaması: ilk alınan önce
                let total = player.wonTricks.count
                let totalInContract = 13 // Standart el sayısı
                let sonIkiCount = 0
                // Tüm oyuncuların trick index'ini bilmiyoruz burada,
                // GameEngine'de trickIndex bazlı hesaplama yapılıyor.
                // Burada basitleştirilmiş: son 2 el kontrolü roundScores üzerinden yapılır.
                // Bu metod sadece görsel rapor için; gerçek puan GameEngine'de hesaplanır.
                _ = total
                _ = totalInContract
                _ = sonIkiCount
                // Puan GameEngine'deki roundScores'dan alınır
                let sonIkiScore = 0 // Placeholder — gerçek değer GameEngine'den gelir
                if sonIkiScore != 0 {
                    penalties.append(PenaltyDetail(description: "Son iki el", points: sonIkiScore))
                    totalScore += sonIkiScore
                }

            // MARK: Rıfkı (-320 sabit)
            case .rifki:
                var hasRifki = false
                for trick in player.wonTricks {
                    if trick.contains(where: { $0.isRifki }) {
                        hasRifki = true
                        break
                    }
                }
                if hasRifki {
                    penalties.append(PenaltyDetail(description: "Rıfkı (♥K) aldı", points: -320))
                    totalScore += -320
                }
            }

            details.append(PlayerScoreDetail(
                playerID: player.id,
                playerName: player.name,
                penalties: penalties,
                totalScore: totalScore
            ))
        }

        return details
    }

    /// Toplam oyun sonucu hesapla (≥0 kazandı, <0 kaybetti)
    static func isWinner(_ player: Player) -> Bool {
        player.score >= 0
    }
}

// MARK: - Yardımcı Yapılar

/// Ceza detayı
struct PenaltyDetail: Identifiable {
    let id = UUID()
    let description: String
    let points: Int
}

/// Oyuncu puan detayı
struct PlayerScoreDetail: Identifiable {
    let id = UUID()
    let playerID: UUID
    let playerName: String
    let penalties: [PenaltyDetail]
    let totalScore: Int
}
