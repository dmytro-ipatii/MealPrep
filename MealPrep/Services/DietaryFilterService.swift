//
//  DietaryFilterService.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 06/09/2026.
//

/// Safety-critical, deterministic dietary filtering. A pure function over
/// `[Product]` with no I/O — see `DietRule` for the rule definitions.
///
/// Runs before candidate selection so the model physically cannot select an
/// unsafe product, and again in `PlanValidator` as a backstop. When multiple
/// dietary needs are active, rules compose as an intersection.
enum DietaryFilterService {

    static func filter(_ products: [Product], for needs: Set<DietaryNeed>) -> [Product] {
        guard !needs.isEmpty else { return products }

        let rules = needs.map(DietRule.rule(for:))

        return products.filter { product in
            rules.allSatisfy { $0.allows(product) }
        }
    }

    static func isSafe(_ product: Product, for need: DietaryNeed) -> Bool {
        DietRule.rule(for: need).allows(product)
    }
}
