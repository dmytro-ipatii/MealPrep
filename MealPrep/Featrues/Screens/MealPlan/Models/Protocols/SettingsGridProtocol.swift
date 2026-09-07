//
//  SettingsGridProtocol.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 05/09/2026.
//


protocol SettingsGridProtocol: Identifiable, Equatable {
    var id: Self {get}

    var label: String {get}
    var emoji: String {get}
}
