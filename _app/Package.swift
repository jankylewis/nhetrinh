// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "nhetrinh",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "Nhetrinh", targets: ["Nhetrinh"]),
        .executable(name: "nhetrinh-readback", targets: ["NhetrinhReadback"]),
    ],
    // One `_` entry per folder marks its most critical entry, so every target names its path.
    targets: [
        // The app: AppKit window, vertical tab sidebar, WKWebView tabs.
        .executableTarget(name: "Nhetrinh", dependencies: ["NhetrinhCore"], path: "_Sources/_Nhetrinh",
                          linkerSettings: [.linkedFramework("AppKit"), .linkedFramework("WebKit")]),
        // The readback tool: uses the installed app as its end user (Accessibility API).
        .executableTarget(name: "NhetrinhReadback", path: "_Sources/NhetrinhReadback",
                          linkerSettings: [.linkedFramework("AppKit"), .linkedFramework("ApplicationServices")]),
        // Pure logic, no AppKit/WebKit: address parsing, session model. Unit tested.
        .target(name: "NhetrinhCore", path: "_Sources/NhetrinhCore"),
        .testTarget(name: "NhetrinhCoreTests", dependencies: ["NhetrinhCore"], path: "Tests/_NhetrinhCoreTests"),
    ],
    swiftLanguageModes: [.v5]
)
