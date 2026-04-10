// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Beacon",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "Beacon",
            path: "Sources/Beacon",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("SwiftUI"),
                .linkedFramework("QuartzCore"),
            ]
        ),
        .testTarget(
            name: "BeaconTests",
            dependencies: ["Beacon"],
            path: "Tests/BeaconTests"
        ),
    ]
)
