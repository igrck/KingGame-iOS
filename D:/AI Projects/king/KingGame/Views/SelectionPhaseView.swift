import SwiftUI

// MARK: - SelectionPhaseView (Koz/Ceza Seçim Ekranı)
/// Rehber §6.3'e göre: kozHaklari > 0 ise KozSecimView, cezaHaklari > 0 ise CezaSecimView.
struct SelectionPhaseView: View {
    let player: Player
    let onSelectContract: (ContractType) -> Void

    @State private var tab: SelectionTab = .koz

    enum SelectionTab {
        case koz, ceza
    }

    var body: some View {
        ZStack {
            // Arka plan blur
            Color.black.opacity(0.75)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Başlık
                VStack(spacing: 4) {
                    Text(player.name)
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.8))
                    Text("Koz mu, Ceza mı?")
                        .font(.title2.bold())
                        .foregroundStyle(.white)

                    // Hak sayıları
                    HStack(spacing: 20) {
                        hakBadge(label: "Koz", count: player.kozHaklari, color: .yellow)
                        hakBadge(label: "Ceza", count: player.cezaHaklari, color: .orange)
                    }
                    .padding(.top, 6)
                }
                .padding(.top, 28)
                .padding(.horizontal, 24)

                // Zorunlu koz uyarısı
                if player.hasUsedAllRights {
                    Text("⚠️ Tüm haklar tükendi — Zorunlu Koz!")
                        .font(.caption.bold())
                        .foregroundStyle(.red)
                        .padding(.top, 8)
                }

                // Tab seçici (hak varsa)
                if player.kozHaklari > 0 || player.cezaHaklari > 0 {
                    HStack(spacing: 0) {
                        if player.kozHaklari > 0 {
                            tabButton("🏆 Koz Seç", tab: .koz, selected: tab == .koz)
                        }
                        if player.cezaHaklari > 0 {
                            tabButton("⚡ Ceza Seç", tab: .ceza, selected: tab == .ceza)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                }

                // İçerik
                Group {
                    if player.hasUsedAllRights {
                        // Zorunlu koz: sadece koz seçenekleri
                        KozSecimView(onSelect: onSelectContract)
                    } else if tab == .koz && player.kozHaklari > 0 {
                        KozSecimView(onSelect: onSelectContract)
                    } else if tab == .ceza && player.cezaHaklari > 0 {
                        CezaSecimView(onSelect: onSelectContract)
                    } else if player.kozHaklari > 0 {
                        KozSecimView(onSelect: onSelectContract)
                    } else {
                        CezaSecimView(onSelect: onSelectContract)
                    }
                }
                .padding(.vertical, 20)
                .padding(.horizontal, 24)

                Spacer()
            }
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.08, green: 0.12, blue: 0.22),
                                    Color(red: 0.05, green: 0.08, blue: 0.16)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                }
            )
            .padding(.horizontal, 20)
            .padding(.vertical, 60)
        }
        .onAppear {
            // Başlangıç tab'ı: koz hakkı varsa koz, yoksa ceza
            if player.kozHaklari <= 0 {
                tab = .ceza
            }
        }
    }

    private func tabButton(_ label: String, tab: SelectionTab, selected: Bool) -> some View {
        Button {
            withAnimation(.spring(response: 0.3)) { self.tab = tab }
        } label: {
            Text(label)
                .font(.subheadline.bold())
                .foregroundStyle(selected ? .white : .white.opacity(0.5))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    selected
                    ? Color.white.opacity(0.15)
                    : Color.clear
                )
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    private func hakBadge(label: String, count: Int, color: Color) -> some View {
        HStack(spacing: 5) {
            Circle()
                .fill(count > 0 ? color : .gray)
                .frame(width: 8, height: 8)
            Text("\(label): \(count) hak kaldı")
                .font(.caption)
                .foregroundStyle(count > 0 ? color : .gray)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color.white.opacity(0.07))
        .clipShape(Capsule())
    }
}

// MARK: - KozSecimView
struct KozSecimView: View {
    let onSelect: (ContractType) -> Void

    let kozOptions: [(ContractType, String, Color)] = [
        (.trumpSpades,   "Maça ♠",  Color(red: 0.2, green: 0.2, blue: 0.25)),
        (.trumpHearts,   "Kupa ♥",  Color(red: 0.6, green: 0.1, blue: 0.15)),
        (.trumpDiamonds, "Karo ♦",  Color(red: 0.6, green: 0.2, blue: 0.1)),
        (.trumpClubs,    "Sinek ♣", Color(red: 0.1, green: 0.35, blue: 0.2)),
    ]

    var body: some View {
        VStack(spacing: 0) {
            Text("Koz Rengi Seç")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.6))
                .padding(.bottom, 12)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(kozOptions, id: \.0) { contract, label, color in
                    Button {
                        withAnimation(.spring(response: 0.35)) {
                            onSelect(contract)
                        }
                    } label: {
                        VStack(spacing: 8) {
                            Text(suitSymbol(contract))
                                .font(.system(size: 36))
                            Text(label)
                                .font(.headline.bold())
                                .foregroundStyle(.white)
                            Text("+50 / el")
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.6))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(color.opacity(0.85))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                )
                        )
                    }
                }
            }
        }
    }

    private func suitSymbol(_ contract: ContractType) -> String {
        switch contract {
        case .trumpSpades:   return "♠"
        case .trumpHearts:   return "♥"
        case .trumpDiamonds: return "♦"
        case .trumpClubs:    return "♣"
        default:             return "?"
        }
    }
}

// MARK: - CezaSecimView
struct CezaSecimView: View {
    let onSelect: (ContractType) -> Void

    let cezaOptions: [(ContractType, String, String, String)] = [
        (.elAlmaz,    "El Almaz",    "hand.raised.slash",          "-50 / el"),
        (.kupaAlmaz,  "Kupa Almaz",  "heart.slash",                "-30 / kupa"),
        (.kizAlmaz,   "Kız Almaz",   "crown",                      "-100 / kız"),
        (.erkekAlmaz, "Erkek Almaz", "person.slash",               "-60 / erkek"),
        (.sonIki,     "Son İki",     "arrow.down.to.line",         "-180 / el"),
        (.rifki,      "Rıfkı ♥K",   "exclamationmark.triangle.fill", "-320 sabit"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            Text("Ceza Türü Seç")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.6))
                .padding(.bottom, 12)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(cezaOptions, id: \.0) { contract, label, icon, penalty in
                    Button {
                        withAnimation(.spring(response: 0.35)) {
                            onSelect(contract)
                        }
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: icon)
                                .font(.system(size: 22))
                                .foregroundStyle(contract == .rifki ? .red : .orange)
                            Text(label)
                                .font(.subheadline.bold())
                                .foregroundStyle(.white)
                            Text(penalty)
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.5))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.07))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(
                                            contract == .rifki
                                            ? Color.red.opacity(0.5)
                                            : Color.white.opacity(0.12),
                                            lineWidth: 1
                                        )
                                )
                        )
                    }
                }
            }
        }
    }
}

#Preview {
    let p = Player(name: "Fatma", isHuman: true, position: .south)
    SelectionPhaseView(player: p, onSelectContract: { _ in })
        .background(Color(red: 0.1, green: 0.35, blue: 0.2))
}
