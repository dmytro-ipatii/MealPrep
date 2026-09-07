//
//  WeekDay.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 06/09/2026.
//

import SwiftUI

enum WeekDay: CaseIterable, Identifiable, Hashable {
    var id: Self {self}

    case monday
    case tuesday
    case wednesday
    case thursday
    case friday
    case saturday
    case sunday

    init?(date: Date, calendar: Calendar = .current) {
        switch calendar.component(.weekday, from: date) {
        case 1: self = .sunday
        case 2: self = .monday
        case 3: self = .tuesday
        case 4: self = .wednesday
        case 5: self = .thursday
        case 6: self = .friday
        case 7: self = .saturday
        default: return nil
        }
    }

    var abbreviation: String {
        switch self {
        case .monday: return "Mon"
        case .tuesday: return "Tue"
        case .wednesday: return "Wed"
        case .thursday: return "Thu"
        case .friday: return "Fri"
        case .saturday: return "Sat"
        case .sunday: return "Sun"
        }
    }

    var name: String {
        switch self {
        case .monday: "Monday"
        case .tuesday: "Tuesday"
        case .wednesday: "Wednesday"
        case .thursday: "Thursday"
        case .friday: "Friday"
        case .saturday: "Saturday"
        case .sunday: "Sunday"
        }
    }

    /// Plans are generated as day 0...6 starting Monday, so the picker's day
    /// maps straight onto `PlanDay.dayIndex`.
    var dayIndex: Int {
        Self.allCases.firstIndex(of: self) ?? 0
    }
}
