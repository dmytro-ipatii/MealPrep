//
//  DietRule.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 06/09/2026.
//

/// A safety-critical, deterministic rule for one `DietaryNeed`.
///
/// The catalog is Open Food Facts-derived: an empty `allergens` array does not
/// mean a product is allergen-free, it usually means nobody filled in the
/// field. Unknown is not safe, which is why `riskyCategoryPrefixes` exists —
/// a risky category is excluded unless a label positively confirms safety.
///
/// Category matching uses `hasPrefix` rather than exact equality so a future,
/// more hierarchical taxonomy (e.g. `en:dairy:cheeses`) keeps working; today's
/// catalog category IDs are flat, so most prefixes are effectively exact IDs.
struct DietRule: Sendable {
    let forbiddenAllergenIDs: Set<String>
    let forbiddenCategoryPrefixes: [String]
    let forbiddenDepartmentIDs: Set<String>
    let requiredLabelIDs: Set<String>
    let riskyCategoryPrefixes: [String]

    func allows(_ product: Product) -> Bool {
        if !forbiddenAllergenIDs.isDisjoint(with: product.allergenIDs) {
            return false
        }

        if forbiddenDepartmentIDs.contains(product.departmentID) {
            return false
        }

        if forbiddenCategoryPrefixes.contains(where: product.categoryID.hasPrefix) {
            return false
        }

        if riskyCategoryPrefixes.contains(where: product.categoryID.hasPrefix) {
            return !requiredLabelIDs.isDisjoint(with: product.labelIDs)
        }

        return true
    }
}

extension DietRule {

    static func rule(for need: DietaryNeed) -> DietRule {
        switch need {
        case .vegetarian: .vegetarian
        case .vegan: .vegan
        case .pescatarian: .pescatarian
        case .glutenFree: .glutenFree
        case .dairyFree: .dairyFree
        }
    }

    /// No meat, poultry, fish, or seafood. Fish/meat allergens are a reliable
    /// hard signal; the rest relies on category and department, since "meat"
    /// is not itself an allergen field in the catalog.
    static let vegetarian = DietRule(
        forbiddenAllergenIDs: ["en:fish", "en:crustaceans", "en:molluscs"],
        forbiddenCategoryPrefixes: [
            "en:meats", "en:poultries", "en:hams", "en:sausages", "en:prepared-meats",
            "en:fishes", "en:canned-fishes", "en:seafood",
        ],
        forbiddenDepartmentIDs: ["carne", "salumi", "pesce"],
        requiredLabelIDs: ["en:vegetarian", "en:vegan"],
        riskyCategoryPrefixes: [
            "en:soups", "en:sauces", "en:tomato-sauces", "en:frozen-pizzas", "en:frozen-foods",
            "en:snacks", "en:crackers", "en:appetizers", "en:salads", "en:canned-foods",
        ]
    )

    /// Vegetarian plus fish and seafood.
    static let pescatarian = DietRule(
        forbiddenAllergenIDs: [],
        forbiddenCategoryPrefixes: [
            "en:meats", "en:poultries", "en:hams", "en:sausages", "en:prepared-meats",
        ],
        forbiddenDepartmentIDs: ["carne", "salumi"],
        requiredLabelIDs: ["en:vegetarian", "en:vegan"],
        riskyCategoryPrefixes: [
            "en:soups", "en:sauces", "en:tomato-sauces", "en:frozen-pizzas", "en:frozen-foods",
            "en:snacks", "en:crackers", "en:appetizers", "en:salads", "en:canned-foods",
        ]
    )

    /// No animal products at all. Worked example from the app plan: require
    /// `en:vegan` on anything processed; allow unlabelled products only from
    /// inherently plant-based categories.
    static let vegan = DietRule(
        forbiddenAllergenIDs: [
            "en:milk", "en:eggs", "en:fish", "en:crustaceans", "en:molluscs",
        ],
        forbiddenCategoryPrefixes: [
            "en:cheeses", "en:yogurts", "en:butters", "en:milks", "en:creams", "en:ice-creams",
            "en:dairies", "en:baby-milks", "en:eggs", "en:honeys",
            "en:meats", "en:poultries", "en:hams", "en:sausages", "en:prepared-meats",
            "en:fishes", "en:canned-fishes", "en:seafood",
        ],
        forbiddenDepartmentIDs: ["carne", "salumi", "pesce", "latticini"],
        requiredLabelIDs: ["en:vegan"],
        riskyCategoryPrefixes: [
            "en:breakfast-cereals", "en:biscuits", "en:soups", "en:chocolates", "en:sauces",
            "en:tomato-sauces", "en:breads", "en:snacks", "en:cakes", "en:crackers",
            "en:condiments", "en:confectioneries", "en:frozen-pizzas", "en:frozen-foods",
            "en:crisps", "en:spreads", "en:rusks", "en:salty-snacks", "en:appetizers",
            "en:salads", "en:dietary-supplements", "en:baby-foods", "en:meat-alternatives",
            "en:canned-foods",
        ]
    )

    /// Worked example from the app plan: exclude the milk allergen and the
    /// dairy department/categories outright; require a positive `en:no-milk`
    /// or `en:vegan` label on risky processed categories.
    static let dairyFree = DietRule(
        forbiddenAllergenIDs: ["en:milk"],
        forbiddenCategoryPrefixes: [
            "en:cheeses", "en:yogurts", "en:butters", "en:milks", "en:creams", "en:ice-creams",
            "en:dairies", "en:baby-milks",
        ],
        forbiddenDepartmentIDs: ["latticini"],
        requiredLabelIDs: ["en:no-milk", "en:vegan"],
        riskyCategoryPrefixes: [
            "en:biscuits", "en:cakes", "en:chocolates", "en:desserts", "en:sauces",
            "en:tomato-sauces", "en:soups", "en:breads", "en:crackers", "en:confectioneries",
            "en:frozen-pizzas", "en:frozen-foods", "en:prepared-meats", "en:spreads", "en:rusks",
            "en:snacks", "en:crisps", "en:salty-snacks", "en:condiments", "en:baby-foods",
            "en:meat-alternatives", "en:dietary-supplements",
        ]
    )

    /// No gluten. The catalog has no `en:gluten-free` label, so every risky
    /// category is excluded unless that changes — matching the plan's
    /// "unknown is not safe" principle.
    static let glutenFree = DietRule(
        forbiddenAllergenIDs: ["en:gluten"],
        forbiddenCategoryPrefixes: [
            "en:breads", "en:pastas", "en:biscuits", "en:cakes", "en:crackers", "en:rusks",
            "en:couscous", "en:frozen-pizzas", "en:beers",
        ],
        forbiddenDepartmentIDs: [],
        requiredLabelIDs: ["en:gluten-free"],
        riskyCategoryPrefixes: [
            "en:flours", "en:breakfast-cereals", "en:sauces", "en:tomato-sauces", "en:soups",
            "en:condiments", "en:confectioneries", "en:chocolates", "en:desserts", "en:snacks",
            "en:crisps", "en:salty-snacks", "en:frozen-foods", "en:prepared-meats",
            "en:sausages", "en:spreads", "en:dietary-supplements", "en:baby-foods",
            "en:meat-alternatives", "en:ice-creams", "en:appetizers", "en:salads",
            "en:canned-foods",
        ]
    )
}
