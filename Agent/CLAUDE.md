# MealPrep

iOS demo app (Swift 6 / SwiftUI / SwiftData, iOS 17+) that generates a 7-day meal
plan from a bundled product catalog, an OpenAI call, and a weekly budget.

@docs/APP_PLAN.md

## Governing rule

The LLM proposes, Swift disposes. Allergen filtering, dietary exclusions, budget
arithmetic, and nutritional totals are computed deterministically in Swift and
unit tested. The model composes meals and writes recipes — nothing else.

## Conventions

- Domain models are `Sendable` structs. SwiftData `@Model` classes stay in
  `Data/Persistence` and never appear in a service signature.
- Services are protocols first; the pipeline depends on `MealPlanLLMClient`, never
  on MacPaw/OpenAI types directly.
- Money is `Decimal`, never `Double`. Quantities are normalized to grams, ml, or
  counts at catalog load — never parse `"1 l"` downstream.
- No force unwraps, no `try!`, no `fatalError` outside `preconditionFailure` in
  genuinely unreachable branches.
- New service ⇒ new test target file in the same commit.

## Build and test

```bash
./scripts/build.sh      # xcodebuild, iOS simulator
./scripts/test.sh       # unit tests
```

Prefer these over hand-written `xcodebuild` invocations so failures are readable.

## Secrets

The OpenAI key lives in `Config/Secrets.xcconfig`, which is gitignored. Never
write a key into a Swift file, a plist, or a test fixture. Never print it.

## Delegation

Use the `ios-swift-expert` subagent for Swift, SwiftUI, SwiftData, and
concurrency implementation work.
