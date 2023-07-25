// swift-tools-version:5.6
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

let package = Package(
    name: "swift-semver",
    products: [
        .library(name: "SwiftSemver", targets: ["SwiftSemver"]),
    ],
    dependencies: [],
    targets: [
        .target(name: "SwiftSemver", dependencies: []),
        .testTarget(name: "SwiftSemverTests", dependencies: [.target(name: "SwiftSemver")]),
    ]
)
