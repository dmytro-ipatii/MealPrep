//
//  DSFontSize.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 05/09/2026.
//

import Foundation

enum DSFontSize {

    case displayXL
    case displayL
    case titleL
    case title
    case headline
    case body
    case callout
    case footnote
    case caption

    var value: CGFloat {
        switch self {
        case .displayXL: 96
        case .displayL: 48
        case .titleL: 40
        case .title: 32
        case .headline: 24
        case .body: 20
        case .callout: 16
        case .footnote: 14
        case .caption: 12
        }
    }
}
