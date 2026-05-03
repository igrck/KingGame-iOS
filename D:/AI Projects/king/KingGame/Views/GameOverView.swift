import SwiftUI

struct GameOverView: View {
    let results: [PlayerResult]
    let onMainMenu: () -> Void
    
    // Kazanana göre sıralanmış sonuçlar (En yüksek puan en üstte)
    var sortedResults: [PlayerResult] {
        results.sorted(by: { $0.totalScore > $1.totalScore })
    }
    
    var body: some View {
        ZStack {
            // Arka plan
            LinearGradient(
                colors: [Color(red: 0.1, green: 0.15, blue: 0.3), Color(red: 0.05, green: 0.08, blue: 0.15)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Taç ve Başlık
                VStack(spacing: 12) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.yellow, .orange],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: .yellow.opacity(0.5), radius: 10, y: 5)
                    
                    Text("Oyun Bitti")
                        .font(.system(size: 40, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                }
                .padding(.top, 40)
                
                // Sıralama
                VStack(spacing: 16) {
                    ForEach(Array(sortedResults.enumerated()), id: \.element.id) { index, result in
                        PlayerResultRow(result: result, rank: index + 1)
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                // Ana Menü Butonu
                Button(action: onMainMenu) {
                    Text("Ana Menüye Dön")
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.8), Color.blue.opacity(0.5)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .blue.opacity(0.3), radius: 10, y: 5)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
    }
}

struct PlayerResultRow: View {
    let result: PlayerResult
    let rank: Int
    
    var rankColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return Color(white: 0.8) // Gümüş
        case 3: return Color(red: 0.8, green: 0.5, blue: 0.2) // Bronz
        default: return .white.opacity(0.5)
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Sıra numarası / İkon
            ZStack {
                Circle()
                    .fill(rankColor.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                if rank == 1 {
                    Image(systemName: "star.fill")
                        .foregroundStyle(rankColor)
                } else {
                    Text("\(rank)")
                        .font(.title2.bold())
                        .foregroundStyle(rankColor)
                }
            }
            
            Text(result.playerName)
                .font(.title3.bold())
                .foregroundStyle(.white)
            
            Spacer()
            
            Text("\(result.totalScore)")
                .font(.title2.bold())
                .foregroundStyle(result.totalScore < 0 ? .red : (result.totalScore > 0 ? .green : .white))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(rank == 1 ? 0.15 : 0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(rankColor.opacity(0.5), lineWidth: rank == 1 ? 2 : 1)
        )
    }
}
