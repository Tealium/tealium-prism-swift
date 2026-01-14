// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "TealiumPrism",
    platforms: [ .iOS(.v13), .macOS(.v10_15), .tvOS(.v13), .watchOS(.v7) ],
    products: [
        .library(
            name: "TealiumPrismCore",
            targets: ["TealiumPrismCore", "TealiumPrismCoreObjC"]),
        .library(
            name: "TealiumPrismLifecycle",
            targets: ["TealiumPrismLifecycle", "TealiumPrismLifecycleObjC"]),
        .library(
            name: "TealiumPrismMomentsAPI",
            targets: ["TealiumPrismMomentsAPI", "TealiumPrismMomentsAPIObjC"]),
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
            exclude: ["Internal/ObjC/"],
            swiftSettings: [.define("lifecycle")]
        ),
        .target(
            name: "TealiumPrismLifecycleObjC",
            dependencies: ["TealiumPrismLifecycle"],
            path: "tealium-prism/lifecycle/Internal/ObjC/"
        ),
        .target(
            name: "TealiumPrismMomentsAPI",
            dependencies: ["TealiumPrismCore"],
            path: "tealium-prism/momentsapi/",
            exclude: ["Internal/ObjC/"],
            swiftSettings: [.define("momentsapi")]
        ),
        .target(
            name: "TealiumPrismMomentsAPIObjC",
            dependencies: ["TealiumPrismMomentsAPI"],
            path: "tealium-prism/momentsapi/Internal/ObjC/"
        ),
    ]
)
