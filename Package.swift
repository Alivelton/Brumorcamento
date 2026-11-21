// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "BrumOrcamento",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .executable(name: "BrumOrcamento", targets: ["BrumOrcamento"])
    ],
    targets: [
        .executableTarget(
            name: "BrumOrcamento",
            path: "Sources/BrumOrcamento"
        )
    ]
)
