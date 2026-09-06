//
//  Double+EXT.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 06/09/2026.
//

import SwiftUI

extension Double {
    func toFormatedString(with decimals: Int = 0) -> String {
        String(format: "%.\(decimals)f", self)
    }
}
