//
//  DSFont.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 05/09/2026.
//

import SwiftUI

extension Font {
    static let dsDisplayXL: Font = .custom(DSFontFamily.promoSemibold.value, size: DSFontSize.displayXL.value)
    static let dsDisplayL: Font = .custom(DSFontFamily.promoSemibold.value, size: DSFontSize.displayL.value)
    static let dsTitleL: Font = .custom(DSFontFamily.promoSemibold.value, size: DSFontSize.titleL.value)
    static let dsTitle: Font = .custom(DSFontFamily.promoMedium.value, size: DSFontSize.title.value)
    static let dsHeadline: Font = .custom(DSFontFamily.promoMedium.value, size: DSFontSize.headline.value)
    static let dsBody: Font = .custom(DSFontFamily.promoMedium.value, size: DSFontSize.body.value)
    static let dsCallout: Font = .custom(DSFontFamily.promoMedium.value, size: DSFontSize.callout.value)
    static let dsFootnote: Font = .custom(DSFontFamily.promoMedium.value, size: DSFontSize.footnote.value)
    static let dsCaption: Font = .custom(DSFontFamily.promoRegular.value, size: DSFontSize.caption.value)

    static func dsCustom(font: DSFontFamily, size: DSFontSize) -> Font {
        .custom(font.value, size: size.value)
    }
}
