// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CompilerSwiftAI",
    platforms: [
        .macOS(.v15), .iOS(.v18)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "CompilerSwiftAI",
            targets: ["CompilerSwiftAI"]),
    ],
    dependencies: [.package(url: "https://github.com/AudioKit/AudioKit", from: "5.5.0")],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "CompilerSwiftAI", dependencies: ["AudioKit"]),
        .testTarget(
            name: "CompilerSwiftAITests",
            dependencies: ["CompilerSwiftAI"]
        ),
    ]
)
