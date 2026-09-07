//
//  StoredPlanDay.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 07/09/2026.
//

import Foundation
import SwiftData

@Model
final class StoredPlanDay {
    var dayIndex: Int
    @Relationship(deleteRule: .cascade) var meals: [StoredMeal]

    init(dayIndex: Int, meals: [StoredMeal]) {
        self.dayIndex = dayIndex
        self.meals = meals
    }
}
