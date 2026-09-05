//
//  ContentView.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 05/09/2026.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(.mealBag)
                .resizable()
                .foregroundStyle(.tint)
                .aspectRatio(1, contentMode: .fit)

            Text("Hello, world!")
                .font(.custom("Promo-SemiBold", size: 30))
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
