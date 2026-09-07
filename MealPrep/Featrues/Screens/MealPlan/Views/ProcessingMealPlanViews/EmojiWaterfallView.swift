//
//  EmojiWaterfallView.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 07/09/2026.
//

import SwiftUI

private struct FallingEmoji: Identifiable {
    let id = UUID()
    let emoji: String
    let xOffset: CGFloat
    let duration: Double
    let delay: Double
}

/// Continuously drops emojis from the top of its bounds down into the
/// bottom-center, fading them out as they "land" — used to suggest
/// ingredients being gathered into the meal bag while a plan generates.
struct EmojiWaterfallView: View {
    var emojis: [String] = ["🥩", "🥕", "🫒", "🍆", "🌽", "🧀", "🍎"]

    private let dropXOffsets: [CGFloat] = [-70, -35, 0, 35, 70, -50, 50]
    /// Points per second, cycled per item for an organic, non-uniform fall.
    private let dropSpeeds: [CGFloat] = [420, 500, 460, 540, 440]

    private func fallingEmojis(distance: CGFloat) -> [FallingEmoji] {
        emojis.enumerated().map { index, emoji in
            let speed = dropSpeeds[index % dropSpeeds.count]
            return FallingEmoji(
                emoji: emoji,
                xOffset: dropXOffsets[index % dropXOffsets.count],
                duration: distance / speed,
                delay: Double(index) * 0.35
            )
        }
    }

    var body: some View {
        GeometryReader { geometry in
            // Distance from this view's top edge up to the very top of the
            // screen (not just the safe area), plus a margin, so an item's
            // pre-animation position at progress 0 is fully off-screen and
            // never visibly "pops in" when it first appears.
            let startY = -(geometry.frame(in: .global).minY + 60)
            let endY = geometry.size.height * 0.35

            ZStack {
                ForEach(fallingEmojis(distance: endY - startY)) { item in
                    FallingEmojiView(
                        emoji: item.emoji,
                        xOffset: item.xOffset,
                        // Lands just past the frame's top edge, so the drop
                        // reads as falling into the bag opening rather than
                        // hovering above it.
                        startY: startY,
                        endY: endY,
                        duration: item.duration,
                        delay: item.delay
                    )
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
        }
        .allowsHitTesting(false)
    }
}

private struct FallingEmojiView: View {
    let emoji: String
    let xOffset: CGFloat
    let startY: CGFloat
    let endY: CGFloat
    let duration: Double
    let delay: Double

    @State private var progress: CGFloat = 0

    var body: some View {
        Text(emoji)
            .font(.system(size: 28))
            .modifier(FallingEmojiModifier(progress: progress, startY: startY, endY: endY))
            .offset(x: xOffset)
            .onAppear {
                withAnimation(
                    .linear(duration: duration)
                    .delay(delay)
                    .repeatForever(autoreverses: false)
                ) {
                    progress = 1
                }
            }
    }
}

/// Maps a 0...1 fall progress onto vertical offset, opacity and scale so the
/// emoji starts above the container and fades out as it drops past the
/// landing point, rather than animating position and opacity independently.
private struct FallingEmojiModifier: Animatable, ViewModifier {
    var progress: CGFloat
    let startY: CGFloat
    let endY: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    private let fadeStart: CGFloat = 0.6

    func body(content: Content) -> some View {
        let clampedProgress = min(max(progress, 0), 1)
        let fadeProgress = max(0, (clampedProgress - fadeStart) / (1 - fadeStart))

        content
            .offset(y: startY + (endY - startY) * clampedProgress)
            .opacity(1 - fadeProgress)
            .scaleEffect(1 - 0.3 * fadeProgress)
    }
}

#Preview {
    EmojiWaterfallView()
        .frame(width: 200, height: 200)
        .background(DSColor.accent.value.opacity(0.1))
}
