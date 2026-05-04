import SwiftUI

@main
struct KingGameApp: App {
    @AppStorage("appTheme") private var appTheme: Int = 0
    
    var colorScheme: ColorScheme? {
        switch appTheme {
        case 1: return .light
        case 2: return .dark
        default: return nil
        }
    }

    var body: some Scene {
        WindowGroup {
            MainMenuView()
                .preferredColorScheme(colorScheme)
        }
    }
}
