// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "flutter_libserialport",
    platforms: [
        .macOS("10.14")
    ],
    products: [
        .library(
            name: "flutter-libserialport",
            targets: ["flutter_libserialport"]
        )
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework"),
    ],
    targets: [
        .target(
            name: "flutter_libserialport",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework"),
            ],
            path: "Sources/flutter_libserialport"
        )
    ]
)
