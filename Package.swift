// swift-tools-version:5.8
//===----------------------------------------------------------------------===//
//
// This source file is part of the swift-semver open source project
//
// Copyright (c) Gwynne Raskind
// Licensed under the MIT license
//
// See LICENSE.txt for license information
//
// SPDX-License-Identifier: MIT
//
//===----------------------------------------------------------------------===//
import PackageDescription

let commonSwiftSettings: [PackageDescription.SwiftSetting] = [
    // We deliberately choose to opt in to several upcoming language features.
    .enableUpcomingFeature("ConciseMagicFile"),
    .enableUpcomingFeature("ForwardTrailingClosures"),
    .enableUpcomingFeature("ExistentialAny"),
    .enableUpcomingFeature("BareSlashRegexLiterals"),
    .enableExperimentalFeature("StrictConcurrency=complete"),
]

let package = Package(
    name: "swift-semver",
    platforms: [
        .macOS(.v13),
        .macCatalyst(.v16),
        .iOS(.v16),
        .watchOS(.v9),
        .tvOS(.v16),
    ],
    products: [
        .library(name: "SwiftSemver", targets: ["SwiftSemver"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "SwiftSemver",
            dependencies: [],
            swiftSettings: commonSwiftSettings
        ),
        .testTarget(
            name: "SwiftSemverTests",
            dependencies: [
                .target(name: "SwiftSemver"),
            ],
            swiftSettings: commonSwiftSettings
        ),
    ]
)
