// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "TealiumPrism",
    platforms: [ .iOS(.v12), .macOS(.v10_14), .tvOS(.v12), .watchOS(.v4) ],
    products: [
        .library(
            name: "TealiumCore",
            targets: ["TealiumCore", "TealiumCoreObjC"]),
        .library(
            name: "TealiumLifecycle",
            targets: ["TealiumLifecycle"]),
    ],
    dependencies: [
        .package(url: "https://github.com/stephencelis/SQLite.swift.git", from: "0.15.4")
    ],
    targets: [
        .target(
            name: "TealiumCore",
            dependencies: [
                .product(name: "SQLite", package: "SQLite.swift")
            ],
            path: "tealium-prism/core/",
            exclude: ["Internal/Misc/ObjC/"]
        ),
        .target(
            name: "TealiumCoreObjC",
            dependencies: ["TealiumCore"],
            path: "tealium-prism/core/Internal/Misc/ObjC/"
        ),
        .target(
            name: "TealiumLifecycle",
            dependencies: ["TealiumCore"],
            path: "tealium-prism/lifecycle/",
            swiftSettings: [.define("lifecycle")]
        ),
    ]
)
