import SwiftUI

// MARK: - ScoreView (Puan Paneli)
struct ScoreView: View {
    let players: [Player]
    let roundScores: [UUID: Int]
    let contractName: String
    let trickNumber: Int
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Başlık
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Puan Tablosu")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("\(contractName) · El \(trickNumber + 1)/13")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.5))
                }
                Spacer()
                Button {
                    isPresented = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(.white.opacity(0.4))
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)
            .padding(.bottom, 12)
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            // Oyuncu puanları
            VStack(spacing: 0) {
                // Başlık satırı
                HStack {
                    Text("Oyuncu")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("Koz")
                        .frame(width: 32)
                    Text("Ceza")
                        .frame(width: 36)
                    Text("Tur")
                        .frame(width: 50)
                    Text("Toplam")
                        .frame(width: 60)
                }
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.4))
                .padding(.horizontal, 18)
                .padding(.vertical, 8)
                
                ForEach(players) { player in
                    HStack {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(colorForPlayer(player))
                                .frame(width: 8, height: 8)
                            
                            Text(player.name)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(.white)
                            
                            if player.isHuman {
                                Text("SEN")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(.white.opacity(0.5))
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 1)
                                    .background(Color.white.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 3))
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        // Koz hakkı
                        Text("♠\(player.kozHaklari)")
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundStyle(player.kozHaklari > 0 ? .yellow : .gray)
                            .frame(width: 32)

                        // Ceza hakkı
                        Text("⚡\(player.cezaHaklari)")
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundStyle(player.cezaHaklari > 0 ? .orange : .gray)
                            .frame(width: 36)

                        // Tur puanı
                        let roundScore = roundScores[player.id] ?? 0
                        Text(scoreText(roundScore))
                            .font(.system(size: 14, weight: .semibold, design: .monospaced))
                            .foregroundStyle(scoreColor(roundScore))
                            .frame(width: 50)

                        // Toplam puan
                        Text(scoreText(player.score))
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundStyle(scoreColor(player.score))
                            .frame(width: 60)
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    
                    if player.id != players.last?.id {
                        Divider()
                            .background(Color.white.opacity(0.06))
                            .padding(.horizontal, 18)
                    }
                }
            }
            .padding(.bottom, 16)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.1, green: 0.13, blue: 0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.5), radius: 20)
        .frame(maxWidth: 320)
    }
    
    private func scoreText(_ score: Int) -> String {
        if score >= 0 { return "\(score)" }
        return "\(score)"
    }
    
    private func scoreColor(_ score: Int) -> Color {
        if score > 0 { return Color.green }
        if score < 0 { return Color(red: 1, green: 0.4, blue: 0.4) }
        return Color.white.opacity(0.6)
    }
    
    private func colorForPlayer(_ player: Player) -> Color {
        switch player.position {
        case .south: return .blue
        case .west:  return .orange
        case .north: return .green
        case .east:  return .purple
        }
    }
}

// MARK: - ScoreMiniView (Mini Puan Göstergesi)
struct ScoreMiniView: View {
    let humanScore: Int
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 5) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.5))
                
                Text("\(humanScore)")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundStyle(humanScore < 0 ? Color(red: 1, green: 0.4, blue: 0.4) : Color.white)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ScoreView(
        players: [
            Player(name: "Sen", isHuman: true, position: .south),
            Player(name: "Batı", position: .west),
            Player(name: "Kuzey", position: .north),
            Player(name: "Doğu", position: .east),
        ],
        roundScores: [:],
        contractName: "El Alma",
        trickNumber: 3,
        isPresented: .constant(true)
    )
    .padding()
    .background(Color(red: 0.05, green: 0.08, blue: 0.15))
}
