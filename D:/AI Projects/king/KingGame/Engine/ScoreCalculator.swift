import Foundation

// MARK: - ScoreCalculator (Puan Hesaplayıcı)
/// Kontrat bazlı ceza puanı hesaplama
struct ScoreCalculator {
    
    /// Bir kontrat sonunda tüm oyuncuların puanlarını hesapla
    /// - Parameters:
    ///   - players: Oyuncular (wonTricks dolu)
    ///   - contract: Aktif kontrat
    /// - Returns: Oyuncu UUID → puan dictionary
    static func calculateScores(
        for players: [Player],
        contract: ContractType
    ) -> [UUID: Int] {
        var scores: [UUID: Int] = [:]
        
        for player in players {
            var totalPenalty = 0
            
            for (trickIndex, trick) in player.wonTricks.enumerated() {
                let penalty = PenaltyConfig.calculatePenalty(
                    for: trick,
                    contract: contract,
                    trickIndex: trickIndex,
                    totalTricks: 13
                )
                totalPenalty += penalty
            }
            
            scores[player.id] = totalPenalty
        }
        
        return scores
    }
    
    /// Kontrat sonunda detaylı puan raporu
    static func detailedReport(
        for players: [Player],
        contract: ContractType
    ) -> [PlayerScoreDetail] {
        var details: [PlayerScoreDetail] = []
        
        for player in players {
            var penalties: [PenaltyDetail] = []
            var totalPenalty = 0
            
            switch contract {
            case .noTricks:
                let trickCount = player.wonTricks.count
                if trickCount > 0 {
                    let penalty = trickCount * -50
                    penalties.append(PenaltyDetail(description: "\(trickCount) el aldı", points: penalty))
                    totalPenalty += penalty
                }
                
            case .noQueens:
                var queenCount = 0
                for trick in player.wonTricks {
                    queenCount += trick.filter { $0.rank == .queen }.count
                }
                if queenCount > 0 {
                    let penalty = queenCount * -100
                    penalties.append(PenaltyDetail(description: "\(queenCount) kız aldı", points: penalty))
                    totalPenalty += penalty
                }
                
            case .noKings:
                var kingCount = 0
                for trick in player.wonTricks {
                    kingCount += trick.filter { $0.rank == .king }.count
                }
                if kingCount > 0 {
                    let penalty = kingCount * -150
                    penalties.append(PenaltyDetail(description: "\(kingCount) kral aldı", points: penalty))
                    totalPenalty += penalty
                }
                
            case .noJacks:
                var jackCount = 0
                for trick in player.wonTricks {
                    jackCount += trick.filter { $0.rank == .jack }.count
                }
                if jackCount > 0 {
                    let penalty = jackCount * -75
                    penalties.append(PenaltyDetail(description: "\(jackCount) vale aldı", points: penalty))
                    totalPenalty += penalty
                }
                
            case .noHearts:
                var heartCount = 0
                for trick in player.wonTricks {
                    heartCount += trick.filter { $0.suit == .hearts }.count
                }
                if heartCount > 0 {
                    let penalty = heartCount * -50
                    penalties.append(PenaltyDetail(description: "\(heartCount) kupa aldı", points: penalty))
                    totalPenalty += penalty
                }
                
            case .noKingOfHearts:
                var hasKingOfHearts = false
                for trick in player.wonTricks {
                    if trick.contains(where: { $0.suit == .hearts && $0.rank == .king }) {
                        hasKingOfHearts = true
                        break
                    }
                }
                if hasKingOfHearts {
                    penalties.append(PenaltyDetail(description: "Kupa Kralı aldı", points: -200))
                    totalPenalty += -200
                }
                
            case .noLastTwo:
                let totalTricks = player.wonTricks.count
                // Son 2 el kontrolü — wonTricks'te indeks bilgisini trickIndex ile takip etmeliyiz
                // Burada basitleştirme: GameEngine tarafında trickIndex ile puanlama yapılır
                // ScoreCalculator sadece toplam el sayısını kontrol eder
                // Bu detay GameEngine'de halledilecek
                break
                
            case .king:
                // Tüm cezalar birleşik
                var trickCount = player.wonTricks.count
                var queenCount = 0, kingCount = 0, jackCount = 0, heartCount = 0
                var hasKingOfHearts = false
                
                for trick in player.wonTricks {
                    queenCount += trick.filter { $0.rank == .queen }.count
                    kingCount += trick.filter { $0.rank == .king }.count
                    jackCount += trick.filter { $0.rank == .jack }.count
                    heartCount += trick.filter { $0.suit == .hearts }.count
                    if trick.contains(where: { $0.suit == .hearts && $0.rank == .king }) {
                        hasKingOfHearts = true
                    }
                }
                
                if trickCount > 0 {
                    let p = trickCount * -50
                    penalties.append(PenaltyDetail(description: "\(trickCount) el: \(p)", points: p))
                    totalPenalty += p
                }
                if queenCount > 0 {
                    let p = queenCount * -100
                    penalties.append(PenaltyDetail(description: "\(queenCount) kız: \(p)", points: p))
                    totalPenalty += p
                }
                if kingCount > 0 {
                    let p = kingCount * -150
                    penalties.append(PenaltyDetail(description: "\(kingCount) kral: \(p)", points: p))
                    totalPenalty += p
                }
                if jackCount > 0 {
                    let p = jackCount * -75
                    penalties.append(PenaltyDetail(description: "\(jackCount) vale: \(p)", points: p))
                    totalPenalty += p
                }
                if heartCount > 0 {
                    let p = heartCount * -50
                    penalties.append(PenaltyDetail(description: "\(heartCount) kupa: \(p)", points: p))
                    totalPenalty += p
                }
                if hasKingOfHearts {
                    penalties.append(PenaltyDetail(description: "Kupa Kralı: -200", points: -200))
                    totalPenalty += -200
                }
            }
            
            details.append(PlayerScoreDetail(
                playerID: player.id,
                playerName: player.name,
                penalties: penalties,
                totalScore: totalPenalty
            ))
        }
        
        return details
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
