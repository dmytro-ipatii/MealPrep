//
//  DSCircularProgressView.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 05/09/2026.
//

import SwiftUI

struct DSCircularProgressView: View {
    var color: DSColor = .ink

    var body: some View {
        ProgressView()
            .tint(color.value)
    }
}

#Preview {
    DSCircularProgressView()
        .padding()
}
