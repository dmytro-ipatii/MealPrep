//
//  GoalRankingService.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 06/09/2026.
//

import Foundation

/// Scores products against active nutritional goals plus a package-efficiency
/// term. A pure function over `[Product]` — no I/O. Scores are 0...1, higher
/// is always better; nutritional goals are soft preferences, not exclusions.
///
/// Every metric is normalized **within its category** first (compare yoghurts
/// to yoghurts, not yoghurt to olive oil), then averaged across the active
/// goals and the package-efficiency signal.
enum GoalRankingService {

    static func score(_ products: [Product], for goals: Set<NutritionalGoal>) -> [String: Double] {
        guard !products.isEmpty else { return [:] }

        let productsByCategory = Dictionary(grouping: products, by: \.categoryID)

        let goalSignals: [NutritionalGoal: [String: Double]] = Dictionary(
            uniqueKeysWithValues: goals.map { goal in
                (goal, normalizedSignal(for: goal, productsByCategory: productsByCategory))
            }
        )

        let efficiencySignal = packageEfficiencySignal(productsByCategory: productsByCategory)

        var scores: [String: Double] = [:]
        for product in products {
            var components = goals.compactMap { goalSignals[$0]?[product.id] }
            if let efficiency = efficiencySignal[product.id] {
                components.append(efficiency)
            }
            scores[product.id] = components.isEmpty ? 0.5 : components.reduce(0, +) / Double(components.count)
        }
        return scores
    }

    // MARK: - Nutritional goal signals

    private static func normalizedSignal(
        for goal: NutritionalGoal,
        productsByCategory: [String: [Product]]
    ) -> [String: Double] {
        var signal: [String: Double] = [:]

        for products in productsByCategory.values {
            let metrics = products.map { (id: $0.id, value: rawMetric(for: goal, product: $0)) }
            applyMinMaxNormalization(metrics, higherIsBetter: goal.prefersHigherRawValue, into: &signal)
        }

        return signal
    }

    private static func rawMetric(for goal: NutritionalGoal, product: Product) -> Double {
        let nutrition = product.nutrition
        switch goal {
        case .highProtein:
            let proteinPerKcal = nutrition.energyKcal > 0 ? nutrition.proteins / nutrition.energyKcal : 0
            return nutrition.proteins + proteinPerKcal * 100
        case .lowSugar:
            return nutrition.sugars
        case .lowFat:
            return nutrition.fat + nutrition.saturatedFat
        case .lowCarbs:
            return nutrition.carbohydrates
        case .lowSalt:
            return nutrition.salt
        }
    }

    // MARK: - Package efficiency

    /// The catalog has no serving-size field, so a realistic single-serving
    /// portion is a documented demo-grade assumption rather than a derived
    /// value: ~150 g for solids, ~200 ml for liquids.
    private static let referencePortionGrams: Double = 150
    private static let referencePortionMilliliters: Double = 200

    /// Cost of one portion of this product if it's used `occurrences` times
    /// across the week — whole-package costing means buying more occurrences
    /// spreads the package price over more portions, up to the next package
    /// boundary.
    private static func costPerPortion(_ product: Product, occurrences: Int) -> Double {
        let price = NSDecimalNumber(decimal: product.price).doubleValue
        let portions = Double(occurrences)

        let packages: Double
        switch product.baseQuantity {
        case .mass(let grams):
            packages = grams > 0 ? (portions * referencePortionGrams / grams).rounded(.up) : 1
        case .volume(let milliliters):
            packages = milliliters > 0 ? (portions * referencePortionMilliliters / milliliters).rounded(.up) : 1
        case .count(let count):
            packages = count > 0 ? (portions / Double(count)).rounded(.up) : 1
        }

        return max(packages, 1) * price / portions
    }

    private static func packageEfficiencySignal(
        productsByCategory: [String: [Product]]
    ) -> [String: Double] {
        var signal: [String: Double] = [:]

        for products in productsByCategory.values {
            let metrics = products.map { product -> (id: String, value: Double) in
                let costAtK1 = costPerPortion(product, occurrences: 1)
                let costAtK3 = costPerPortion(product, occurrences: 3)
                return (product.id, (costAtK1 + costAtK3) / 2)
            }

            // Cheaper cost-per-portion scores higher.
            applyMinMaxNormalization(metrics, higherIsBetter: false, into: &signal)
        }

        return signal
    }

    // MARK: - Shared normalization

    private static func applyMinMaxNormalization(
        _ metrics: [(id: String, value: Double)],
        higherIsBetter: Bool,
        into signal: inout [String: Double]
    ) {
        let values = metrics.map(\.value)
        guard let low = values.min(), let high = values.max(), high > low else {
            metrics.forEach { signal[$0.id] = 0.5 }
            return
        }

        for metric in metrics {
            let normalized = (metric.value - low) / (high - low)
            signal[metric.id] = higherIsBetter ? normalized : 1 - normalized
        }
    }
}

private extension NutritionalGoal {
    var prefersHigherRawValue: Bool {
        self == .highProtein
    }
}
