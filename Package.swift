// swift-tools-version:5.5
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
        .package(name: "NetUtils" ,url: "https://github.com/svdo/swift-netutils", from: "4.1.0"),
        .package(url: "https://github.com/sammysmallman/CoreOSC.git", from: "1.2.1")
    ],
    targets: [
        .target(
            name: "OSCKit",
            dependencies: [
                "CocoaAsyncSocket",
                "NetUtils",
                "CoreOSC"
            ],
            resources: [
                .process("LICENSE.md")
            ]),
        .testTarget(
            name: "OSCKitTests",
            dependencies: ["OSCKit"])
    ]
)
