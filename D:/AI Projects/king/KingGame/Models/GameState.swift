import Foundation

// MARK: - GamePhase (Oyun Aşaması)
enum GamePhase: String, Codable {
    case dealing        // Kart dağıtımı
    case choosingTrump  // Koz seçimi
    case playing        // Oyun devam ediyor
    case trickComplete  // El tamamlandı (animasyon arası)
    case scoring        // Kontrat sonu puanlama
    case gameOver       // Oyun bitti
}

// MARK: - PlayedCard (Oynanan Kart)
/// Trick alanında gösterilmek üzere oynanan kart bilgisi
struct PlayedCard: Identifiable, Codable {
    let id: UUID
    let playerID: UUID
    let card: Card
    let playerPosition: PlayerPosition
    
    init(playerID: UUID, card: Card, playerPosition: PlayerPosition) {
        self.id = UUID()
        self.playerID = playerID
        self.card = card
        self.playerPosition = playerPosition
    }
}

// MARK: - GameState (Oyun Durumu)
/// Tüm oyun durumunu tutan ana yapı — Codable ile kayıt/yükleme destekli
struct GameState: Codable {
    // MARK: Oyuncular
    var players: [Player]
    
    // MARK: Kontrat bilgisi
    var currentContract: ContractType
    var contractIndex: Int  // Kaçıncı kontrat (0-7)
    
    // MARK: Koz bilgisi
    var trumpSuit: Suit?
    var trumpMode: TrumpMode
    
    // MARK: Aktif el (trick) bilgisi
    var currentTrick: [PlayedCard]
    var leadSuit: Suit?
    var trickNumber: Int  // Bu kontrattaki kaçıncı el (0-12)
    
    // MARK: Sıra bilgisi
    var currentLeadPlayerIndex: Int
    var currentPlayerIndex: Int
    var dealerIndex: Int
    
    // MARK: Özel kurallar
    var openingRuleApplied: Bool  // Karo 2 başlangıç kuralı uygulandı mı
    
    // MARK: Puanlama
    var roundScores: [UUID: Int]  // Tur bazlı puanlar
    var contractScores: [UUID: [ContractType: Int]]  // Kontrat bazlı puan geçmişi
    
    // MARK: Oyun aşaması
    var phase: GamePhase
    
    // MARK: - Init
    init(players: [Player], trumpMode: TrumpMode = .dealerChooses) {
        self.players = players
        self.currentContract = .noTricks  // İlk kontrat
        self.contractIndex = 0
        self.trumpSuit = nil
        self.trumpMode = trumpMode
        self.currentTrick = []
        self.leadSuit = nil
        self.trickNumber = 0
        self.currentLeadPlayerIndex = 0
        self.currentPlayerIndex = 0
        self.dealerIndex = 0
        self.openingRuleApplied = false
        self.roundScores = [:]
        self.contractScores = [:]
        self.phase = .dealing
        
        // Puanları sıfırla
        for player in players {
            self.roundScores[player.id] = 0
            self.contractScores[player.id] = [:]
        }
    }
    
    // MARK: - Computed Properties
    
    /// Aktif oyuncu
    var currentPlayer: Player {
        players[currentPlayerIndex]
    }
    
    /// Dağıtıcı oyuncu
    var dealer: Player {
        players[dealerIndex]
    }
    
    /// Lead oyuncu
    var leadPlayer: Player {
        players[currentLeadPlayerIndex]
    }
    
    /// Bu elde kaç kart oynandı
    var cardsPlayedInTrick: Int {
        currentTrick.count
    }
    
    /// El tamamlandı mı (4 kart oynandı mı)
    var isTrickComplete: Bool {
        currentTrick.count == 4
    }
    
    /// Kontrat tamamlandı mı (13 el oynandı mı)
    var isContractComplete: Bool {
        trickNumber >= 13
    }
    
    /// Oyun tamamlandı mı (tüm 8 kontrat)
    var isGameComplete: Bool {
        contractIndex >= ContractType.allCases.count
    }
    
    /// İnsan oyuncunun sırası mı
    var isHumanTurn: Bool {
        currentPlayer.isHuman && phase == .playing
    }
    
    // MARK: - Kayıt/Yükleme
    
    /// Oyun durumunu JSON olarak kaydet
    func saveToJSON() -> Data? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        return try? encoder.encode(self)
    }
    
    /// JSON'dan oyun durumu yükle
    static func loadFromJSON(_ data: Data) -> GameState? {
        let decoder = JSONDecoder()
        return try? decoder.decode(GameState.self, from: data)
    }
    
    /// Documents dizinine kaydet
    func saveToDisk() {
        guard let data = saveToJSON() else { return }
        let url = GameState.saveFileURL
        try? data.write(to: url)
    }
    
    /// Documents dizininden yükle
    static func loadFromDisk() -> GameState? {
        let url = saveFileURL
        guard let data = try? Data(contentsOf: url) else { return nil }
        return loadFromJSON(data)
    }
    
    /// Kayıt dosyası silme
    static func deleteSaveFile() {
        let url = saveFileURL
        try? FileManager.default.removeItem(at: url)
    }
    
    /// Kayıtlı oyun var mı
    static var hasSavedGame: Bool {
        FileManager.default.fileExists(atPath: saveFileURL.path)
    }
    
    /// Kayıt dosyası URL'i
    private static var saveFileURL: URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documents.appendingPathComponent("king_save.json")
    }
}
