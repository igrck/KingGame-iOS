import SwiftUI

struct GameBoardView: View {
    @ObservedObject var viewModel: GameViewModel
    @Environment(\.dismiss) private var dismiss
    @Namespace private var animation

    var body: some View {
        ZStack {
            // Arka plan masası
            Color(red: 0.1, green: 0.35, blue: 0.2)
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
                // Üst kısım: Kuzey rakip
                HStack {
                    Spacer()

                    // Kuzey Rakip
                    if let north = viewModel.playerAt(.north) {
                        VStack(spacing: 8) {
                            Text(viewModel.currentContract.displayName)
                                .font(.caption.bold())
                                .foregroundStyle(.yellow)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Capsule())
                                
                            OpponentHandView(
                                cardCount: north.hand.count,
                                position: .north,
                                playerName: north.name,
                                isCurrentPlayer: viewModel.gameState.currentPlayerIndex == viewModel.playerIndexAt(.north),
                                showDiamondBadge: north.hasDiamondTwo && viewModel.gameState.trickCount == 0
                            )
                        }
                    }

                    Spacer()
                }
                .padding(.top, 10)

                Spacer()

                // Orta kısım: Batı, Trick Area, Doğu
                HStack {
                    if let west = viewModel.playerAt(.west) {
                        OpponentHandView(
                            cardCount: west.hand.count,
                            position: .west,
                            playerName: west.name,
                            isCurrentPlayer: viewModel.gameState.currentPlayerIndex == viewModel.playerIndexAt(.west),
                            showDiamondBadge: west.hasDiamondTwo && viewModel.gameState.trickCount == 0
                        )
                    }

                    Spacer()

                    TrickAreaView(
                        playedCards: viewModel.currentTrick,
                        trumpSuit: viewModel.trumpSuit,
                        animatingTrick: viewModel.animatingTrick,
                        winnerName: viewModel.lastTrickWinnerName
                    )
                    .frame(width: 250, height: 250)

                    Spacer()

                    if let east = viewModel.playerAt(.east) {
                        OpponentHandView(
                            cardCount: east.hand.count,
                            position: .east,
                            playerName: east.name,
                            isCurrentPlayer: viewModel.gameState.currentPlayerIndex == viewModel.playerIndexAt(.east),
                            showDiamondBadge: east.hasDiamondTwo && viewModel.gameState.trickCount == 0
                        )
                    }
                }
                .padding(.horizontal)

                Spacer()

                // Otomatik oynama sayacı (sadece insan sırası ve countdown aktifse)
                if viewModel.isHumanTurn && viewModel.autoPlayCountdown > 0 {
                    HStack {
                        Spacer()
                        AutoPlayTimerView(
                            countdown: viewModel.autoPlayCountdown,
                            totalSeconds: Int(viewModel.gameState.autoPlayTimeout)
                        )
                        .padding(.trailing, 16)
                    }
                }

                // Alt kısım: Kullanıcı Eli
                HandView(
                    cards: viewModel.humanPlayer.hand,
                    trumpSuit: viewModel.trumpSuit,
                    isHumanTurn: viewModel.isHumanTurn,
                    selectedCard: viewModel.selectedCard,
                    shakeCard: viewModel.shakeCard,
                    isCardPlayable: { viewModel.isCardPlayable($0) },
                    onCardTap: { viewModel.humanTapCard($0) }
                )
                .padding(.bottom, 20)
                .background(
                    LinearGradient(
                        colors: [Color.yellow.opacity(viewModel.isHumanTurn ? 0.15 : 0), .clear],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                    .allowsHitTesting(false)
                )
            }

            // UI Overlays

            // Mesaj
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

            // Seçim Fazı: Koz/Ceza Seçim Ekranı
            if viewModel.phase == .selection && viewModel.isHumanSelectionTurn {
                SelectionPhaseView(
                    player: viewModel.humanPlayer,
                    onSelectContract: { contract in
                        viewModel.humanSelectContract(contract)
                    }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
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
                    contractName: viewModel.currentContract.displayName,
                    trickNumber: viewModel.gameState.trickCount,
                    isPresented: $viewModel.showScorePanel
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
        .onAppear {
            Task { await viewModel.resumeGame() }
        }
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Menu {
                    Section("Oyun Bilgisi") {
                        Text("Oyun Türü: \(viewModel.currentContract.displayName)")
                        if let suit = viewModel.trumpSuit {
                            Text("Koz: \(suit.displayName)")
                        }
                    }
                    
                    Section("Senin Durumun") {
                        Text("Skor: \(viewModel.humanPlayer.score)")
                        Text("Kalan Koz Hakkı: \(viewModel.humanPlayer.kozHaklari)")
                        Text("Kalan Ceza Hakkı: \(viewModel.humanPlayer.cezaHaklari)")
                    }
                    
                    Section {
                        Button {
                            withAnimation { viewModel.showScorePanel.toggle() }
                        } label: {
                            Label("Skor Tablosunu Aç", systemImage: "list.number")
                        }
                        
                        Button(role: .destructive) {
                            viewModel.saveGame()
                            dismiss()
                        } label: {
                            Label("Oyundan Çık", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    }
                } label: {
                    Image(systemName: "line.3.horizontal")
                        .font(.title2)
                        .foregroundStyle(.white.opacity(0.9))
                        .padding(10)
                        .background(Color.black.opacity(0.4))
                        .clipShape(Circle())
                }
            }
        }
    }
}
