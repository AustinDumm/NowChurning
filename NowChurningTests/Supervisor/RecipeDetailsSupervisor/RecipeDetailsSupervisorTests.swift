//
//  RecipeDetailsSupervisorTests.swift
//  NowChurningTests
//
//  Created by Austin Dumm on 4/17/23.
//

import XCTest
import Factory

@testable import NowChurning

final class RecipeDetailsSupervisorTests: SupervisorTests {

    var container: UIViewController!
    var navigationItem: UINavigationItem!
    var parent: RecipeDetailsSupervisorParentMock!
    var store: RecipeListCoreDataStore!

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.container = .init()
        self.navigationItem = .init()
        self.parent = .init()
        self.store = .init(
            sink: RecipeListDomainModelSinkMock(),
            storeUser: Container.shared.coreDataUserManager().user,
            objectContext: Container.shared.managedObjectContext()
        )
    }

    func testRecipeDetailsSupervisor_InitializesWithNoRecipe() throws {
        let _ = RecipeDetailsSupervisor(
            container: self.container,
            navigationItem: self.navigationItem,
            parent: self.parent,
            recipeListStore: self.store,
            content: .init(
                applicationContent: TestAppContent.testRecipeApplicationContent,
                presentationContent: TestAppContent.testRecipePresentationContent
            )
        )

        XCTAssert(
            self.container.children.first is ItemListViewController
        )
    }

    func testRecipeDetailsSupervisor_InitializesWithRecipe() throws {
        let _ = RecipeDetailsSupervisor(
            container: self.container,
            navigationItem: self.navigationItem,
            parent: self.parent,
            recipe: .init(name: "Test Recipe", description: "Test Description"),
            recipeListStore: self.store,
            content: .init(
                applicationContent: TestAppContent.testRecipeApplicationContent,
                presentationContent: TestAppContent.testRecipePresentationContent
            )
        )

        XCTAssert(
            self.container.children.first is ItemListViewController
        )
    }

    func testRecipeDetailsSupervisor_NoChanges_EndsCorrectly() throws {
        let supervisor = RecipeDetailsSupervisor(
            container: self.container,
            navigationItem: self.navigationItem,
            parent: self.parent,
            recipe: .init(name: "Test Recipe", description: "Test Description"),
            recipeListStore: self.store,
            content: .init(
                applicationContent: TestAppContent.testRecipeApplicationContent,
                presentationContent: TestAppContent.testRecipePresentationContent
            )
        )

        XCTAssert(
            supervisor.canEnd()
        )

        let expectation = XCTestExpectation()
        supervisor.requestEnd {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 0.0)
    }
    
}
