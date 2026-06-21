// swift-tools-version: 5.9
//
//  Package.swift
//  DynamicCollectionView
//
//  데이터(Section / Cell / ReusableView)에 따라 동적으로 구성되는
//  UIKit CompositionalLayout 기반 CollectionView 와, 이를 감싸는 SwiftUI 래퍼를
//  3rd-party 의존성 없이 제공하는 라이브러리입니다.
//

import PackageDescription

let package = Package(
    name: "DynamicCollectionView",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(
            name: "DynamicCollectionView",
            targets: ["DynamicCollectionView"]
        )
    ],
    targets: [
        .target(
            name: "DynamicCollectionView"
        )
    ]
)
