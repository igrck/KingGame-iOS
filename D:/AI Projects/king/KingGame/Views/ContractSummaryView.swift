import SwiftUI

struct ContractSummaryView: View {
    let details: [PlayerScoreDetail]
    let contract: ContractType
    let onContinue: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.8).ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Başlık
                VStack(spacing: 8) {
                    Text("Kontrat Bitti")
                        .font(.title2)
                        .foregroundStyle(.white.opacity(0.8))
                    
                    Text(contract.displayName)
                        .font(.largeTitle.bold())
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.yellow, .orange],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
                
                // Detaylar
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(details) { detail in
                            PlayerSummaryCard(detail: detail)
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(maxHeight: 400)
                
                // Devam Butonu
                Button(action: onContinue) {
                    Text("Sonraki Kontrat")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [Color(red: 0.2, green: 0.6, blue: 0.4), Color(red: 0.1, green: 0.4, blue: 0.2)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.3), radius: 5, y: 3)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 20)
            }
            .padding(.top, 30)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(red: 0.1, green: 0.15, blue: 0.25))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .padding()
        }
    }
}

struct PlayerSummaryCard: View {
    let detail: PlayerScoreDetail
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(detail.playerName)
                    .font(.headline)
                    .foregroundStyle(.white)
                
                Spacer()
                
                Text("\(detail.totalScore)")
                    .font(.title3.bold())
                    .foregroundStyle(detail.totalScore < 0 ? .red : (detail.totalScore > 0 ? .green : .white))
            }
            
            if !detail.penalties.isEmpty {
                Divider().background(Color.white.opacity(0.2))
                
                ForEach(detail.penalties) { penalty in
                    HStack {
                        Text(penalty.description)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.7))
                        Spacer()
                        Text("\(penalty.points)")
                            .font(.subheadline.bold())
                            .foregroundStyle(penalty.points < 0 ? .red.opacity(0.8) : .green.opacity(0.8))
                    }
                }
            } else {
                Text("Ceza yok")
                    .font(.subheadline)
                    .foregroundStyle(.green.opacity(0.8))
            }
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
}
