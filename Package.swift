// swift-tools-version:5.10
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2017-2023 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import PackageDescription

let swiftAtomics: PackageDescription.Target.Dependency = .product(name: "Atomics", package: "swift-atomics")
let swiftCollections: PackageDescription.Target.Dependency = .product(name: "DequeModule", package: "swift-collections")
let swiftSystem: PackageDescription.Target.Dependency = .product(name: "SystemPackage", package: "swift-system")

// These platforms require a dependency on `NIOPosix` from `NIOHTTP1` to maintain backward
// compatibility with previous NIO versions.
let historicalNIOPosixDependencyRequired: [Platform] = [.macOS, .iOS, .tvOS, .watchOS, .linux, .android]

let strictConcurrencyDevelopment = false

let strictConcurrencySettings: [SwiftSetting] = {
    var initialSettings: [SwiftSetting] = []
    initialSettings.append(contentsOf: [
        .enableUpcomingFeature("StrictConcurrency"),
        .enableUpcomingFeature("InferSendableFromCaptures"),
    ])

    if strictConcurrencyDevelopment {
        // -warnings-as-errors here is a workaround so that IDE-based development can
        // get tripped up on -require-explicit-sendable.
        initialSettings.append(.unsafeFlags(["-require-explicit-sendable", "-warnings-as-errors"]))
    }

    return initialSettings
}()

// This doesn't work when cross-compiling: the privacy manifest will be included in the Bundle and
// Foundation will be linked. This is, however, strictly better than unconditionally adding the
// resource.
#if canImport(Darwin)
let includePrivacyManifest = true
#else
let includePrivacyManifest = false
#endif

let package = Package(
    name: "swift-nio",
    products: [
        .library(name: "NIOCore", targets: ["NIOCore"]),
        .library(name: "NIO", targets: ["NIO"]),
        .library(name: "NIOEmbedded", targets: ["NIOEmbedded"]),
        .library(name: "NIOPosix", targets: ["NIOPosix"]),
        .library(name: "_NIOConcurrency", targets: ["_NIOConcurrency"]),
        .library(name: "NIOTLS", targets: ["NIOTLS"]),
        .library(name: "NIOHTTP1", targets: ["NIOHTTP1"]),
        .library(name: "NIOConcurrencyHelpers", targets: ["NIOConcurrencyHelpers"]),
        .library(name: "NIOFoundationCompat", targets: ["NIOFoundationCompat"]),
        .library(name: "NIOWebSocket", targets: ["NIOWebSocket"]),
        .library(name: "NIOTestUtils", targets: ["NIOTestUtils"]),
        .library(name: "_NIOFileSystem", targets: ["_NIOFileSystem", "NIOFileSystem"]),
        .library(name: "_NIOFileSystemFoundationCompat", targets: ["_NIOFileSystemFoundationCompat"]),
    ],
    targets: [
        // MARK: - Targets

        .target(
            name: "NIOCore",
            dependencies: [
                "NIOConcurrencyHelpers",
                "_NIOBase64",
                "CNIODarwin",
                "CNIOLinux",
                "CNIOWindows",
                "CNIOWASI",
                "_NIODataStructures",
                swiftCollections,
                swiftAtomics,
            ],
            swiftSettings: strictConcurrencySettings
        ),
        .target(
            name: "_NIODataStructures",
            swiftSettings: strictConcurrencySettings
        ),
        .target(
            name: "_NIOBase64",
            swiftSettings: strictConcurrencySettings
        ),
        .target(
            name: "NIOEmbedded",
            dependencies: [
                "NIOCore",
                "NIOConcurrencyHelpers",
                "_NIODataStructures",
                swiftAtomics,
                swiftCollections,
            ],
            swiftSettings: strictConcurrencySettings
        ),
        .target(
            name: "NIOPosix",
            dependencies: [
                "CNIOLinux",
                "CNIODarwin",
                "CNIOWindows",
                "NIOConcurrencyHelpers",
                "NIOCore",
                "_NIODataStructures",
                "CNIOPosix",
                swiftAtomics,
            ],
            exclude: includePrivacyManifest ? [] : ["PrivacyInfo.xcprivacy"],
            resources: includePrivacyManifest ? [.copy("PrivacyInfo.xcprivacy")] : [],
            swiftSettings: strictConcurrencySettings
        ),
        .target(
            name: "NIO",
            dependencies: [
                "NIOCore",
                "NIOEmbedded",
                "NIOPosix",
            ],
            swiftSettings: strictConcurrencySettings
        ),
        .target(
            name: "_NIOConcurrency",
            dependencies: [
                .target(name: "NIO", condition: .when(platforms: historicalNIOPosixDependencyRequired)),
                "NIOCore",
            ],
            swiftSettings: strictConcurrencySettings
        ),
        .target(
            name: "NIOFoundationCompat",
            dependencies: [
                .target(name: "NIO", condition: .when(platforms: historicalNIOPosixDependencyRequired)),
                "NIOCore",
            ],
            swiftSettings: strictConcurrencySettings
        ),
        .target(
            name: "CNIOAtomics",
            dependencies: [],
            cSettings: [
                .define("_GNU_SOURCE")
            ]
        ),
        .target(
            name: "CNIOPosix",
            dependencies: [],
            cSettings: [
                .define("_GNU_SOURCE")
            ]
        ),
        .target(
            name: "CNIOSHA1",
            dependencies: []
        ),
        .target(
            name: "CNIOLinux",
            dependencies: [],
            cSettings: [
                .define("_GNU_SOURCE")
            ]
        ),
        .target(
            name: "CNIODarwin",
            dependencies: [],
            cSettings: [
                .define("__APPLE_USE_RFC_3542")
            ]
        ),
        .target(
            name: "CNIOWindows",
            dependencies: []
        ),
        .target(
            name: "CNIOWASI",
            dependencies: []
        ),
        .target(
            name: "NIOConcurrencyHelpers",
            dependencies: [
                "CNIOAtomics"
            ],
            swiftSettings: strictConcurrencySettings
        ),
        .target(
            name: "NIOHTTP1",
            dependencies: [
                .target(name: "NIO", condition: .when(platforms: historicalNIOPosixDependencyRequired)),
                "NIOCore",
                "NIOConcurrencyHelpers",
                "CNIOLLHTTP",
                swiftCollections,
            ],
            swiftSettings: strictConcurrencySettings
        ),
        .target(
            name: "NIOWebSocket",
            dependencies: [
                .target(name: "NIO", condition: .when(platforms: historicalNIOPosixDependencyRequired)),
                "NIOCore",
                "NIOHTTP1",
                "CNIOSHA1",
                "_NIOBase64",
            ],
            swiftSettings: strictConcurrencySettings
        ),
        .target(
            name: "CNIOLLHTTP",
            cSettings: [
                .define("_GNU_SOURCE"),
                .define("LLHTTP_STRICT_MODE"),
            ]
        ),
        .target(
            name: "NIOTLS",
            dependencies: [
                .target(name: "NIO", condition: .when(platforms: historicalNIOPosixDependencyRequired)),
                "NIOCore",
                swiftCollections,
            ],
            swiftSettings: strictConcurrencySettings
        ),
        .target(
            name: "NIOTestUtils",
            dependencies: [
                "NIOPosix",
                "NIOCore",
                "NIOEmbedded",
                "NIOHTTP1",
                swiftAtomics,
            ],
            swiftSettings: strictConcurrencySettings
        ),
        .target(
            name: "_NIOFileSystem",
            dependencies: [
                "NIOCore",
                "NIOPosix",
                "CNIOLinux",
                "CNIODarwin",
                swiftAtomics,
                swiftCollections,
                swiftSystem,
            ],
            path: "Sources/NIOFileSystem",
            exclude: includePrivacyManifest ? [] : ["PrivacyInfo.xcprivacy"],
            resources: includePrivacyManifest ? [.copy("PrivacyInfo.xcprivacy")] : [],
            swiftSettings: strictConcurrencySettings + [
                .define("ENABLE_MOCKING", .when(configuration: .debug))
            ]
        ),
        .target(
            name: "NIOFileSystem",
            dependencies: [
                "_NIOFileSystem"
            ],
            path: "Sources/_NIOFileSystemExported",
            swiftSettings: strictConcurrencySettings
        ),
        .target(
            name: "_NIOFileSystemFoundationCompat",
            dependencies: [
                "_NIOFileSystem",
                "NIOFoundationCompat",
            ],
            path: "Sources/NIOFileSystemFoundationCompat",
            swiftSettings: strictConcurrencySettings
        ),

        // MARK: - Examples

        .executableTarget(
            name: "NIOTCPEchoServer",
            dependencies: [
                "NIOPosix",
                "NIOCore",
            ],
            exclude: ["README.md"],
            swiftSettings: strictConcurrencySettings
        ),
        .executableTarget(
            name: "NIOTCPEchoClient",
            dependencies: [
                "NIOPosix",
                "NIOCore",
            ],
            exclude: ["README.md"],
            swiftSettings: strictConcurrencySettings
        ),
        .executableTarget(
            name: "NIOEchoServer",
            dependencies: [
                "NIOPosix",
                "NIOCore",
                "NIOConcurrencyHelpers",
            ],
            exclude: ["README.md"],
            swiftSettings: strictConcurrencySettings
        ),
        .executableTarget(
            name: "NIOEchoClient",
            dependencies: [
                "NIOPosix",
                "NIOCore",
                "NIOConcurrencyHelpers",
            ],
            exclude: ["README.md"],
            swiftSettings: strictConcurrencySettings
        ),
        .executableTarget(
            name: "NIOHTTP1Server",
            dependencies: [
                "NIOPosix",
                "NIOCore",
                "NIOHTTP1",
                "NIOConcurrencyHelpers",
            ],
            exclude: ["README.md"],
            swiftSettings: strictConcurrencySettings
        ),
        .executableTarget(
            name: "NIOHTTP1Client",
            dependencies: [
                "NIOPosix",
                "NIOCore",
                "NIOHTTP1",
                "NIOConcurrencyHelpers",
            ],
            exclude: ["README.md"],
            swiftSettings: strictConcurrencySettings
        ),
        .executableTarget(
            name: "NIOChatServer",
            dependencies: [
                "NIOPosix",
                "NIOCore",
                "NIOConcurrencyHelpers",
            ],
            exclude: ["README.md"],
            swiftSettings: strictConcurrencySettings
        ),
        .executableTarget(
            name: "NIOChatClient",
            dependencies: [
                "NIOPosix",
                "NIOCore",
                "NIOConcurrencyHelpers",
            ],
            exclude: ["README.md"],
            swiftSettings: strictConcurrencySettings
        ),
        .executableTarget(
            name: "NIOWebSocketServer",
            dependencies: [
                "NIOPosix",
                "NIOCore",
                "NIOHTTP1",
                "NIOWebSocket",
            ],
            exclude: ["README.md"],
            swiftSettings: strictConcurrencySettings
        ),
        .executableTarget(
            name: "NIOWebSocketClient",
            dependencies: [
                "NIOPosix",
                "NIOCore",
                "NIOHTTP1",
                "NIOWebSocket",
            ],
            exclude: ["README.md"],
            swiftSettings: strictConcurrencySettings
        ),
        .executableTarget(
            name: "NIOMulticastChat",
            dependencies: [
                "NIOPosix",
                "NIOCore",
            ],
            swiftSettings: strictConcurrencySettings
        ),
        .executableTarget(
            name: "NIOUDPEchoServer",
            dependencies: [
                "NIOPosix",
                "NIOCore",
            ],
            exclude: ["README.md"],
            swiftSettings: strictConcurrencySettings
        ),
        .executableTarget(
            name: "NIOUDPEchoClient",
            dependencies: [
                "NIOPosix",
                "NIOCore",
            ],
            exclude: ["README.md"],
            swiftSettings: strictConcurrencySettings
        ),
        .executableTarget(
            name: "NIOAsyncAwaitDemo",
            dependencies: [
                "NIOPosix",
                "NIOCore",
                "NIOHTTP1",
            ],
            swiftSettings: strictConcurrencySettings
        ),

        // MARK: - Tests

        .executableTarget(
            name: "NIOPerformanceTester",
            dependencies: [
                "NIOPosix",
                "NIOCore",
                "NIOEmbedded",
                "NIOHTTP1",
                "NIOFoundationCompat",
                "NIOWebSocket",
            ],
            swiftSettings: strictConcurrencySettings
        ),
        .executableTarget(
            name: "NIOCrashTester",
            dependencies: [
                "NIOPosix",
                "NIOCore",
                "NIOEmbedded",
                "NIOHTTP1",
                "NIOWebSocket",
                "NIOFoundationCompat",
            ],
            swiftSettings: strictConcurrencySettings
        ),
        .testTarget(
            name: "NIOCoreTests",
            dependencies: [
                "NIOConcurrencyHelpers",
                "NIOCore",
                "NIOEmbedded",
                "NIOFoundationCompat",
                "NIOTestUtils",
                swiftAtomics,
            ],
            swiftSettings: strictConcurrencySettings
        ),
        .testTarget(
            name: "NIOEmbeddedTests",
            dependencies: [
                "NIOConcurrencyHelpers",
                "NIOCore",
                "NIOEmbedded",
            ],
            swiftSettings: strictConcurrencySettings
        ),
        .testTarget(
            name: "NIOPosixTests",
            dependencies: [
                "NIOPosix",
                "NIOCore",
                "NIOFoundationCompat",
                "NIOTestUtils",
                "NIOConcurrencyHelpers",
                "NIOEmbedded",
                "CNIOLinux",
                "CNIODarwin",
                "NIOTLS",
            ],
            swiftSettings: strictConcurrencySettings
        ),
        .testTarget(
            name: "NIOConcurrencyHelpersTests",
            dependencies: [
                "NIOConcurrencyHelpers",
                "NIOCore",
            ],
            swiftSettings: strictConcurrencySettings
        ),
        .testTarget(
            name: "NIODataStructuresTests",
            dependencies: ["_NIODataStructures"],
            swiftSettings: strictConcurrencySettings
        ),
        .testTarget(
            name: "NIOBase64Tests",
            dependencies: ["_NIOBase64"],
            swiftSettings: strictConcurrencySettings
        ),
        .testTarget(
            name: "NIOHTTP1Tests",
            dependencies: [
                "NIOCore",
                "NIOEmbedded",
                "NIOPosix",
                "NIOHTTP1",
                "NIOFoundationCompat",
                "NIOTestUtils",
            ],
            swiftSettings: strictConcurrencySettings
        ),
        .testTarget(
            name: "NIOTLSTests",
            dependencies: [
                "NIOCore",
                "NIOEmbedded",
                "NIOTLS",
                "NIOFoundationCompat",
                "NIOTestUtils",
            ],
            swiftSettings: strictConcurrencySettings
        ),
        .testTarget(
            name: "NIOWebSocketTests",
            dependencies: [
                "NIOCore",
                "NIOEmbedded",
                "NIOWebSocket",
            ],
            swiftSettings: strictConcurrencySettings
        ),
        .testTarget(
            name: "NIOTestUtilsTests",
            dependencies: [
                "NIOTestUtils",
                "NIOCore",
                "NIOEmbedded",
                "NIOPosix",
            ],
            swiftSettings: strictConcurrencySettings
        ),
        .testTarget(
            name: "NIOFoundationCompatTests",
            dependencies: [
                "NIOCore",
                "NIOFoundationCompat",
            ],
            swiftSettings: strictConcurrencySettings
        ),
        .testTarget(
            name: "NIOTests",
            dependencies: ["NIO"],
            swiftSettings: strictConcurrencySettings
        ),
        .testTarget(
            name: "NIOSingletonsTests",
            dependencies: ["NIOCore", "NIOPosix"],
            swiftSettings: strictConcurrencySettings
        ),
        .testTarget(
            name: "NIOFileSystemTests",
            dependencies: [
                "NIOCore",
                "_NIOFileSystem",
                swiftAtomics,
                swiftCollections,
                swiftSystem,
            ],
            swiftSettings: strictConcurrencySettings + [
                .define("ENABLE_MOCKING", .when(configuration: .debug))
            ]
        ),
        .testTarget(
            name: "NIOFileSystemIntegrationTests",
            dependencies: [
                "NIOCore",
                "NIOPosix",
                "_NIOFileSystem",
                "NIOFoundationCompat",
            ],
            exclude: [
                // Contains known files and directory structures used
                // for the integration tests. Exclude the whole tree from
                // the build.
                "Test Data"
            ],
            swiftSettings: strictConcurrencySettings
        ),
        .testTarget(
            name: "NIOFileSystemFoundationCompatTests",
            dependencies: [
                "_NIOFileSystem",
                "_NIOFileSystemFoundationCompat",
            ],
            swiftSettings: strictConcurrencySettings
        ),
    ]
)

if Context.environment["SWIFTCI_USE_LOCAL_DEPS"] == nil {
    package.dependencies += [
        .package(url: "https://github.com/apple/swift-atomics.git", from: "1.1.0"),
        .package(url: "https://github.com/apple/swift-collections.git", from: "1.1.0"),
        .package(url: "https://github.com/apple/swift-system.git", from: "1.4.0"),
    ]
} else {
    package.dependencies += [
        .package(path: "../swift-atomics"),
        .package(path: "../swift-collections"),
        .package(path: "../swift-system"),
    ]
}

// ---    STANDARD CROSS-REPO SETTINGS DO NOT EDIT   --- //
for target in package.targets {
    switch target.type {
    case .regular, .test, .executable:
        var settings = target.swiftSettings ?? []
        // https://github.com/swiftlang/swift-evolution/blob/main/proposals/0444-member-import-visibility.md
        settings.append(.enableUpcomingFeature("MemberImportVisibility"))
        target.swiftSettings = settings
    case .macro, .plugin, .system, .binary:
        ()  // not applicable
    @unknown default:
        ()  // we don't know what to do here, do nothing
    }
}
// --- END: STANDARD CROSS-REPO SETTINGS DO NOT EDIT --- //
