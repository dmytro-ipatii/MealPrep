//
//  MealPrepApp.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 05/09/2026.
//

import SwiftUI

@main
struct MealPrepApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            ContentView()
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

    init() {
        self.modalManager = ModalManager()
    }
}
