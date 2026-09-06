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

    /// Asks for a minimal edit to a plan that failed validation. Regenerating
    /// from scratch would throw away the days that already validated and is
    /// far more likely to introduce brand new violations.
    static func repairPrompt(for request: PlanRepairRequest) -> String {
        let violations = request.violations
            .map { "- \($0.description)" }
            .joined(separator: "\n")

        let previousPlan = encodedSkeleton(request.skeleton)

        return """
        The plan below failed validation. Fix ONLY the listed problems by making \
        the smallest possible edit. Keep every meal that is not implicated — do \
        not regenerate the plan, do not renumber days, and do not rename meals \
        you are not changing.

        Problems to fix:
        \(violations)

        How to fix cost problems, in order of preference:
        1. Replace a product used in only one meal with a product already used \
        elsewhere in the plan from the same category — that removes a whole package.
        2. Swap a product for a cheaper one in the same category.
        3. Reduce quantities, but only where that drops a whole package.
        4. Only as a last resort, remove an ingredient from a meal that still \
        has at least 2 priced ingredients left.

        Current plan:
        \(previousPlan)

        \(constraintsDescription(for: request))

        \(candidateProductsListing(request.candidates))
        """
    }

    private static func encodedSkeleton(_ skeleton: PlanSkeleton) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        guard let data = try? encoder.encode(skeleton) else { return "{}" }
        return String(decoding: data, as: UTF8.self)
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
        constraintsDescription(
            configuration: request.configuration,
            dayCount: request.dayCount,
            skuBudget: skuBudget(for: request.dayCount)
        )
    }

    private static func constraintsDescription(for request: PlanRepairRequest) -> String {
        constraintsDescription(
            configuration: request.configuration,
            dayCount: request.skeleton.days.count,
            skuBudget: request.skuLimit
        )
    }

    private static func constraintsDescription(
        configuration: MealPlanConfiguration,
        dayCount: Int,
        skuBudget: Int
    ) -> String {
        let targetSpend = (configuration.weeklyBudget * Decimal(dayCount) / 7 * Decimal(0.85))
        let budgetLine = "The full week's budget is \(configuration.weeklyBudget) \(configuration.currencyCode); "
            + "aim to use about \(targetSpend) \(configuration.currencyCode) for this \(dayCount == 1 ? "day" : "\(dayCount)-day span") "
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

    /// The distinct-product ceiling. Shared with `PlanValidator` so the plan
    /// is judged against the same number the prompt asked for — models handle
    /// a discrete count far more reliably than a running currency total.
    static func skuBudget(for dayCount: Int) -> Int {
        max(6, Int((Double(dayCount) / 7.0 * 28).rounded()))
    }
}
