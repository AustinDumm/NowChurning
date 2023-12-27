//
//  RecipeFlowSupervisorTests.swift
//  NowChurningTests
//
//  Created by Austin Dumm on 4/17/23.
//

import XCTest
import Factory

@testable import NowChurning

final class RecipeFlowSupervisorTests: SupervisorTests {

    var parent: RecipeFlowSupervisorParentMock!
    var navigator: StackNavigation!
    var store: RecipeListCoreDataStore!

    var testRecipe: Recipe {
        self.recipeList[1]
    }
    let recipeList: [Recipe] = [
        .init(name: "First", description: "Descr"),
        .init(name: "Second", description: "Descr"),
        .init(name: "Third", description: "Descr"),
        .init(name: "Fourth", description: "Descr"),
    ]

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.parent = .init()
        self.navigator = StackNavigation(rootViewController: .init())
        self.store = .init(
            sink: RecipeListDomainModelSinkMock(),
            storeUser: Container.shared.coreDataUserManager().user,
            objectContext: Container.shared.managedObjectContext()
        )
    }

    func testSupervisor_Initializes() throws {
        let _ = RecipeFlowSupervisor(
            parent: self.parent,
            navigator: self.navigator,
            recipe: self.testRecipe,
            recipeListStore: self.store,
            content: TestAppContent.testRecipeDetailsContent
        )

        let expecation = XCTestExpectation()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            XCTAssert(
                self.navigator
                    .topViewController?
                    .children
                    .first is ItemListViewController
            )
            expecation.fulfill()
        }

        wait(for: [expecation], timeout: 0.5)
    }

    func testSupervisor_InitializesWithNoRecipe() throws {
        let _ = RecipeFlowSupervisor(
            parent: self.parent,
            navigator: self.navigator,
            recipeListStore: self.store,
            content: TestAppContent.testRecipeDetailsContent
        )

        let expecation = XCTestExpectation()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            XCTAssert(
                self.navigator
                    .topViewController?
                    .children
                    .first is ItemListViewController
            )
            expecation.fulfill()
        }

        wait(for: [expecation], timeout: 0.5)
    }

    func testSupervisor_CanEndWithNoChanges() throws {
        let supervisor = RecipeFlowSupervisor(
            parent: self.parent,
            navigator: self.navigator,
            recipeListStore: self.store,
            content: TestAppContent.testRecipeDetailsContent
        )

        XCTAssert(supervisor.canEnd())

        let expectation = XCTestExpectation()
        supervisor.requestEnd {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 0.0)
    }

    func testSupervisor_OnEditFinish_DoesAlertParent() throws {
        let supervisor = RecipeFlowSupervisor(
            parent: self.parent,
            navigator: self.navigator,
            recipeListStore: self.store,
            content: TestAppContent.testRecipeDetailsContent
        )

        let testType = EditModeAction.DoneType.save
        let expectation = XCTestExpectation()
        self.parent.didFinishEditByClosure = { recievedType in
            XCTAssertEqual(
                recievedType,
                testType
            )
            expectation.fulfill()
        }

        supervisor.didFinishEdit(by: testType)
        wait(for: [expectation], timeout: 0.0)
    }

    func testSupervisor_WhenNavigationStackPopped_EndsSelf() throws {
        let supervisor = RecipeFlowSupervisor(
            parent: self.parent,
            navigator: self.navigator,
            recipeListStore: self.store,
            content: TestAppContent.testRecipeDetailsContent
        )

        let expectation = XCTestExpectation()
        DispatchQueue.main.async {
            self.parent
                .childDidEndSupervisorClosure = { child in
                    XCTAssertIdentical(
                        child,
                        supervisor
                    )
                    expectation.fulfill()
                }

            _ = self.navigator.popViewController(animated: false)
            self.navigator.delegate?.navigationController?(
                self.navigator,
                didShow: UIViewController(),
                animated: false
            )
        }
        wait(for: [expectation], timeout: 0.05)
    }

    func testSupervisor_WhenEndSelf_ReplacesNavigationDelegate() throws {
        let delegate = MockStackNavigationDelegate()
        self.navigator.pushDelegate(delegate)

        let supervisor = RecipeFlowSupervisor(
            parent: self.parent,
            navigator: self.navigator,
            recipeListStore: self.store,
            content: TestAppContent.testRecipeDetailsContent
        )
        _ = supervisor

        let expectation = XCTestExpectation()
        DispatchQueue.main.async {
            _ = self.navigator.popViewController(animated: false)
            self.navigator.delegate?.navigationController?(
                self.navigator,
                didShow: UIViewController(),
                animated: false
            )

            XCTAssertIdentical(
                self.navigator.topDelegate,
                delegate
            )
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 0.05)
    }

}
