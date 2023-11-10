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
///
/// > Note: While numeric version components are represented by `Int` rather than `UInt` for convenience, it is always
///   guaranteed that outputs are `>= 0` and it is a precondition for all APIs that integer inputs also be thus.
public struct SemanticVersion: Sendable, Hashable {
    /// The major version number.
    public var major: Int

    /// The minor version number.
    public var minor: Int

    /// The patch level number.
    public var patch: Int

    /// The prerelease identifiers.
    public var prereleaseIdentifiers: [String]

    /// The build metadata identifiers.
    public var buildMetadataIdentifiers: [String]

    /// Create a semantic version from the individual components.
    /// 
    /// - Parameters:
    ///   - major: The major version number.
    ///   - minor: The minor version number.
    ///   - patch: The patch level number.
    ///   - prereleaseIdentifiers: A list of prerelease identifiers.
    ///   - buildMetadataIdentifiers: A list of build metadata identifiers.
    ///
    /// - Precondition: `major >= 0, minor >= 0, patch >= 0`
    /// - Precondition: All elements of `prereleaseIdentifiers` and `buildMetadataIdentifiers` must contain only the
    ///                 characters `[A-Za-z0-9-]`.
    /// - Precondition: Elements of `prereleaseIdentifiers` consisting of only numeric digits may not start with `0`.
    public init(
        _ major: Int,
        _ minor: Int,
        _ patch: Int,
        prereleaseIdentifiers: [String] = [],
        buildMetadataIdentifiers: [String] = []
    ) {
        precondition(major >= 0 && minor >= 0 && patch >= 0)
        precondition(prereleaseIdentifiers.allSatisfy(\.semver_isValidPrereleaseIdentifier))
        precondition(buildMetadataIdentifiers.allSatisfy(\.semver_isValidBuildMetadataIdentifier))
        
        self.major = major
        self.minor = minor
        self.patch = patch
        self.prereleaseIdentifiers = prereleaseIdentifiers
        self.buildMetadataIdentifiers = buildMetadataIdentifiers
    }

    /// Create a semantic version from a provided string, parsing it according to spec.
    /// 
    /// ## Discussion
    /// The regex used by this method is noticeably uglier than it needs to be, thanks to the engine not yet
    /// supporting `\g<>` subpattern references or `(?(DEFINE))` conditions. Without these limitations, the
    /// regex would look more like this (longer, but much more understandable):
    /// 
    /// ```regex
    /// #/
    ///   (?nPi)
    ///   (?(DEFINE)(?<numid>    0|([1-9]\d*)            )) # numeric identifier (may not start with 0 unless equal to 0)
    ///   (?(DEFINE)(?<alnumid>  [a-z\d-]*[a-z-][a-z\d-]*)) # alphanumeric identifier (must contain at least one non-digit)
    ///   (?(DEFINE)(?<prerelid> \g<numid>|\g<alnumid>   )) # prerelease identifier (numeric or alphanumeric)
    ///   (?(DEFINE)(?<buildid>  [a-z\d-]+               )) # build metadata identifier (any alphanumeric)
    ///
    ///      (?<major>\d+)                                  # major version number
    ///    \.(?<minor>\d+)                                  # minor version number
    ///    \.(?<patch>\d+)                                  # patch version number
    ///   (\-(?<prerelids>(\g<prerelid>\.)*\g<prerelid>))?  # list of zero or more prerelease identifiers
    ///   (\+(?<buildids> (\g<buildid> \.)*\g<buildid> ))?  # list of zero or more build metadata identifiers
    /// /#
    /// ```
    /// 
    /// - Parameter string: The string or substring to parse.
    /// - Returns: `nil` if the provided string is not a valid semantic version.
    public init?<S>(string: S)
        where S: StringProtocol, S.SubSequence == Substring
    {
        let pattern = #/
            (?nPi)
            (?<major>\d+)\.(?<minor>\d+)\.(?<patch>\d+)
            (\-(?<prerelids>((0|([1-9]\d*)|([a-z\d-]*[a-z-][a-z\d-]*))\.)*(0|([1-9]\d*)|([a-z\d-]*[a-z-][a-z\d-]*))))?
            (\+(?<buildids>(([a-z\d-]+)\.)*([a-z\d-]+)))?
        /#

        guard let match = string.wholeMatch(of: pattern) else {
            return nil
        }

        self.init(
            Int(match.output.major)!,
            Int(match.output.minor)!,
            Int(match.output.patch)!,
            prereleaseIdentifiers: match.output.prerelids?.split(separator: ".").map(String.init(_:)) ?? [],
            buildMetadataIdentifiers: match.output.buildids?.split(separator: ".").map(String.init(_:)) ?? []
        )
    }
}

extension SemanticVersion: Comparable {
    /// Implements the "precedence" ordering specified by the semver specification.
    public static func < (lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
        /// Unequal major versions - lower major version has lower precedence.
        guard lhs.major == rhs.major else {
            return lhs.major < rhs.major
        }
        
        /// Unequal minor versions - lower minor version has lower precedence.
        guard lhs.minor == rhs.minor else {
            return lhs.minor < rhs.minor
        }
        
        /// Unequal patch versions - lower patch version has lower precedence.
        guard lhs.patch == rhs.patch else {
            return lhs.patch < rhs.patch
        }
        
        /// If there are prerelease identifiers on only one of the versions, the one without any
        /// has higher precedence. If there are none on either, the versions are equal.
        switch (lhs.prereleaseIdentifiers.isEmpty, rhs.prereleaseIdentifiers.isEmpty) {
            case (true, true), (true, false):
                return false // equal or higher precedence
            case (false, true):
                return true // lower precedence
            case (false, false):
                break // further comparison needed
        }

        /// Find the first pair of mismatched prerelease identifiers, if such a pair exists.
        /// If it doesn't, precedence belongs to the version with more identifiers.
        guard let (lhsIdent, rhsIdent) = zip(lhs.prereleaseIdentifiers, rhs.prereleaseIdentifiers)
            .first(where: { $0 != $1 })
        else {
            return lhs.prereleaseIdentifiers.count < rhs.prereleaseIdentifiers.count
        }
        
        /// A numeric prerelease identifier always has lower precedence than an alphanumeric one.
        if lhsIdent.allSatisfy(\.isWholeNumber) {
            guard rhsIdent.allSatisfy(\.isWholeNumber) else {
                return true
            }
            
            /// For the sake of absolutely fanatical compliance with the spec, don't convert to Int
            /// to compare numeric values, as this will fail for extremely large numbers. If the
            /// values have different lengths, the shorter one has lower precedence; otherwise, a
            /// lexicographic comparison will yield the correct result.
            guard lhsIdent.count == rhsIdent.count else {
                return lhsIdent.count < rhsIdent.count
            }
        } else {
            guard !rhsIdent.allSatisfy(\.isWholeNumber) else {
                return false
            }
        }

        /// Alphanumeric identifiers and equal-length numeric identifiers are compared lexicographically.
        return lhsIdent.lexicographicallyPrecedes(rhsIdent)
    }
}

extension SemanticVersion: LosslessStringConvertible {
    // See `LosslessStringConvertible.init(_:)`.
    public init?(_ description: String) {
        self.init(string: description)
    }
    
    // See `CustomStringConvertible.description`.
    public var description: String {
        """
        \(self.major).\
        \(self.minor).\
        \(self.patch)\
        \(self.prereleaseIdentifiers.isEmpty ? "" : "-")\
        \(self.prereleaseIdentifiers.joined(separator: "."))\
        \(self.buildMetadataIdentifiers.isEmpty ? "" : "+")\
        \(self.buildMetadataIdentifiers.joined(separator: "."))
        """
    }
}

extension SemanticVersion: CustomDebugStringConvertible {
    // See `CustomDebugStringConvertible.debugDescripton`.
    public var debugDescription: String {
        """
        Version:{\
        Major: \(self.major) \
        Minor: \(self.minor) \
        Patch: \(self.patch) \
        Prerelease identifiers: [\(self.prereleaseIdentifiers.joined(separator: ", "))] \
        Build metadata identifiers: [\(self.buildMetadataIdentifiers.joined(separator: ", "))]\
        }
        """
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
