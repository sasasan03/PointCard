//
//  PointCardStore.swift
//  PointCard
//
//  Created by Codex on 2026/04/14.
//

import Combine
import Foundation
import SwiftUI
import UIKit

@MainActor
final class PointCardStore: ObservableObject {
    @Published var points: Int {
        didSet { schedulePersistence() }
    }
    @Published var cardTitle: String {
        didSet { schedulePersistence() }
    }
    @Published var studentName: String {
        didSet { schedulePersistence() }
    }
    @Published private(set) var selectedStamp: PersistedStampImage? {
        didSet { schedulePersistence() }
    }
    @Published private(set) var stampHistory: [StampHistoryEntry] {
        didSet { schedulePersistence() }
    }

    let maxPoints: Int

    private let persistence: PointCardPersistence
    private var scheduledSave: DispatchWorkItem?
    private var isRestoringState = false

    init(maxPoints: Int = 10, persistence: PointCardPersistence? = nil) {
        self.maxPoints = maxPoints
        self.persistence = persistence ?? PointCardPersistence()

        let restoredState = Self.restoreState(from: self.persistence, maxPoints: maxPoints)
        points = restoredState.points
        cardTitle = restoredState.cardTitle
        studentName = restoredState.studentName
        selectedStamp = restoredState.selectedStamp
        stampHistory = restoredState.stampHistory
    }

    var displayCardTitle: String {
        let trimmedTitle = cardTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedTitle.isEmpty ? PointCardState.defaultCardTitle : trimmedTitle
    }

    var displayStudentName: String {
        let trimmedName = studentName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedName.isEmpty ? PointCardState.defaultStudentName : trimmedName
    }

    var selectedStampImage: UIImage? {
        selectedStamp?.uiImage
    }

    var currentStampPhotoInfo: StampPhotoInfo? {
        selectedStamp?.photoInfo
    }

    var earnedStampImages: [UIImage?] {
        let imagesByIndex = Dictionary(uniqueKeysWithValues: stampHistory.map { ($0.pointIndex, $0.stamp?.uiImage) })
        return (0..<points).map { imagesByIndex[$0] ?? nil }
    }

    var stampHistoryForDisplay: [StampHistoryEntry] {
        stampHistory.sorted { $0.earnedAt > $1.earnedAt }
    }

    func addPoint(at index: Int) {
        guard index == points, points < maxPoints else { return }

        let historyEntry = StampHistoryEntry(
            pointIndex: index,
            earnedAt: Date(),
            stamp: selectedStamp
        )

        stampHistory.append(historyEntry)
        stampHistory.sort { $0.pointIndex < $1.pointIndex }
        points += 1
    }

    func resetPoints() {
        points = 0
        stampHistory.removeAll()
    }

    func updateSelectedStampImage(from data: Data, assetIdentifier: String?) throws {
        guard let image = PersistedStampImage.make(from: data, assetIdentifier: assetIdentifier) else {
            throw PointCardStoreError.invalidStampData
        }

        selectedStamp = image
    }

    func clearSelectedStampImage() {
        selectedStamp = nil
    }

    func flushPersistence() {
        scheduledSave?.cancel()
        scheduledSave = nil
        persistNow()
    }

    private func schedulePersistence() {
        guard !isRestoringState else { return }

        scheduledSave?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            self?.persistNow()
        }

        scheduledSave = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: workItem)
    }

    private func persistNow() {
        guard !isRestoringState else { return }

        do {
            try persistence.save(
                PointCardState(
                    points: points,
                    cardTitle: cardTitle,
                    studentName: studentName,
                    selectedStamp: selectedStamp,
                    stampHistory: stampHistory
                )
            )
        } catch {
#if DEBUG
            print("Failed to persist point card state: \(error)")
#endif
        }
    }

    private static func restoreState(from persistence: PointCardPersistence, maxPoints: Int) -> PointCardState {
        do {
            return normalize(try persistence.load(), maxPoints: maxPoints)
        } catch {
#if DEBUG
            print("Failed to restore point card state: \(error)")
#endif
            return normalize(.defaultState, maxPoints: maxPoints)
        }
    }

    private static func normalize(_ state: PointCardState, maxPoints: Int) -> PointCardState {
        var historyByIndex: [Int: StampHistoryEntry] = [:]

        for entry in state.stampHistory where (0..<maxPoints).contains(entry.pointIndex) {
            guard let currentEntry = historyByIndex[entry.pointIndex] else {
                historyByIndex[entry.pointIndex] = entry
                continue
            }

            if currentEntry.earnedAt < entry.earnedAt {
                historyByIndex[entry.pointIndex] = entry
            }
        }

        let normalizedHistory = historyByIndex.values.sorted { $0.pointIndex < $1.pointIndex }
        let minimumPointsFromHistory = (normalizedHistory.last?.pointIndex ?? -1) + 1
        let normalizedPoints = min(max(max(state.points, minimumPointsFromHistory), 0), maxPoints)
        let filteredHistory = normalizedHistory.filter { $0.pointIndex < normalizedPoints }

        return PointCardState(
            points: normalizedPoints,
            cardTitle: state.cardTitle,
            studentName: state.studentName,
            selectedStamp: state.selectedStamp,
            stampHistory: filteredHistory
        )
    }
}

enum PointCardStoreError: LocalizedError {
    case invalidStampData

    var errorDescription: String? {
        switch self {
        case .invalidStampData:
            return "スタンプ画像の形式が不正です。"
        }
    }
}

struct PointCardState: Codable, Equatable {
    static let defaultCardTitle = "ポイントカード"
    static let defaultStudentName = "たろう"
    static let defaultState = PointCardState(points: 3)

    var points: Int = 3
    var cardTitle: String = PointCardState.defaultCardTitle
    var studentName: String = PointCardState.defaultStudentName
    var selectedStamp: PersistedStampImage?
    var stampHistory: [StampHistoryEntry] = []
}

struct StampHistoryEntry: Codable, Equatable, Identifiable {
    let id: UUID
    let pointIndex: Int
    let earnedAt: Date
    let stamp: PersistedStampImage?

    init(
        id: UUID = UUID(),
        pointIndex: Int,
        earnedAt: Date,
        stamp: PersistedStampImage?
    ) {
        self.id = id
        self.pointIndex = pointIndex
        self.earnedAt = earnedAt
        self.stamp = stamp
    }

    var pointLabel: String {
        "\(pointIndex + 1)こめ"
    }

    var earnedAtLabel: String {
        earnedAt.formatted(
            .dateTime
                .year()
                .month()
                .day()
                .hour()
                .minute()
        )
    }
}

struct PersistedStampImage: Codable, Equatable {
    let imageData: Data
    let photoInfo: StampPhotoInfo

    var uiImage: UIImage? {
        UIImage(data: imageData)
    }

    static func make(from data: Data, assetIdentifier: String?) -> PersistedStampImage? {
        guard let image = UIImage(data: data) else {
            return nil
        }

        let normalizedData = image.normalizedStampData() ?? data
        let persistedImage = UIImage(data: normalizedData) ?? image

        return PersistedStampImage(
            imageData: normalizedData,
            photoInfo: StampPhotoInfo(
                assetIdentifier: assetIdentifier,
                pixelWidth: persistedImage.pixelWidth,
                pixelHeight: persistedImage.pixelHeight,
                byteCount: normalizedData.count,
                selectedAt: Date()
            )
        )
    }
}

struct StampPhotoInfo: Codable, Equatable {
    let assetIdentifier: String?
    let pixelWidth: Int
    let pixelHeight: Int
    let byteCount: Int
    let selectedAt: Date

    var dimensionsLabel: String {
        "\(pixelWidth) x \(pixelHeight)"
    }

    var fileSizeLabel: String {
        ByteCountFormatter.string(fromByteCount: Int64(byteCount), countStyle: .file)
    }

    var selectedAtLabel: String {
        selectedAt.formatted(
            .dateTime
                .year()
                .month()
                .day()
                .hour()
                .minute()
        )
    }

    var assetIdentifierLabel: String {
        assetIdentifier ?? "未保存"
    }
}

struct PointCardPersistence {
    private let fileURL: URL

    init(fileURL: URL = Self.defaultFileURL()) {
        self.fileURL = fileURL
    }

    func load() throws -> PointCardState {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return .defaultState
        }

        let data = try Data(contentsOf: fileURL)
        return try Self.decoder.decode(PointCardState.self, from: data)
    }

    func save(_ state: PointCardState) throws {
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true,
            attributes: nil
        )

        let data = try Self.encoder.encode(state)
        try data.write(to: fileURL, options: .atomic)
    }

    private static func defaultFileURL() -> URL {
        let applicationSupportURL = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)

        return applicationSupportURL
            .appendingPathComponent("PointCard", isDirectory: true)
            .appendingPathComponent("point-card-state.json", isDirectory: false)
    }

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}

private extension UIImage {
    var pixelWidth: Int {
        Int(size.width * scale)
    }

    var pixelHeight: Int {
        Int(size.height * scale)
    }

    var hasAlphaChannel: Bool {
        guard let alphaInfo = cgImage?.alphaInfo else {
            return false
        }

        switch alphaInfo {
        case .first, .last, .premultipliedFirst, .premultipliedLast:
            return true
        default:
            return false
        }
    }

    func normalizedStampData(maxDimension: CGFloat = 512) -> Data? {
        let longestSide = max(size.width, size.height)
        let scaleRatio = longestSide > maxDimension ? maxDimension / longestSide : 1
        let targetSize = CGSize(
            width: max(size.width * scaleRatio, 1),
            height: max(size.height * scaleRatio, 1)
        )

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = false

        let renderedImage = UIGraphicsImageRenderer(size: targetSize, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: targetSize))
        }

        if renderedImage.hasAlphaChannel {
            return renderedImage.pngData()
        }

        return renderedImage.jpegData(compressionQuality: 0.85)
    }
}
