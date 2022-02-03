// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "OSCKit",
    platforms: [
        .iOS(.v9),
        .macOS(.v10_10),
        .tvOS(.v9)
    ],
    products: [
        .library(
            name: "OSCKit",
            targets: ["OSCKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/robbiehanson/CocoaAsyncSocket", from: "7.6.4"),
        .package(name: "NetUtils", url: "https://github.com/svdo/swift-netutils", from: "4.1.0"),
    ],
    targets: [
        .target(
            name: "OSCKit",
            dependencies: ["CocoaAsyncSocket", "NetUtils"],
            resources: [
                .process("LICENSE.md")
            ]),
        .testTarget(
            name: "OSCKitTests",
            dependencies: ["OSCKit"]),
    ]
)
