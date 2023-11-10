extension String {
    /// `true` if the string is valid for use as a SemVer prerelease identifier
    ///
    /// A valid prerelease identifier must be nonempty, contain only ASCII letters, numbers, and `-`, and
    /// must obey **exactly one** of the following rules:
    ///
    /// - The identifier consists solely of a single zero digit (`0`),
    /// - The identifier consists solely of numeric digits, of which the first is **not** zero, **or**
    /// - The identifier contains at least one non-numeric character.
    ///
    /// See [the SemVer BNF grammar][semver2bnf] for the formal grammar specification..
    ///
    /// [semver2bnf]: https://semver.org/spec/v2.0.0.html#backusnaur-form-grammar-for-valid-semver-versions
    public var semver_isValidPrereleaseIdentifier: Bool {
        self.wholeMatch(of: /(?inP)0|([1-9]\d*)|([a-z\d-]*[a-z-][a-z\d-]*)/) != nil
    }
    
    /// `true` if the string is valid for use as a SemVer build metadata identifier
    ///
    /// A valid build metadata identifier must be nonempty and contain only ASCII letters, numbers, and `-`.
    /// It is not subject to the additional rules governing prerelease identifiers.
    ///
    /// See [the SemVer BNF grammar][semver2bnf] for the formal grammar specification.
    ///
    /// [semver2bnf]: https://semver.org/spec/v2.0.0.html#backusnaur-form-grammar-for-valid-semver-versions
    public var semver_isValidBuildMetadataIdentifier: Bool {
        self.wholeMatch(of: /(?inP)[a-z\d-]+/) != nil
    }
}
