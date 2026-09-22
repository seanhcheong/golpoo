// swift-tools-version:5.9
import PackageDescription

// GolfSwingCore holds pose-extraction data models, swing-phase detection,
// metrics calculation, and reference-data lookup. It has no MediaPipe or
// AVFoundation dependency so the same logic can be ported to Android later.
let package = Package(
    name: "GolfSwingCore",
    platforms: [.iOS(.v16)],
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
