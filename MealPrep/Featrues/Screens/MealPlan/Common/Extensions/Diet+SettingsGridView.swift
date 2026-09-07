//
//  Diet+SettingsGridView.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 05/09/2026.
//

extension Diet: SettingsGridProtocol {

    var id: Self {self}

    var label: String {
        switch self {
        case .none: "None"
        case .vegetarian: "Vegetarian"
        case .vegan: "Vegan"
        case .pescaterian: "Pescaterian"
        case .glutenFree: "Gluten free"
        case .dairyFree: "Dairy free"
        }
    }

    var emoji: String {
        switch self {
        case .none: ""
        case .vegetarian: "🥕"
        case .vegan: "🌱"
        case .pescaterian: "🐟"
        case .glutenFree: "🌾"
        case .dairyFree: "🥛"
        }
    }
}
