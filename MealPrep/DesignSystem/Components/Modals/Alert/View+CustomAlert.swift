//
//  View+CustomAlert.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 06/09/2026.
//

import SwiftUI

extension View {

    @ViewBuilder
    func showDSAlert(with manager: ModalManager) -> some View {
        self.modifier(DSAlertModifier(manager: manager))

    }
}
