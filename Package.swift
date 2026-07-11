// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AtollCodexUsage",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "AtollCodexUsage", targets: ["AtollCodexUsage"])
    ],
    dependencies: [
        .package(url: "https://github.com/Ebullioscopic/AtollExtensionKit.git", branch: "main")
    ],
    targets: [
        .target(name: "AtollCodexUsageCore"),
        .executableTarget(
            name: "AtollCodexUsage",
            dependencies: [
                "AtollCodexUsageCore",
                .product(name: "AtollExtensionKit", package: "AtollExtensionKit")
            ]
        ),
        .executableTarget(
            name: "AtollCodexUsageCoreTests",
            dependencies: ["AtollCodexUsageCore"],
            path: "Tests/AtollCodexUsageCoreTests"
        )
    ]
)
