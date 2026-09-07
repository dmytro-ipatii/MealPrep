//
//  Nutrition+SettingsGridView.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 05/09/2026.
//

extension Nutrition: @MainActor SettingsGridProtocol {

    var id: Self {self}

    var label: String {
        switch self {
        case .none: "None"
        case .highProtein: "High protein"
        case .lowSugar: "Low sugar"
        case .lowFat: "Low fat"
        case .lowCarbs: "Low carbs"
        case .lowSalt: "Low salt"
        }
    }

    var emoji: String {
        switch self {
        case .none: ""
        case .highProtein: "🥩"
        case .lowSugar: "🍯"
        case .lowFat: "🫑"
        case .lowCarbs: "🍝"
        case .lowSalt: "🧂"
        }
    }
}
