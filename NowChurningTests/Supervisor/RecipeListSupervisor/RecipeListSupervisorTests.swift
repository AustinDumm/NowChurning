//
//  RecipeListSupervisorTests.swift
//  NowChurningTests
//
//  Created by Austin Dumm on 4/17/23.
//

import XCTest

@testable import NowChurning

final class RecipeListSupervisorTests: SupervisorTests {

    var container: UIViewController!
    var navigationItem: UINavigationItem!
    var parent: RecipeListSupervisorParentMock!

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.container = .init()
        self.navigationItem = .init()
        self.parent = .init()
    }


    func testSupervisor_InitializesCorrectly() throws {
        let supervisor = RecipeListSupervisor(
            container: self.container,
            navigationItem: self.navigationItem,
            parent: self.parent,
            content: TestAppContent.testRecipeListContent
        )

        XCTAssertNotNil(supervisor)
        XCTAssert(
            self.container.children.first is ItemListViewController
        )
    }

    func testSupervisor_CanEndImmediately() throws {
        guard let supervisor = RecipeListSupervisor(
            container: self.container,
            navigationItem: self.navigationItem,
            parent: self.parent,
            content: TestAppContent.testRecipeListContent
        ) else {
            XCTFail("Failed to initialize recipe list supervisor")
            return
        }

        XCTAssert(supervisor.canEnd())

        let expectation = XCTestExpectation()
        supervisor.requestEnd {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 0.0)
    }

}
