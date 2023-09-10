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

/// An arbitrary semantic version number, represented as its individual components. This type adheres to the format and
/// behaviors specified by [Semantic Versioning 2.0.0][semver2]. This is the same versioning format used by the Swift
/// Package Manager, and some of this implementation was informed by the one found in SPM. A short summary of the
/// semantics provided by the specification follows.
///
/// [semver2]: https://semver.org/spec/v2.0.0.html
///
/// A semantic version contains three required components (major version, minor version, and patch level). It may
/// optionally contain any number of "prerelease identifier" components; these are often used to represent development
/// stages, such as "alpha", "beta", and "rc". It may also optionally contain any number of build metadata identifiers,
/// which are sometimes used to uniquely identify builds (such as by a timestamp or UUID, or with an architecture name).
///
/// All of a version's components, including both types of identifiers, are considered when determining _equality_ of
/// any two or more semantic versions. This is not the case, however, when determining the precedence of a given version
/// relative to another, where "precedence" refers to the total ordering of semantic versions. The semver specification
/// provides a detailed algorithm for making this determination. The most notable difference between this algorithm and
/// an equality comparison is that precedence does not consider build metadata identifiers; this behavior may be
/// observable via, e.g., the results of applying a sorting algorithm.
public struct SemanticVersion: Sendable, Hashable {
    /// The major version number.
    public var major: UInt

    /// The minor version number.
    public var minor: UInt

    /// The patch level number.
    public var patch: UInt

    /// The prerelease identifiers.
    public var prereleaseIdentifiers: [String]

    /// The build metadata identifiers.
    public var buildMetadataIdentifiers: [String]

    /// Create a semantic version from the individual components.
    ///
    /// - Important: It is considered **programmer error** to provide prerelease identifiers and/or build metadata
    ///   identifiers containing invalid characters (e.g. anything other than `[A-Za-z0-9-]`); doing so will trigger a
    ///   a fatal error.
    public init(
        _ major: UInt,
        _ minor: UInt,
        _ patch: UInt,
        prereleaseIdentifiers: [String] = [],
        buildMetadataIdentifiers: [String] = []
    ) {
        guard (prereleaseIdentifiers + buildMetadataIdentifiers).allSatisfy({ $0.allSatisfy(\.isValidInSemverIdentifier) }) else {
            fatalError("Invalid character found in semver identifier, must match [A-Za-z0-9-]")
        }
        guard prereleaseIdentifiers.allSatisfy({ $0.isValidSemverPrereleaseIdentifier }) else {
            fatalError("Invalid prerelease identifier found, must be alphanumeric, exactly 0, or not start with 0.")
        }
        self.major = major
        self.minor = minor
        self.patch = patch
        self.prereleaseIdentifiers = prereleaseIdentifiers
        self.buildMetadataIdentifiers = buildMetadataIdentifiers
    }

    /// Create a semantic version from a provided string, parsing it according to spec.
    ///
    /// - Returns: `nil` if the provided string is not a valid semantic version.
    ///
    /// - TODO: Possibly throw more specific validation errors? Would this be useful?
    ///
    /// - TODO: This code, while it does check validity better than what was here before, is ugly as heck. Clean it up.
    public init?(string: some StringProtocol) {
        guard string.allSatisfy(\.isASCII) else { return nil }
        
        var idx = string.startIndex
        func readNumber(usingIdx idx: inout String.Index) -> UInt? {
            let startIdx = idx
            idx = string[idx...].firstIndex(where: { !$0.isWholeNumber }) ?? string.endIndex
            return UInt(string[startIdx ..< idx])
        }
        func readIdent(usingIdx idx: inout String.Index) -> String? {
            let startIdx = idx
            idx = string[idx...].firstIndex(where: { !$0.isValidInSemverIdentifier }) ?? string.endIndex
            return idx > startIdx ? String(string[startIdx ..< idx]) : nil
        }
        
        guard let major = readNumber(usingIdx: &idx) else { return nil }
        guard idx < string.endIndex, string[idx] == "." else { return nil }
        string.formIndex(after: &idx)
        
        guard let minor = readNumber(usingIdx: &idx) else { return nil }
        guard idx < string.endIndex, string[idx] == "." else { return nil }
        string.formIndex(after: &idx)
        
        guard let patch = readNumber(usingIdx: &idx) else { return nil }
        
        var prereleaseIdentifiers: [String] = [], buildMetadataIdentifiers: [String] = []
        var seenPlus = false
        let identsStartIdx = idx
        while idx < string.endIndex {
            // String must be one of "-" (prerelease indicator), "+" (build metadata indicator), "." (identifier separator)
            switch string[idx] {
            case "+" where !seenPlus:
                seenPlus = true // saw a build metadata indicator for the first time, read identifiers into that now
            case "-" where idx == identsStartIdx:
                break // saw a prerelease indicator at start of idents parsing
            case "." where idx > identsStartIdx:
                break // saw identifier separator in valid position
            default:
                return nil // invalid separator
            }
            string.formIndex(after: &idx)
            guard let ident = readIdent(usingIdx: &idx) else { return nil }
            if seenPlus {
                buildMetadataIdentifiers.append(ident)
            } else {
                guard ident.isValidSemverPrereleaseIdentifier else {
                    return nil
                }
                prereleaseIdentifiers.append(ident)
            }
        }
        
        self.major = major
        self.minor = minor
        self.patch = patch
        self.prereleaseIdentifiers = prereleaseIdentifiers
        self.buildMetadataIdentifiers = buildMetadataIdentifiers
    }
}

extension SemanticVersion: Comparable {
    /// Implements the "precedence" ordering specified by the semver specification.
    public static func < (lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
        let lhsComponents = [lhs.major, lhs.minor, lhs.patch]
        let rhsComponents = [rhs.major, rhs.minor, rhs.patch]

        guard lhsComponents == rhsComponents else {
            return lhsComponents.lexicographicallyPrecedes(rhsComponents)
        }
        
        if lhs.prereleaseIdentifiers.isEmpty { return false } // Non-prerelease lhs >= potentially prerelease rhs
        if rhs.prereleaseIdentifiers.isEmpty { return true } // Prerelease lhs < non-prerelease rhs

        switch zip(lhs.prereleaseIdentifiers, rhs.prereleaseIdentifiers)
                .first(where: { $0 != $1 })
                .map({ ((Int($0) ?? $0) as Any, (Int($1) ?? $1) as Any) })
        {
            case let .some((lId as Int, rId as Int)):       return lId < rId
            case let .some((lId as String, rId as String)): return lId < rId
            case     .some((is Int, _)):                    return true // numeric prerelease identifier always < non-numeric
            case     .some:                                 return false // rhs > lhs
            case     .none:                                 break // all prerelease identifiers are equal
        }

        return lhs.prereleaseIdentifiers.count < rhs.prereleaseIdentifiers.count
    }
}

extension SemanticVersion: LosslessStringConvertible {
    /// An additional API guarantee is made by this type that this property will always yield a string
    /// which is correctly formatted as a valid semantic version number.
    public var description: String {
        """
        \(self.major).\
        \(self.minor).\
        \(self.patch)\
        \(self.prereleaseIdentifiers.joined(separator: ".", prefix: "-"))\
        \(self.buildMetadataIdentifiers.joined(separator: ".", prefix: "+"))
        """
    }
    
    // See `LosslessStringConvertible.init(_:)`. Identical semantics to ``init?(string:)``.
    public init?(_ description: String) {
        self.init(string: description)
    }
}

extension SemanticVersion: Codable {
    // See `Encodable.encode(to:)`.
    public func encode(to encoder: any Encoder) throws {
        try self.description.encode(to: encoder)
    }

    // See `Decodable.init(from:)`.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)

        guard let version = SemanticVersion(string: raw) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid semantic version: \(raw)")
        }
        self = version
    }
}

fileprivate extension Array<String> {
    /// Identical to ``joined(separator:)``, except that when the result is non-empty, the provided `prefix` will be
    /// prepended to it. This is a mildly silly solution to the issue of how best to implement "add a joiner character
    /// between one interpolation and the next, but only if the second one is non-empty".
    func joined(separator: String, prefix: String) -> String {
        self.isEmpty ? "" : "\(prefix)\(self.joined(separator: separator))"
    }
}

fileprivate extension Character {
    /// Valid characters in a semver identifier are defined by these BNF rules,
    /// taken directly from [the SemVer BNF grammar][semver2bnf]:
    ///
    /// [semver2bnf]: https://semver.org/spec/v2.0.0.html#backusnaur-form-grammar-for-valid-semver-versions
    ///
    /// ```bnf
    /// <identifier character> ::= <digit>
    ///                          | <non-digit>
    ///
    /// <non-digit> ::= <letter>
    ///               | "-"
    ///
    /// <digit> ::= "0"
    ///           | <positive digit>
    ///
    /// <positive digit> ::= "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9"
    ///
    /// <letter> ::= "A" | "B" | "C" | "D" | "E" | "F" | "G" | "H" | "I" | "J"
    ///            | "K" | "L" | "M" | "N" | "O" | "P" | "Q" | "R" | "S" | "T"
    ///            | "U" | "V" | "W" | "X" | "Y" | "Z" | "a" | "b" | "c" | "d"
    ///            | "e" | "f" | "g" | "h" | "i" | "j" | "k" | "l" | "m" | "n"
    ///            | "o" | "p" | "q" | "r" | "s" | "t" | "u" | "v" | "w" | "x"
    ///            | "y" | "z"
    /// ```
    var isValidInSemverIdentifier: Bool {
        self.isLetter || self.isWholeNumber || self == "-"
    }
}

fileprivate extension StringProtocol {
    /// A valid prerelease identifier must either:
    ///
    /// - Be exactly "0",
    /// - Not start with "0", or
    /// - Contain non-numeric characters
    ///
    /// 
    var isValidSemverPrereleaseIdentifier: Bool {
        self == "0" ||
        !self.starts(with: "0") ||
        self.contains { !$0.isWholeNumber }
    }
}
