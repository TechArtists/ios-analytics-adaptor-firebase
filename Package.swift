// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "TAAnalyticsFirebaseConsumer",
    platforms: [.iOS(.v13), .macOS(.v10_13)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "TAAnalyticsFirebaseConsumer",
            targets: ["TAAnalyticsFirebaseConsumer"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", .upToNextMajor(from: "10.0.0")),
        .package(url: "git@github.com:TechArtists/TAAnalytics.git", from: "2.0.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "TAAnalyticsFirebaseConsumer",
            dependencies: [
                .product(name:"FirebaseAnalytics", package: "firebase-ios-sdk"),
                //.product(name:"FirebaseCore", package: "firebase-ios-sdk"),
                .product(name:"FirebaseCrashlytics", package: "firebase-ios-sdk"),
                .product(name:"TAAnalytics", package:"TAAnalytics")
            ]
        ),
        .testTarget(
            name: "TAAnalyticsFirebaseConsumerTests",
            dependencies: ["TAAnalyticsFirebaseConsumer"]
        )
    ]
)
