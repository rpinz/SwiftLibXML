// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
let deps = [Package.Dependency]()
#else
let deps: [Package.Dependency] = [.package(url: "https://github.com/rpinz/CLibXML2",
                                           .branch("master"))]
#endif

let package = Package(
    name: "SwiftLibXML",
    products: [
        .library(
            name: "SwiftLibXML",
            targets: ["SwiftLibXML"]),
    ],
    dependencies: deps,
    targets: [
        .target(
            name: "SwiftLibXML",
            dependencies: []),
        //.testTarget(name: ""SwiftLibXMLTests",
        //    dependencies: ["SwiftLibXML"]),
    ],
    swiftLanguageVersions: [4]
)
