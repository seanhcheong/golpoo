// swift-tools-version:5.9
import PackageDescription

// GolfSwingCore holds pose-extraction data models, swing-phase detection,
// metrics calculation, and reference-data lookup. It has no MediaPipe or
// AVFoundation dependency so the same logic can be ported to Android later.
let package = Package(
    name: "GolfSwingCore",
    // macOS is listed alongside iOS purely so `swift test` can run
    // directly from the command line on a Mac (no simulator, no Xcode
    // project needed) — this package has no UIKit/AVFoundation/MediaPipe
    // dependency, so it builds identically on either platform.
    platforms: [.iOS(.v16), .macOS(.v13)],
    products: [
        .library(name: "GolfSwingCore", targets: ["GolfSwingCore"])
    ],
    targets: [
        .target(
            name: "GolfSwingCore",
            resources: [.copy("ReferenceData/Resources/reference_ranges.json")]
        ),
        .testTarget(
            name: "GolfSwingCoreTests",
            dependencies: ["GolfSwingCore"]
        )
    ]
)
