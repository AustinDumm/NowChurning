//
//  IngredientFlowSupervisorTests.swift
//  NowChurningTests
//
//  Created by Austin Dumm on 4/17/23.
//

import XCTest

@testable import NowChurning

final class IngredientFlowSupervisorTests: SupervisorTests {

    var parent: IngredientFlowSupervisorParentMock!
    var navigator: UINavigationController!
    var store: IngredientListStoreActionSinkMock!

    var testIngredient: Ingredient {
        self.ingredients[2]
    }
    let ingredients: [Ingredient] = [
        .init(name: "First", description: "", tags: []),
        .init(name: "Second", description: "", tags: []),
        .init(name: "Third", description: "", tags: []),
        .init(name: "Fourth", description: "", tags: []),
    ]

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.parent = .init()
        self.navigator = .init(rootViewController: .init())
        self.store = .init()
    }

    func testSupervisor_Initializes() throws {
        let _ = IngredientFlowSupervisor(
            parent: self.parent,
            navigator: self.navigator,
            ingredient: self.testIngredient,
            ingredientStore: self.store,
            content: TestAppContent.testEditIngredientDetailsContent
        )

        let expectation = XCTestExpectation()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            XCTAssert(
                self.navigator
                    .topViewController?
                    .children
                    .first is ItemListViewController
            )
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 0.5)
    }

    func testSupervisor_InitializesWithNoIngredient() throws {
        let _ = IngredientFlowSupervisor(
            parent: self.parent,
            navigator: self.navigator,
            ingredientStore: self.store,
            content: TestAppContent.testEditIngredientDetailsContent
        )

        let expectation = XCTestExpectation()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            XCTAssert(
                self.navigator
                    .topViewController?
                    .children
                    .first is ItemListViewController
            )
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 0.5)
    }

    func testSupervisor_CanEndImmediatelyWithNoChanges() throws {
        let supervisor = IngredientFlowSupervisor(
            parent: self.parent,
            navigator: self.navigator,
            ingredient: self.testIngredient,
            ingredientStore: self.store,
            content: TestAppContent.testEditIngredientDetailsContent
        )

        XCTAssert(supervisor.canEnd())

        let expectation = XCTestExpectation()
        supervisor.requestEnd {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 0.0)
    }

    func testSupervisor_CanEndImmediatelyWithNoChanges_OnTags() throws {
        let supervisor = IngredientFlowSupervisor(
            parent: self.parent,
            navigator: self.navigator,
            ingredient: self.testIngredient,
            ingredientStore: self.store,
            content: TestAppContent.testEditIngredientDetailsContent
        )
        supervisor.navigateToTagSelector(forIngredient: self.testIngredient)

        XCTAssert(supervisor.canEnd())

        let expectation = XCTestExpectation()
        supervisor.requestEnd {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 0.0)
    }

    func testSupervisor_WhenDone_AlertsParent() throws {
        let supervisor = IngredientFlowSupervisor(
            parent: self.parent,
            navigator: self.navigator,
            ingredient: self.testIngredient,
            ingredientStore: self.store,
            content: TestAppContent.testEditIngredientDetailsContent
        )

        let expectation = XCTestExpectation()
        let testType = EditModeAction.DoneType.cancel
        self.parent.navigateForEditDoneTypeClosure = { receivedType in
            XCTAssertEqual(
                receivedType,
                testType
            )

            expectation.fulfill()
        }

        supervisor.navigate(forEditDoneType: testType)

        wait(for: [expectation], timeout: 0.0)
    }

    func testSupervisor_WhenNavigationBack_AlertsParent() throws {
        let delegate = MockUINavigationControllerDelegate()
        self.navigator.delegate = delegate
        
        let supervisor = IngredientFlowSupervisor(
            parent: self.parent,
            navigator: self.navigator,
            ingredient: self.testIngredient,
            ingredientStore: self.store,
            content: TestAppContent.testEditIngredientDetailsContent
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

            self.navigator
                .popViewController(animated: false)
            self.navigator
                .delegate?
                .navigationController?(
                    self.navigator,
                    didShow: .init(),
                    animated: false
                )

            XCTAssertIdentical(
                self.navigator.delegate,
                delegate
            )
        }

        wait(for: [expectation], timeout: 0.05)
    }
}
