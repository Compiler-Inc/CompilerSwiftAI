// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "CompilerSwiftAI",
    platforms: [.macOS(.v15), .iOS(.v18)],
    products: [.library(name: "CompilerSwiftAI", targets: ["CompilerSwiftAI"])],
    targets: [
        .target(name: "CompilerSwiftAI"),
        .testTarget(name: "CompilerSwiftAITests", dependencies: ["CompilerSwiftAI"]),
    ]
)
