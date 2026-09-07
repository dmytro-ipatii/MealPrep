# MealPrep

An iOS demo app (Swift / SwiftUI / SwiftData) that generates a 7-day meal plan
from a bundled grocery catalog, a weekly budget, dietary needs, and nutritional
goals. Products come from a local JSON catalog; meal composition and recipe
text come from the OpenAI API. Everything is stored on device. There is no
account system, no authentication, and no backend.

The governing rule is **the LLM proposes, Swift disposes**: allergen filtering,
dietary exclusions, budget arithmetic, and nutritional totals are computed
deterministically in Swift and unit tested. The model only composes meals and
writes recipes.

See `Agent/APP_PLAN.md` for the full specification.

---

## Requirements

| | |
| --- | --- |
| Xcode | 26.6 or later |
| iOS deployment target | 18.6 (app), 26.5 (test targets) |
| Swift language mode | 5 |
| Dependencies | Resolved automatically via SPM — no CocoaPods, no Carthage |
| OpenAI API key | Required to generate a plan (see below) |

Dependencies are fetched by Xcode on first open:

- [MacPaw/OpenAI](https://github.com/MacPaw/OpenAI) 0.5.1
- apple/swift-http-types, apple/swift-openapi-runtime (transitive)

> `Package.resolved` is gitignored, so a fresh clone resolves dependency
> versions from scratch and may pick up newer ones than those above.

---

## Setup

### 1. Create your secrets file — the project will not build without it

`MealPrep/Configs/Secrets.xcconfig` is gitignored, but it is wired as the
**base configuration** for both Debug and Release. A fresh clone therefore
fails to build until you create it:

```
error: Unable to open base configuration reference file
'.../MealPrep/Configs/Secrets.xcconfig'
```

Copy the template:

```bash
cp MealPrep/Configs/Secrets.example.xcconfig MealPrep/Configs/Secrets.xcconfig
```

Then open it and paste your OpenAI API key:

```
OPEN_AI_API_KEY = sk-proj-your-key-here
```

**Do not wrap the key in quotes.** `.xcconfig` treats quotes as part of the
value, so `OPEN_AI_API_KEY = "sk-..."` sends the quote characters to OpenAI and
every request fails with a `401` that looks like an invalid key. Write it bare.

You can get a key from <https://platform.openai.com/api-keys>.

### 2. Open and run

```bash
open MealPrep.xcodeproj
```

Select the **MealPrep** scheme and any iOS 18.6+ simulator, then run.

Building without a key is fine — the app launches and the configuration
screens work. Generation will fail with "The app is missing its API key".

---

## How the key reaches the app

```
Secrets.xcconfig  →  build setting  →  Info.plist  →  APIKeyProvider
 (gitignored)        OPEN_AI_API_KEY   $(OPEN_AI_API_KEY)   Bundle.main
```

`Info.plist` contains `OPEN_AI_API_KEY = $(OPEN_AI_API_KEY)`, which Xcode
substitutes at build time. `APIKeyProvider.openAIAPIKey()` reads it and throws
`MealPlanLLMError.missingAPIKey` when it is absent or empty.

To verify your key actually made it into the built app (without printing it):

```bash
APP=$(find ~/Library/Developer/Xcode/DerivedData/MealPrep-*/Build/Products/Debug-iphonesimulator \
  -maxdepth 1 -name "MealPrep.app" | head -1)
/usr/libexec/PlistBuddy -c "Print :OPEN_AI_API_KEY" "$APP/Info.plist" | awk '{print length($0) " chars"}'
```

If the length is 2 more than your key, you left the quotes in.

> This bundles the key into the app, which is acceptable only because MealPrep
> is a local demo. A shipping app needs a backend proxy.

### API usage and cost

One plan generation makes **8–10 calls** to `gpt-4o`:

- 1 call for Pass A (the plan skeleton)
- 0–2 optional repair calls, only if deterministic repair cannot fix the plan
- 7 calls for Pass B (recipes, one per day, run concurrently)

Generation takes roughly 20–60 seconds. The whole test suite runs against
stubs and never touches the network, so it costs nothing.

---

## Running the tests

```bash
# Everything (174 tests: 171 unit + 3 UI)
xcodebuild test -project MealPrep.xcodeproj -scheme MealPrep \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'

# A single suite
xcodebuild test -project MealPrep.xcodeproj -scheme MealPrep \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:MealPrepTests/PlanValidatorTests
```

Unit tests use Swift Testing (`@Test` / `#expect`); UI tests use XCTest.
No test makes a network call — the LLM client is a protocol with a stub.

---

## Debug helpers

The app supports a DEBUG-only launch argument that opens straight to the weekly
plan screen with sample data, so you can work on those screens without spending
a real generation:

```bash
xcrun simctl launch <device-id> com.dmytro-ipatii.MealPrep -seedPreviewPlan
```

The UI tests use the same flag. SwiftUI previews use `MealPlan.preview` and
the stand-ins in `Data/Persistence/PreviewDoubles.swift`.

---

## App flow

1. **First run** — Lander → budget → dietary needs → nutritional goals →
   generation → weekly plan.
2. **Every later launch** — opens straight to the weekly plan, which is
   restored from SwiftData.
3. **Updating** — "Update meal plan" on the weekly screen reopens the
   configuration screens, prefilled with your saved settings, and regenerates.

A plan is saved **only** on complete success, so a cancelled or failed run
never leaves a half-written plan behind.

---

## Project layout

```
MealPrep/
├── MealPrepApp.swift          entry point, dependency container
├── ContentView.swift          picks onboarding vs. a restored plan
├── DesignSystem/              tokens (color, type, spacing) and components
├── Domain/
│   ├── Configuration/         DietaryNeed, NutritionalGoal, MealSlot, PantryStaple
│   ├── Models/                Product, MealPlan, Basket, ShoppingLine, Recipe
│   └── Errors/                PlanViolation, GenerationError
├── Data/
│   ├── Catalog/               ProductCatalogLoader, DTOs, UnitNormalizer
│   ├── OpenAI/                MealPlanLLMClient protocol, MacPaw adapter, prompts
│   └── Persistence/           SwiftData models, repositories
├── Services/                  the deterministic pipeline (see below)
├── Featrues/                  SwiftUI screens and navigation [sic: folder name]
└── Resources/                 assets, fonts
```

The generation pipeline, in order:

```
catalog → DietaryFilterService → GoalRankingService → CandidateSelector
        → FeasibilityChecker → Pass A → PlanValidator → PlanRepairService
        → Pass B (parallel) → MealPlanAssembler → MealPlanRepository
```

`MealPlanGenerator` orchestrates it and reports progress through an
`AsyncThrowingStream<GenerationProgress, Error>`.

The bundled catalog lives at
`MealPrep/Services/Products/Data/product_catalog_en.json` (3,295 rows, of which
2,949 normalize successfully; the rest are dropped for a missing `netContent`
or `category`).

---

## Troubleshooting

**`Unable to open base configuration reference file '.../Secrets.xcconfig'`**
You skipped setup step 1. Create the file from the template.

**Generation fails with "The app is missing its API key"**
`Secrets.xcconfig` exists but `OPEN_AI_API_KEY` is empty. Note that Xcode
caches build settings — clean the build folder (⇧⌘K) after editing the file.

**Every request fails with a 401**
Check for quotes around the key; see setup step 1.

**`Could not resolve package dependencies`**
Usually a transient network issue or a race with Xcode resolving in the
background. Retry, or run:
```bash
xcodebuild -resolvePackageDependencies -project MealPrep.xcodeproj -scheme MealPrep
```

**A gluten-free plan looks thin or repetitive**
Expected, and a data limitation rather than a bug. The bundled catalog has no
`en:gluten-free` label, so every processed category is excluded on the
"unknown is not safe" rule, leaving roughly 40% of the catalog. See
`Agent/APP_PLAN.md` section 15.
