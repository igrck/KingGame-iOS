import SwiftUI

// MARK: - CardView (Kart Görünümü)
struct CardView: View {
    let card: Card
    var isFaceUp: Bool = true
    var isTrump: Bool = false
    var isPlayable: Bool = true
    var isSelected: Bool = false
    var size: CardSize = .normal
    
    var body: some View {
        ZStack {
            if isFaceUp {
                cardFront
            } else {
                cardBack
            }
        }
        .frame(width: size.width, height: size.height)
        .shadow(
            color: isTrump ? Color.yellow.opacity(0.4) : Color.black.opacity(0.3),
            radius: isTrump ? 6 : 3,
            y: 2
        )
        .opacity(isPlayable ? 1.0 : 0.4)
        .scaleEffect(isSelected ? 1.08 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
    
    // MARK: - Kart Ön Yüzü
    private var cardFront: some View {
        ZStack {
            // Arka plan
            RoundedRectangle(cornerRadius: size.cornerRadius)
                .fill(Color(red: 0.95, green: 0.93, blue: 0.88))
            
            // Koz kartı border
            if isTrump {
                RoundedRectangle(cornerRadius: size.cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color(red: 0.85, green: 0.75, blue: 0.35),
                                Color(red: 1.0, green: 0.9, blue: 0.5),
                                Color(red: 0.85, green: 0.75, blue: 0.35)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2.5
                    )
            } else {
                RoundedRectangle(cornerRadius: size.cornerRadius)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
            }
            
            // Seçili border
            if isSelected {
                RoundedRectangle(cornerRadius: size.cornerRadius)
                    .stroke(Color.blue, lineWidth: 2.5)
            }
            
            // Kart içeriği
            VStack(spacing: 0) {
                // Sol üst köşe
                HStack {
                    VStack(spacing: -2) {
                        Text(card.rank.symbol)
                            .font(.system(size: size.rankFontSize, weight: .bold, design: .serif))
                        Text(card.suit.symbol)
                            .font(.system(size: size.suitFontSize))
                    }
                    .foregroundStyle(cardColor)
                    Spacer()
                }
                .padding(.leading, size.padding)
                .padding(.top, size.padding)
                
                Spacer()
                
                // Merkez sembol
                Text(card.suit.symbol)
                    .font(.system(size: size.centerFontSize))
                    .foregroundStyle(cardColor)
                
                Spacer()
                
                // Sağ alt köşe (ters çevrilmiş)
                HStack {
                    Spacer()
                    VStack(spacing: -2) {
                        Text(card.suit.symbol)
                            .font(.system(size: size.suitFontSize))
                        Text(card.rank.symbol)
                            .font(.system(size: size.rankFontSize, weight: .bold, design: .serif))
                    }
                    .foregroundStyle(cardColor)
                    .rotationEffect(.degrees(180))
                }
                .padding(.trailing, size.padding)
                .padding(.bottom, size.padding)
            }
        }
    }
    
    // MARK: - Kart Arka Yüzü
    private var cardBack: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size.cornerRadius)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.15, green: 0.25, blue: 0.55),
                            Color(red: 0.1, green: 0.18, blue: 0.4)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            RoundedRectangle(cornerRadius: size.cornerRadius)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
            
            // Dekoratif desen
            RoundedRectangle(cornerRadius: size.cornerRadius - 4)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                .padding(4)
            
            // Merkez desen
            VStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { row in
                    HStack(spacing: 4) {
                        ForEach(0..<3, id: \.self) { col in
                            Image(systemName: "suit.diamond.fill")
                                .font(.system(size: size == .small ? 6 : 8))
                                .foregroundStyle(Color.white.opacity(0.15))
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Kart Rengi
    private var cardColor: Color {
        card.suit.isRed ? Color(red: 0.8, green: 0.1, blue: 0.1) : Color(red: 0.1, green: 0.1, blue: 0.15)
    }
}

// MARK: - CardSize
enum CardSize {
    case small, normal, large
    
    var width: CGFloat {
        switch self {
        case .small:  return 42
        case .normal: return 63
        case .large:  return 80
        }
    }
    
    var height: CGFloat {
        switch self {
        case .small:  return 59
        case .normal: return 88
        case .large:  return 112
        }
    }
    
    var cornerRadius: CGFloat {
        switch self {
        case .small:  return 4
        case .normal: return 6
        case .large:  return 8
        }
    }
    
    var rankFontSize: CGFloat {
        switch self {
        case .small:  return 10
        case .normal: return 14
        case .large:  return 18
        }
    }
    
    var suitFontSize: CGFloat {
        switch self {
        case .small:  return 8
        case .normal: return 12
        case .large:  return 16
        }
    }
    
    var centerFontSize: CGFloat {
        switch self {
        case .small:  return 16
        case .normal: return 28
        case .large:  return 36
        }
    }
    
    var padding: CGFloat {
        switch self {
        case .small:  return 3
        case .normal: return 5
        case .large:  return 7
        }
    }
}

#Preview {
    HStack(spacing: 16) {
        CardView(card: Card(suit: .hearts, rank: .king), isTrump: true)
        CardView(card: Card(suit: .spades, rank: .ace))
        CardView(card: Card(suit: .diamonds, rank: .two))
        CardView(card: Card(suit: .clubs, rank: .five), isFaceUp: false)
    }
    .padding()
    .background(Color(red: 0.08, green: 0.12, blue: 0.2))
}
