//
//  ModalManager.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 06/09/2026.
//

import SwiftUI

@MainActor
@Observable
public class ModalManager {
    var content: ModalContent?

    public init() {
    }

    func present(content: ModalContent?) {
        self.content = content
    }

    func dismiss() {
        self.content = nil
    }
}
