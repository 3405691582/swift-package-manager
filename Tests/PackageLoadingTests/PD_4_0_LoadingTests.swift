/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2017 - 2020 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See http://swift.org/LICENSE.txt for license information
 See http://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import Basics
import PackageLoading
import PackageModel
import SPMTestSupport
import TSCBasic
import TSCUtility
import XCTest

class PackageDescription4_0LoadingTests: PackageDescriptionLoadingTests {
    override var toolsVersion: ToolsVersion {
        .v4
    }

    func testTrivial() throws {
        let manifest = """
            import PackageDescription
            let package = Package(
                name: "Trivial"
            )
            """

        loadManifest(manifest) { manifest in
            XCTAssertEqual(manifest.name, "Trivial")
            XCTAssertEqual(manifest.toolsVersion, .v4)
            XCTAssertEqual(manifest.targets, [])
            XCTAssertEqual(manifest.dependencies, [])
        }
    }

    func testTargetDependencies() throws {
        let manifest = """
            import PackageDescription
            let package = Package(
                name: "Trivial",
                targets: [
                    .target(name: "foo", dependencies: [
                        "dep1",
                        .target(name: "dep2"),
                        .product(name: "dep3", package: "Pkg"),
                        .product(name: "dep4"),
                    ]),
                    .testTarget(name: "bar", dependencies: [
                        "foo",
                    ])
                ]
            )
            """

        loadManifest(manifest) { manifest in
            XCTAssertEqual(manifest.name, "Trivial")
            let foo = manifest.targetMap["foo"]!
            XCTAssertEqual(foo.name, "foo")
            XCTAssertFalse(foo.isTest)

            let expectedDependencies: [TargetDescription.Dependency]
            expectedDependencies = [
                "dep1",
                .target(name: "dep2"),
                .product(name: "dep3", package: "Pkg"),
                .product(name: "dep4"),
            ]
            XCTAssertEqual(foo.dependencies, expectedDependencies)

            let bar = manifest.targetMap["bar"]!
            XCTAssertEqual(bar.name, "bar")
            XCTAssertTrue(bar.isTest)
            XCTAssertEqual(bar.dependencies, ["foo"])
        }
    }

    func testCompatibleSwiftVersions() throws {
        var manifest = """
            import PackageDescription
            let package = Package(
               name: "Foo",
               swiftLanguageVersions: [3, 4]
            )
            """
        loadManifest(manifest) { manifest in
            XCTAssertEqual(manifest.swiftLanguageVersions?.map({$0.rawValue}), ["3", "4"])
        }

        manifest = """
            import PackageDescription
            let package = Package(
               name: "Foo",
               swiftLanguageVersions: []
            )
            """
        loadManifest(manifest) { manifest in
            XCTAssertEqual(manifest.swiftLanguageVersions, [])
        }

        manifest = """
            import PackageDescription
            let package = Package(
               name: "Foo")
            """
        loadManifest(manifest) { manifest in
            XCTAssertEqual(manifest.swiftLanguageVersions, nil)
        }
    }

    func testPackageDependencies() throws {
        let manifest = """
            import PackageDescription
            let package = Package(
               name: "Foo",
               dependencies: [
                   .package(url: "/foo1", from: "1.0.0"),
                   .package(url: "/foo2", .upToNextMajor(from: "1.0.0")),
                   .package(url: "/foo3", .upToNextMinor(from: "1.0.0")),
                   .package(url: "/foo4", .exact("1.0.0")),
                   .package(url: "/foo5", .branch("main")),
                   .package(url: "/foo6", .revision("58e9de4e7b79e67c72a46e164158e3542e570ab6")),
               ]
            )
            """
        loadManifest(manifest, toolsVersion: ToolsVersion(string: "5.5")) { manifest in
        let deps = Dictionary(uniqueKeysWithValues: manifest.dependencies.map{ ($0.identity.description, $0) })
            XCTAssertEqual(deps["foo1"], .localSourceControl(path: .init("/foo1"), requirement: .upToNextMajor(from: "1.0.0")))
            XCTAssertEqual(deps["foo2"], .localSourceControl(path: .init("/foo2"), requirement: .upToNextMajor(from: "1.0.0")))
            XCTAssertEqual(deps["foo3"], .localSourceControl(path: .init("/foo3"), requirement: .upToNextMinor(from: "1.0.0")))
            XCTAssertEqual(deps["foo4"], .localSourceControl(path: .init("/foo4"), requirement: .exact("1.0.0")))
            XCTAssertEqual(deps["foo5"], .localSourceControl(path: .init("/foo5"), requirement: .branch("main")))
            XCTAssertEqual(deps["foo6"], .localSourceControl(path: .init("/foo6"), requirement: .revision("58e9de4e7b79e67c72a46e164158e3542e570ab6")))
        }
    }

    func testProducts() throws {
        let manifest = """
            import PackageDescription
            let package = Package(
                name: "Foo",
                products: [
                    .executable(name: "tool", targets: ["tool"]),
                    .library(name: "Foo", targets: ["Foo"]),
                    .library(name: "FooDy", type: .dynamic, targets: ["Foo"]),
                ],
                targets: [
                    .target(name: "Foo"),
                    .target(name: "tool"),
                ]
            )
            """
        loadManifest(manifest) { manifest in
            let products = Dictionary(uniqueKeysWithValues: manifest.products.map{ ($0.name, $0) })
            // Check tool.
            let tool = products["tool"]!
            XCTAssertEqual(tool.name, "tool")
            XCTAssertEqual(tool.targets, ["tool"])
            XCTAssertEqual(tool.type, .executable)
            // Check Foo.
            let foo = products["Foo"]!
            XCTAssertEqual(foo.name, "Foo")
            XCTAssertEqual(foo.type, .library(.automatic))
            XCTAssertEqual(foo.targets, ["Foo"])
            // Check FooDy.
            let fooDy = products["FooDy"]!
            XCTAssertEqual(fooDy.name, "FooDy")
            XCTAssertEqual(fooDy.type, .library(.dynamic))
            XCTAssertEqual(fooDy.targets, ["Foo"])
        }
    }

    func testSystemPackage() throws {
        let manifest = """
            import PackageDescription
            let package = Package(
               name: "Copenssl",
               pkgConfig: "openssl",
               providers: [
                   .brew(["openssl"]),
                   .apt(["openssl", "libssl-dev"]),
               ]
            )
            """
        loadManifest(manifest) { manifest in
            XCTAssertEqual(manifest.name, "Copenssl")
            XCTAssertEqual(manifest.pkgConfig, "openssl")
            XCTAssertEqual(manifest.providers, [
                .brew(["openssl"]),
                .apt(["openssl", "libssl-dev"]),
            ])
        }
    }

    func testCTarget() throws {
        let manifest = """
            import PackageDescription
            let package = Package(
               name: "libyaml",
               targets: [
                   .target(
                       name: "Foo",
                       publicHeadersPath: "inc"),
                   .target(
                   name: "Bar"),
               ]
            )
            """
        loadManifest(manifest) { manifest in
            let foo = manifest.targetMap["Foo"]!
            XCTAssertEqual(foo.publicHeadersPath, "inc")

            let bar = manifest.targetMap["Bar"]!
            XCTAssertEqual(bar.publicHeadersPath, nil)
        }
    }

    func testTargetProperties() throws {
        let manifest = """
            import PackageDescription
            let package = Package(
               name: "libyaml",
               targets: [
                   .target(
                       name: "Foo",
                       path: "foo/z",
                       exclude: ["bar"],
                       sources: ["bar.swift"],
                       publicHeadersPath: "inc"),
                   .target(
                   name: "Bar"),
               ]
            )
            """
        loadManifest(manifest) { manifest in
            let foo = manifest.targetMap["Foo"]!
            XCTAssertEqual(foo.publicHeadersPath, "inc")
            XCTAssertEqual(foo.path, "foo/z")
            XCTAssertEqual(foo.exclude, ["bar"])
            XCTAssertEqual(foo.sources ?? [], ["bar.swift"])

            let bar = manifest.targetMap["Bar"]!
            XCTAssertEqual(bar.publicHeadersPath, nil)
            XCTAssertEqual(bar.path, nil)
            XCTAssertEqual(bar.exclude, [])
            XCTAssert(bar.sources == nil)
        }
    }

    func testUnavailableAPIs() throws {
        let manifest = """
            import PackageDescription
            let package = Package(
               name: "Foo",
               dependencies: [
                   .package(url: "/foo1", version: "1.0.0"),
                   .package(url: "/foo2", branch: "master"),
                   .package(url: "/foo3", revision: "rev"),
                   .package(url: "/foo4", range: "1.0.0"..<"1.5.0"),
               ]
            )
            """
        do {
            try loadManifestThrowing(manifest) { manifest in
                XCTFail("this package should not load successfully")
            }
            XCTFail("this package should not load successfully")
        } catch ManifestParseError.invalidManifestFormat(let error, _) {
            XCTAssert(error.contains("error: 'package(url:version:)' is unavailable: use package(url:exact:) instead\n"), "\(error)")
            XCTAssert(error.contains("error: 'package(url:range:)' is unavailable: use package(url:_:) instead\n"), "\(error)")
        }
    }

    func testLanguageStandards() throws {
        let stream = BufferedOutputByteStream()
        stream <<< """
            import PackageDescription
            let package = Package(
                name: "testPackage",
                targets: [
                    .target(name: "Foo"),
                ],
                cLanguageStandard: .iso9899_199409,
                cxxLanguageStandard: .gnucxx14
            )
        """
        loadManifest(stream.bytes) { manifest in
            XCTAssertEqual(manifest.name, "testPackage")
            XCTAssertEqual(manifest.cLanguageStandard, "iso9899:199409")
            XCTAssertEqual(manifest.cxxLanguageStandard, "gnu++14")
        }
    }

    func testManifestWithWarnings() throws {
        let fs = InMemoryFileSystem()
        let manifestPath = AbsolutePath.root.appending(component: Manifest.filename)
        let stream = BufferedOutputByteStream()

        stream <<< """
            import PackageDescription
            func foo() {
                let a = 5
            }
            let package = Package(
                name: "Trivial"
            )
            """

        try fs.writeFileContents(manifestPath, bytes: stream.bytes)

        let observability = ObservabilitySystem.makeForTesting()
        let manifest = try manifestLoader.load(
            at: .root,
            packageKind: .root(.root),
            toolsVersion: .v4,
            fileSystem: fs,
            diagnostics: observability.topScope.makeDiagnosticsEngine()
        )

        XCTAssertEqual(manifest.name, "Trivial")
        XCTAssertEqual(manifest.toolsVersion, .v4)
        XCTAssertEqual(manifest.targets, [])
        XCTAssertEqual(manifest.dependencies, [])

        testDiagnostics(observability.diagnostics) { result in
            result.check(diagnostic: .contains("initialization of immutable value 'a' was never used"), severity: .warning)
        }
    }

    func testDuplicateTargets() throws {
        let manifest = """
            import PackageDescription

            let package = Package(
                name: "Foo",
                targets: [
                    .target(name: "A"),
                    .target(name: "B"),
                    .target(name: "A"),
                    .target(name: "B"),
                ]
            )
            """

        XCTAssertManifestLoadThrows(manifest) { _, diagnotics in
            diagnotics.checkUnordered(diagnostic: "duplicate target named 'A'", severity: .error)
            diagnotics.checkUnordered(diagnostic: "duplicate target named 'B'", severity: .error)
        }
    }

    func testEmptyProductTargets() throws {
        let manifest = """
            import PackageDescription

            let package = Package(
                name: "Foo",
                products: [
                    .library(name: "Product", targets: []),
                ],
                targets: [
                    .target(name: "Target"),
                ]
            )
            """

        XCTAssertManifestLoadThrows(manifest) { _, diagnostics in
            diagnostics.check(diagnostic: "product 'Product' doesn't reference any targets", severity: .error)
        }
    }

    func testProductTargetNotFound() throws {
        let manifest = """
            import PackageDescription

            let package = Package(
                name: "Foo",
                products: [
                    .library(name: "Product", targets: ["A", "B"]),
                ],
                targets: [
                    .target(name: "A"),
                ]
            )
            """

        XCTAssertManifestLoadThrows(manifest) { _, diagnostics in
            diagnostics.check(diagnostic: "target 'B' referenced in product 'Product' could not be found; valid targets are: 'A'", severity: .error)
        }
    }
}
