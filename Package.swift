// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DutiUI",
    defaultLocalization: "zh-Hans",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "DutiUI",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
