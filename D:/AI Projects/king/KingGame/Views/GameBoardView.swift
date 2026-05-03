import SwiftUI

struct GameBoardView: View {
    @State var viewModel: GameViewModel
    @Environment(\.dismiss) private var dismiss
    @Namespace private var animation
    
    var body: some View {
        ZStack {
            // Arka plan masası
            Color(red: 0.1, green: 0.35, blue: 0.2) // Koyu yeşil çuha
                .ignoresSafeArea()
                .overlay(
                    RadialGradient(
                        colors: [Color.black.opacity(0), Color.black.opacity(0.4)],
                        center: .center,
                        startRadius: 100,
                        endRadius: 500
                    )
                )
            
            // Oyun Alanı
            VStack {
                // Üst kısım: Kuzey rakip ve Skor/Koz göstergesi
                HStack(alignment: .top) {
                    // Skor Paneli (Sol)
                    Button {
                        withAnimation { viewModel.showScorePanel.toggle() }
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Skor")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.7))
                            Text("\(viewModel.humanPlayer.score)")
                                .font(.title3.bold())
                                .foregroundStyle(.white)
                        }
                        .padding(10)
                        .background(Color.black.opacity(0.3))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    Spacer()
                    
                    // Kuzey Rakip
                    if let north = viewModel.playerAt(.north) {
                        OpponentHandView(
                            player: north,
                            isActive: viewModel.gameState.currentPlayerIndex == viewModel.playerIndexAt(.north),
                            position: .north
                        )
                    }
                    
                    Spacer()
                    
                    // Koz Göstergesi (Sağ)
                    TrumpIndicatorView(
                        trumpSuit: viewModel.trumpSuit,
                        contractType: viewModel.currentContract,
                        showLabel: false
                    )
                    .frame(width: 50, height: 50)
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                Spacer()
                
                // Orta kısım: Batı Rakip, Trick Area, Doğu Rakip
                HStack {
                    // Batı Rakip
                    if let west = viewModel.playerAt(.west) {
                        OpponentHandView(
                            player: west,
                            isActive: viewModel.gameState.currentPlayerIndex == viewModel.playerIndexAt(.west),
                            position: .west
                        )
                        .rotationEffect(.degrees(90))
                        .frame(width: 80) // Rotate nedeniyle width height yer değiştirir
                    }
                    
                    Spacer()
                    
                    // Ortada Oynanan Kartlar
                    TrickAreaView(
                        trick: viewModel.currentTrick,
                        trickWinnerIndex: viewModel.lastTrickWinnerIndex,
                        players: viewModel.players,
                        animationNamespace: animation
                    )
                    .frame(width: 250, height: 250)
                    
                    Spacer()
                    
                    // Doğu Rakip
                    if let east = viewModel.playerAt(.east) {
                        OpponentHandView(
                            player: east,
                            isActive: viewModel.gameState.currentPlayerIndex == viewModel.playerIndexAt(.east),
                            position: .east
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 80)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Alt kısım: Kullanıcı Eli
                HandView(
                    cards: viewModel.humanPlayer.hand,
                    isInteractive: viewModel.isHumanTurn,
                    playableCheck: { viewModel.isCardPlayable($0) },
                    onCardPlayed: { viewModel.humanPlayCard($0) },
                    animationNamespace: animation
                )
                .padding(.bottom, 20)
                .background(
                    // Sıra kullanıcıda ise hafif parlama
                    LinearGradient(
                        colors: [Color.yellow.opacity(viewModel.isHumanTurn ? 0.15 : 0), .clear],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                    .allowsHitTesting(false)
                )
            }
            
            // UI Overlays
            
            // Mesaj (örn. "Koz: Kupa", "Geçersiz Kart")
            if !viewModel.message.isEmpty {
                Text(viewModel.message)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .clipShape(Capsule())
                    .opacity(viewModel.messageOpacity)
                    .animation(.easeInOut, value: viewModel.messageOpacity)
                    .offset(y: -100)
            }
            
            // Koz Seçici
            if viewModel.showTrumpPicker {
                TrumpPickerView(onSelect: { suit in
                    viewModel.selectTrump(suit)
                })
            }
            
            // Skor Tablosu
            if viewModel.showScorePanel {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation { viewModel.showScorePanel = false }
                    }
                
                ScoreView(
                    players: viewModel.players,
                    roundScores: viewModel.gameState.roundScores,
                    onClose: {
                        withAnimation { viewModel.showScorePanel = false }
                    }
                )
                .frame(maxWidth: 400, maxHeight: 500)
                .transition(.scale.combined(with: .opacity))
            }
            
            // Kontrat Özeti
            if viewModel.showContractSummary {
                ContractSummaryView(
                    details: viewModel.getContractSummary(),
                    contract: viewModel.currentContract,
                    onContinue: { viewModel.proceedAfterContractSummary() }
                )
            }
            
            // Oyun Bitti
            if viewModel.showGameOver {
                GameOverView(
                    results: viewModel.getGameResults(),
                    onMainMenu: { dismiss() }
                )
            }
        }
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    viewModel.saveGame()
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.white.opacity(0.8))
                        .font(.title3)
                }
            }
        }
        .onAppear {
            if viewModel.gameState.phase == .dealing {
                // MainMenu'den startNewGame çağrılmış olabilir,
                // Ama ilk açılışta animasyonları ve AI döngüsünü tetiklemek için startNewContract gerekirse.
                // startNewGame zaten viewModel oluşturulurken çağrılıyor (MainMenu içinde)
            }
        }
    }
}

// MARK: - Trump Picker View
struct TrumpPickerView: View {
    let onSelect: (Suit) -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
            
            VStack(spacing: 24) {
                Text("Koz Seç")
                    .font(.title.bold())
                    .foregroundStyle(.white)
                
                HStack(spacing: 20) {
                    ForEach(Suit.allCases) { suit in
                        Button {
                            onSelect(suit)
                        } label: {
                            VStack(spacing: 12) {
                                Text(suit.symbol)
                                    .font(.system(size: 50))
                                    .foregroundStyle(suit.isRed ? .red : .primary)
                                
                                Text(suit.displayName)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                            }
                            .frame(width: 100, height: 140)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
                        }
                    }
                }
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(red: 0.15, green: 0.2, blue: 0.3))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
    }
}
