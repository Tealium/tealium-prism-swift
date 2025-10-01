// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "TealiumPrism",
    platforms: [ .iOS(.v12), .macOS(.v10_14), .tvOS(.v12), .watchOS(.v4) ],
    products: [
        .library(
            name: "TealiumPrismCore",
            targets: ["TealiumPrismCore", "TealiumPrismCoreObjC"]),
        .library(
            name: "TealiumPrismLifecycle",
            targets: ["TealiumPrismLifecycle"]),
    ],
    dependencies: [
        .package(url: "https://github.com/stephencelis/SQLite.swift.git", from: "0.15.4")
    ],
    targets: [
        .target(
            name: "TealiumPrismCore",
            dependencies: [
                .product(name: "SQLite", package: "SQLite.swift")
            ],
            path: "tealium-prism/core/",
            exclude: ["Internal/Misc/ObjC/"]
        ),
        .target(
            name: "TealiumPrismCoreObjC",
            dependencies: ["TealiumPrismCore"],
            path: "tealium-prism/core/Internal/Misc/ObjC/"
        ),
        .target(
            name: "TealiumPrismLifecycle",
            dependencies: ["TealiumPrismCore"],
            path: "tealium-prism/lifecycle/",
            swiftSettings: [.define("lifecycle")]
        ),
    ]
)
