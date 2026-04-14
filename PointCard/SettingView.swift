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
    @Binding var showsRewardSection: Bool
    @Binding var rewardText: String
    @Binding var selectedStampItem: PhotosPickerItem?
    let stampImage: UIImage?
    let currentStampPhotoInfo: StampPhotoInfo?
    let completedCards: [CompletedPointCard]
    let isLoadingStampImage: Bool
    let onClearStampImage: () -> Void

    var body: some View {
        Form {
            Section("ポイントカード名") {
                TextField("ポイントカード", text: $cardTitle)
                    .font(.system(size: 17, weight: .medium, design: .rounded))
            }

            Section("なまえ") {
                TextField("たろう", text: $studentName)
                    .font(.system(size: 17, weight: .medium, design: .rounded))
            }

            Section("ご褒美") {
                Toggle("ご褒美（目標）の表示", isOn: $showsRewardSection)
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .tint(PointCardPalette.primary)

                VStack(alignment: .leading, spacing: 8) {
                    Text("ご褒美の内容")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(PointCardPalette.foreground)

                    Text("下の欄をタップして編集できます")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(PointCardPalette.mutedForeground)

                    TextField("ごほうびを きめてね", text: $rewardText, axis: .vertical)
                        .font(.system(size: 17, weight: .medium, design: .rounded))
                        .lineLimit(1...4)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(PointCardPalette.card)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(PointCardPalette.secondary, lineWidth: 2)
                        )
                }
                .padding(.vertical, 4)
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

                if stampImage != nil {
                    Button("画像をリセット", role: .destructive) {
                        selectedStampItem = nil
                        onClearStampImage()
                    }
                }
            }

            Section("ポイント履歴") {
                if completedCards.isEmpty {
                    Text("10こたまったポイントカードはまだありません。")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(PointCardPalette.mutedForeground)
                } else {
                    ForEach(completedCards) { card in
                        NavigationLink {
                            PointCardHistoryDetailView(card: card)
                        } label: {
                            CompletedPointCardRow(card: card)
                        }
                    }
                }
            }
        }
        .navigationTitle("設定")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct CompletedPointCardRow: View {
    let card: CompletedPointCard

    var body: some View {
        HStack(spacing: 14) {
            CompletedPointCardThumbnail(image: card.thumbnailImage)

            VStack(alignment: .leading, spacing: 6) {
                Text(card.displayCardTitle)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(PointCardPalette.foreground)

                Text(card.displayStudentName)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(PointCardPalette.mutedForeground)

                Text("達成日時: \(card.completedAtLabel)")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(PointCardPalette.mutedForeground)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

private struct CompletedPointCardThumbnail: View {
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

private struct PointCardHistoryDetailView: View {
    let card: CompletedPointCard

    private let maxPoints = 10

    var body: some View {
        ZStack {
            PointCardPalette.background
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    PointCardHistoryTitleSection(title: card.displayCardTitle)

                    PointCardView(
                        studentName: card.displayStudentName,
                        points: maxPoints,
                        maxPoints: maxPoints,
                        earnedStampImages: card.earnedStampImages,
                        lastTappedIndex: nil,
                        pulseNextPoint: false,
                        isAuthenticating: false,
                        onPointTap: { _ in }
                    )
                }
                .frame(maxWidth: 560)
                .padding(.horizontal, 20)
                .padding(.vertical, 28)
            }
        }
        .navigationTitle(card.displayCardTitle)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct PointCardHistoryTitleSection: View {
    let title: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "sparkles")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(PointCardPalette.primary)

            Text(title)
                .font(.system(size: 30, weight: .heavy, design: .rounded))
                .foregroundStyle(PointCardPalette.foreground)

            Image(systemName: "sparkles")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(PointCardPalette.accent)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(
            Capsule(style: .continuous)
                .fill(PointCardPalette.card)
                .shadow(color: .black.opacity(0.08), radius: 18, x: 0, y: 10)
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(PointCardPalette.secondary, lineWidth: 2)
        )
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
    @State private var showsRewardSection = true
    @State private var rewardText = PointCardState.defaultRewardText
    @State private var selectedStampItem: PhotosPickerItem?
    @State private var stampImage: UIImage?
    @State private var currentStampPhotoInfo: StampPhotoInfo?
    @State private var completedCards: [CompletedPointCard]

    let isLoadingStampImage: Bool

    init(stampImage: UIImage?, isLoadingStampImage: Bool = false) {
        _stampImage = State(initialValue: stampImage)
        _currentStampPhotoInfo = State(initialValue: SettingViewPreviewData.samplePersistedImage?.photoInfo)
        _completedCards = State(initialValue: SettingViewPreviewData.sampleCompletedCards)
        self.isLoadingStampImage = isLoadingStampImage
    }

    var body: some View {
        NavigationStack {
            SettingView(
                cardTitle: $cardTitle,
                studentName: $studentName,
                showsRewardSection: $showsRewardSection,
                rewardText: $rewardText,
                selectedStampItem: $selectedStampItem,
                stampImage: stampImage,
                currentStampPhotoInfo: currentStampPhotoInfo,
                completedCards: completedCards,
                isLoadingStampImage: isLoadingStampImage,
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

    static let sampleCompletedCards: [CompletedPointCard] = {
        let now = Date()
        return [
            CompletedPointCard(
                cardTitle: "よくできましたカード",
                studentName: "たろう",
                completedAt: now,
                stamps: sampleStamps
            )
        ]
    }()

    static let sampleStamps: [StampHistoryEntry] = (0..<10).map { index in
        StampHistoryEntry(
            pointIndex: index,
            earnedAt: Date().addingTimeInterval(TimeInterval(index * 300)),
            stamp: samplePersistedImage
        )
    }

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
