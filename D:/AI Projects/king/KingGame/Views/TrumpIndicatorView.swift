import SwiftUI

// MARK: - TrumpIndicatorView (Koz Göstergesi)
struct TrumpIndicatorView: View {
    let trumpSuit: Suit?
    let contractName: String
    var isRevealing: Bool = false
    
    @State private var scale: CGFloat = 1
    
    var body: some View {
        VStack(spacing: 3) {
            // Kontrat adı
            Text(contractName)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.5))
            
            // Koz göstergesi
            if let suit = trumpSuit {
                HStack(spacing: 4) {
                    Text(suit.symbol)
                        .font(.system(size: 18))
                        .foregroundStyle(suit.isRed ? Color.red : Color.white)
                        .scaleEffect(scale)
                    
                    Text("Koz")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.8))
                }
            } else {
                Text("—")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.white.opacity(0.3))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            trumpSuit != nil
                                ? Color.yellow.opacity(0.3)
                                : Color.white.opacity(0.1),
                            lineWidth: 1
                        )
                )
        )
        .onChange(of: isRevealing) { _, revealing in
            if revealing {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5).repeatCount(3, autoreverses: true)) {
                    scale = 1.4
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    withAnimation(.spring) { scale = 1 }
                }
            }
        }
    }
}

// MARK: - TrumpPickerView (Koz Seçici)
struct TrumpPickerView: View {
    let onSelect: (Suit) -> Void
    @State private var appeared = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Koz Rengini Seçin")
                .font(.system(size: 22, weight: .bold, design: .serif))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, .white.opacity(0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            
            HStack(spacing: 16) {
                ForEach(Suit.allCases) { suit in
                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        onSelect(suit)
                    } label: {
                        VStack(spacing: 8) {
                            Text(suit.symbol)
                                .font(.system(size: 44))
                                .foregroundStyle(suit.isRed ? Color.red : Color.white)
                            
                            Text(suit.displayName)
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(.white.opacity(0.7))
                        }
                        .frame(width: 72, height: 90)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.white.opacity(0.06))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                    .scaleEffect(appeared ? 1 : 0.5)
                    .opacity(appeared ? 1 : 0)
                    .animation(
                        .spring(response: 0.4, dampingFraction: 0.7)
                            .delay(Double(Suit.allCases.firstIndex(of: suit) ?? 0) * 0.1),
                        value: appeared
                    )
                }
            }
        }
        .padding(28)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.5), radius: 30)
        .onAppear {
            withAnimation { appeared = true }
        }
    }
}

#Preview {
    VStack(spacing: 30) {
        TrumpIndicatorView(trumpSuit: .hearts, contractName: "El Alma")
        TrumpPickerView(onSelect: { _ in })
    }
    .padding()
    .background(Color(red: 0.08, green: 0.12, blue: 0.2))
}
