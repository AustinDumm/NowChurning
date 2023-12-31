//
//  MyRecipesSupervisorTests.swift
//  NowChurningTests
//
//  Created by Austin Dumm on 4/17/23.
//

import XCTest

@testable import NowChurning

final class MyRecipesSupervisorTests: SupervisorTests {

    var parent: MyRecipesSupervisorParentMock!
    var navigator: SegmentedNavigationController!

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.parent = .init()
        self.navigator = .init(rootViewController: .init())
    }

    func testSupervisor_Initializes() throws {
        let supervisor = RecipesSupervisor(
            parent: self.parent,
            navigator: self.navigator,
            content: TestAppContent.testMyRecipesContent
        )

        XCTAssertNotNil(supervisor)

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

    func testSupervisor_CanEndImmediately() throws {
        guard let supervisor = RecipesSupervisor(
            parent: self.parent,
            navigator: self.navigator,
            content: TestAppContent.testMyRecipesContent
        ) else {
            XCTFail("Failed to initialize MyRecipesSupervisor")
            return
        }

        XCTAssert(supervisor.canEnd())

        let expectation = XCTestExpectation()
        supervisor.requestEnd {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 0.0)
    }

    func testSupervisor_CanEndRecipeDetails() throws {
        guard let supervisor = RecipesSupervisor(
            parent: self.parent,
            navigator: self.navigator,
            content: TestAppContent.testMyRecipesContent
        ) else {
            XCTFail("Failed to initialize MyRecipesSupervisor")
            return
        }

        supervisor.navigateToDetails(forRecipe: .init(name: "Test", description: ""))

        XCTAssert(supervisor.canEnd())

        let expectation = XCTestExpectation()
        supervisor.requestEnd {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 0.0)
    }

    func testSupervisor_OnNavigateToDetails_DoesPushView() throws {
        let supervisor = RecipesSupervisor(
            parent: self.parent,
            navigator: self.navigator,
            content: TestAppContent.testMyRecipesContent
        )

        supervisor?.navigateToDetails(
            forRecipe: .init(name: "Test Recipe", description: "")
        )

        let expectation = XCTestExpectation()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            XCTAssert(
                self.navigator
                    .topViewController?
                    .children
                    .first is ItemListViewController
            )

            XCTAssertEqual(
                self.navigator
                    .viewControllers
                    .count,
                3
            )
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 0.5)
    }

    func testSupervisor_WhenNavigationBack_EndsSelf() throws {
        let delegate = MockStackNavigationDelegate()
        self.navigator.startSegment(withDelegate: delegate)

        let supervisor = RecipesSupervisor(
            parent: self.parent,
            navigator: self.navigator,
            content: TestAppContent.testMyRecipesContent
        )

        let expecation = XCTestExpectation()
        DispatchQueue.main.async {
            self.parent
                .childDidEndSupervisorClosure = { child in
                    XCTAssertIdentical(
                        child,
                        supervisor
                    )
                    expecation.fulfill()

                }

            _ = self.navigator.popViewController(animated: false)
            self.navigator
                .navigationController(
                    self.navigator,
                    didShow: .init(),
                    animated: false
                )

            XCTAssertIdentical(
                self.navigator.topSegmentDelegate,
                delegate
            )
        }

        wait(for: [expecation], timeout: 0.5)
    }

}
