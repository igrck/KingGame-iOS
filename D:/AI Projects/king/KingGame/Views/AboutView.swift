import SwiftUI

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Kralın 20 Eli")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                
                Text("Klasik 52 kartlık Türk King oyunu şimdi iOS’ta!")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                Text("Uzun kış gecelerinin, çay sohbetlerinin ve en heyecanlı masa oyunlarının vazgeçilmezi King (Rıfkı) artık cebinizde. Papaz kaçtı, koz savaşı, ceza puanı ve 20 el boyunca süren nefes kesen rekabet… Hepsi en gerçekçi şekilde!")
                    .font(.body)
                    .lineSpacing(4)
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Hakkında")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationView {
        AboutView()
    }
}
