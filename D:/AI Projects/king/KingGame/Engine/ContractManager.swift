import Foundation

// MARK: - ContractManager (Kontrat Yöneticisi)
/// Sabit sıralı kontrat yönetimi ve koz yapılandırması
class ContractManager {
    
    /// Tüm kontratlar sabit sırayla
    let contracts: [ContractType] = ContractType.allCases
    
    /// Aktif kontrat indeksi
    private(set) var currentIndex: Int = 0
    
    /// Aktif kontrat
    var currentContract: ContractType {
        guard currentIndex < contracts.count else {
            return .king // Güvenlik
        }
        return contracts[currentIndex]
    }
    
    /// Tüm kontratlar tamamlandı mı?
    var isComplete: Bool {
        currentIndex >= contracts.count
    }
    
    /// Kalan kontrat sayısı
    var remainingContracts: Int {
        max(0, contracts.count - currentIndex)
    }
    
    /// Bir sonraki kontrata geç
    /// - Returns: Yeni kontrat, eğer tüm kontratlar bittiyse nil
    @discardableResult
    func advanceToNextContract() -> ContractType? {
        currentIndex += 1
        guard !isComplete else { return nil }
        return currentContract
    }
    
    /// Belirli bir kontrata git (test amaçlı)
    func setContract(at index: Int) {
        guard index >= 0 && index < contracts.count else { return }
        currentIndex = index
    }
    
    /// Kontratı sıfırla
    func reset() {
        currentIndex = 0
    }
    
    /// Belirli kontrat için koz modu
    func trumpMode(for contract: ContractType) -> TrumpMode {
        // Tüm kontratlar için dağıtıcı seçer (kullanıcının tercihine göre)
        return .dealerChooses
    }
    
    /// Kontrat ilerleme yüzdesi
    var progressPercentage: Double {
        Double(currentIndex) / Double(contracts.count)
    }
    
    /// Kontrat özet bilgisi
    func summary() -> [ContractSummary] {
        contracts.enumerated().map { index, contract in
            ContractSummary(
                contract: contract,
                isCompleted: index < currentIndex,
                isCurrent: index == currentIndex,
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
