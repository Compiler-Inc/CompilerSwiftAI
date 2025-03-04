// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "CompilerSwiftAI",
    platforms: [.macOS(.v15), .iOS(.v18)],
    products: [.library(name: "CompilerSwiftAI", targets: ["CompilerSwiftAI"])],
    dependencies: [
        .package(url: "https://github.com/gonzalezreal/swift-markdown-ui", from: "2.4.1"),
        .package(url: "https://github.com/Compiler-Inc/Transcriber", from: "0.1.4")
    ],
    targets: [
        .target(name: "CompilerSwiftAI", dependencies: ["Transcriber", .product(name: "MarkdownUI", package: "swift-markdown-ui")] ),
        .testTarget(name: "CompilerSwiftAITests", dependencies: ["CompilerSwiftAI"]),
    ]
)

