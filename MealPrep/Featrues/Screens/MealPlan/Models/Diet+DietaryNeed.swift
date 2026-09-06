//
//  Diet+DietaryNeed.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 06/09/2026.
//

extension Diet {

    var dietaryNeed: DietaryNeed? {
        switch self {
        case .none: nil
        case .vegetarian: .vegetarian
        case .vegan: .vegan
        case .pescaterian: .pescatarian
        case .glutenFree: .glutenFree
        case .dairyFree: .dairyFree
        }
    }

    init(dietaryNeed: DietaryNeed) {
        switch dietaryNeed {
        case .vegetarian: self = .vegetarian
        case .vegan: self = .vegan
        case .pescatarian: self = .pescaterian
        case .glutenFree: self = .glutenFree
        case .dairyFree: self = .dairyFree
        }
    }
}
