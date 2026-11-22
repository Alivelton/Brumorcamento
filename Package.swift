// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "BrumOrcamento",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        // An xtool project should contain exactly one library product,
        // representing the main app.
        .library(
            name: "BrumOrcamento",
            targets: ["BrumOrcamento"]
        )
    ],
    targets: [
        .target(
            name: "BrumOrcamento",
            path: "Sources/BrumOrcamento"
        )
    ]
)
