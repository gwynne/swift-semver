# SwiftSemver

<p align="center">
<a href="LICENSE"><img src="https://design.vapor.codes/images/mitlicense.svg" alt="MIT License"></a>
<a href="https://github.com/gwynne/swift-semver/actions/workflows/test.yml"><img src="https://img.shields.io/github/actions/workflow/status/gwynne/swift-semver/test.yml?event=push&amp;style=plastic&amp;logo=github&amp;label=tests&amp;logoColor=%23ccc" alt="Continuous Integration"></a>
<a href="https://codecov.io/github/gwynne/swift-semver"><img src="https://img.shields.io/codecov/c/github/gwynne/swift-semver?style=plastic&amp;logo=codecov&amp;label=coverage&amp;token=GB8LS6ELKA"></a>
<a href="https://swift.org"><img src="https://img.shields.io/badge/swift-5.8%2b-white?style=plastic&amp;logoColor=%23f07158&amp;labelColor=gray&amp;color=%23f07158&logo=data%3Aimage%2Fsvg%2Bxml%3Bbase64%2CPHN2ZyB2aWV3Qm94PSIwIDAgMjQgMjQiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI%2BPHBhdGggZD0iTSA2LDI0YyAtMywwIC02LC0zIC02LC02diAtMTJjIDAsLTMgMywtNiA2LC02aCAxMmMgMywwIDYsMyA2LDZ2IDEyYyAwLDMgLTMsNiAtNiw2eiIgZmlsbD0iI2YwNzE1OCIvPjxwYXRoIGQ9Ik0gMTMuNTUsMy40YyA0LjE1LDIuMzkgNi4zLDcuNTMgNS4zLDExLjUgMS45NSwyLjggMS42NSw1LjE3IDEuMzgsNC42NiAtMS4yLC0yLjMzIC0zLjMzLC0xLjQyIC00LjM3LC0wLjcxIC0zLjksMS44MSAtMTAuMTYsMC4xOCAtMTMuNDYsLTUuMDMgMi45OCwyLjIgNy4yLDMuMTUgMTAuMywxLjI1IC00LjYsLTMuNTcgLTguNSwtOS4xNyAtOC41LC05LjI4IDIuMjgsMi4xNSA1Ljk4LDQuODQgNy4zLDUuNzEgLTIuOCwtMy4xIC01LjMsLTYuNjUgLTUuMiwtNi42NSAyLjczLDIuNjggNS42Niw1LjIgOC45LDcuMiAwLjM3LC0wLjc5IDEuNDMsLTQuNDcgLTEuNjUsLTguNjV6IiBmaWxsPSJ3aGl0ZSIvPjwvc3ZnPg%3D%3D" alt="Swift 5.8+"></a>
</p>

A small library which provides a `SemanticVersion` type, containing a complete implementation of the grammar (both parsing and serialization) and precedence behaviors described by [Semantic Versioning 2.0.0](https://semver.org/spec/v2.0.0.html).
