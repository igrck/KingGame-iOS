import SwiftUI

// MARK: - OpponentHandView (Rakip El Görünümü)
struct OpponentHandView: View {
    let cardCount: Int
    let position: PlayerPosition
    let playerName: String
    let isCurrentPlayer: Bool
    let showDiamondBadge: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            if position == .north {
                playerLabel
                cardStack
            } else {
                cardStack
                playerLabel
            }
        }
    }
    
    // MARK: - Kart Yığını
    private var cardStack: some View {
        ZStack {
            ForEach(0..<cardCount, id: \.self) { index in
                let offset = cardOffset(index: index)
                
                CardView(
                    card: Card(suit: .spades, rank: .ace), // Placeholder, arka yüz gösterilecek
                    isFaceUp: false,
                    size: .small
                )
                .rotationEffect(.degrees(position == .west || position == .east ? 90 : 0))
                .offset(x: offset.x, y: offset.y)
                .zIndex(Double(index))
            }
        }
        .frame(
            width: frameWidth,
            height: frameHeight
        )
    }
    
    // MARK: - Oyuncu Etiketi
    private var playerLabel: some View {
        HStack(spacing: 6) {
            // Sıra göstergesi
            if isCurrentPlayer {
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
                    .shadow(color: .green.opacity(0.6), radius: 4)
            }
            
            Text(playerName)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(isCurrentPlayer ? Color.white : Color.white.opacity(0.6))
            
            // Karo 2 rozeti
            if showDiamondBadge {
                Text("♦2")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.red)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Color.white.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            
            // Kart sayısı
            Text("(\(cardCount))")
                .font(.system(size: 11))
                .foregroundStyle(Color.white.opacity(0.4))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            isCurrentPlayer
                ? Color.green.opacity(0.15)
                : Color.clear
        )
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
    
    // MARK: - Yardımcılar
    
    private func cardOffset(index: Int) -> CGPoint {
        switch position {
        case .north:
            return CGPoint(x: CGFloat(index) * 14 - CGFloat(cardCount - 1) * 7, y: 0)
        case .west, .east:
            return CGPoint(x: 0, y: CGFloat(index) * 10 - CGFloat(cardCount - 1) * 5)
        case .south:
            return .zero
        }
    }
    
    private var frameWidth: CGFloat {
        switch position {
        case .north:
            return CGFloat(cardCount - 1) * 14 + 42
        case .west, .east:
            return 59 // Döndürülmüş small kart yüksekliği
        case .south:
            return 42
        }
    }
    
    private var frameHeight: CGFloat {
        switch position {
        case .north:
            return 59
        case .west, .east:
            return CGFloat(cardCount - 1) * 10 + 42
        case .south:
            return 59
        }
    }
}

#Preview {
    HStack(spacing: 40) {
        OpponentHandView(cardCount: 8, position: .west, playerName: "Batı", isCurrentPlayer: true, showDiamondBadge: false)
        OpponentHandView(cardCount: 13, position: .north, playerName: "Kuzey", isCurrentPlayer: false, showDiamondBadge: true)
        OpponentHandView(cardCount: 5, position: .east, playerName: "Doğu", isCurrentPlayer: false, showDiamondBadge: false)
    }
    .padding()
    .background(Color(red: 0.08, green: 0.12, blue: 0.2))
}
