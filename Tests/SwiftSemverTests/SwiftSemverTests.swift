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
import XCTest
import SwiftSemver

/// - Note: Most of the tests refer to productions found in the semver BNF grammar.
/// - Note: These tests depend heavily on the "strict" behavior of `SemanticVersion`'s `Equatable` conformance.
final class SwiftSemverTests: XCTestCase {
    
    func testEqualityIsStrict() throws {
        XCTAssertEqual(SemanticVersion(1, 0, 0, prereleaseIdentifiers: ["a"], buildMetadataIdentifiers: ["a"]),
                       SemanticVersion(1, 0, 0, prereleaseIdentifiers: ["a"], buildMetadataIdentifiers: ["a"]))

        XCTAssertEqual(SemanticVersion(1, 0, 0, prereleaseIdentifiers: ["a", "b"], buildMetadataIdentifiers: ["a", "b"]),
                       SemanticVersion(1, 0, 0, prereleaseIdentifiers: ["a", "b"], buildMetadataIdentifiers: ["a", "b"]))
        
        XCTAssertNotEqual(SemanticVersion(1, 0, 0, prereleaseIdentifiers: ["a"], buildMetadataIdentifiers: ["a"]),
                          SemanticVersion(1, 0, 0, prereleaseIdentifiers: ["a"], buildMetadataIdentifiers: ["b"]))

        XCTAssertNotEqual(SemanticVersion(1, 0, 0, prereleaseIdentifiers: ["a", "b"], buildMetadataIdentifiers: ["a", "b"]),
                          SemanticVersion(1, 0, 0, prereleaseIdentifiers: ["a", "b"], buildMetadataIdentifiers: ["a"]))

        XCTAssertNotEqual(SemanticVersion(1, 0, 0, prereleaseIdentifiers: ["a", "b"], buildMetadataIdentifiers: ["a", "b"]),
                          SemanticVersion(1, 0, 0, prereleaseIdentifiers: ["a"], buildMetadataIdentifiers: ["a", "b"]))

        XCTAssertNotEqual(SemanticVersion(1, 0, 0, prereleaseIdentifiers: ["a", "b"], buildMetadataIdentifiers: ["a", "b"]),
                          SemanticVersion(1, 0, 0, prereleaseIdentifiers: ["a", "b"], buildMetadataIdentifiers: ["b", "a"]))

        XCTAssertNotEqual(SemanticVersion(1, 0, 0, prereleaseIdentifiers: ["a", "b"], buildMetadataIdentifiers: ["a", "b"]),
                          SemanticVersion(1, 0, 0, prereleaseIdentifiers: ["b", "a"], buildMetadataIdentifiers: ["a", "b"]))
    }
    
    func testParseVersionCore() throws {
        XCTAssertEqual(SemanticVersion("0.0.0"), SemanticVersion(0, 0, 0))

        XCTAssertEqual(SemanticVersion("0.0.1"), SemanticVersion(0, 0, 1))
        XCTAssertEqual(SemanticVersion("0.1.0"), SemanticVersion(0, 1, 0))
        XCTAssertEqual(SemanticVersion("0.1.1"), SemanticVersion(0, 1, 1))
        XCTAssertEqual(SemanticVersion("1.0.0"), SemanticVersion(1, 0, 0))
        XCTAssertEqual(SemanticVersion("1.0.1"), SemanticVersion(1, 0, 1))
        XCTAssertEqual(SemanticVersion("1.1.0"), SemanticVersion(1, 1, 0))
        XCTAssertEqual(SemanticVersion("1.1.1"), SemanticVersion(1, 1, 1))

        XCTAssertEqual(SemanticVersion("0.0.99999"), SemanticVersion(0, 0, 99999))
        XCTAssertEqual(SemanticVersion("0.99999.0"), SemanticVersion(0, 99999, 0))
        XCTAssertEqual(SemanticVersion("0.99999.99999"), SemanticVersion(0, 99999, 99999))
        XCTAssertEqual(SemanticVersion("99999.0.0"), SemanticVersion(99999, 0, 0))
        XCTAssertEqual(SemanticVersion("99999.0.99999"), SemanticVersion(99999, 0, 99999))
        XCTAssertEqual(SemanticVersion("99999.99999.0"), SemanticVersion(99999, 99999, 0))
        XCTAssertEqual(SemanticVersion("99999.99999.99999"), SemanticVersion(99999, 99999, 99999))
        
        XCTAssertEqual(SemanticVersion("01.02.03"), SemanticVersion(1, 2, 3))

        for badStr in [
            "", // empty
            "0", "0.0", "0.0.0.0", "1.2.3.4.5", // wrong # of components
            "-0.0.0", "0.-0.0", "0.0.-0", // negative values
            "0a.0.0", "0.0a.0", "0.0.0a", "a0.0.0", "0.a0.0", "0.0.a0", // non-numeric characters
            "a.1.2", "1.a.2", "1.2.a", // non-numeric components
            ".1.2.3", "1..2.3", "1.2..3", "1.2.3.", // extra dots
        ] {
            XCTAssertNil(SemanticVersion("\(badStr)"))
            XCTAssertNil(SemanticVersion("\(badStr)-a"))
            XCTAssertNil(SemanticVersion("\(badStr)+b"))
            XCTAssertNil(SemanticVersion("\(badStr)-a+b"))
        }
    }
    
    func testParseVersionCoreWithPreRelease() throws {
        XCTAssertEqual(SemanticVersion("1.2.3-dev"), SemanticVersion(1, 2, 3, prereleaseIdentifiers: ["dev"]))
        XCTAssertEqual(SemanticVersion("1.2.3-dev1.dev2"), SemanticVersion(1, 2, 3, prereleaseIdentifiers: ["dev1", "dev2"]))
        XCTAssertEqual(SemanticVersion("1.2.3-dev.1.more"), SemanticVersion(1, 2, 3, prereleaseIdentifiers: ["dev", "1", "more"]))
        XCTAssertEqual(SemanticVersion("1.2.3-dev.1.2"), SemanticVersion(1, 2, 3, prereleaseIdentifiers: ["dev", "1", "2"]))
        XCTAssertEqual(SemanticVersion("1.2.3-1.dev"), SemanticVersion(1, 2, 3, prereleaseIdentifiers: ["1", "dev"]))
        XCTAssertEqual(SemanticVersion("1.2.3-dev-a"), SemanticVersion(1, 2, 3, prereleaseIdentifiers: ["dev-a"]))
        XCTAssertEqual(SemanticVersion("1.2.3--dev"), SemanticVersion(1, 2, 3, prereleaseIdentifiers: ["-dev"]))
        
        for badStr in [
            "1.2.3-!dev", "1.2.3-dev!", "1.2.3-d!ev", // non-letter characters
            "1.2.3-dev-!1", "1.2.3-dev-1!", "1.2.3-dev.!",
        ] {
            XCTAssertNil(SemanticVersion("\(badStr)"))
            XCTAssertNil(SemanticVersion("\(badStr)+b"))
        }
    }
    
    func testParseVersionCoreWithBuild() throws {
        XCTAssertEqual(SemanticVersion("1.2.3+dev"), SemanticVersion(1, 2, 3, prereleaseIdentifiers: [], buildMetadataIdentifiers: ["dev"]))
        XCTAssertEqual(SemanticVersion("1.2.3+dev1.dev2"), SemanticVersion(1, 2, 3, prereleaseIdentifiers: [], buildMetadataIdentifiers: ["dev1", "dev2"]))
        XCTAssertEqual(SemanticVersion("1.2.3+dev.1.more"), SemanticVersion(1, 2, 3, prereleaseIdentifiers: [], buildMetadataIdentifiers: ["dev", "1", "more"]))
        XCTAssertEqual(SemanticVersion("1.2.3+dev.1.2"), SemanticVersion(1, 2, 3, prereleaseIdentifiers: [], buildMetadataIdentifiers: ["dev", "1", "2"]))
        XCTAssertEqual(SemanticVersion("1.2.3+1.dev"), SemanticVersion(1, 2, 3, prereleaseIdentifiers: [], buildMetadataIdentifiers: ["1", "dev"]))
        XCTAssertEqual(SemanticVersion("1.2.3+dev-a"), SemanticVersion(1, 2, 3, prereleaseIdentifiers: [], buildMetadataIdentifiers: ["dev-a"]))
        XCTAssertEqual(SemanticVersion("1.2.3+-dev"), SemanticVersion(1, 2, 3, prereleaseIdentifiers: [], buildMetadataIdentifiers: ["-dev"]))

        for badStr in [
            "1.2.3+!dev", "1.2.3+dev!", "1.2.3+d!ev", // non-letter characters
            "1.2.3+dev-!1", "1.2.3+dev-1!", "1.2.3+dev.!",
        ] {
            XCTAssertNil(SemanticVersion("\(badStr)"))
        }
    }
    
    func testParseVersionCoreWithPrereleaseAndBuild() throws {
        XCTAssertEqual(SemanticVersion("1.2.3-dev+dev"), SemanticVersion(1, 2, 3, prereleaseIdentifiers: ["dev"], buildMetadataIdentifiers: ["dev"]))
        XCTAssertEqual(SemanticVersion("1.2.3-dev1.dev2+dev1.dev2"), SemanticVersion(1, 2, 3, prereleaseIdentifiers: ["dev1", "dev2"], buildMetadataIdentifiers: ["dev1", "dev2"]))
        XCTAssertEqual(SemanticVersion("1.2.3-dev.1.more+dev.1.more"), SemanticVersion(1, 2, 3, prereleaseIdentifiers: ["dev", "1", "more"], buildMetadataIdentifiers: ["dev", "1", "more"]))
        XCTAssertEqual(SemanticVersion("1.2.3-dev.1.2+dev.1.2"), SemanticVersion(1, 2, 3, prereleaseIdentifiers: ["dev", "1", "2"], buildMetadataIdentifiers: ["dev", "1", "2"]))
        XCTAssertEqual(SemanticVersion("1.2.3-1.dev+1.dev"), SemanticVersion(1, 2, 3, prereleaseIdentifiers: ["1", "dev"], buildMetadataIdentifiers: ["1", "dev"]))
        XCTAssertEqual(SemanticVersion("1.2.3-dev-a+dev-a"), SemanticVersion(1, 2, 3, prereleaseIdentifiers: ["dev-a"], buildMetadataIdentifiers: ["dev-a"]))
        XCTAssertEqual(SemanticVersion("1.2.3--dev+-dev"), SemanticVersion(1, 2, 3, prereleaseIdentifiers: ["-dev"], buildMetadataIdentifiers: ["-dev"]))
    }
    
    func testSerializeVersions() throws {
        XCTAssertEqual(SemanticVersion(1, 0, 0, prereleaseIdentifiers: [], buildMetadataIdentifiers: []).description, "1.0.0")
        XCTAssertEqual(SemanticVersion(1, 1, 0, prereleaseIdentifiers: [], buildMetadataIdentifiers: []).description, "1.1.0")
        XCTAssertEqual(SemanticVersion(1, 1, 1, prereleaseIdentifiers: [], buildMetadataIdentifiers: []).description, "1.1.1")
        XCTAssertEqual(SemanticVersion(1, 0, 0, prereleaseIdentifiers: ["a"], buildMetadataIdentifiers: []).description, "1.0.0-a")
        XCTAssertEqual(SemanticVersion(1, 0, 0, prereleaseIdentifiers: ["a", "b"], buildMetadataIdentifiers: []).description, "1.0.0-a.b")
        XCTAssertEqual(SemanticVersion(1, 0, 0, prereleaseIdentifiers: ["1", "a"], buildMetadataIdentifiers: []).description, "1.0.0-1.a")
        XCTAssertEqual(SemanticVersion(1, 0, 0, prereleaseIdentifiers: ["1"], buildMetadataIdentifiers: []).description, "1.0.0-1")
        XCTAssertEqual(SemanticVersion(1, 0, 0, prereleaseIdentifiers: [], buildMetadataIdentifiers: ["a"]).description, "1.0.0+a")
        XCTAssertEqual(SemanticVersion(1, 0, 0, prereleaseIdentifiers: [], buildMetadataIdentifiers: ["a", "b"]).description, "1.0.0+a.b")
        XCTAssertEqual(SemanticVersion(1, 0, 0, prereleaseIdentifiers: [], buildMetadataIdentifiers: ["1", "a"]).description, "1.0.0+1.a")
        XCTAssertEqual(SemanticVersion(1, 0, 0, prereleaseIdentifiers: [], buildMetadataIdentifiers: ["1"]).description, "1.0.0+1")
        XCTAssertEqual(SemanticVersion(1, 0, 0, prereleaseIdentifiers: ["a"], buildMetadataIdentifiers: ["a"]).description, "1.0.0-a+a")
        XCTAssertEqual(SemanticVersion(1, 0, 0, prereleaseIdentifiers: ["a", "b"], buildMetadataIdentifiers: ["a", "b"]).description, "1.0.0-a.b+a.b")
        XCTAssertEqual(SemanticVersion(1, 0, 0, prereleaseIdentifiers: ["1", "a"], buildMetadataIdentifiers: ["1", "a"]).description, "1.0.0-1.a+1.a")
        XCTAssertEqual(SemanticVersion(1, 0, 0, prereleaseIdentifiers: ["1"], buildMetadataIdentifiers: ["1"]).description, "1.0.0-1+1")
    }
    
    func testPrecedenceWithVersionCoreOnly() throws {
        // Comparable <
        XCTAssertLessThan(SemanticVersion("0.0.0")!, SemanticVersion("0.0.1")!)
        XCTAssertLessThan(SemanticVersion("0.0.0")!, SemanticVersion("0.1.0")!)
        XCTAssertLessThan(SemanticVersion("0.0.1")!, SemanticVersion("0.1.0")!)
        XCTAssertLessThan(SemanticVersion("0.0.0")!, SemanticVersion("1.0.0")!)
        XCTAssertLessThan(SemanticVersion("0.0.1")!, SemanticVersion("1.0.0")!)
        XCTAssertLessThan(SemanticVersion("0.1.0")!, SemanticVersion("1.0.0")!)
        
        // Comparable <=
        XCTAssertLessThanOrEqual(SemanticVersion("0.0.0")!, SemanticVersion("0.0.1")!)
        XCTAssertLessThanOrEqual(SemanticVersion("0.0.0")!, SemanticVersion("0.1.0")!)
        XCTAssertLessThanOrEqual(SemanticVersion("0.0.1")!, SemanticVersion("0.1.0")!)
        XCTAssertLessThanOrEqual(SemanticVersion("0.0.0")!, SemanticVersion("1.0.0")!)
        XCTAssertLessThanOrEqual(SemanticVersion("0.0.1")!, SemanticVersion("1.0.0")!)
        XCTAssertLessThanOrEqual(SemanticVersion("0.1.0")!, SemanticVersion("1.0.0")!)
        
        // Comparable >
        XCTAssertGreaterThan(SemanticVersion("0.0.1")!, SemanticVersion("0.0.0")!)
        XCTAssertGreaterThan(SemanticVersion("0.1.0")!, SemanticVersion("0.0.0")!)
        XCTAssertGreaterThan(SemanticVersion("0.1.0")!, SemanticVersion("0.0.1")!)
        XCTAssertGreaterThan(SemanticVersion("1.0.0")!, SemanticVersion("0.0.0")!)
        XCTAssertGreaterThan(SemanticVersion("1.0.0")!, SemanticVersion("0.0.1")!)
        XCTAssertGreaterThan(SemanticVersion("1.0.0")!, SemanticVersion("0.1.0")!)
        
        // Comparable >=
        XCTAssertGreaterThanOrEqual(SemanticVersion("0.0.1")!, SemanticVersion("0.0.0")!)
        XCTAssertGreaterThanOrEqual(SemanticVersion("0.1.0")!, SemanticVersion("0.0.0")!)
        XCTAssertGreaterThanOrEqual(SemanticVersion("0.1.0")!, SemanticVersion("0.0.1")!)
        XCTAssertGreaterThanOrEqual(SemanticVersion("1.0.0")!, SemanticVersion("0.0.0")!)
        XCTAssertGreaterThanOrEqual(SemanticVersion("1.0.0")!, SemanticVersion("0.0.1")!)
        XCTAssertGreaterThanOrEqual(SemanticVersion("1.0.0")!, SemanticVersion("0.1.0")!)
        
        // Comparable <= && >=
        XCTAssertLessThanOrEqual(SemanticVersion("0.0.0")!, SemanticVersion("0.0.0")!)
        XCTAssertLessThanOrEqual(SemanticVersion("0.0.1")!, SemanticVersion("0.0.1")!)
        XCTAssertLessThanOrEqual(SemanticVersion("0.1.0")!, SemanticVersion("0.1.0")!)
        XCTAssertLessThanOrEqual(SemanticVersion("1.0.0")!, SemanticVersion("1.0.0")!)
        XCTAssertGreaterThanOrEqual(SemanticVersion("0.0.0")!, SemanticVersion("0.0.0")!)
        XCTAssertGreaterThanOrEqual(SemanticVersion("0.0.1")!, SemanticVersion("0.0.1")!)
        XCTAssertGreaterThanOrEqual(SemanticVersion("0.1.0")!, SemanticVersion("0.1.0")!)
        XCTAssertGreaterThanOrEqual(SemanticVersion("1.0.0")!, SemanticVersion("1.0.0")!)
    }
    
    func testPrecedenceWithPreRelease() throws {
        // Rule 3: Major/minor/patch being equal, pre-release versions are always less than normal versions.
        XCTAssertLessThan(SemanticVersion("1.0.0-rc.9")!, SemanticVersion("1.0.0")!)
        XCTAssertLessThanOrEqual(SemanticVersion("1.0.0-rc.9")!, SemanticVersion("1.0.0")!)
        XCTAssertGreaterThan(SemanticVersion("1.0.0")!, SemanticVersion("1.0.0-rc.9")!)
        XCTAssertGreaterThanOrEqual(SemanticVersion("1.0.0")!, SemanticVersion("1.0.0-rc.9")!)
        
        // Rule 4.1: Numeric identifiers are compared numerically, not lexicographically.
        XCTAssertLessThan(SemanticVersion("1.0.0-rc.2")!, SemanticVersion("1.0.0-rc.10")!)
        XCTAssertLessThanOrEqual(SemanticVersion("1.0.0-rc.2")!, SemanticVersion("1.0.0-rc.10")!)
        XCTAssertGreaterThan(SemanticVersion("1.0.0-rc.10")!, SemanticVersion("1.0.0-rc.2")!)
        XCTAssertGreaterThanOrEqual(SemanticVersion("1.0.0-rc.10")!, SemanticVersion("1.0.0-rc.2")!)
        
        // Rule 4.2: Alphanumeric identifiers are compared lexicographically.
        XCTAssertLessThan(SemanticVersion("1.0.0-alpha")!, SemanticVersion("1.0.0-beta")!)
        XCTAssertLessThanOrEqual(SemanticVersion("1.0.0-alpha")!, SemanticVersion("1.0.0-beta")!)
        XCTAssertGreaterThan(SemanticVersion("1.0.0-beta")!, SemanticVersion("1.0.0-alpha")!)
        XCTAssertGreaterThanOrEqual(SemanticVersion("1.0.0-beta")!, SemanticVersion("1.0.0-alpha")!)
        
        // Rule 4.3: Numeric identifiers are always lower precedence than alphanumeric identifiers.
        XCTAssertLessThan(SemanticVersion("1.0.0-10")!, SemanticVersion("1.0.0-a")!)
        XCTAssertLessThanOrEqual(SemanticVersion("1.0.0-10")!, SemanticVersion("1.0.0-a")!)
        XCTAssertGreaterThan(SemanticVersion("1.0.0-a")!, SemanticVersion("1.0.0-10")!)
        XCTAssertGreaterThanOrEqual(SemanticVersion("1.0.0-a")!, SemanticVersion("1.0.0-10")!)
        
        // Rule 4.4: All preceeding identifiers being equal, a shorter set has lower precedence than a longer set.
        XCTAssertLessThan(SemanticVersion("1.0.0-alpha.1")!, SemanticVersion("1.0.0-alpha.1.2")!)
        XCTAssertLessThanOrEqual(SemanticVersion("1.0.0-alpha.1")!, SemanticVersion("1.0.0-alpha.1.2")!)
        XCTAssertGreaterThan(SemanticVersion("1.0.0-alpha.1.2")!, SemanticVersion("1.0.0-alpha.1")!)
        XCTAssertGreaterThanOrEqual(SemanticVersion("1.0.0-alpha.1.2")!, SemanticVersion("1.0.0-alpha.1")!)
        
        // Rule 1 corollary: Build metadata identifiers do not affect precedence.
        XCTAssertLessThanOrEqual(SemanticVersion("1.0.0-alpha.1+snafu")!, SemanticVersion("1.0.0-alpha.1+fubar")!)
        XCTAssertGreaterThanOrEqual(SemanticVersion("1.0.0-alpha.1+snafu")!, SemanticVersion("1.0.0-alpha.1+fubar")!)
        XCTAssertLessThanOrEqual(SemanticVersion("1.0.0-alpha.1+fubar")!, SemanticVersion("1.0.0-alpha.1+snafu")!)
        XCTAssertGreaterThanOrEqual(SemanticVersion("1.0.0-alpha.1+fubar")!, SemanticVersion("1.0.0-alpha.1+snafu")!)
    }
    
    func testPrecedenceOrdering() throws {
        // This is the sequence provided as an example of the precedence rules by the spec.
        var sequence = [
            "1.0.0-alpha",
            "1.0.0-alpha.1",
            "1.0.0-alpha.beta",
            "1.0.0-beta",
            "1.0.0-beta.2",
            "1.0.0-beta.11",
            "1.0.0-rc.1",
            "1.0.0",
        ].map { SemanticVersion($0)! }
        
        while let ver = sequence.popFirst() {
            sequence.forEach {
                XCTAssertLessThan(ver, $0)
                XCTAssertLessThanOrEqual(ver, $0)
                XCTAssertGreaterThan($0, ver)
                XCTAssertGreaterThanOrEqual($0, ver)
            }
        }
    }
}

fileprivate extension RangeReplaceableCollection {
    mutating func popFirst() -> Element? {
        guard !self.isEmpty else { return nil }
        return self.removeFirst()
    }
}
