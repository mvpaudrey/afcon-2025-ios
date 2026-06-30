// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "TournamentKit",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "TournamentKit", targets: ["TournamentKit"])
    ],
    dependencies: [
        // AFCONClient lives in the AFCONApp package two directories up
        .package(path: "../../")
    ],
    targets: [
        .target(
            name: "TournamentKit",
            dependencies: [
                .product(name: "AFCONClient", package: "AFCONApp")
            ]
        ),
        .testTarget(
            name: "TournamentKitTests",
            dependencies: ["TournamentKit"]
        )
    ]
)
