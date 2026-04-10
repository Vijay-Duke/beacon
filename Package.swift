// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LaserTool",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "LaserTool",
            path: "Sources/LaserTool",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("SwiftUI"),
                .linkedFramework("QuartzCore"),
            ]
        ),
        .testTarget(
            name: "LaserToolTests",
            dependencies: ["LaserTool"],
            path: "Tests/LaserToolTests"
        ),
    ]
)
