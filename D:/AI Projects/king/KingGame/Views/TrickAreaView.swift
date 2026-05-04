import SwiftUI
import AudioToolbox

// MARK: - TrickAreaView (Oynanan Kartlar Alanı)
struct TrickAreaView: View {
    let playedCards: [PlayedCard]
    let trumpSuit: Suit?
    let animatingTrick: Bool
    let winnerName: String?
    
    @State private var trumpGlow = false
    
    @AppStorage("soundEnabled") private var soundEnabled = true
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    
    var body: some View {
        ZStack {
            // Masa yüzeyi
            Circle()
                .fill(Color.white.opacity(0.03))
                .frame(width: 200, height: 200)
            
            Circle()
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
                .frame(width: 200, height: 200)
            
            // Oynanan kartlar
            ForEach(playedCards) { played in
                let offset = cardPosition(for: played.playerPosition)
                
                CardView(
                    card: played.card,
                    isFaceUp: true,
                    isTrump: played.card.isTrump(trumpSuit),
                    size: .normal
                )
                .offset(x: offset.x, y: offset.y)
                .transition(.asymmetric(
                    insertion: .move(edge: edgeForPosition(played.playerPosition))
                        .combined(with: .opacity),
                    removal: .scale.combined(with: .opacity)
                ))
                .zIndex(Double(playedCards.firstIndex(where: { $0.id == played.id }) ?? 0))
                
                // Koz atıldığında parıltı
                if played.card.isTrump(trumpSuit) {
                    Circle()
                        .fill(Color.yellow.opacity(trumpGlow ? 0.3 : 0))
                        .frame(width: 80, height: 80)
                        .offset(x: offset.x, y: offset.y)
                        .blur(radius: 10)
                        .animation(
                            .easeInOut(duration: 0.6).repeatCount(2, autoreverses: true),
                            value: trumpGlow
                        )
                }
            }
            
            // Kazanan göstergesi
            if animatingTrick, let winner = winnerName {
                VStack(spacing: 4) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.yellow)
                    
                    Text(winner)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.black.opacity(0.6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.yellow.opacity(0.4), lineWidth: 1)
                        )
                )
                .transition(.scale.combined(with: .opacity))
                .zIndex(100)
            }
        }
        .frame(width: 240, height: 240)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: playedCards.count)
        .animation(.easeInOut(duration: 0.3), value: animatingTrick)
        .onChange(of: playedCards.count) { _, newCount in
            // Koz kartı oynandığında parıltı tetikle
            if let last = playedCards.last, last.card.isTrump(trumpSuit) {
                trumpGlow = true
                if hapticsEnabled {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                }
                if soundEnabled {
                    AudioServicesPlaySystemSound(1057)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    trumpGlow = false
                }
            }
        }
    }
    
    // MARK: - Pozisyon Hesaplama
    private func cardPosition(for position: PlayerPosition) -> CGPoint {
        switch position {
        case .south: return CGPoint(x: 0, y: 45)
        case .north: return CGPoint(x: 0, y: -45)
        case .west:  return CGPoint(x: -50, y: 0)
        case .east:  return CGPoint(x: 50, y: 0)
        }
    }
    
    private func edgeForPosition(_ position: PlayerPosition) -> Edge {
        switch position {
        case .south: return .bottom
        case .north: return .top
        case .west:  return .leading
        case .east:  return .trailing
        }
    }
}

#Preview {
    TrickAreaView(
        playedCards: [
            PlayedCard(playerID: UUID(), card: Card(suit: .hearts, rank: .ace), playerPosition: .south),
            PlayedCard(playerID: UUID(), card: Card(suit: .hearts, rank: .king), playerPosition: .west),
            PlayedCard(playerID: UUID(), card: Card(suit: .spades, rank: .queen), playerPosition: .north),
        ],
        trumpSuit: .spades,
        animatingTrick: false,
        winnerName: nil
    )
    .background(Color(red: 0.08, green: 0.12, blue: 0.2))
}
