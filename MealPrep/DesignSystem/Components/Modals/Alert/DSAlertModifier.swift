//
//  DSAlertModifier.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 06/09/2026.
//

import SwiftUI

public struct DSAlertModifier: ViewModifier {

    @Bindable var manager: ModalManager

    public func body(content: Content) -> some View {
        ZStack {
            content

            ZStack {

                if let content = manager.content {

                    Color.black.opacity(0.25)
                        .ignoresSafeArea(.all)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .transition(
                            .asymmetric(
                                insertion: .opacity.animation(
                                    .linear
                                ),
                                removal: .opacity.animation(
                                    .linear.delay(
                                        0.1
                                    )
                                )
                            )
                        )
                        .onTapGesture {
                            manager.dismiss()
                        }

                    DSAlertContentView(content: content)
                        .transition(
                            .scale(scale: 0.9)
                            .combined(with: .opacity)
                        )
                        .zIndex(999999)

                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.spring(
                response: 0.3,
                dampingFraction: 0.8
            ), value: manager.content != nil)
        }

    }
}
