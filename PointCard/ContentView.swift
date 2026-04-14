//
//  ContentView.swift
//  PointCard
//
//  Created by sako0602 on 2026/04/11.
//

import LocalAuthentication
import PhotosUI
import SwiftUI

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var store = PointCardStore()
    @State private var showCelebration = false
    @State private var lastTappedIndex: Int?
    @State private var pulseNextPoint = false
    @State private var isAuthenticating = false
    @State private var activeAlert: ContentViewAlert?
    @State private var selectedStampItem: PhotosPickerItem?
    @State private var isLoadingStampImage = false

    var body: some View {
        NavigationStack {
            ZStack {
                PointCardPalette.background
                    .ignoresSafeArea()

                BackgroundDecorations()
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        titleSection
                        pointCardSection
                        rewardSection
                    }
                    .frame(maxWidth: 560)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 28)
                }

                if showCelebration {
                    CelebrationOverlay {
                        withAnimation(.spring(response: 0.42, dampingFraction: 0.84)) {
                            showCelebration = false
                        }
                    } resetAction: {
                        resetPoints()
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        activeAlert = .confiscateLastStamp
                    } label: {
                        Text("🥺")
                            .font(.system(size: 24))
                    }
                    .disabled(store.points == 0 || isAuthenticating)
                    .accessibilityLabel("スタンプを1つ没収")
                }

                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SettingView(
                            cardTitle: $store.cardTitle,
                            studentName: $store.studentName,
                            selectedStampItem: $selectedStampItem,
                            stampImage: store.selectedStampImage,
                            currentStampPhotoInfo: store.currentStampPhotoInfo,
                            completedCards: store.completedCardsForDisplay,
                            isLoadingStampImage: isLoadingStampImage,
                            onClearStampImage: {
                                store.clearSelectedStampImage()
                                selectedStampItem = nil
                            }
                        )
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(PointCardPalette.primary)
                    }
                    .accessibilityLabel("設定")
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                pulseNextPoint = true
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase != .active {
                store.flushPersistence()
            }
        }
        .onChange(of: selectedStampItem) { _, newItem in
            guard let newItem else { return }

            Task {
                await loadStampImage(from: newItem)
            }
        }
        .alert(item: $activeAlert, content: makeAlert)
    }

    private var titleSection: some View {
        VStack(spacing: 14) {
            HStack(spacing: 14) {
                Image(systemName: "sparkles")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(PointCardPalette.primary)

                Text(store.displayCardTitle)
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

    private var pointCardSection: some View {
        PointCardView(
            studentName: store.displayStudentName,
            points: store.points,
            maxPoints: store.maxPoints,
            earnedStampImages: store.earnedStampImages,
            lastTappedIndex: lastTappedIndex,
            pulseNextPoint: pulseNextPoint,
            isAuthenticating: isAuthenticating,
            onPointTap: addPoint
        )
    }

    private var rewardSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ポイント１０このご褒美は、、")
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundStyle(PointCardPalette.foreground)

            Text("好きなおもちゃを買ってもらう")
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundStyle(PointCardPalette.mutedForeground)
                .frame(maxWidth: .infinity, alignment: .center)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.vertical, 22)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(PointCardPalette.card)
                .shadow(color: .black.opacity(0.08), radius: 18, x: 0, y: 10)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(PointCardPalette.secondary, lineWidth: 3)
        )
    }

    private func addPoint(_ index: Int) {
        guard index == store.points, store.points < store.maxPoints, !isAuthenticating else { return }

        isAuthenticating = true

        Task {
            let result = await authenticateForNextPoint()

            await MainActor.run {
                isAuthenticating = false

                switch result {
                case .success:
                    applyPoint(at: index)
                case .cancelled:
                    break
                case .failure(let message):
                    activeAlert = .error(
                        title: "ロック解除できませんでした",
                        message: message
                    )
                }
            }
        }
    }

    private func applyPoint(at index: Int) {
        lastTappedIndex = index

        withAnimation(.spring(response: 0.34, dampingFraction: 0.7)) {
            store.addPoint(at: index)
        }

        if store.points == store.maxPoints {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                    showCelebration = true
                }
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
            lastTappedIndex = nil
        }
    }

    private func resetPoints() {
        withAnimation(.spring(response: 0.38, dampingFraction: 0.86)) {
            store.resetPoints()
            showCelebration = false
            lastTappedIndex = nil
            isAuthenticating = false
        }
    }

    private func confiscateLastPoint() {
        withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
            store.removeLastPoint()
            showCelebration = false
            lastTappedIndex = nil
        }
    }

    private func authenticateForNextPoint() async -> PointAuthenticationResult {
        let context = LAContext()
        context.localizedCancelTitle = "キャンセル"

        var error: NSError?
        let reason = "ポイントの星をつけるためにロックを解除してください。"

        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            return .failure(authenticationFailureMessage(for: error))
        }

        return await withCheckedContinuation { continuation in
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, authError in
                if success {
                    continuation.resume(returning: .success)
                    return
                }

                if let laError = authError as? LAError {
                    switch laError.code {
                    case .userCancel, .appCancel, .systemCancel:
                        continuation.resume(returning: .cancelled)
                        return
                    default:
                        break
                    }
                }

                continuation.resume(returning: .failure(authenticationFailureMessage(for: authError)))
            }
        }
    }

    private func authenticationFailureMessage(for error: Error?) -> String {
        guard let laError = error as? LAError else {
            return "ロック解除に失敗しました。もういちどためしてください。"
        }

        switch laError.code {
        case .authenticationFailed:
            return "ロック解除に失敗しました。もういちどためしてください。"
        case .passcodeNotSet:
            return "この iPhone ではパスコードが設定されていません。設定アプリでパスコードを有効にしてください。"
        case .biometryNotAvailable:
            return "この iPhone では Face ID または Touch ID が使えません。"
        case .biometryNotEnrolled:
            return "Face ID または Touch ID が未設定です。設定アプリで登録してください。"
        case .biometryLockout:
            return "生体認証がロックされています。パスコードで解除してからもういちど試してください。"
        case .invalidContext:
            return "認証の準備に失敗しました。もういちどためしてください。"
        case .notInteractive:
            return "この状態ではロック解除画面を表示できません。"
        default:
            return "ロック解除できませんでした。もういちどためしてください。"
        }
    }

    @MainActor
    private func loadStampImage(from item: PhotosPickerItem) async {
        isLoadingStampImage = true
        defer { isLoadingStampImage = false }

        do {
            guard let data = try await item.loadTransferable(type: Data.self) else {
                activeAlert = .error(
                    title: "画像を読み込めませんでした",
                    message: "写真アプリの画像をもういちど選びなおしてください。"
                )
                return
            }

            try store.updateSelectedStampImage(from: data, assetIdentifier: item.itemIdentifier)
        } catch {
            activeAlert = .error(
                title: "画像を読み込めませんでした",
                message: "スタンプ画像の取得に失敗しました。もういちどためしてください。"
            )
        }
    }

    private func makeAlert(for alert: ContentViewAlert) -> Alert {
        switch alert {
        case .confiscateLastStamp:
            return Alert(
                title: Text("本当にスタンプを１つ没収してもいいですか？"),
                primaryButton: .destructive(Text("はい"), action: confiscateLastPoint),
                secondaryButton: .cancel(Text("いいえ"))
            )
        case .error(let title, let message):
            return Alert(
                title: Text(title),
                message: Text(message),
                dismissButton: .cancel(Text("OK"))
            )
        }
    }
}

private enum PointAuthenticationResult {
    case success
    case cancelled
    case failure(String)
}

private enum ContentViewAlert: Identifiable {
    case confiscateLastStamp
    case error(title: String, message: String)

    var id: String {
        switch self {
        case .confiscateLastStamp:
            return "confiscate-last-stamp"
        case .error(let title, let message):
            return "error-\(title)-\(message)"
        }
    }
}

struct PointCardView: View {
    let studentName: String
    let points: Int
    let maxPoints: Int
    let earnedStampImages: [UIImage?]
    let lastTappedIndex: Int?
    let pulseNextPoint: Bool
    let isAuthenticating: Bool
    let onPointTap: (Int) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 5)

    var body: some View {
        VStack(spacing: 0) {
            nameSection
            pointsSection
        }
        .background(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(PointCardPalette.card)
                .shadow(color: .black.opacity(0.1), radius: 24, x: 0, y: 14)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke(PointCardPalette.secondary, lineWidth: 4)
        )
    }

    private var nameSection: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(PointCardPalette.accent)
                    .frame(width: 50, height: 50)

                Text("🌟")
                    .font(.system(size: 24))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("なまえ")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(PointCardPalette.mutedForeground)

                Text(studentName)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(PointCardPalette.foreground)
            }

            Spacer()
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(PointCardPalette.secondary.opacity(0.3))
        )
        .padding(.horizontal, 12)
        .padding(.top, 12)
    }

    private var pointsSection: some View {
        VStack(spacing: 18) {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(0..<maxPoints, id: \.self) { index in
                    let isEarned = index < points
                    let isNext = index == points && points < maxPoints
                    let isJustTapped = lastTappedIndex == index
                    let earnedStampImage = stampImage(at: index)

                    Button {
                        onPointTap(index)
                    } label: {
                        ZStack(alignment: .bottomTrailing) {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(backgroundColor(isEarned: isEarned, isNext: isNext))
                                .overlay {
                                    if isNext {
                                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                                            .stroke(
                                                style: StrokeStyle(lineWidth: 2, dash: [6, 5])
                                            )
                                            .foregroundStyle(PointCardPalette.primary.opacity(0.6))
                                    }
                                }

                            pointIcon(
                                stampImage: earnedStampImage,
                                isEarned: isEarned,
                                isNext: isNext,
                                isJustTapped: isJustTapped
                            )

                            Text("\(index + 1)")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(
                                    isEarned ? PointCardPalette.accent : PointCardPalette.mutedForeground.opacity(0.7)
                                )
                                .padding(8)
                        }
                        .aspectRatio(1, contentMode: .fit)
                        .scaleEffect(cellScale(isNext: isNext, isJustTapped: isJustTapped))
                        .shadow(
                            color: isEarned ? PointCardPalette.secondary.opacity(0.35) : .clear,
                            radius: 10,
                            x: 0,
                            y: 6
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(!isNext || isAuthenticating)
                }
            }

            messageSection
            progressBar
        }
        .padding(22)
    }

    @ViewBuilder
    private func pointIcon(stampImage: UIImage?, isEarned: Bool, isNext: Bool, isJustTapped: Bool) -> some View {
        if isEarned {
            if let stampImage {
                Image(uiImage: stampImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 42, height: 42)
                    .clipShape(Circle())
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .shadow(color: .black.opacity(0.12), radius: 6, x: 0, y: 4)
                    .scaleEffect(isJustTapped ? 1.18 : 1.0)
                    .rotationEffect(.degrees(isJustTapped ? -6 : 0))
            } else {
                Image(systemName: "star.fill")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(PointCardPalette.accent)
                    .scaleEffect(isJustTapped ? 1.18 : 1.0)
                    .rotationEffect(.degrees(isJustTapped ? -6 : 0))
            }
        } else if isNext {
            Image(systemName: isAuthenticating ? "lock.rotation" : "lock.fill")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(PointCardPalette.primary.opacity(0.8))
        } else {
            Circle()
                .fill(.white.opacity(0.55))
                .frame(width: 30, height: 30)
        }
    }

    private func stampImage(at index: Int) -> UIImage? {
        guard earnedStampImages.indices.contains(index) else {
            return nil
        }

        return earnedStampImages[index]
    }

    private var messageSection: some View {
        Group {
            if points < maxPoints {
                Text(
                    "あと \(Text("\(maxPoints - points)").foregroundStyle(PointCardPalette.primary)) こ！"
                )
                .foregroundStyle(PointCardPalette.foreground)
            } else {
                Text("ぜんぶあつめた！すごい！")
                    .foregroundStyle(PointCardPalette.primary)
            }
        }
        .font(.system(size: 24, weight: .bold, design: .rounded))
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
    }

    private var progressBar: some View {
        GeometryReader { geometry in
            let width = geometry.size.width * CGFloat(points) / CGFloat(maxPoints)

            ZStack(alignment: .leading) {
                Capsule(style: .continuous)
                    .fill(PointCardPalette.muted)

                Capsule(style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.yellow, Color.pink],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(width, 0))
                    .overlay(alignment: .trailing) {
                        if points > 0 {
                            Image(systemName: "sparkles")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.trailing, 10)
                        }
                    }
            }
        }
        .frame(height: 24)
    }

    private func backgroundColor(isEarned: Bool, isNext: Bool) -> Color {
        if isEarned {
            return PointCardPalette.secondary
        }
        if isNext {
            return PointCardPalette.border
        }
        return PointCardPalette.muted
    }

    private func cellScale(isNext: Bool, isJustTapped: Bool) -> CGFloat {
        if isJustTapped {
            return 1.14
        }
        if isNext && pulseNextPoint {
            return 1.06
        }
        return 1
    }
}

private struct CelebrationOverlay: View {
    let dismissAction: () -> Void
    let resetAction: () -> Void

    var body: some View {
        ZStack {
            PointCardPalette.foreground.opacity(0.28)
                .ignoresSafeArea()
                .onTapGesture(perform: dismissAction)

            VStack(spacing: 18) {
                HStack(spacing: 14) {
                    Image(systemName: "party.popper.fill")
                    Image(systemName: "sparkles")
                    Image(systemName: "party.popper.fill")
                }
                .font(.system(size: 42, weight: .bold))
                .foregroundStyle(
                    PointCardPalette.accent,
                    PointCardPalette.secondary,
                    PointCardPalette.primary
                )

                Text("すごい！")
                    .font(.system(size: 38, weight: .heavy, design: .rounded))
                    .foregroundStyle(PointCardPalette.foreground)

                Text("全部あつめたね！")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(PointCardPalette.foreground)

                Button("もういちど！") {
                    resetAction()
                }
                .buttonStyle(.plain)
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .background(Capsule(style: .continuous).fill(PointCardPalette.primary))
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 30)
            .frame(maxWidth: 340)
            .background(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(PointCardPalette.card)
                    .shadow(color: .black.opacity(0.16), radius: 26, x: 0, y: 18)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .stroke(PointCardPalette.secondary, lineWidth: 3)
            )
            .padding(.horizontal, 24)
        }
    }
}

private struct BackgroundDecorations: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                backgroundBubble(
                    color: PointCardPalette.secondary.opacity(0.32),
                    diameter: 86,
                    x: geometry.size.width * 0.18,
                    y: 84
                )

                backgroundBubble(
                    color: PointCardPalette.primary.opacity(0.24),
                    diameter: 132,
                    x: geometry.size.width - 84,
                    y: 180
                )

                backgroundBubble(
                    color: PointCardPalette.accent.opacity(0.22),
                    diameter: 104,
                    x: geometry.size.width * 0.26,
                    y: geometry.size.height - 150
                )

                backgroundBubble(
                    color: PointCardPalette.secondary.opacity(0.4),
                    diameter: 64,
                    x: geometry.size.width - 54,
                    y: geometry.size.height - 220
                )
            }
        }
    }

    private func backgroundBubble(color: Color, diameter: CGFloat, x: CGFloat, y: CGFloat) -> some View {
        Circle()
            .fill(color)
            .frame(width: diameter, height: diameter)
            .blur(radius: 14)
            .position(x: x, y: y)
    }
}

enum PointCardPalette {
    static let background = Color(red: 0.996, green: 0.955, blue: 0.878)
    static let foreground = Color(red: 0.345, green: 0.231, blue: 0.137)
    static let card = Color.white
    static let primary = Color(red: 0.925, green: 0.494, blue: 0.196)
    static let secondary = Color(red: 0.984, green: 0.835, blue: 0.369)
    static let accent = Color(red: 0.965, green: 0.663, blue: 0.216)
    static let muted = Color(red: 0.984, green: 0.931, blue: 0.840)
    static let mutedForeground = Color(red: 0.839, green: 0.431, blue: 0.620)
    static let border = Color(red: 0.953, green: 0.847, blue: 0.659)
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
