// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "KingGame",
    platforms: [.iOS(.v16)],
    products: [
        .library(name: "KingGame", targets: ["KingGame"])
    ],
    targets: [
        .target(
            name: "KingGame",
            path: ".",
            exclude: [],
            sources: ["App", "Engine", "Models", "ViewModels", "Views"]
        )
    ]
)
