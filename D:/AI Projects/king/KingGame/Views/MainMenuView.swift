import SwiftUI

struct MainMenuView: View {
    @State private var showGame = false
    @State private var showSettings = false
    @State private var hasSavedGame = GameState.hasSavedGame
    @State private var animateTitle = false
    @State private var animateCards = false
    @State private var continueSavedGame = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Arka plan gradyan
                LinearGradient(
                    colors: [
                        Color(red: 0.05, green: 0.08, blue: 0.15),
                        Color(red: 0.1, green: 0.15, blue: 0.25),
                        Color(red: 0.08, green: 0.1, blue: 0.2)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Dekoratif kart desenleri
                decorativeCards
                
                VStack(spacing: 0) {
                    Spacer()
                    
                    // Logo ve başlık
                    titleSection
                    
                    Spacer()
                    
                    // Menü butonları
                    menuButtons
                    
                    Spacer()
                        .frame(height: 60)
                }
            }
            .navigationDestination(isPresented: $showGame) {
                GameBoardView(viewModel: {
                    let vm = GameViewModel()
                    vm.startNewGame()
                    return vm
                }())
            }
            .navigationDestination(isPresented: $continueSavedGame) {
                GameBoardView(viewModel: {
                    let vm = GameViewModel()
                    _ = vm.continueGame()
                    return vm
                }())
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .onAppear {
                withAnimation(.easeOut(duration: 1.0)) {
                    animateTitle = true
                }
                withAnimation(.easeOut(duration: 1.5).delay(0.3)) {
                    animateCards = true
                }
            }
        }
    }
    
    // MARK: - Başlık
    private var titleSection: some View {
        VStack(spacing: 16) {
            // Kart ikonları
            HStack(spacing: 8) {
                ForEach(Suit.allCases) { suit in
                    Text(suit.symbol)
                        .font(.system(size: 36))
                        .foregroundStyle(suit.isRed ? Color.red : Color.white)
                        .opacity(animateCards ? 1 : 0)
                        .offset(y: animateCards ? 0 : -20)
                        .animation(
                            .spring(response: 0.6, dampingFraction: 0.7)
                                .delay(Double(Suit.allCases.firstIndex(of: suit) ?? 0) * 0.15),
                            value: animateCards
                        )
                }
            }
            
            Text("KING")
                .font(.system(size: 72, weight: .black, design: .serif))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(red: 0.85, green: 0.75, blue: 0.45),
                            Color(red: 1.0, green: 0.9, blue: 0.55),
                            Color(red: 0.85, green: 0.75, blue: 0.45)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color(red: 0.85, green: 0.75, blue: 0.45).opacity(0.5), radius: 20)
                .opacity(animateTitle ? 1 : 0)
                .scaleEffect(animateTitle ? 1 : 0.7)
            
            Text("Kart Oyunu")
                .font(.system(size: 20, weight: .medium, design: .serif))
                .foregroundStyle(Color.white.opacity(0.6))
                .opacity(animateTitle ? 1 : 0)
        }
    }
    
    // MARK: - Menü Butonları
    private var menuButtons: some View {
        VStack(spacing: 16) {
            // Yeni Oyun
            MenuButton(
                title: "Yeni Oyun",
                icon: "play.fill",
                gradient: [Color(red: 0.2, green: 0.6, blue: 0.4), Color(red: 0.15, green: 0.5, blue: 0.35)]
            ) {
                showGame = true
            }
            
            // Devam Et
            if hasSavedGame {
                MenuButton(
                    title: "Devam Et",
                    icon: "arrow.counterclockwise",
                    gradient: [Color(red: 0.3, green: 0.5, blue: 0.7), Color(red: 0.2, green: 0.4, blue: 0.6)]
                ) {
                    continueSavedGame = true
                }
            }
            
            // Ayarlar
            MenuButton(
                title: "Ayarlar",
                icon: "gearshape.fill",
                gradient: [Color.white.opacity(0.15), Color.white.opacity(0.08)]
            ) {
                showSettings = true
            }
        }
        .padding(.horizontal, 40)
        .opacity(animateCards ? 1 : 0)
        .offset(y: animateCards ? 0 : 30)
    }
    
    // MARK: - Dekoratif Kartlar
    private var decorativeCards: some View {
        ZStack {
            // Yarı saydam kart şekilleri
            ForEach(0..<6, id: \.self) { i in
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.03), lineWidth: 1)
                    .frame(width: 63, height: 88)
                    .rotationEffect(.degrees(Double(i) * 30 - 75))
                    .offset(
                        x: CGFloat.random(in: -150...150),
                        y: CGFloat.random(in: -300...300)
                    )
                    .opacity(animateCards ? 0.4 : 0)
            }
        }
    }
}

// MARK: - MenuButton
struct MenuButton: View {
    let title: String
    let icon: String
    let gradient: [Color]
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                
                Text(title)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .opacity(0.5)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 18)
            .background(
                LinearGradient(colors: gradient, startPoint: .leading, endPoint: .trailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: gradient[0].opacity(0.3), radius: 8, y: 4)
            .scaleEffect(isPressed ? 0.97 : 1)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.15)) { isPressed = pressing }
        }) {}
    }
}

#Preview {
    MainMenuView()
        .preferredColorScheme(.dark)
}
