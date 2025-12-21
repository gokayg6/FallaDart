// swift-tools-version:6.2
// Package.swift
// Falla - iOS 26 Fortune Telling App
// Swift Package Manager configuration

import PackageDescription

let package = Package(
    name: "Falla",
    platforms: [
        .iOS(.v26)
    ],
    products: [
        .library(
            name: "Falla",
            targets: ["Falla"]
        ),
    ],
    dependencies: [
        // Firebase iOS SDK
        .package(
            url: "https://github.com/firebase/firebase-ios-sdk.git",
            from: "11.0.0"
        ),
    ],
    targets: [
        .target(
            name: "Falla",
            dependencies: [
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseStorage", package: "firebase-ios-sdk"),
                .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk"),
                .product(name: "FirebaseMessaging", package: "firebase-ios-sdk"),
            ],
            path: "Falla"
        ),
        .testTarget(
            name: "FallaTests",
            dependencies: ["Falla"],
            path: "FallaTests"
        ),
    ]
)
