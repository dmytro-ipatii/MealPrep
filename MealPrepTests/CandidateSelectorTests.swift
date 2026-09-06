//
//  CandidateSelectorTests.swift
//  MealPrepTests
//
//  Created by Dmytro Ipatii on 06/09/2026.
//

import Foundation
import Testing
@testable import MealPrep

struct CandidateSelectorTests {

    @Test func quotasSpreadSelectionAcrossDepartments() {
        // 3 departments, 5 products each, all with enough spread to avoid
        // a fallback to the neutral score.
        let departments = ["proteins", "grains", "produce"]
        var products: [Product] = []
        var scores: [String: Double] = [:]

        for department in departments {
            for index in 0..<5 {
                let id = "\(department)-\(index)"
                products.append(Product.stub(id: id, departmentID: department))
                scores[id] = Double(index)
            }
        }

        let selected = CandidateSelector.select(from: products, scores: scores, targetCount: 6)

        let countsByDepartment = Dictionary(grouping: selected, by: \.departmentID).mapValues(\.count)
        #expect(countsByDepartment.values.allSatisfy { $0 == 2 })
        #expect(selected.count == 6)
    }

    @Test func quotaPicksHighestScoredProductsWithinEachDepartment() {
        let products = (0..<5).map { Product.stub(id: "p\($0)", departmentID: "proteins") }
        let scores = Dictionary(uniqueKeysWithValues: products.enumerated().map { ($1.id, Double($0)) })

        let selected = CandidateSelector.select(from: products, scores: scores, targetCount: 2)

        #expect(Set(selected.map(\.id)) == ["p3", "p4"])
    }

    @Test func backfillsFromRemainingProductsWhenADepartmentIsThin() {
        // 1 department has only 1 product, well below its quota — the
        // shortfall should be made up from the other department instead of
        // returning a short list.
        var products: [Product] = [Product.stub(id: "thin-0", departmentID: "thin")]
        var scores: [String: Double] = ["thin-0": 1.0]

        for index in 0..<5 {
            let id = "rich-\(index)"
            products.append(Product.stub(id: id, departmentID: "rich"))
            scores[id] = Double(index)
        }

        let selected = CandidateSelector.select(from: products, scores: scores, targetCount: 4)

        #expect(selected.count == 4)
        #expect(selected.contains { $0.id == "thin-0" })
    }

    @Test func neverReturnsMoreThanAvailableProducts() {
        let products = (0..<3).map { Product.stub(id: "p\($0)", departmentID: "proteins") }
        let scores = Dictionary(uniqueKeysWithValues: products.map { ($0.id, 0.5) })

        let selected = CandidateSelector.select(from: products, scores: scores, targetCount: 130)

        #expect(selected.count == 3)
    }

    @Test func emptyInputReturnsEmptyOutput() {
        #expect(CandidateSelector.select(from: [], scores: [:]).isEmpty)
    }

    // MARK: - Real catalog sanity

    @Test func realCatalogPipelineProducesFullDepartmentDiversity() throws {
        let result = try ProductCatalogLoader.load()
        let scores = GoalRankingService.score(result.products, for: [.highProtein, .lowSugar])

        let selected = CandidateSelector.select(from: result.products, scores: scores)

        #expect(selected.count == CandidateSelector.defaultTargetCount)

        let representedDepartments = Set(selected.map(\.departmentID))
        let availableDepartments = Set(result.products.map(\.departmentID))
        #expect(representedDepartments == availableDepartments)
    }
}

private extension Product {
    static func stub(id: String, departmentID: String) -> Product {
        Product(
            id: id,
            name: "Test Product \(id)",
            departmentID: departmentID,
            categoryID: "en:test-category",
            baseQuantity: .mass(grams: 500),
            price: Decimal(1.99),
            nutrition: NutritionFacts(
                energyKcal: 100, proteins: 5, carbohydrates: 10, sugars: 2,
                fat: 3, saturatedFat: 1, fiber: 1, salt: 0.5
            ),
            labelIDs: [],
            allergenIDs: []
        )
    }
}
