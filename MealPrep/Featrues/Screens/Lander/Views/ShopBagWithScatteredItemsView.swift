//
//  ShopBagWithScatteredItemsView.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 05/09/2026.
//

import SwiftUI

private struct ScatteredItem: Identifiable {
    let id = UUID()
    let emoji: String
    let offset: CGSize
}

struct ShopBagWithScatteredItemsView: View {
    /// Fires once the bag has finished vibrating, exploding and scattering
    /// its items — the caller can use it to reveal content that should stay
    /// hidden until the intro animation is done.
    var onAnimationComplete: () -> Void

    init(onAnimationComplete: @escaping () -> Void = {}) {
        self.onAnimationComplete = onAnimationComplete
    }

    private var scatteredItems: [ScatteredItem] = [
        ScatteredItem(emoji: "🥩", offset: CGSize(width: 40, height: -140)),
        ScatteredItem(emoji: "🥕", offset: CGSize(width: 140, height: -50)),
        ScatteredItem(emoji: "🫒", offset: CGSize(width: 130, height: 90)),
        ScatteredItem(emoji: "🍆", offset: CGSize(width: 20, height: 150)),
        ScatteredItem(emoji: "🌽", offset: CGSize(width: -110, height: 110)),
        ScatteredItem(emoji: "🧀", offset: CGSize(width: -140, height: 10)),
        ScatteredItem(emoji: "🍎", offset: CGSize(width: -110, height: -110)),
    ]

    @State private var bagRotation: Double = 0
    @State private var bagScale: CGFloat = 1
    @State private var isExploded = false
    @State private var isSettled = false

    private let vibrationDuration: Double = 2.0
    private let vibrationStep: Double = 0.07
    private let vibrationAngle: Double = 5

    var body: some View {
        VStack {
            ZStack {

                // Shop bag Image
                Image(.mealBag)
                    .resizable()
                    .aspectRatio(1, contentMode: .fit)
                    .frame(height: 200)
                    .rotationEffect(.degrees(bagRotation))
                    .scaleEffect(bagScale)
                    .zIndex(9999)

                // Scattered emojis
                ForEach(Array(scatteredItems.enumerated()), id: \.element.id) { index, item in
                    ScatteredItemAnimatedView(item: item, index: index, isExploded: isExploded, isSettled: isSettled)
                }
            }

        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task {
            await runIntroSequence()
        }
    }

    private func runIntroSequence() async {
        await vibrateBag()
        await explodeBag()
        isSettled = true
        onAnimationComplete()
    }

    /// Small back-and-forth rotations for a couple of seconds, as if the bag
    /// is rattling right before it bursts open.
    private func vibrateBag() async {
        let stepCount = Int(vibrationDuration / vibrationStep)
        for step in 0..<stepCount {
            withAnimation(.easeInOut(duration: vibrationStep)) {
                bagRotation = step.isMultiple(of: 2) ? vibrationAngle : -vibrationAngle
            }
            try? await Task.sleep(nanoseconds: UInt64(vibrationStep * 1_000_000_000))
        }
        withAnimation(.easeOut(duration: 0.1)) {
            bagRotation = 0
        }
        try? await Task.sleep(nanoseconds: 100_000_000)
    }

    /// A quick scale out-in "pop" on the bag, timed with the items bursting
    /// outward like a firework.
    private func explodeBag() async {
        withAnimation(.easeIn(duration: 0.12)) {
            bagScale = 1.3
        }
        try? await Task.sleep(nanoseconds: 120_000_000)

        withAnimation(.spring(response: 0.35, dampingFraction: 0.55)) {
            bagScale = 1.0
        }
        isExploded = true

        try? await Task.sleep(nanoseconds: 550_000_000)
    }
}

/// Owns an item's idle rotation/scale wobble so each one can animate
/// independently once the firework settles, on top of the shared explosion
/// trigger from the parent.
private struct ScatteredItemAnimatedView: View {
    let item: ScatteredItem
    let index: Int
    let isExploded: Bool
    let isSettled: Bool

    @State private var idleRotation: Double = 0
    @State private var idleScale: CGFloat = 1

    private let itemContainerSize: CGFloat = 44

    // Fixed per-item variety so items don't all wobble in lockstep.
    private static let idleRotationRanges: [Double] = [10, -14, 12, -9, 15, -11, 13]
    private static let idleScaleRanges: [CGFloat] = [0.15, 0.2, 0.12, 0.18, 0.22, 0.14, 0.19]
    private static let idleDurations: [Double] = [1.6, 2.0, 1.8, 2.3, 1.7, 2.1, 1.9]

    private var idleRotationRange: Double { Self.idleRotationRanges[index % Self.idleRotationRanges.count] }
    private var idleScaleRange: CGFloat { Self.idleScaleRanges[index % Self.idleScaleRanges.count] }
    private var idleDuration: Double { Self.idleDurations[index % Self.idleDurations.count] }

    var body: some View {
        Text(item.emoji)
            .font(.system(size: 40))
            .frame(width: itemContainerSize, height: itemContainerSize)
            .scaleEffect(isExploded ? idleScale : 0.01)
            .rotationEffect(.degrees(idleRotation))
            .opacity(isExploded ? 1 : 0)
            .offset(isExploded ? item.offset : .zero)
            .animation(
                .spring(response: 0.45, dampingFraction: 0.6).delay(Double(index) * 0.05),
                value: isExploded
            )
            .onChange(of: isSettled) { _, settled in
                guard settled else { return }

                withAnimation(.easeInOut(duration: idleDuration).repeatForever(autoreverses: true)) {
                    idleRotation = idleRotationRange
                }
                withAnimation(.easeInOut(duration: idleDuration * 1.15).repeatForever(autoreverses: true)) {
                    idleScale = 1 + idleScaleRange
                }
            }
    }
}


#Preview {
    ShopBagWithScatteredItemsView()
}
