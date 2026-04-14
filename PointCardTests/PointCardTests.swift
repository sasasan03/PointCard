//
//  PointCardTests.swift
//  PointCardTests
//
//  Created by sako0602 on 2026/04/11.
//

import Foundation
import Testing
import UIKit
@testable import PointCard

struct PointCardTests {

    @Test @MainActor
    func persistenceRoundTripRestoresCardAndHistory() throws {
        let persistence = PointCardPersistence(fileURL: testFileURL())
        let savedDate = Date(timeIntervalSince1970: 1_760_000_000)
        let stamp = try #require(
            PersistedStampImage.make(
                from: sampleImageData(color: .systemOrange),
                assetIdentifier: "asset-sample"
            )
        )
        let savedState = PointCardState(
            points: 2,
            cardTitle: "おてつだいカード",
            studentName: "はなこ",
            selectedStamp: stamp,
            stampHistory: [
                StampHistoryEntry(
                    pointIndex: 0,
                    earnedAt: savedDate,
                    stamp: stamp
                )
            ]
        )

        try persistence.save(savedState)

        let loadedState = try persistence.load()

        #expect(loadedState == savedState)
    }

    @Test @MainActor
    func storePersistsStampHistorySnapshots() throws {
        let persistence = PointCardPersistence(fileURL: testFileURL())
        try persistence.save(PointCardState(points: 0))

        let store = PointCardStore(maxPoints: 10, persistence: persistence)

        try store.updateSelectedStampImage(
            from: sampleImageData(color: .systemBlue),
            assetIdentifier: "asset-1"
        )
        store.addPoint(at: 0)

        try store.updateSelectedStampImage(
            from: sampleImageData(color: .systemPink),
            assetIdentifier: "asset-2"
        )
        store.addPoint(at: 1)
        store.flushPersistence()

        let reloadedStore = PointCardStore(maxPoints: 10, persistence: persistence)

        #expect(reloadedStore.points == 2)
        #expect(reloadedStore.stampHistory.count == 2)
        #expect(reloadedStore.stampHistory[0].stamp?.photoInfo.assetIdentifier == "asset-1")
        #expect(reloadedStore.stampHistory[1].stamp?.photoInfo.assetIdentifier == "asset-2")
        #expect(reloadedStore.currentStampPhotoInfo?.assetIdentifier == "asset-2")
    }

}

private extension PointCardTests {
    func testFileURL() -> URL {
        let directoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)

        return directoryURL.appendingPathComponent("point-card-state.json", isDirectory: false)
    }

    func sampleImageData(color: UIColor) -> Data {
        let size = CGSize(width: 120, height: 120)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }

        return image.pngData() ?? Data()
    }
}
