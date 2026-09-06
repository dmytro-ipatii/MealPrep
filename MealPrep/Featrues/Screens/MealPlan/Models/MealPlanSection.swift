//
//  MealPlanSettingPhase.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 05/09/2026.
//

import SwiftUI

enum MealPlanSection: CaseIterable, Identifiable {
    var id: Self { self }

    case budget
    case dietry
    case nutrition

    static var initial: Self = .budget

    static var sectionsCount: CGFloat {
        CGFloat(MealPlanSection.allCases.count)
    }
}
