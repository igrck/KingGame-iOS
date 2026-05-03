import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    // UserDefaults AppStorage kullanımı
    @AppStorage("soundEnabled") private var soundEnabled = true
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("trumpDeterminationMode") private var trumpMode = 0 // 0: Dealer, 1: Fixed
    @AppStorage("playerAvatar") private var playerAvatar = "person.fill"
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Ses Efektleri", isOn: $soundEnabled)
                        .tint(.blue)
                    
                    Toggle("Titreşim (Haptics)", isOn: $hapticsEnabled)
                        .tint(.blue)
                } header: {
                    Text("Oyun Deneyimi")
                } footer: {
                    Text("Oyun içi kart atma ve kazanma seslerini açıp kapatabilirsiniz.")
                }
                
                Section {
                    Picker("Koz Belirleme", selection: $trumpMode) {
                        Text("Dağıtıcı Seçer").tag(0)
                        Text("Sabit (Maça)").tag(1)
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Kurallar")
                } footer: {
                    Text("Sonraki yeni oyunda geçerli olur.")
                }
                
                Section {
                    HStack {
                        Text("Profil İkonu")
                        Spacer()
                        Picker("", selection: $playerAvatar) {
                            Image(systemName: "person.fill").tag("person.fill")
                            Image(systemName: "face.smiling.fill").tag("face.smiling.fill")
                            Image(systemName: "star.fill").tag("star.fill")
                            Image(systemName: "crown.fill").tag("crown.fill")
                        }
                        .pickerStyle(.menu)
                    }
                } header: {
                    Text("Kişiselleştirme")
                }
                
                Section {
                    Button("Hakkında", action: {
                        // Hakkında ekranı
                    })
                    
                    Button("Kurallar", action: {
                        // Kurallar ekranı
                    })
                }
                
                Section {
                    Text("Versiyon 1.1.0")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .navigationTitle("Ayarlar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Bitti") {
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
