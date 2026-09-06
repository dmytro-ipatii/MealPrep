//
//  MealPrepApp.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 05/09/2026.
//

import SwiftUI
import SwiftData

@main
struct MealPrepApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            ContentView(configurationStore: delegate.dependencies.configurationStore)
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

    init() {
        self.modalManager = ModalManager()

        do {
            self.modelContainer = try ModelContainer(for: StoredConfiguration.self)
        } catch {
            preconditionFailure("Failed to create SwiftData ModelContainer: \(error)")
        }

        self.configurationStore = SwiftDataConfigurationStore(
            modelContext: ModelContext(modelContainer)
        )
    }
}
