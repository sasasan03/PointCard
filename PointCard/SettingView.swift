//
//  SettingView.swift
//  PointCard
//
//  Created by sako0602 on 2026/04/12.
//

import PhotosUI
import SwiftUI
import UIKit

struct SettingView: View {
    @Binding var cardTitle: String
    @Binding var studentName: String
    @Binding var selectedStampItem: PhotosPickerItem?
    let stampImage: UIImage?
    let currentStampPhotoInfo: StampPhotoInfo?
    let stampHistory: [StampHistoryEntry]
    @State private var showResetPointsAlert = false
    let isLoadingStampImage: Bool
    let onResetPoints: () -> Void
    let onClearStampImage: () -> Void

    var body: some View {
        Form {
            Section("ポイントカード") {
                TextField("ポイントカード", text: $cardTitle)
                    .font(.system(size: 17, weight: .medium, design: .rounded))
            }

            Section("なまえ") {
                TextField("たろう", text: $studentName)
                    .font(.system(size: 17, weight: .medium, design: .rounded))
            }

            Section("スタンプ画像") {
                VStack(spacing: 16) {
                    StampSettingPreview(
                        stampImage: stampImage,
                        isLoading: isLoadingStampImage
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)

                    Text("スタンプに使う画像を写真アプリから選べます。")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(PointCardPalette.mutedForeground)
                        .frame(maxWidth: .infinity, alignment: .center)
                }

                PhotosPicker(selection: $selectedStampItem, matching: .images) {
                    Label("写真から選ぶ", systemImage: "photo.on.rectangle.angled")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                }

                if let currentStampPhotoInfo {
                    LabeledContent("保存サイズ", value: currentStampPhotoInfo.dimensionsLabel)
                    LabeledContent("容量", value: currentStampPhotoInfo.fileSizeLabel)
                    LabeledContent("選択日時", value: currentStampPhotoInfo.selectedAtLabel)

                    if let assetIdentifier = currentStampPhotoInfo.assetIdentifier {
                        LabeledContent("写真ID") {
                            Text(assetIdentifier)
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                                .foregroundStyle(PointCardPalette.mutedForeground)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                    }
                }

                if stampImage != nil {
                    Button("画像をリセット", role: .destructive) {
                        selectedStampItem = nil
                        onClearStampImage()
                    }
                }
            }

            Section("スタンプ履歴") {
                if stampHistory.isEmpty {
                    Text("まだスタンプ履歴はありません。")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(PointCardPalette.mutedForeground)
                } else {
                    ForEach(stampHistory) { entry in
                        StampHistoryRow(entry: entry)
                    }
                }
            }

            Section("ポイント") {
                Button("ポイントをリセット", role: .destructive) {
                    showResetPointsAlert = true
                }
                .font(.system(size: 17, weight: .semibold, design: .rounded))
            }
        }
        .navigationTitle("設定")
        .navigationBarTitleDisplayMode(.inline)
        .alert("ポイントをリセットしますか？", isPresented: $showResetPointsAlert) {
            Button("キャンセル", role: .cancel) {}
            Button("リセット", role: .destructive) {
                onResetPoints()
            }
        } message: {
            Text("今までのポイントがすべて消えます。")
        }
    }
}

private struct StampHistoryRow: View {
    let entry: StampHistoryEntry

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            StampHistoryThumbnail(image: entry.stamp?.uiImage)

            VStack(alignment: .leading, spacing: 6) {
                Text(entry.pointLabel)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(PointCardPalette.foreground)

                Text("押した日時: \(entry.earnedAtLabel)")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(PointCardPalette.mutedForeground)

                if let photoInfo = entry.stamp?.photoInfo {
                    Text("画像: \(photoInfo.dimensionsLabel) / \(photoInfo.fileSizeLabel)")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(PointCardPalette.mutedForeground)

                    Text("写真選択: \(photoInfo.selectedAtLabel)")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(PointCardPalette.mutedForeground)
                } else {
                    Text("画像なしでスタンプしました。")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(PointCardPalette.mutedForeground)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

private struct StampHistoryThumbnail: View {
    let image: UIImage?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(PointCardPalette.muted)
                .frame(width: 58, height: 58)

            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 58, height: 58)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            } else {
                Image(systemName: "star.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(PointCardPalette.accent)
            }
        }
    }
}

private struct StampSettingPreview: View {
    let stampImage: UIImage?
    let isLoading: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(PointCardPalette.card)
                .frame(width: 124, height: 124)
                .shadow(color: .black.opacity(0.12), radius: 18, x: 0, y: 12)

            if let stampImage {
                Image(uiImage: stampImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 112, height: 112)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(PointCardPalette.muted)
                    .frame(width: 112, height: 112)
                    .overlay {
                        Image(systemName: "photo")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundStyle(PointCardPalette.primary)
                    }
            }

            if isLoading {
                ProgressView()
                    .controlSize(.large)
                    .tint(PointCardPalette.primary)
            }
        }
        .overlay(
            Circle()
                .stroke(PointCardPalette.secondary, lineWidth: 4)
        )
        .accessibilityLabel("スタンプ画像を設定")
    }
}

private struct SettingViewPreviewContainer: View {
    @State private var cardTitle = "ポイントカード"
    @State private var studentName = "たろう"
    @State private var selectedStampItem: PhotosPickerItem?
    @State private var stampImage: UIImage?
    @State private var currentStampPhotoInfo: StampPhotoInfo?
    @State private var stampHistory: [StampHistoryEntry]

    let isLoadingStampImage: Bool

    init(stampImage: UIImage?, isLoadingStampImage: Bool = false) {
        _stampImage = State(initialValue: stampImage)
        _currentStampPhotoInfo = State(initialValue: SettingViewPreviewData.samplePersistedImage?.photoInfo)
        _stampHistory = State(initialValue: SettingViewPreviewData.sampleHistory)
        self.isLoadingStampImage = isLoadingStampImage
    }

    var body: some View {
        NavigationStack {
            SettingView(
                cardTitle: $cardTitle,
                studentName: $studentName,
                selectedStampItem: $selectedStampItem,
                stampImage: stampImage,
                currentStampPhotoInfo: currentStampPhotoInfo,
                stampHistory: stampHistory,
                isLoadingStampImage: isLoadingStampImage,
                onResetPoints: {},
                onClearStampImage: {
                    stampImage = nil
                    currentStampPhotoInfo = nil
                }
            )
        }
    }
}

private enum SettingViewPreviewData {
    static let samplePersistedImage: PersistedStampImage? = {
        guard let data = sampleStampImage.pngData() else {
            return nil
        }

        return PersistedStampImage.make(from: data, assetIdentifier: "preview-sample-image")
    }()

    static let sampleHistory: [StampHistoryEntry] = {
        let now = Date()
        return [
            StampHistoryEntry(
                pointIndex: 2,
                earnedAt: now,
                stamp: samplePersistedImage
            ),
            StampHistoryEntry(
                pointIndex: 1,
                earnedAt: now.addingTimeInterval(-3600),
                stamp: samplePersistedImage
            )
        ]
    }()

    static let sampleStampImage: UIImage = {
        let size = CGSize(width: 240, height: 240)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            let bounds = CGRect(origin: .zero, size: size)
            UIColor.systemYellow.setFill()
            context.fill(bounds)

            UIColor.systemOrange.setFill()
            context.cgContext.fillEllipse(in: bounds.insetBy(dx: 20, dy: 20))

            let starRect = CGRect(x: 60, y: 60, width: 120, height: 120)
            let starImage = UIImage(systemName: "star.fill")?
                .withTintColor(.white, renderingMode: .alwaysOriginal)
            starImage?.draw(in: starRect)
        }
    }()
}

struct SettingView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SettingViewPreviewContainer(stampImage: SettingViewPreviewData.sampleStampImage)
                .previewDisplayName("With Image")

            SettingViewPreviewContainer(stampImage: nil)
                .previewDisplayName("Empty")
        }
    }
}
