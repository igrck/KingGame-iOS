import Foundation

// MARK: - ContractManager (Kontrat Yöneticisi)
/// Rehber modelinde: her el başında seçim sırası olan oyuncu koz/ceza seçer.
/// Bu manager artık seçim sırası ve kontrat geçmişini takip eder.
class ContractManager {

    /// Toplam kontrat sayısı (her oyuncu 5 haktan 4 oyuncu = 20 kontrat, ama oyun
    /// tüm haklar tükenince biter — checkGameOver() bunu yakalar)
    var contractHistory: [ContractType] = []

    /// Aktif kontrat
    var currentContract: ContractType = .elAlmaz

    /// Kontrat geçmişine ekle
    func recordContract(_ contract: ContractType) {
        contractHistory.append(contract)
    }

    /// Toplam oynanan kontrat sayısı
    var totalPlayed: Int { contractHistory.count }

    /// Sıfırla
    func reset() {
        contractHistory = []
        currentContract = .elAlmaz
    }

    /// Kontrat özet bilgisi
    func summary() -> [ContractSummary] {
        contractHistory.enumerated().map { index, contract in
            ContractSummary(
                contract: contract,
                isCompleted: true,
                isCurrent: index == contractHistory.count - 1,
                order: index + 1
            )
        }
    }
}

// MARK: - ContractSummary
struct ContractSummary: Identifiable {
    let id = UUID()
    let contract: ContractType
    let isCompleted: Bool
    let isCurrent: Bool
    let order: Int
}
