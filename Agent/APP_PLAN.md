# MealPrep — App Plan (North Star)

> This document is the authoritative specification. When code and this document
> disagree, this document wins — or the document gets updated first, deliberately.
> Do not silently deviate. If a decision here turns out to be wrong, say so and
> propose an amendment.

---

## 1. What this app is

An iOS demo app (Swift + SwiftUI) that generates a 7-day meal plan tailored to a
user's weekly grocery budget, dietary needs, and nutritional goals. Products come
from a bundled local catalog. Meal composition and recipe text come from the
OpenAI API. Everything is persisted locally with SwiftData. There is no account
system, no authentication, and no backend.

### Screens (UI already exists)

1. **Lander** — welcome screen, entry point for new users
2. **Budget settings** — weekly budget to spend on products
3. **Dietary needs** — multi-select: veggie, vegan, pescatarian, gluten free, dairy free
4. **Nutritional goal** — multi-select: high protein, low sugar, low fat, low carbs, low salt
5. **Meal plan** — the generated 7-day result

### Deliverable per day

Three meals (breakfast, lunch, dinner), each with:

- Meal name, preparation time, servings, cost
- Ingredient list (product name + quantity used in this meal)
- Recipe text: step-by-step preparation guide

---

## 2. Locked decisions

These are settled. Do not re-litigate them mid-implementation.

| Decision | Value |
| --- | --- |
| Meals per day | 3 — breakfast, lunch, dinner |
| Days per plan | 7 |
| Servings | 1 (multi-serving is a future feature; do not build it now) |
| Budget accounting | **Whole packages.** Using 200 ml from a 1 L carton costs the full carton price. |
| Pantry staples | Assumed already owned. Free, excluded from the budget and the shopping list. |
| Persistence | SwiftData, local only |
| Minimum iOS | 17.0 (SwiftData requirement) |
| Product data | Bundled `product_catalog_en.json`, read-only |
| AI provider | OpenAI via the MacPaw/OpenAI Swift package (SPM) |

### The governing principle

**The LLM proposes, Swift disposes.**

Anything that must be *correct* — allergen exclusions, dietary filtering, budget
arithmetic, nutritional totals — is computed deterministically in Swift and unit
tested. The model is used only for what it is actually good at: combining
available ingredients into plausible meals and writing readable recipes.

Never ask the model to do arithmetic. Never trust the model to enforce a dietary
restriction. Both are enforced before and after the call.

---

## 3. Architecture

```
ConfigurationStore (SwiftData)
        │
        ▼
ProductCatalogLoader ──────► [Product]        (normalize units, drop unusable rows)
        │
        ▼
DietaryFilterService        (hard exclusions — safety critical, deterministic)
        │
        ▼
GoalRankingService          (score candidates against active nutritional goals)
        │
        ▼
CandidateSelector           (~100–150 products, department quotas for diversity)
        │
        ▼
FeasibilityChecker          (is this budget achievable at all? fail fast)
        │
        ▼
MealPlanGenerator  ── Pass A ──► plan skeleton (meals + productIDs + grams)
        │                              │
        │                              ▼
        │                       PlanValidator + CostCalculator
        │                              │
        │                       deterministic repair → LLM repair (max 2)
        │                              │
        └────────── Pass B ──────► recipes, 7 parallel calls, one per day
                                       │
                                       ▼
                            MealPlanRepository (SwiftData)
```

### Why two passes

Generating 21 meals *and* 21 recipes in one response is slow, prone to
truncation, and wastes tokens when validation fails. Pass A returns a compact
structural skeleton that is cheap to validate and repair. Only once the plan is
valid does Pass B spend tokens on prose — and those seven calls run concurrently.

### Layer rules

- The catalog JSON shape must not leak past `ProductCatalogLoader`.
- SwiftData `@Model` classes must not leak into service signatures. Services take
  and return plain `Sendable` structs.
- The pipeline depends on `MealPlanLLMClient` (a protocol), never on MacPaw types
  directly. Steps 1–5 of the build order must be fully testable with a stub client
  and no network.

---

## 4. Module map

```
MealPrep/
├── App/                        entry point, DI container
├── Features/                   existing SwiftUI screens (+ MealPlan screen)
│   ├── Lander/
│   ├── BudgetSettings/
│   ├── DietaryNeeds/
│   ├── NutritionalGoals/
│   └── MealPlan/
├── Domain/
│   ├── Models/                 Product, Nutrition, MealPlan, Meal, Recipe, Basket
│   ├── Configuration/          DietaryNeed, NutritionalGoal, MealSlot, PantryStaple
│   └── Errors/                 GenerationError, PlanViolation
├── Data/
│   ├── Catalog/                ProductCatalogLoader, ProductDTO, UnitNormalizer
│   ├── Persistence/            SwiftData @Model types, MealPlanRepository
│   └── OpenAI/                 MealPlanLLMClient + MacPawLLMClient, prompt builders
├── Services/
│   ├── DietaryFilterService
│   ├── GoalRankingService
│   ├── CandidateSelector
│   ├── FeasibilityChecker
│   ├── CostCalculator
│   ├── PlanValidator
│   ├── PlanRepairService
│   └── MealPlanGenerator       (actor, orchestrates the pipeline)
└── Resources/
    └── product_catalog_en.json
```

---

## 5. Data contracts

### 5.1 Catalog DTO

Mirrors `product_catalog_en.json` exactly. `Decodable` only. No business logic.

```swift
struct ProductDTO: Decodable {
    let id: String
    let barcode: String?
    let name: String
    let brand: String?
    let department: TaxonomyRefDTO
    let category: TaxonomyRefDTO
    let quantity: String?
    let netContent: NetContentDTO      // { value: Double, unit: String }
    let price: PriceDTO                // { amount: Double, currency: String }
    let unitPrice: UnitPriceDTO?
    let nutrition: NutritionDTO        // all per 100 g/ml
    let nutriScore: String?
    let novaGroup: Int?
    let labels: [TaxonomyRefDTO]
    let allergens: [TaxonomyRefDTO]
}
```

### 5.2 Domain model

```swift
struct Product: Identifiable, Sendable, Hashable {
    let id: String
    let name: String
    let departmentID: String
    let categoryID: String
    let baseQuantity: BaseQuantity      // normalized: .mass(grams) / .volume(ml) / .count(n)
    let price: Decimal
    let nutrition: Nutrition            // per 100 g/ml
    let labelIDs: Set<String>
    let allergenIDs: Set<String>
}
```

**Unit normalization is mandatory at load time.** Everything downstream works in
grams, millilitres, or counts — never the raw `"1 l"` string. A product whose
`netContent` cannot be normalized is logged and excluded from the candidate pool
rather than silently mishandled.

### 5.3 Configuration

```swift
enum DietaryNeed: String, Codable, CaseIterable, Sendable {
    case vegetarian, vegan, pescatarian, glutenFree, dairyFree
}

enum NutritionalGoal: String, Codable, CaseIterable, Sendable {
    case highProtein, lowSugar, lowFat, lowCarbs, lowSalt
}

enum MealSlot: String, Codable, CaseIterable, Sendable {
    case breakfast, lunch, dinner
}
```

### 5.4 SwiftData models

Separate classes from the domain structs. Snapshot product name and price into
the stored ingredient so an old plan still renders if the catalog file changes.

```swift
@Model final class StoredConfiguration {
    var weeklyBudget: Decimal
    var currencyCode: String
    var dietaryNeedsRaw: [String]
    var goalsRaw: [String]
    var servings: Int
    var createdAt: Date
}

@Model final class StoredMealPlan {
    var generatedAt: Date
    var totalCost: Decimal
    var totalWasteGrams: Double
    @Relationship(deleteRule: .cascade) var days: [StoredPlanDay]
    @Relationship(deleteRule: .cascade) var basket: [StoredBasketLine]
    var configuration: StoredConfiguration?
}

@Model final class StoredMeal {
    var slotRaw: String
    var name: String
    var prepTimeMinutes: Int
    var servings: Int
    var estimatedCost: Decimal
    var recipeMarkdown: String
    var pantryItemsRaw: [String]
    @Relationship(deleteRule: .cascade) var ingredients: [StoredIngredient]
}

@Model final class StoredIngredient {
    var productID: String
    var productNameSnapshot: String
    var quantityValue: Double
    var quantityUnit: String
    var costShare: Decimal
}
```

---

## 6. Dietary filtering (safety critical)

**Read this section before writing a single line of `DietaryFilterService`.**

The catalog is Open Food Facts-derived. **An empty `allergens` array does not mean
the product is allergen-free** — it usually means nobody filled in the field.
Filtering only on "does `allergens` contain `en:milk`" will hand a dairy-free
user a product containing dairy. Unknown is not safe.

Every dietary need uses a three-layer rule:

```swift
struct DietRule {
    let forbiddenAllergenIDs: Set<String>     // exclude if present
    let forbiddenCategoryPrefixes: [String]   // exclude by taxonomy
    let forbiddenDepartmentIDs: Set<String>
    let requiredLabelIDs: Set<String>         // any-of, applied to risky categories
    let riskyCategoryPrefixes: [String]       // where missing data ⇒ exclude
}
```

Worked example — `dairyFree`:

- Exclude any product with allergen `en:milk`
- Exclude the dairy department and `en:cheeses`, `en:yogurts`, `en:butters` prefixes
- For risky processed categories (baked goods, sauces, prepared meals, chocolate),
  require a positive `en:no-milk` or `en:vegan` label; exclude when absent

Worked example — `vegan`:

- Require `en:vegan` on anything processed
- Allow unlabelled products only from inherently plant-based categories
  (fresh fruit, vegetables, legumes, plain grains, nuts)

Requirements:

- `DietaryFilterService` is a pure function over `[Product]` with no I/O.
- Every rule needs unit tests, including a "missing label in a risky category is
  excluded" case per dietary need.
- The filter runs **before** candidate selection, so the model physically cannot
  select an unsafe product, and again in `PlanValidator` as a backstop.
- When multiple dietary needs are active, rules compose as an intersection.

---

## 7. Goal ranking and candidate selection

Nutritional goals are soft preferences, not exclusions.

| Goal | Signal (per 100 g) |
| --- | --- |
| High protein | `proteins100g` ↑, plus protein-per-kcal density |
| Low sugar | `sugars100g` ↓ |
| Low fat | `fat100g` + `saturatedFat100g` ↓ |
| Low carbs | `carbohydrates100g` ↓ |
| Low salt | `salt100g` ↓ |

Normalize each metric **within its category** (compare yoghurts to yoghurts, not
yoghurt to olive oil), then average across the active goals.

Add a **package-efficiency term**. Under whole-package costing, a €9.09 litre of
almond milk used in one breakfast consumes a large slice of a weekly budget.
Score down products whose package is large and expensive relative to a realistic
single-serving portion. Evaluate cost-per-portion at k=1 and k=3 appearances; a
product only viable at k=3 stays in the pool but the prompt must push reuse.

**Selection uses department quotas, not top-N.** A pure top-N on "low sugar"
returns 120 vegetables and no protein source, and the plan becomes seven days of
salad. Take the top *k* per department — proteins, grains, vegetables, fruit,
dairy/alternatives, fats — so the shortlist can compose balanced meals.

Target: 100–150 products, roughly 4–6k tokens once compacted.

**Compact DTO sent to the model** carries only: `id`, `name`, `category`,
`netContent`, `price`, and the nutrition fields relevant to the active goals.
Drop brand, barcode, NutriScore, NOVA, labels, allergens — filtering already
happened and every extra field is repeated cost on every call.

---

## 8. Pantry staples

A fixed, code-owned list. **Not** catalog products.

```swift
enum PantryStaple: String, CaseIterable, Sendable {
    case salt, blackPepper, oliveOil, vegetableOil, vinegar
    case water, garlicPowder, driedHerbs, groundSpices, bakingSoda
}
```

Two invariants:

1. **Every staple is safe for all five dietary needs by construction.** That is why
   butter, honey, stock cubes, and soy sauce are absent — dairy, non-vegan, and
   hidden gluten respectively. Anything requiring a check against the user's
   config is not a staple; it is a catalog product.
2. **Staples never enter the cost calculator or the shopping list.** They are free
   and invisible to the budget.

Consequences:

- Filter catalog categories `en:salts`, `en:olive-oils`, `en:spices`,
  `en:condiments` out of the candidate pool entirely.
- `PlanValidator` rejects any `pantryItems` value outside the enum, and rejects
  ingredients that duplicate a staple. Paying €4 for olive oil the user already
  owns is exactly the waste this decision exists to prevent.
- UI renders staples in a separate "From your pantry" group beneath the priced
  ingredients.

---

## 9. Cost model

Whole-package costing makes cost a step function driven mostly by **how many
distinct SKUs the plan touches**, not by grams consumed. A plan using 60 distinct
products blows any realistic weekly budget even if every portion is tiny.

The real objective: **minimize distinct SKUs while keeping the week varied enough
to be pleasant.**

```swift
struct BasketLine: Sendable {
    let product: Product
    let requiredGrams: Double
    let packages: Int
    let purchasedGrams: Double
    let cost: Decimal
    var wasteGrams: Double { purchasedGrams - requiredGrams }
    var utilization: Double { requiredGrams / purchasedGrams }
}
```

Algorithm: aggregate required quantity per product across the whole week, then
`packages = ceil(required / packageSize)`, `cost = packages × price`.

Waste is a first-class output, not a side effect. Surface total waste and
per-line utilization in the UI — "you'll have 400 g of rice left over" is useful
information and free to compute.

### Feasibility precheck

Before any API call, compute the cheapest compliant basket for the config
(roughly: minimum SKU set per department at the cheapest candidate in each). If
the weekly budget is below that floor, fail immediately with an actionable
message:

> A gluten-free, high-protein week needs about €38 minimum with this catalogue.
> Try raising the budget or relaxing one requirement.

This beats three failed repair rounds ending in a degraded plan, and costs nothing.

---

## 10. OpenAI integration

Package: `https://github.com/MacPaw/OpenAI.git` via SPM.

Use **Structured Outputs with `strict: true`** — `responseFormat: .jsonSchema(...)`
on `ChatQuery`. Prefer the `derivedJsonSchema(Type.self)` builder: conform the DTO
to `JSONSchemaConvertible` and supply a fully populated `example`.

### Pass A schema

```swift
struct PlanSkeleton: JSONSchemaConvertible {
    struct Ingredient: Codable {
        let productID: String
        let grams: Double
    }
    struct Meal: Codable {
        let slot: MealSlot
        let name: String
        let prepTimeMinutes: Int
        let ingredients: [Ingredient]     // catalog productIDs, costed
        let pantryItems: [String]         // PantryStaple raw values, free
    }
    struct Day: Codable { let dayIndex: Int; let meals: [Meal] }
    let days: [Day]

    static let example: PlanSkeleton = /* fully populated, see gotchas */
}
```

### Pass B schema

Takes one validated day, returns `{ mealName, ingredientLines[], steps[] }` per meal.

### Schema gotchas

- **Every array in `example` must be non-empty.** The schema is derived from the
  instance; an empty `ingredients: []` yields a schema with no item type and the
  model returns garbage.
- **No optionals in these DTOs.** Strict mode requires every property to be
  required with `additionalProperties: false`. Model absence as an empty array.
- Enums must conform to `JSONSchemaEnumConvertible`.
- If the derived builder can't express a needed constraint (`minItems`, numeric
  bounds), drop to `dynamicJsonSchema` with a hand-written dictionary.

### Prompt requirements (Pass A)

- Give an explicit **SKU budget**: "use at most 28 distinct products across the
  entire week." Models handle a discrete count far more reliably than a running
  currency total.
- State that every product costs its full package price regardless of amount used.
- Target ~85% of the weekly budget, not 100% — leave headroom for repair.
- Per-slot expectations, or you get 40-minute breakfasts:

  | Slot | Prep time | Ingredients |
  | --- | --- | --- |
  | Breakfast | ≤ 10 min | 2–4 |
  | Lunch | ≤ 25 min | 3–6 |
  | Dinner | ≤ 45 min | 5–7 |

- Only `productID` values from the supplied list may be used. Verify anyway.
- Nutritional goals are evaluated **per day, not per meal**. A per-meal
  high-protein constraint produces chicken breast at breakfast.

### Settings

- Pass A: low temperature (~0.2). Constraint satisfaction, not creativity.
- Pass B: ~0.7. Recipe variety is desirable.
- Handle the `refusal` field as its own error case — a structured-output refusal
  arrives with nil content and must not surface as a decode failure.
- API key lives in a gitignored `.xcconfig`, read via `Bundle.main.infoDictionary`.
  Acceptable for a demo. A shipping app needs a backend proxy; leave a code
  comment saying so.

---

## 11. Validation and repair

```swift
enum PlanViolation: Sendable {
    case unknownProduct(id: String, day: Int, slot: MealSlot)
    case dietaryViolation(productID: String, need: DietaryNeed)
    case pantryItemNotRecognized(String)
    case stapleDuplicatedAsIngredient(productID: String)
    case implausibleQuantity(productID: String, grams: Double)
    case overBudget(computed: Decimal, limit: Decimal)
    case skuCountExceeded(count: Int, limit: Int)
    case goalMissed(goal: NutritionalGoal, day: Int, value: Double)
}
```

Repair strategies, **in this order** — highest leverage first:

1. **Consolidate** — replace a single-use product with one already in the basket
   from the same category. Often removes an entire package. Deterministic, no
   API call.
2. **Substitute** — cheaper product, same category and diet class. Deterministic.
3. **Resize portions** — only helps when it crosses an integer package boundary.
   Compute whether it does before asking.
4. **Simplify** — drop the least structurally important ingredient from a meal.

Run steps 1 and 2 deterministically **before** the first repair prompt. They are
instant and frequently bring the plan into budget alone.

Only then send an LLM repair message containing the previous plan plus the
violation list, asking for a *minimal edit*, not a regeneration. Cap at two
attempts. If it still fails, fall back to deterministic downgrading until it fits.

**Never show the user an over-budget or diet-violating plan.**

---

## 12. Concurrency and progress

`MealPlanGenerator` is an `actor` exposing `AsyncStream<GenerationProgress>`:

```swift
enum GenerationProgress: Sendable {
    case loadingCatalog
    case filtering(candidateCount: Int)
    case checkingFeasibility
    case planning
    case validating(attempt: Int)
    case writingRecipes(completed: Int, total: Int)
    case finished
}
```

Generation is a 20–60 second multi-call operation. A bare spinner reads as a hang.

- Persist to SwiftData **only on complete success** — a cancelled run leaves no
  half-plan.
- Cancelling the enclosing Task cancels the in-flight request; MacPaw's async API
  propagates cancellation to the underlying `URLSessionDataTask`.

---

## 13. Build order

Each step ships something verifiable. Do not start step N+1 with step N untested.

| # | Step | Done when |
| --- | --- | --- |
| 1 | Catalog loader + unit normalization | Test asserts every product either normalizes or is explicitly flagged |
| 2 | SwiftData schema + config persistence, wired to existing screens | Config survives app restart. No AI yet. |
| 3 | Dietary filter + goal ranking + candidate selection | Unit tested; debug screen lists candidates for a given config |
| 4 | Cost calculator + feasibility checker | Tested against hand-computed fixtures |
| 5 | Pass A for a single day, behind the stub-able protocol | One valid day end to end |
| 6 | Validator + deterministic repair + LLM repair, scaled to 7 days | Full week validates within budget |
| 7 | Pass B recipes, parallelized | Complete plan with recipe text |
| 8 | Persist, reload, regenerate; then per-meal swap | Plan reopens after restart; single meal regenerates |

Steps 1–4 have no AI dependency and cover most of the correctness risk. That is
why they come first.

---

## 14. Definition of done for a generated plan

- [ ] Computed basket cost ≤ weekly budget
- [ ] Zero dietary violations under the user's active needs
- [ ] Every `productID` resolves to a product in the catalog
- [ ] Every pantry item is a `PantryStaple` case
- [ ] 7 days × 3 meals, no empty meals
- [ ] Every meal has ≥ 2 ingredients and a non-empty recipe
- [ ] Daily nutritional totals move in the direction of every active goal
- [ ] Plan and basket persist and reload correctly

---

## 15. Known risk to verify early

Whole-package costing assumes package sizes suited to single-serving cooking.
Open Food Facts-derived catalogs skew heavily toward barcoded packaged goods —
the smallest carrot entry may be a 1 kg bag, with no loose produce at all. If so,
a one-person week shows high waste and an unreasonable budget floor, and **the fix
is a data problem, not a prompt problem.**

Before starting step 3, run a histogram of `netContent.value` per department. If
fresh produce is sparse or bulk-only, add a small set of loose-produce entries to
the JSON with realistic per-100g pricing and note the addition in this document.

---

## 16. Out of scope

Do not build these without an explicit request:

- Accounts, authentication, sync, or any backend
- Multiple servings per meal (the data model should not block it later, but do not
  implement it)
- Shopping list export, sharing, notifications
- Barcode scanning, product search UI, catalog editing
- Localization beyond English
- Analytics or crash reporting
