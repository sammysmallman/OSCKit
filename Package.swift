// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

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
            targets: ["OSCKit"])
    ],
    dependencies: [
        .package(url: "https://github.com/robbiehanson/CocoaAsyncSocket", from: "7.6.4"),
        .package(url: "https://github.com/svdo/swift-netutils", from: "4.1.0"),
        .package(url: "https://github.com/sammysmallman/CoreOSC", .branch("main"))
    ],
    targets: [
        .target(
            name: "OSCKit",
            dependencies: ["CocoaAsyncSocket", "NetUtils", "CoreOSC"]),
        .testTarget(
            name: "OSCKitTests",
            dependencies: ["OSCKit"])
    ]
)
