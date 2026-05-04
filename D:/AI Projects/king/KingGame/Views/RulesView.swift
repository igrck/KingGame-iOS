import SwiftUI

struct RulesView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Oyun Kuralları")
                    .font(.title)
                    .fontWeight(.bold)
                
                Group {
                    Text("Genel Kurallar")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding(.top, 8)
                    
                    Text("1. King oyunu 4 kişiyle oynanır ve her oyuncuya 13'er kart dağıtılır.")
                    Text("2. Oyun toplam 20 elden oluşur. 12 ceza eli ve 8 koz eli oynanır.")
                    Text("3. İlk elde oyunu başlatan, elinde Karo 2 olan oyuncudur. Sonraki ellerde oyun sırası saat yönünün tersine dönerek ilerler ve sırası gelen oyuncu oyunu belirler.")
                    Text("4. Eli kazanan oyuncu bir sonraki elin ilk kartını atma hakkına sahip olur.")
                }
                
                Group {
                    Text("Ceza Oyunları")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding(.top, 16)
                    
                    Text("• El Almaz: Mümkün olduğunca az el almak hedeflenir. Alınan her el eksi puan yazar.")
                    Text("• Kupa Almaz: Kupa serisinden kart almamak hedeflenir.")
                    Text("• Erkek Almaz: Papaz ve Vale (J) kartlarını almamak hedeflenir.")
                    Text("• Kız Almaz: Kız (Q) kartlarını almamak hedeflenir.")
                    Text("• Rıfkı: Kupa Papazı'nı almamak hedeflenir.")
                    Text("• Son İki: Son iki eli almamak hedeflenir.")
                }
                
                Group {
                    Text("Koz Oyunları")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding(.top, 16)
                    
                    Text("• Koz oyunlarında amaç mümkün olduğunca çok el almaktır.")
                    Text("• Oyunu seçen oyuncu koz rengini (Maça, Kupa, Karo, Sinek) belirler.")
                    Text("• Yerde dönen renkten elinizde yoksa koz atmak zorundasınız. Koz atıldıysa o eli en büyük kozu atan kazanır.")
                }
            }
            .padding()
        }
        .navigationTitle("Kurallar")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationView {
        RulesView()
    }
}
