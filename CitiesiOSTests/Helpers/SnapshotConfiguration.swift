//
//  SnapshotConfiguration.swift
//  CitiesiOSTests
//
//  Created by Juan Francisco Bazan Carrizo on 11/08/2026.
//

import UIKit

struct SnapshotConfiguration {
    let size: CGSize
    let safeAreaInsets: UIEdgeInsets
    let userInterfaceStyle: UIUserInterfaceStyle
    let horizontalSizeClass: UIUserInterfaceSizeClass
    let verticalSizeClass: UIUserInterfaceSizeClass
    let displayScale: CGFloat

    static let iPhone17ProPortrait = SnapshotConfiguration(
        size: CGSize(width: 402, height: 874),
        safeAreaInsets: UIEdgeInsets(top: 62, left: 0, bottom: 34, right: 0),
        userInterfaceStyle: .light,
        horizontalSizeClass: .compact,
        verticalSizeClass: .regular,
        displayScale: 3
    )

    static let iPhone17ProLandscape = SnapshotConfiguration(
        size: CGSize(width: 874, height: 402),
        safeAreaInsets: UIEdgeInsets(top: 0, left: 62, bottom: 21, right: 62),
        userInterfaceStyle: .light,
        horizontalSizeClass: .compact,
        verticalSizeClass: .compact,
        displayScale: 3
    )
}
