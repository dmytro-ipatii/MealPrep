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
    private var scatteredItems: [ScatteredItem] = [
        ScatteredItem(emoji: "🥩", offset: CGSize(width: 40, height: -140)),
        ScatteredItem(emoji: "🥕", offset: CGSize(width: 140, height: -50)),
        ScatteredItem(emoji: "🫒", offset: CGSize(width: 130, height: 90)),
        ScatteredItem(emoji: "🍆", offset: CGSize(width: 20, height: 150)),
        ScatteredItem(emoji: "🌽", offset: CGSize(width: -110, height: 110)),
        ScatteredItem(emoji: "🧀", offset: CGSize(width: -140, height: 10)),
        ScatteredItem(emoji: "🍎", offset: CGSize(width: -110, height: -110)),
    ]

    private let itemContainerSize: CGFloat = 44

    var body: some View {
        VStack {
            ZStack {

                // Shop bag Image
                Image(.mealBag)
                    .resizable()
                    .aspectRatio(1, contentMode: .fit)
                    .frame(height: 200)


                // Scattered emojis
                ForEach(scatteredItems) { item in
                    scatteredItemView(item)
                }
            }


        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)

    }

    // Each emoji lives in its own fixed-size, centered container positioned
    // via offset. Future appear/scatter animations should animate the emoji
    // from the center of this container, so the container's position must
    // stay untouched by that animation.
    private func scatteredItemView(_ item: ScatteredItem) -> some View {
        Text(item.emoji)
            .font(.system(size: 40))
            .frame(width: itemContainerSize, height: itemContainerSize)
            .offset(item.offset)

    }
}


#Preview {
    ShopBagWithScatteredItemsView()
}
