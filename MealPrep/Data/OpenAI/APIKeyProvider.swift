//
//  APIKeyProvider.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 06/09/2026.
//

import Foundation

/// Reads the OpenAI key injected from the gitignored `Secrets.xcconfig` via
/// `Info.plist`. Never written into a Swift file, a plist committed to git,
/// or a test fixture — see `MealPrep/Configs/Secrets.xcconfig`.
///
/// A backend proxy is the right answer for a shipping app; this is
/// acceptable only because MealPrep is a local demo.
enum APIKeyProvider {
    static func openAIAPIKey(bundle: Bundle = .main) throws -> String {
        guard
            let key = bundle.infoDictionary?["OPEN_AI_API_KEY"] as? String,
            !key.isEmpty
        else {
            throw MealPlanLLMError.missingAPIKey
        }
        return key
    }
}
