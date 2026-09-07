//
//  ConfigurationStore.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 06/09/2026.
//

import Foundation
import SwiftData

@MainActor
protocol ConfigurationStoring {
    func loadConfiguration() -> MealPlanConfiguration?
    func save(_ configuration: MealPlanConfiguration)
}

@MainActor
final class SwiftDataConfigurationStore: ConfigurationStoring {

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func loadConfiguration() -> MealPlanConfiguration? {
        let descriptor = FetchDescriptor<StoredConfiguration>()
        return try? modelContext.fetch(descriptor).first?.asConfiguration
    }

    func save(_ configuration: MealPlanConfiguration) {
        let descriptor = FetchDescriptor<StoredConfiguration>()

        if let existing = try? modelContext.fetch(descriptor).first {
            existing.update(with: configuration)
        } else {
            modelContext.insert(StoredConfiguration(configuration: configuration))
        }

        try? modelContext.save()
    }
}

#if DEBUG
@MainActor
final class PreviewConfigurationStore: ConfigurationStoring {
    private var configuration: MealPlanConfiguration?

    init(configuration: MealPlanConfiguration? = nil) {
        self.configuration = configuration
    }

    func loadConfiguration() -> MealPlanConfiguration? { configuration }

    func save(_ configuration: MealPlanConfiguration) {
        self.configuration = configuration
    }
}
#endif
