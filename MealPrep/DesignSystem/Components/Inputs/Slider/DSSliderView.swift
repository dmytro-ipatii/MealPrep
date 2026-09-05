//
//  DSSliderView.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 05/09/2026.
//

import SwiftUI

struct DSSliderView: View {
    @Binding var value: Double
    var range: ClosedRange<Double>
    var step: Double = 1
    var onEditingChanged: (Bool) -> Void = { _ in }

    @State private var isDragging = false

    private let trackHeight: CGFloat = 16
    private let thumbSize: CGFloat = 64

    var body: some View {
        GeometryReader { geometry in
            let trackSize = geometry.size
            let trackWidth = trackSize.width - thumbSize
            let progress = normalizedProgress
            let thumbCenterX = thumbSize / 2 + progress * trackWidth

            ZStack(alignment: .leading) {

                // Slider area
                sliderAreaView

                // Filled track
                sliderFilledTrack(thumbCenterX: thumbCenterX)

                // Thumb view
                thumbView(
                    trackSize: trackSize,
                    thumbCenterX: thumbCenterX
                )

            }
        }
        .frame(height: thumbSize)
    }

    private var sliderAreaView: some View {
        RoundedRectangle(cornerRadius: DSCornerRadius.full.value)
            .fill(DSColor.backgroundSecondary.value)
            .frame(height: trackHeight)
    }

    private func sliderFilledTrack(thumbCenterX: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: DSCornerRadius.full.value)
            .fill(DSColor.accent.value)
            .frame(width: max(thumbCenterX, trackHeight), height: trackHeight)
    }

    private func thumbView(
        trackSize: CGSize,
        thumbCenterX: CGFloat
    ) -> some View {
        let trackWidth = trackSize.width - thumbSize

        return Circle()
            .fill(DSColor.accent.value)
            .aspectRatio(1, contentMode: .fit)
            .frame(height: thumbSize)
            .position(x: thumbCenterX, y: trackSize.height / 2)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { drag in
                        onThumbMoved(drag: drag, trackWidth: trackWidth)
                    }
                    .onEnded { _ in
                        onDragEnd()
                    }
            )
    }

    private func onThumbMoved(drag: DragGesture.Value, trackWidth: CGFloat) {
        if !isDragging {
            isDragging = true
            onEditingChanged(true)
        }
        let clampedX = min(max(drag.location.x, thumbSize / 2), thumbSize / 2 + trackWidth)
        let newProgress = trackWidth > 0 ? (clampedX - thumbSize / 2) / trackWidth : 0
        value = steppedValue(for: newProgress)
    }

    private func onDragEnd() {
        isDragging = false
        onEditingChanged(false)
    }

    private var normalizedProgress: Double {
        guard range.upperBound > range.lowerBound else { return 0 }
        let progress = (value - range.lowerBound) / (range.upperBound - range.lowerBound)
        return min(max(progress, 0), 1)
    }

    private func steppedValue(for progress: Double) -> Double {
        let rawValue = range.lowerBound + progress * (range.upperBound - range.lowerBound)
        guard step > 0 else {
            return min(max(rawValue, range.lowerBound), range.upperBound)
        }
        let steppedValue = (rawValue / step).rounded() * step
        return min(max(steppedValue, range.lowerBound), range.upperBound)
    }
}



private struct DSSliderWithStateView: View {
    @State private var value: Double = 210.0
    private let range: ClosedRange<Double> = 25...150
    private let step: Double = 1

    var body: some View {
        VStack {
            Text("\(value)")
            Slider(value: $value, in: range, step: step)
            DSSliderView(value: $value, range: range, step: step)
        }
    }
}
#Preview {

    VStack {
        DSSliderView(value: .constant(25), range: 25...150, step: 1)
        DSSliderView(value: .constant(75), range: 25...150, step: 1)
        DSSliderView(value: .constant(150), range: 25...150, step: 1)
    }
    .padding()

}
