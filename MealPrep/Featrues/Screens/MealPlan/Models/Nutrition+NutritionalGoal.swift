//
//  Nutrition+NutritionalGoal.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 06/09/2026.
//

extension Nutrition {

    var nutritionalGoal: NutritionalGoal? {
        switch self {
        case .none: nil
        case .highProtein: .highProtein
        case .lowSugar: .lowSugar
        case .lowFat: .lowFat
        case .lowCarbs: .lowCarbs
        case .lowSalt: .lowSalt
        }
    }

    init(nutritionalGoal: NutritionalGoal) {
        switch nutritionalGoal {
        case .highProtein: self = .highProtein
        case .lowSugar: self = .lowSugar
        case .lowFat: self = .lowFat
        case .lowCarbs: self = .lowCarbs
        case .lowSalt: self = .lowSalt
        }
    }
}
