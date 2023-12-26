//
//  IngredientTagSelectionSupervisorTests.swift
//  NowChurningTests
//
//  Created by Austin Dumm on 4/12/23.
//

import XCTest
import CoreData
import Factory

@testable import NowChurning

final class IngredientTagSelectionSupervisorTests: SupervisorTests {

    var container: UIViewController!
    var navigationItem: UINavigationItem!
    let tags: [Tag<Ingredient>] = [
        .init(name: "First"),
        .init(name: "Second"),
        .init(name: "Third"),
        .init(name: "Fourth"),
    ]
    var mockParent: TagSelectorSupervisorParentMock!

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.container = .init()
        self.navigationItem = .init()
        self.mockParent = TagSelectorSupervisorParentMock()
    }

    func testSupervisor_InitializesCorrectly() throws {
        let ingredientTagSupervisor = IngredientTagSelectorSupervisor(
            container: self.container,
            navigationItem: self.navigationItem,
            initialTags: self.tags,
            parent: self.mockParent,
            content: TestAppContent.testTagSelectorContent
        )

        XCTAssert(
            self.container.children.first is SelectionListViewController
        )

        XCTAssertNotNil(ingredientTagSupervisor)
    }

    func testSupervisor_HandlesEndImmediately() throws {
        let ingredientTagSupervisor = IngredientTagSelectorSupervisor(
            container: self.container,
            navigationItem: self.navigationItem,
            initialTags: self.tags,
            parent: self.mockParent,
            content: TestAppContent.testTagSelectorContent
        )

        XCTAssert(ingredientTagSupervisor?.canEnd() ?? false)

        let expectation = XCTestExpectation()
        ingredientTagSupervisor?.requestEnd {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 0.0)
    }

    func testSupervisor_WhenTagsSelected_AlertsParent() throws {
        let ingredientTagSupervisor = IngredientTagSelectorSupervisor(
            container: self.container,
            navigationItem: self.navigationItem,
            initialTags: self.tags,
            parent: self.mockParent,
            content: TestAppContent.testTagSelectorContent
        )

        let expectation = XCTestExpectation()
        self.mockParent
            .didSelectTagsClosure = { tags in
                XCTAssertEqual(
                    tags,
                    self.tags
                )
                expectation.fulfill()
            }

        ingredientTagSupervisor?.didSelect(tags: self.tags)
    }

    func testSupervisor_WhenCancelled_AlertsParent() throws {
        let ingredientTagSupervisor = IngredientTagSelectorSupervisor(
            container: self.container,
            navigationItem: self.navigationItem,
            initialTags: self.tags,
            parent: self.mockParent,
            content: TestAppContent.testTagSelectorContent
        )

        let expectation = XCTestExpectation()
        self.mockParent
            .didSelectTagsClosure = { tags in
                XCTAssertNil(tags)
                expectation.fulfill()
            }

        ingredientTagSupervisor?.cancelTagSelection()
    }

}
