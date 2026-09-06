//
//  PlanSkeletonPromptBuilder.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 06/09/2026.
//

import Foundation

/// Builds the Pass A prompt. Kept separate from `MacPawLLMClient` so the
/// prompt text can be unit tested without a network call or an `OpenAI`
/// dependency.
enum PlanSkeletonPromptBuilder {

    static func systemPrompt() -> String {
        """
        You are a meal planning assistant. You combine grocery products into \
        realistic, appealing meals and never invent products or quantities. \
        You never perform budget arithmetic yourself — a deterministic system \
        validates cost and nutrition after you respond, so favor variety and \
        realism over trying to hit an exact number.
        """
    }

    static func userPrompt(for request: PlanSkeletonRequest) -> String {
        var sections: [String] = []

        sections.append(taskDescription(for: request))
        sections.append(constraintsDescription(for: request))
        sections.append(perSlotExpectations())
        sections.append(candidateProductsListing(request.candidates))

        return sections.joined(separator: "\n\n")
    }

    // MARK: - Sections

    private static func taskDescription(for request: PlanSkeletonRequest) -> String {
        let dayLabel = request.dayCount == 1 ? "1 day" : "\(request.dayCount) days"
        let firstIndex = request.startingDayIndex
        let lastIndex = request.startingDayIndex + request.dayCount - 1
        let dayIndexRange = firstIndex == lastIndex ? "\(firstIndex)" : "\(firstIndex)-\(lastIndex)"

        return """
        Generate a meal plan skeleton for \(dayLabel) (dayIndex \(dayIndexRange)), \
        each with breakfast, lunch, and dinner. For every meal, choose products \
        only from the candidate list below and specify the quantity of each in \
        grams (or millilitres for liquids). Do not write recipe steps yet — \
        only the structural skeleton.
        """
    }

    private static func constraintsDescription(for request: PlanSkeletonRequest) -> String {
        let configuration = request.configuration
        let skuBudget = skuBudget(for: request.dayCount)
        let targetSpend = (configuration.weeklyBudget * Decimal(request.dayCount) / 7 * Decimal(0.85))
        let budgetLine = "The full week's budget is \(configuration.weeklyBudget) \(configuration.currencyCode); "
            + "aim to use about \(targetSpend) \(configuration.currencyCode) for this \(request.dayCount == 1 ? "day" : "\(request.dayCount)-day span") "
            + "(roughly 85% — leave headroom for repair)."

        var lines = [
            "Constraints:",
            "- Use at most \(skuBudget) distinct products across this plan. Reusing the same product across meals and days is encouraged and keeps cost down.",
            "- Every product costs its full package price regardless of how much of it you use — buying one product is far cheaper than buying five.",
            budgetLine,
            "- Only use productID values that appear in the candidate list. Do not invent products.",
            "- pantryItems must only be values from this list: \(PantryStaple.allCases.map(\.rawValue).joined(separator: ", ")). They are free and already owned — do not also list them as priced ingredients.",
            "- Evaluate nutritional goals per day, not per meal — a single high-protein meal does not need to carry the whole day's protein target.",
        ]

        if !configuration.dietaryNeeds.isEmpty {
            lines.append("- Active dietary needs: \(configuration.dietaryNeeds.map(\.rawValue).sorted().joined(separator: ", ")). Every candidate product already satisfies these, so any product on the list is safe to use.")
        }

        if !configuration.goals.isEmpty {
            lines.append("- Active nutritional goals: \(configuration.goals.map(\.rawValue).sorted().joined(separator: ", ")).")
        }

        return lines.joined(separator: "\n")
    }

    private static func perSlotExpectations() -> String {
        """
        Per-slot expectations:
        - breakfast: at most 10 minutes prep, 2-4 ingredients
        - lunch: at most 25 minutes prep, 3-6 ingredients
        - dinner: at most 45 minutes prep, 5-7 ingredients
        """
    }

    private static func candidateProductsListing(_ candidates: [Product]) -> String {
        let lines = candidates.map { product -> String in
            "\(product.id) | \(product.name) | \(product.categoryID) | \(quantityDescription(product.baseQuantity)) | \(product.price) EUR"
        }
        return "Candidate products (id | name | category | quantity | price):\n" + lines.joined(separator: "\n")
    }

    private static func quantityDescription(_ baseQuantity: BaseQuantity) -> String {
        switch baseQuantity {
        case .mass(let grams): "\(grams.formatted()) g"
        case .volume(let milliliters): "\(milliliters.formatted()) ml"
        case .count(let count): "\(count) ct"
        }
    }

    private static func skuBudget(for dayCount: Int) -> Int {
        max(6, Int((Double(dayCount) / 7.0 * 28).rounded()))
    }
}
