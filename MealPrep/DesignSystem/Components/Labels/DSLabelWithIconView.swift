//
//  DSLabelView.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 05/09/2026.
//

import SwiftUI

struct DSLabelWithIconView: View {
    let icon: ImageResource
    let label: String
    var color: DSColor = .textSecondary

    var body: some View {
        HStack(alignment: .center, spacing: DSSpace.xxs.value) {
            Group {
                Image(icon)

                Text(label)

            }
            .font(.dsCaption)
            .foregroundStyle(color.value)
        }
    }
}

#Preview {
    VStack {
        DSLabelWithIconView(icon: .clock, label: "25 min")
        DSLabelWithIconView(icon: .user, label: "Servings")
        DSLabelWithIconView(icon: .cash, label: "€4.18 / serving")
    }
    .padding()
}
