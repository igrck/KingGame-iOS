import SwiftUI

@main
struct KingGameApp: App {
    var body: some Scene {
        WindowGroup {
            MainMenuView()
                .preferredColorScheme(.dark)
        }
    }
}
