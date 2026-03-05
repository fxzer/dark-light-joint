// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DarkLightJoint",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "DarkLightJoint", targets: ["DarkLightJoint"])
    ],
    targets: [
        .executableTarget(
            name: "DarkLightJoint",
            dependencies: [],
            path: ".",
            sources: [
                "DarkLightJointApp.swift",
                "ContentView.swift"
            ],
            resources: [
                .process("Info.plist")
            ]
        )
    ]
)
