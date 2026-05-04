import SwiftUI

// MARK: - AutoPlayTimerView (Otomatik Oynama Geri Sayım)
/// Rehber §6.6'ya göre: circular progress + sayısal geri sayım.
/// Son 3s'de kırmızıya döner + titreşim.
struct AutoPlayTimerView: View {
    let countdown: Int
    let totalSeconds: Int

    private var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return Double(countdown) / Double(totalSeconds)
    }

    private var isUrgent: Bool {
        countdown <= 3 && countdown > 0
    }

    private var timerColor: Color {
        if isUrgent { return .red }
        if countdown <= 6 { return .orange }
        return .white
    }

    var body: some View {
        ZStack {
            // Arka halka
            Circle()
                .stroke(Color.white.opacity(0.15), lineWidth: 4)

            // İlerleme halkası
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    timerColor,
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: progress)

            // Sayaç metni
            Text("\(countdown)")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundStyle(timerColor)
                .contentTransition(.numericText())
        }
        .frame(width: 44, height: 44)
        .modifier(UrgentShakeModifier(active: isUrgent, countdown: countdown))
    }
}

// MARK: - Titreşim Modifier
private struct UrgentShakeModifier: ViewModifier {
    let active: Bool
    let countdown: Int

    func body(content: Content) -> some View {
        content
            .scaleEffect(active ? 1.15 : 1.0)
            .animation(
                active
                    ? .easeInOut(duration: 0.3).repeatCount(2, autoreverses: true)
                    : .default,
                value: countdown
            )
    }
}

#Preview {
    HStack(spacing: 24) {
        AutoPlayTimerView(countdown: 10, totalSeconds: 10)
        AutoPlayTimerView(countdown: 5, totalSeconds: 10)
        AutoPlayTimerView(countdown: 2, totalSeconds: 10)
    }
    .padding(40)
    .background(Color(red: 0.1, green: 0.35, blue: 0.2))
}
