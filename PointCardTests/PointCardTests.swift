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
    func persistenceRoundTripRestoresCurrentCardAndCompletedCards() throws {
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
            currentStamps: [
                StampHistoryEntry(
                    pointIndex: 0,
                    earnedAt: savedDate,
                    stamp: stamp
                )
            ],
            completedCards: [
                CompletedPointCard(
                    cardTitle: "がんばりカード",
                    studentName: "はなこ",
                    completedAt: savedDate,
                    stamps: (0..<10).map { index in
                        StampHistoryEntry(
                            pointIndex: index,
                            earnedAt: savedDate.addingTimeInterval(TimeInterval(index * 60)),
                            stamp: stamp
                        )
                    }
                )
            ]
        )

        try persistence.save(savedState)

        let loadedState = try persistence.load()

        #expect(loadedState == savedState)
    }

    @Test @MainActor
    func storePersistsCurrentCardImmediatelyWhenStampAdded() throws {
        let persistence = PointCardPersistence(fileURL: testFileURL())
        try persistence.save(PointCardState(points: 0))

        let store = PointCardStore(maxPoints: 10, persistence: persistence)

        try store.updateSelectedStampImage(
            from: sampleImageData(color: .systemBlue),
            assetIdentifier: "asset-1"
        )
        store.addPoint(at: 0)

        let reloadedState = try persistence.load()

        #expect(reloadedState.points == 1)
        #expect(reloadedState.currentStamps.count == 1)
        #expect(reloadedState.completedCards.isEmpty)
        #expect(reloadedState.currentStamps[0].stamp?.photoInfo.assetIdentifier == "asset-1")
    }

    @Test @MainActor
    func storeArchivesCompletedCardAfterTenStamps() throws {
        let persistence = PointCardPersistence(fileURL: testFileURL())
        try persistence.save(PointCardState(points: 0))

        let store = PointCardStore(maxPoints: 10, persistence: persistence)
        store.cardTitle = "おかいものカード"
        store.studentName = "ゆうた"

        try store.updateSelectedStampImage(
            from: sampleImageData(color: .systemPink),
            assetIdentifier: "asset-10"
        )

        for index in 0..<10 {
            store.addPoint(at: index)
        }

        let reloadedStore = PointCardStore(maxPoints: 10, persistence: persistence)

        #expect(reloadedStore.points == 10)
        #expect(reloadedStore.currentStamps.count == 10)
        #expect(reloadedStore.completedCards.count == 1)
        #expect(reloadedStore.completedCards[0].displayCardTitle == "おかいものカード")
        #expect(reloadedStore.completedCards[0].displayStudentName == "ゆうた")
        #expect(reloadedStore.completedCards[0].stamps.count == 10)
    }

    @Test @MainActor
    func removingLastPointRollsBackPersistedCurrentCardAndCompletionHistory() throws {
        let persistence = PointCardPersistence(fileURL: testFileURL())
        try persistence.save(PointCardState(points: 0))

        let store = PointCardStore(maxPoints: 10, persistence: persistence)

        try store.updateSelectedStampImage(
            from: sampleImageData(color: .systemTeal),
            assetIdentifier: "asset-remove"
        )

        for index in 0..<10 {
            store.addPoint(at: index)
        }

        store.removeLastPoint()

        let reloadedStore = PointCardStore(maxPoints: 10, persistence: persistence)

        #expect(reloadedStore.points == 9)
        #expect(reloadedStore.currentStamps.count == 9)
        #expect(reloadedStore.currentStamps.last?.pointIndex == 8)
        #expect(reloadedStore.completedCards.isEmpty)
    }

    @Test @MainActor
    func legacyStampHistoryDecodesIntoCurrentStamps() throws {
        let stamp = try #require(
            PersistedStampImage.make(
                from: sampleImageData(color: .systemGreen),
                assetIdentifier: "legacy-asset"
            )
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let legacyJSON = try encoder.encode(
            LegacyPointCardState(
                points: 1,
                cardTitle: "れがしー",
                studentName: "じろう",
                selectedStamp: stamp,
                stampHistory: [
                    StampHistoryEntry(
                        pointIndex: 0,
                        earnedAt: Date(timeIntervalSince1970: 1_760_100_000),
                        stamp: stamp
                    )
                ]
            )
        )

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let decoded = try decoder.decode(PointCardState.self, from: legacyJSON)

        #expect(decoded.points == 1)
        #expect(decoded.currentStamps.count == 1)
        #expect(decoded.completedCards.isEmpty)
        #expect(decoded.currentStamps[0].stamp?.photoInfo.assetIdentifier == "legacy-asset")
    }

}

private struct LegacyPointCardState: Codable {
    let points: Int
    let cardTitle: String
    let studentName: String
    let selectedStamp: PersistedStampImage?
    let stampHistory: [StampHistoryEntry]
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
