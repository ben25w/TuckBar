// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "TuckBar",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "TuckBar", targets: ["TuckBar"])
    ],
    targets: [
        .target(
            name: "TuckBarCore",
            resources: [
                .copy("Resources")
            ]
        ),
        .executableTarget(
            name: "TuckBar",
            dependencies: ["TuckBarCore"]
        ),
        .testTarget(
            name: "TuckBarTests",
            dependencies: ["TuckBarCore"]
        )
    ]
)
