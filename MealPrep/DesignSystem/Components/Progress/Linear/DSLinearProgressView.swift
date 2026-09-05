//
//  DSLinearProgressView.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 05/09/2026.
//

import SwiftUI

struct DSLinearProgressStyle: ProgressViewStyle {

    func makeBody(configuration: Configuration) -> some View {
        let value = CGFloat(configuration.fractionCompleted ?? 0)

        return GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: DSCornerRadius.full.value)
                    .fill(DSColor.backgroundSecondary.value)

                RoundedRectangle(cornerRadius: DSCornerRadius.full.value)
                    .fill(DSColor.green.value)
                    .frame(width: geometry.size.width * value)
                    .overlay(alignment: .top) {
                        RoundedRectangle(cornerRadius: DSCornerRadius.full.value)
                            .fill(DSColor.white.value.opacity(0.5))
                            .padding(.horizontal, DSSpace.sm.value)
                            .offset(y: 3)
                            .frame(height: 6)

                    }
                    .animation(.easeInOut(duration: 0.5), value: value)

            }
        }
        .frame(height: 20)
    }
}

struct DSLinearProgressView: View {
    @Binding var value: CGFloat
    var total: CGFloat = 1.0

    var body: some View {
        ProgressView(value: value, total: total)
            .progressViewStyle(DSLinearProgressStyle())
    }
}


#Preview {
    VStack {
        DSLinearProgressView(value: .constant(0.3))
        DSLinearProgressView(value: .constant(0.5))
        DSLinearProgressView(value: .constant(0.8))
    }
    .padding()
}
