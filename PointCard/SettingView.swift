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
    @Binding var stampImage: UIImage?
    let isLoadingStampImage: Bool

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

                if stampImage != nil {
                    Button("画像をリセット", role: .destructive) {
                        stampImage = nil
                        selectedStampItem = nil
                    }
                }
            }
        }
        .navigationTitle("設定")
        .navigationBarTitleDisplayMode(.inline)
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

    let isLoadingStampImage: Bool

    init(stampImage: UIImage?, isLoadingStampImage: Bool = false) {
        _stampImage = State(initialValue: stampImage)
        self.isLoadingStampImage = isLoadingStampImage
    }

    var body: some View {
        NavigationStack {
            SettingView(
                cardTitle: $cardTitle,
                studentName: $studentName,
                selectedStampItem: $selectedStampItem,
                stampImage: $stampImage,
                isLoadingStampImage: isLoadingStampImage
            )
        }
    }
}

private enum SettingViewPreviewData {
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
