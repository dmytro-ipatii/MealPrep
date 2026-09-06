//
//  MealPrepApp.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 05/09/2026.
//

import SwiftUI
import SwiftData
import OpenAI

@main
struct MealPrepApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            ContentView(
                configurationStore: delegate.dependencies.configurationStore,
                generator: delegate.dependencies.mealPlanGenerator,
                mealPlanRepository: delegate.dependencies.mealPlanRepository
            )
            .environment(delegate.dependencies.modalManager)
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {

    var dependencies: Dependencies!

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        self.dependencies = Dependencies()
        return true
    }
}


@MainActor
struct Dependencies {
    let modalManager: ModalManager
    let modelContainer: ModelContainer
    let configurationStore: ConfigurationStoring
    let mealPlanRepository: MealPlanRepositoryProtocol
    let mealPlanGenerator: MealPlanGenerator

    init() {
        self.modalManager = ModalManager()

        do {
            self.modelContainer = try ModelContainer(
                for: StoredConfiguration.self, StoredMealPlan.self
            )
        } catch {
            preconditionFailure("Failed to create SwiftData ModelContainer: \(error)")
        }

        let context = ModelContext(modelContainer)
        self.configurationStore = SwiftDataConfigurationStore(modelContext: context)
        self.mealPlanRepository = SwiftDataMealPlanRepository(modelContext: context)

        // A shipping app needs a backend proxy for this; a bundled key is
        // acceptable only because MealPrep is a local demo.
        let apiKey = (try? APIKeyProvider.openAIAPIKey()) ?? ""
        self.mealPlanGenerator = MealPlanGenerator(
            client: MacPawLLMClient(client: OpenAI(apiToken: apiKey))
        )
    }
}
