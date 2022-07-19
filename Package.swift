// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "senseye-ios-sdk",
    platforms: [.iOS(.v11)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "senseye-ios-sdk",
            targets: ["senseye-ios-sdk"]),
    ],
    dependencies: [
        .package(name: "Amplify", url: "https://github.com/aws-amplify/amplify-ios", from: "1.17.0"),
        .package(name: "Alamofire", url: "https://github.com/Alamofire/Alamofire.git", .upToNextMajor(from: "5.5.0")),
        .package(name: "CocoaLumberjack", url: "https://github.com/CocoaLumberjack/CocoaLumberjack.git", from: "3.7.4"),
        .package(name: "Firebase", url: "https://github.com/firebase/firebase-ios-sdk.git", .upToNextMajor(from: "8.10.0")),
        .package(name: "SwiftyJSON", url: "https://github.com/SwiftyJSON/SwiftyJSON.git", from: "4.0.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "senseye-ios-sdk",
            dependencies: [
                .product(name: "Amplify", package: "Amplify", condition: nil),
                .product(name: "AWSPluginsCore", package: "Amplify", condition: nil),
                .product(name: "AWSDataStorePlugin", package: "Amplify", condition: nil),
                .product(name: "AWSS3StoragePlugin", package: "Amplify", condition: nil),
                .product(name: "AWSCognitoAuthPlugin", package: "Amplify", condition: nil),
                .product(name: "Alamofire", package: "Alamofire", condition: nil),
                .product(name: "CocoaLumberjackSwift", package: "CocoaLumberjack", condition: nil),
                .product(name: "FirebaseCrashlytics", package: "Firebase", condition: nil),
                .product(name: "SwiftyJSON", package: "SwiftyJSON", condition: nil)
            ],
            resources: [
                .process("Resources/amplifyconfiguration.json"),
                .process("Resources/awsconfiguration.json"),
                .process("Resources/GoogleService-Info.plist")
            ]),
        .testTarget(
            name: "senseye-ios-sdkTests",
            dependencies: ["senseye-ios-sdk"]),
    ]
)
