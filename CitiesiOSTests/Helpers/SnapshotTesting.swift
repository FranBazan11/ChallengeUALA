//
//  SnapshotTesting.swift
//  CitiesiOSTests
//
//  Created by Juan Francisco Bazan Carrizo on 11/08/2026.
//

import XCTest
import SwiftUI

@MainActor
func makeSnapshot(
    of view: some View,
    configuration: SnapshotConfiguration,
    until isReady: () -> Bool = { true }
) async -> UIImage {
    let window = SnapshotWindow(configuration: configuration, root: UIHostingController(rootView: view))
    await window.settle(until: isReady)
    let snapshot = window.snapshot()
    window.dismantle()
    return snapshot
}

func assertSnapshot(
    _ snapshot: UIImage,
    named name: String,
    recording: Bool = false,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    let referenceURL = makeReferenceURL(named: name, file: file)

    guard let snapshotData = snapshot.pngData() else {
        return XCTFail("No se pudo generar el PNG del snapshot \(name)", file: file, line: line)
    }

    if recording {
        return record(snapshotData, at: referenceURL, file: file, line: line)
    }

    guard let referenceData = try? Data(contentsOf: referenceURL) else {
        return XCTFail(
            "No hay referencia grabada para \(name). Corré el test una vez con `recording: true`.",
            file: file,
            line: line
        )
    }

    guard referenceData == snapshotData else {
        let failedURL = referenceURL.deletingPathExtension().appendingPathExtension("FAILED.png")
        try? snapshotData.write(to: failedURL)
        return XCTFail(
            "El snapshot \(name) no coincide con su referencia.\nNuevo: \(failedURL.path)\nReferencia: \(referenceURL.path)",
            file: file,
            line: line
        )
    }
}

private func record(_ snapshotData: Data, at referenceURL: URL, file: StaticString, line: UInt) {
    do {
        try FileManager.default.createDirectory(
            at: referenceURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try snapshotData.write(to: referenceURL)
        XCTFail(
            "Referencia grabada en \(referenceURL.path). Sacá `recording: true` para que el test verifique.",
            file: file,
            line: line
        )
    } catch {
        XCTFail("No se pudo grabar la referencia: \(error)", file: file, line: line)
    }
}

private func makeReferenceURL(named name: String, file: StaticString) -> URL {
    URL(filePath: String(describing: file))
        .deletingLastPathComponent()
        .appending(path: "snapshots")
        .appending(path: "\(name).png")
}

private final class SnapshotWindow: UIWindow {
    private let configuration: SnapshotConfiguration

    init(configuration: SnapshotConfiguration, root: UIViewController) {
        self.configuration = configuration
        super.init(frame: CGRect(origin: .zero, size: configuration.size))
        traitOverrides.userInterfaceStyle = configuration.userInterfaceStyle
        traitOverrides.horizontalSizeClass = configuration.horizontalSizeClass
        traitOverrides.verticalSizeClass = configuration.verticalSizeClass
        traitOverrides.displayScale = configuration.displayScale
        rootViewController = root
        isHidden = false
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) no se usa")
    }

    override var safeAreaInsets: UIEdgeInsets { configuration.safeAreaInsets }

    func settle(until isReady: () -> Bool, attempts: Int = 100) async {
        layoutIfNeeded()

        var remainingAttempts = attempts
        while !isReady() && remainingAttempts > 0 {
            await Task.yield()
            layoutIfNeeded()
            remainingAttempts -= 1
        }
    }

    func dismantle() {
        rootViewController = nil
        isHidden = true
    }

    func snapshot() -> UIImage {
        layoutIfNeeded()

        let format = UIGraphicsImageRendererFormat()
        format.scale = configuration.displayScale

        return UIGraphicsImageRenderer(size: bounds.size, format: format).image { context in
            layer.render(in: context.cgContext)
        }
    }
}
