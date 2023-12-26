//
//  IngredientDetailsSupervisorTests.swift
//  NowChurningTests
//
//  Created by Austin Dumm on 4/17/23.
//

import XCTest

@testable import NowChurning

final class IngredientDetailsSupervisorTests: SupervisorTests {

    var container: UIViewController!
    var navigationItem: UINavigationItem!
    var parent: IngredientDetailsSupervisorParentMock!
    var store: IngredientListStoreActionSinkMock!

    var ingredientId: ID<Ingredient> {
        self.testIngredient.id
    }
    var testIngredient: Ingredient {
        self.ingredientList.first!
    }
    let ingredientList: [Ingredient] = [
        .init(name: "Test first", description: "Test description", tags: []),
        .init(name: "Test second", description: "Test description", tags: []),
        .init(name: "Test third", description: "Test description", tags: []),
    ]

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.container = .init()
        self.navigationItem = .init()
        self.parent = .init()
        self.store = .init()
    }


    func testSupervisor_InitializesWithIngredient() throws {
        let _ = IngredientDetailsSupervisor(
            container: self.container,
            navigationItem: self.navigationItem,
            parent: self.parent,
            ingredientId: self.ingredientId,
            ingredientListStore: self.store,
            content: TestAppContent.testIngredientDetailsContent
        )

        XCTAssert(
            self.container.children.first is ItemListViewController
        )
    }

    func testSupervisor_InitializesWithNoIngredient() throws {
        let _ = IngredientDetailsSupervisor(
            container: self.container,
            navigationItem: self.navigationItem,
            parent: self.parent,
            ingredientId: nil,
            ingredientListStore: self.store,
            content: TestAppContent.testIngredientDetailsContent
        )

        XCTAssert(
            self.container.children.first is ItemListViewController
        )
    }

    func testSupervisor_HandlesEndWithNoChanges() throws {
        let supervisor = IngredientDetailsSupervisor(
            container: self.container,
            navigationItem: self.navigationItem,
            parent: self.parent,
            ingredientId: nil,
            ingredientListStore: self.store,
            content: TestAppContent.testIngredientDetailsContent
        )

        XCTAssert(supervisor.canEnd())

        let expectation = XCTestExpectation()
        supervisor.requestEnd {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 0.0)
    }

    func testSupervisor_RequestToEditTags_DoesAlertParent() throws {
        let supervisor = IngredientDetailsSupervisor(
            container: self.container,
            navigationItem: self.navigationItem,
            parent: self.parent,
            ingredientId: nil,
            ingredientListStore: self.store,
            content: TestAppContent.testIngredientDetailsContent
        )

        let expectation = XCTestExpectation()
        self.parent
            .navigateToTagSelectorForIngredientClosure = { ingredient in
                XCTAssertEqual(
                    ingredient,
                    self.testIngredient
                )
                expectation.fulfill()
            }

        supervisor.requestEditTags(forIngredient: self.testIngredient)
        wait(for: [expectation], timeout: 0.0)
    }
}
