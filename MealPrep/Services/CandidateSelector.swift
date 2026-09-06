//
//  CandidateSelector.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 06/09/2026.
//

/// Narrows a (dietary-filtered, goal-ranked) product list down to a shortlist
/// small enough to send to the model — target 100–150 products.
///
/// A pure top-N on the goal score returns, say, 120 vegetables and no protein
/// source: the plan becomes seven days of salad. Instead this takes the top
/// *k* scored products **per department**, then backfills any remaining slots
/// with the next-highest-scoring products overall, so the shortlist can
/// compose balanced meals.
enum CandidateSelector {

    static let defaultTargetCount = 130

    static func select(
        from products: [Product],
        scores: [String: Double],
        targetCount: Int = defaultTargetCount
    ) -> [Product] {
        guard !products.isEmpty else { return [] }

        let productsByDepartment = Dictionary(grouping: products, by: \.departmentID)
        guard !productsByDepartment.isEmpty else { return [] }

        let quotaPerDepartment = max(1, targetCount / productsByDepartment.count)

        var selectedIDs = Set<String>()
        var selected: [Product] = []

        for departmentProducts in productsByDepartment.values {
            let ranked = rankedByScore(departmentProducts, scores: scores)
            for product in ranked.prefix(quotaPerDepartment) where selectedIDs.insert(product.id).inserted {
                selected.append(product)
            }
        }

        if selected.count < targetCount {
            let remaining = rankedByScore(products.filter { !selectedIDs.contains($0.id) }, scores: scores)
            for product in remaining {
                guard selected.count < targetCount else { break }
                if selectedIDs.insert(product.id).inserted {
                    selected.append(product)
                }
            }
        }

        return rankedByScore(selected, scores: scores)
    }

    private static func rankedByScore(_ products: [Product], scores: [String: Double]) -> [Product] {
        products.sorted { (scores[$0.id] ?? 0) > (scores[$1.id] ?? 0) }
    }
}
