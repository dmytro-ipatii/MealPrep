//
//  PlanRepairService.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 06/09/2026.
//

import Foundation

/// Deterministic, offline plan repair. Runs before any LLM repair call
/// because these moves are instant, free, and frequently bring a plan into
/// budget on their own.
///
/// Strategies run highest-leverage first (app plan section 11):
/// 1. **Consolidate** — replace a single-use product with one already in the
///    basket from the same category. Often removes an entire package.
/// 2. **Substitute** — a cheaper product from the same category.
/// 3. **Resize** — shrink quantities, but only when that actually crosses an
///    integer package boundary. Anything else just makes meals smaller for no
///    saving, because cost is a step function of packages, not grams.
/// 4. **Simplify** — drop the least structurally important ingredient. Last
///    resort: this is the only strategy that removes food from a meal.
enum PlanRepairService {

    private static let maximumIterations = 200

    /// The most a `resize` is allowed to shrink a product's quantities.
    /// Below this the meal stops resembling what the model designed.
    private static let minimumResizeScale: Double = 0.75

    static func repair(
        _ skeleton: PlanSkeleton,
        candidates: [Product],
        configuration: MealPlanConfiguration,
        skuLimit: Int
    ) -> PlanSkeleton {
        let productsByID = Dictionary(candidates.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })

        var current = skeleton
        let strategies: [(PlanSkeleton, [String: Product], [Product], Int) -> PlanSkeleton?] = [
            consolidate, substitute, resize, simplify,
        ]

        for strategy in strategies {
            var iterations = 0
            while needsCostRepair(current, productsByID: productsByID, configuration: configuration, skuLimit: skuLimit),
                  iterations < maximumIterations {
                iterations += 1
                guard let next = strategy(current, productsByID, candidates, skuLimit), next != current else { break }
                current = next
            }
        }

        return current
    }

    static func needsCostRepair(
        _ skeleton: PlanSkeleton,
        productsByID: [String: Product],
        configuration: MealPlanConfiguration,
        skuLimit: Int
    ) -> Bool {
        let basket = CostCalculator.basket(for: PlanValidator.usages(in: skeleton, productsByID: productsByID))
        return basket.totalCost > configuration.weeklyBudget || basket.skuCount > skuLimit
    }

    // MARK: - 1. Consolidate

    static func consolidate(
        _ skeleton: PlanSkeleton,
        productsByID: [String: Product],
        candidates: [Product],
        skuLimit: Int
    ) -> PlanSkeleton? {
        let counts = usageCounts(in: skeleton)
        let usedIDs = Set(counts.keys)

        // Most expensive single-use product first: dropping that package is
        // the biggest win, and it keeps the cheaper of the two products.
        let singleUse = counts
            .filter { $0.value == 1 }
            .keys
            .compactMap { productsByID[$0] }
            .sorted { ($0.price, $0.id) > ($1.price, $1.id) }

        for product in singleUse {
            let replacements = usedIDs
                .subtracting([product.id])
                .compactMap { productsByID[$0] }
                .filter { $0.categoryID == product.categoryID && $0.price <= product.price }
                .sorted { ($0.price, $0.id) < ($1.price, $1.id) }

            // Cheapest replacement first, but keep trying: the best one may
            // already be in the same meal, and merging onto it would leave
            // that meal with a single ingredient.
            for replacement in replacements {
                let candidate = replacing(product.id, with: replacement.id, in: skeleton)
                if isStructurallySound(candidate) { return candidate }
            }
        }

        return nil
    }

    // MARK: - 2. Substitute

    static func substitute(
        _ skeleton: PlanSkeleton,
        productsByID: [String: Product],
        candidates: [Product],
        skuLimit: Int
    ) -> PlanSkeleton? {
        let usedIDs = Set(usageCounts(in: skeleton).keys)

        // Most expensive first: that is where the saving is.
        let used = usedIDs
            .compactMap { productsByID[$0] }
            .sorted { ($0.price, $0.id) > ($1.price, $1.id) }

        for product in used {
            let cheaperOptions = candidates
                .filter { $0.categoryID == product.categoryID && $0.price < product.price && $0.id != product.id }
                .sorted { ($0.price, $0.id) < ($1.price, $1.id) }

            for cheaper in cheaperOptions {
                let candidate = replacing(product.id, with: cheaper.id, in: skeleton)
                if isStructurallySound(candidate) { return candidate }
            }
        }

        return nil
    }

    // MARK: - 3. Resize

    static func resize(
        _ skeleton: PlanSkeleton,
        productsByID: [String: Product],
        candidates: [Product],
        skuLimit: Int
    ) -> PlanSkeleton? {
        let basket = CostCalculator.basket(for: PlanValidator.usages(in: skeleton, productsByID: productsByID))

        let resizable = basket.lines
            .filter { $0.packages >= 2 }
            .compactMap { line -> (productID: String, scale: Double, saving: Decimal)? in
                let packageSize = line.purchasedQuantity / Double(line.packages)
                let target = Double(line.packages - 1) * packageSize
                guard target > 0 else { return nil }

                let scale = target / line.requiredQuantity
                guard scale >= minimumResizeScale, scale < 1 else { return nil }

                return (line.product.id, scale, line.product.price)
            }
            .sorted { ($0.saving, $0.productID) > ($1.saving, $1.productID) }

        guard let move = resizable.first else { return nil }

        return mapIngredients(skeleton) { ingredient in
            guard ingredient.productID == move.productID else { return ingredient }
            // Round down: rounding up can leave the total a few grams above
            // the package boundary, which buys the package back again and
            // makes the whole move pointless.
            let scaled = max(
                PlanValidator.minimumPlausibleQuantity,
                (ingredient.grams * move.scale).rounded(.down)
            )
            return .init(productID: ingredient.productID, grams: scaled)
        }
    }

    // MARK: - 4. Simplify

    static func simplify(
        _ skeleton: PlanSkeleton,
        productsByID: [String: Product],
        candidates: [Product],
        skuLimit: Int
    ) -> PlanSkeleton? {
        let counts = usageCounts(in: skeleton)

        var best: (dayIndex: Int, slot: MealSlot, productID: String, price: Decimal)?

        for day in skeleton.days {
            for meal in day.meals where meal.ingredients.count >= 3 {
                for ingredient in meal.ingredients {
                    guard counts[ingredient.productID] == 1,
                          let product = productsByID[ingredient.productID]
                    else { continue }

                    if best == nil || (product.price, product.id) > (best!.price, best!.productID) {
                        best = (day.dayIndex, meal.slot, product.id, product.price)
                    }
                }
            }
        }

        guard let best else { return nil }

        return mapMeals(skeleton) { dayIndex, meal in
            guard dayIndex == best.dayIndex, meal.slot == best.slot else { return meal }
            return .init(
                slot: meal.slot,
                name: meal.name,
                prepTimeMinutes: meal.prepTimeMinutes,
                ingredients: meal.ingredients.filter { $0.productID != best.productID },
                pantryItems: meal.pantryItems
            )
        }
    }

    // MARK: - Skeleton editing helpers

    private static func replacing(
        _ productID: String,
        with replacementID: String,
        in skeleton: PlanSkeleton
    ) -> PlanSkeleton {
        mergingDuplicates(
            mapIngredients(skeleton) { ingredient in
                ingredient.productID == productID
                    ? .init(productID: replacementID, grams: ingredient.grams)
                    : ingredient
            }
        )
    }

    /// Repair must not trade a cost violation for a structural one. Merging
    /// two ingredients onto the same product can leave a meal with a single
    /// ingredient, which is its own blocking violation — such a move is not
    /// an improvement and gets rejected.
    private static func isStructurallySound(_ skeleton: PlanSkeleton) -> Bool {
        skeleton.days.allSatisfy { day in
            day.meals.allSatisfy { $0.ingredients.count >= 2 }
        }
    }

    /// Number of meals referencing each product across the whole plan.
    static func usageCounts(in skeleton: PlanSkeleton) -> [String: Int] {
        var counts: [String: Int] = [:]
        for day in skeleton.days {
            for meal in day.meals {
                for productID in Set(meal.ingredients.map(\.productID)) {
                    counts[productID, default: 0] += 1
                }
            }
        }
        return counts
    }

    private static func mapIngredients(
        _ skeleton: PlanSkeleton,
        transform: (PlanSkeleton.Ingredient) -> PlanSkeleton.Ingredient
    ) -> PlanSkeleton {
        mapMeals(skeleton) { _, meal in
            .init(
                slot: meal.slot,
                name: meal.name,
                prepTimeMinutes: meal.prepTimeMinutes,
                ingredients: meal.ingredients.map(transform),
                pantryItems: meal.pantryItems
            )
        }
    }

    private static func mapMeals(
        _ skeleton: PlanSkeleton,
        transform: (Int, PlanSkeleton.Meal) -> PlanSkeleton.Meal
    ) -> PlanSkeleton {
        PlanSkeleton(
            days: skeleton.days.map { day in
                .init(dayIndex: day.dayIndex, meals: day.meals.map { transform(day.dayIndex, $0) })
            }
        )
    }

    /// A rewrite can point two ingredients in one meal at the same product;
    /// merge them so the meal doesn't list the same thing twice.
    private static func mergingDuplicates(_ skeleton: PlanSkeleton) -> PlanSkeleton {
        mapMeals(skeleton) { _, meal in
            var order: [String] = []
            var totals: [String: Double] = [:]

            for ingredient in meal.ingredients {
                if totals[ingredient.productID] == nil { order.append(ingredient.productID) }
                totals[ingredient.productID, default: 0] += ingredient.grams
            }

            return .init(
                slot: meal.slot,
                name: meal.name,
                prepTimeMinutes: meal.prepTimeMinutes,
                ingredients: order.map { .init(productID: $0, grams: totals[$0] ?? 0) },
                pantryItems: meal.pantryItems
            )
        }
    }
}
