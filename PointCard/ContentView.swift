//
//  ContentView.swift
//  PointCard
//
//  Created by sako0602 on 2026/04/11.
//

import SwiftUI

struct ContentView: View {
    @State private var points = 3
    @State private var showCelebration = false
    @State private var lastTappedIndex: Int?
    @State private var pulseNextPoint = false

    private let studentName = "たろう"
    private let maxPoints = 10

    var body: some View {
        ZStack {
            PointCardPalette.background
                .ignoresSafeArea()

            BackgroundDecorations()
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    titleSection
                    pointCardSection
                    usageSection
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
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                pulseNextPoint = true
            }
        }
    }

    private var titleSection: some View {
        VStack(spacing: 14) {
            HStack(spacing: 14) {
                Image(systemName: "sparkles")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(PointCardPalette.primary)

                Text("ポイントカード")
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

            Text("がんばったらほしがもらえるよ")
                .font(.system(size: 20, weight: .medium, design: .rounded))
                .foregroundStyle(PointCardPalette.mutedForeground)
                .multilineTextAlignment(.center)
        }
    }

    private var pointCardSection: some View {
        PointCardView(
            studentName: studentName,
            points: points,
            maxPoints: maxPoints,
            lastTappedIndex: lastTappedIndex,
            pulseNextPoint: pulseNextPoint,
            onPointTap: addPoint,
            onReset: resetPoints
        )
    }

    private var usageSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 10) {
                Text("📖")
                    .font(.system(size: 26))
                Text("つかいかた")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(PointCardPalette.foreground)
            }

            VStack(spacing: 14) {
                InstructionRow(number: 1, text: "がんばったら、ひかっているところをタップ！")
                InstructionRow(number: 2, text: "ほしがふえるよ！")
                InstructionRow(number: 3, text: "ぜんぶあつめたら、すてきなことがあるかも！")
            }
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(PointCardPalette.card)
                .shadow(color: .black.opacity(0.08), radius: 18, x: 0, y: 10)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(PointCardPalette.border, lineWidth: 2)
        )
    }

    private func addPoint(_ index: Int) {
        guard index == points, points < maxPoints else { return }

        lastTappedIndex = index

        withAnimation(.spring(response: 0.34, dampingFraction: 0.7)) {
            points += 1
        }

        if points == maxPoints {
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
            points = 0
            showCelebration = false
            lastTappedIndex = nil
        }
    }
}

private struct PointCardView: View {
    let studentName: String
    let points: Int
    let maxPoints: Int
    let lastTappedIndex: Int?
    let pulseNextPoint: Bool
    let onPointTap: (Int) -> Void
    let onReset: () -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 5)

    var body: some View {
        VStack(spacing: 0) {
            header
            nameSection
            pointsSection
            footer
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

    private var header: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(PointCardPalette.primary)

            Circle()
                .fill(.white.opacity(0.12))
                .frame(width: 96, height: 96)
                .offset(x: 120, y: -34)

            Circle()
                .fill(.white.opacity(0.08))
                .frame(width: 140, height: 140)
                .offset(x: -140, y: 70)

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                        Text("キラキラカード")
                            .font(.system(size: 28, weight: .heavy, design: .rounded))
                    }

                    Text("がんばったらもらえるよ")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .opacity(0.82)
                }
                .foregroundStyle(.white)

                Spacer(minLength: 12)

                Text("\(points)/\(maxPoints)")
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.white.opacity(0.18), in: Capsule(style: .continuous))
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 20)
        }
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 28,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 28,
                style: .continuous
            )
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
        .background(PointCardPalette.secondary.opacity(0.3))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(PointCardPalette.border)
                .frame(height: 1)
        }
    }

    private var pointsSection: some View {
        VStack(spacing: 18) {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(0..<maxPoints, id: \.self) { index in
                    let isEarned = index < points
                    let isNext = index == points && points < maxPoints
                    let isJustTapped = lastTappedIndex == index

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

                            pointIcon(isEarned: isEarned, isNext: isNext, isJustTapped: isJustTapped)

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
                    .disabled(!isNext)
                }
            }

            messageSection
            progressBar
        }
        .padding(22)
    }

    @ViewBuilder
    private func pointIcon(isEarned: Bool, isNext: Bool, isJustTapped: Bool) -> some View {
        if isEarned {
            Image(systemName: "star.fill")
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(PointCardPalette.accent)
                .scaleEffect(isJustTapped ? 1.18 : 1.0)
                .rotationEffect(.degrees(isJustTapped ? -6 : 0))
        } else if isNext {
            Text("+")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(PointCardPalette.mutedForeground.opacity(0.6))
        } else {
            Circle()
                .fill(.white.opacity(0.55))
                .frame(width: 30, height: 30)
        }
    }

    private var messageSection: some View {
        Group {
            if points == 0 {
                Text("さいしょのほしをタップしよう！")
                    .foregroundStyle(PointCardPalette.mutedForeground)
            } else if points < maxPoints {
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
                            colors: [PointCardPalette.primary, PointCardPalette.accent],
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

    private var footer: some View {
        HStack {
            HStack(spacing: 8) {
                Circle()
                    .fill(PointCardPalette.accent)
                    .frame(width: 12, height: 12)
                Circle()
                    .fill(PointCardPalette.primary)
                    .frame(width: 12, height: 12)
                Circle()
                    .fill(PointCardPalette.secondary)
                    .frame(width: 12, height: 12)
            }

            Spacer()

            Button("リセット") {
                onReset()
            }
            .buttonStyle(.plain)
            .font(.system(size: 16, weight: .semibold, design: .rounded))
            .foregroundStyle(PointCardPalette.mutedForeground)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 18)
        .background(PointCardPalette.muted.opacity(0.75))
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: 28,
                bottomTrailingRadius: 28,
                topTrailingRadius: 0,
                style: .continuous
            )
        )
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

private struct InstructionRow: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(Circle().fill(PointCardPalette.primary))

            Text(text)
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundStyle(PointCardPalette.foreground)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
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

private enum PointCardPalette {
    static let background = Color(red: 0.985, green: 0.972, blue: 0.915)
    static let foreground = Color(red: 0.275, green: 0.220, blue: 0.365)
    static let card = Color.white
    static let primary = Color(red: 0.352, green: 0.733, blue: 0.474)
    static let secondary = Color(red: 0.953, green: 0.847, blue: 0.529)
    static let accent = Color(red: 0.949, green: 0.553, blue: 0.333)
    static let muted = Color(red: 0.945, green: 0.925, blue: 0.875)
    static let mutedForeground = Color(red: 0.555, green: 0.500, blue: 0.635)
    static let border = Color(red: 0.914, green: 0.875, blue: 0.780)
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
