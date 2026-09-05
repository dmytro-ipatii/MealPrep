//
//  DSFontFamily.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 05/09/2026.
//

import Foundation

enum DSFontFamily {
    case promoRegular
    case promoMedium
    case promoSemibold

    var value: String {
        switch self {
        case .promoRegular: "Promo-Regular"
        case .promoMedium: "Promo-Medium"
        case .promoSemibold: "Promo-SemiBold"
        }
    }

}
