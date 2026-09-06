//
//  ModalContent.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 06/09/2026.
//

import SwiftUI

public struct ModalButton: Sendable, Identifiable {
    let label: String
    let variant: DSButtonVariant
    let action: @MainActor () -> Void

    public var id: String {
        "\(label)_\(UUID().uuidString)"
    }
}

public struct ModalContent: Sendable, Equatable {

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.title != rhs.title
        && lhs.message != rhs.message
    }

    let title: String
    let message: String?
    let buttons: [ModalButton]

    init(
        title: String,
        message: String? = nil,
        buttons: [ModalButton] = []
    ) {
        self.title = title
        self.message = message
        self.buttons = buttons
    }

}
