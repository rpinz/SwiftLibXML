// swift-tools-version:5.0

import PackageDescription

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
let sysLibrary: Target = Target()
#else
let sysLibrary: Target = .systemLibrary(
                             name: "CLibXML2",
                             path: "Library/CLibXML2",
                             pkgConfig: "libxml-2.0",
                             providers: [
                                 .brew(["libxml2"]),
                                 .apt(["libxml2-dev"])
                             ])
#endif

let package = Package(
    name: "SwiftLibXML",
    products: [
        .library(
            name: "SwiftLibXML",
            targets: ["SwiftLibXML"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "SwiftLibXML",
            dependencies: ["CLibXML2"]),
        sysLibrary
    ],
    swiftLanguageVersions: [
        .v5
    ]
)
