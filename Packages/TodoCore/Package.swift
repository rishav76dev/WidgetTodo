// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "TodoCore",
    defaultLocalization: "en",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "TodoKit", targets: ["TodoKit"]),
        .library(name: "TodoData", targets: ["TodoData"]),
        .library(name: "TodoUI", targets: ["TodoUI"]),
    ],
    targets: [
        .target(name: "TodoKit", resources: [.process("Resources")]),
        .target(name: "TodoData", dependencies: ["TodoKit"]),
        .target(name: "TodoUI", dependencies: ["TodoKit"]),
        .testTarget(name: "TodoKitTests", dependencies: ["TodoKit"]),
    ]
)
