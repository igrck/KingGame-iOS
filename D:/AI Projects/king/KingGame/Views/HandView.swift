import SwiftUI

// MARK: - HandView (Oyuncunun Eli)
struct HandView: View {
    let cards: [Card]
    let trumpSuit: Suit?
    let isHumanTurn: Bool
    let selectedCard: Card?       // ViewModel'dan gelir
    let shakeCard: Card?          // Geçersiz kart titreşim
    let isCardPlayable: (Card) -> Bool
    let onCardTap: (Card) -> Void // humanTapCard tetikler
    
    @State private var appeared = false
    
    var body: some View {
        GeometryReader { geo in
            let totalWidth = geo.size.width - 40 // Padding
            let cardWidth: CGFloat = 63
            let maxOverlap = max(10, totalWidth - cardWidth)
            let spacing = cards.count > 1 ? min(cardWidth * 0.6, maxOverlap / CGFloat(cards.count - 1)) : 0
            let totalCardsWidth = cardWidth + spacing * CGFloat(max(0, cards.count - 1))
            let startX = (totalWidth - totalCardsWidth) / 2 + 20
            
            ZStack {
                ForEach(Array(cards.enumerated()), id: \.element.id) { index, card in
                    let playable = isHumanTurn && isCardPlayable(card)
                    let isSelected = selectedCard == card
                    
                    CardView(
                        card: card,
                        isFaceUp: true,
                        isTrump: card.isTrump(trumpSuit),
                        isPlayable: isHumanTurn ? playable : true,
                        isSelected: isSelected,
                        size: .normal
                    )
                    .offset(
                        x: startX + CGFloat(index) * spacing - totalWidth / 2 + cardWidth / 2,
                        y: isSelected ? -20 : fanOffset(index: index, total: cards.count)
                    )
                    .modifier(ShakeModifier(active: shakeCard == card))
                    .rotationEffect(
                        .degrees(fanRotation(index: index, total: cards.count)),
                        anchor: .bottom
                    )
                    .zIndex(Double(index) + (isSelected ? 100 : 0))
                    .onTapGesture {
                        guard isHumanTurn else { return }
                        // ViewModel'daki humanTapCard() tüm mantığı yönetir
                        onCardTap(card)
                    }
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
                    .animation(
                        .spring(response: 0.4, dampingFraction: 0.7)
                            .delay(appeared ? 0 : Double(index) * 0.05),
                        value: cards.count
                    )
                    .accessibilityLabel(card.accessibilityName(trumpSuit: trumpSuit))
                    .accessibilityHint(playable ? "Oynamak için çift dokunun" : "Bu kartı şu an oynayamazsınız")
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(height: 120)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                appeared = true
            }
        }
    }
    
    // Fan şeklinde Y offset
    private func fanOffset(index: Int, total: Int) -> CGFloat {
        guard total > 1 else { return 0 }
        let mid = CGFloat(total - 1) / 2
        let dist = abs(CGFloat(index) - mid) / mid
        return dist * 8 // Kenar kartlar biraz daha aşağı
    }
    
    // Fan şeklinde rotasyon
    private func fanRotation(index: Int, total: Int) -> Double {
        guard total > 1 else { return 0 }
        let mid = Double(total - 1) / 2
        let maxAngle: Double = min(15, Double(total) * 1.2)
        return (Double(index) - mid) / mid * maxAngle
    }
}

// MARK: - ShakeModifier (Geçersiz Kart Titremesi)
struct ShakeModifier: ViewModifier {
    let active: Bool

    func body(content: Content) -> some View {
        content
            .offset(x: active ? 6 : 0)
            .animation(
                active
                    ? .easeInOut(duration: 0.06).repeatCount(5, autoreverses: true)
                    : .default,
                value: active
            )
    }
}

#Preview {
    let cards = [
        Card(suit: .hearts, rank: .ace),
        Card(suit: .hearts, rank: .king),
        Card(suit: .diamonds, rank: .queen),
        Card(suit: .diamonds, rank: .seven),
        Card(suit: .clubs, rank: .jack),
        Card(suit: .clubs, rank: .five),
        Card(suit: .spades, rank: .ten),
        Card(suit: .spades, rank: .three),
    ]

    HandView(
        cards: cards,
        trumpSuit: .hearts,
        isHumanTurn: true,
        selectedCard: nil,
        shakeCard: nil,
        isCardPlayable: { _ in true },
        onCardTap: { _ in }
    )
    .background(Color(red: 0.08, green: 0.12, blue: 0.2))
}

