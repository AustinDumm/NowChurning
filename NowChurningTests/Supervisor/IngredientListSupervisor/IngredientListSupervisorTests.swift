//
//  IngredientListSupervisorTests.swift
//  NowChurningTests
//
//  Created by Austin Dumm on 4/17/23.
//

import XCTest

@testable import NowChurning

final class IngredientListSupervisorTests: SupervisorTests {

    var container: UIViewController!
    var navigationItem: UINavigationItem!
    var parent: IngredientListSupervisorParentMock!

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.container = .init()
        self.navigationItem = .init()
        self.parent = .init()
    }

    func testSupervisor_Initializes() throws {
        let supervisor = IngredientListSupervisor(
            container: self.container,
            navigationItem: self.navigationItem,
            parent: self.parent,
            content: TestAppContent.testBarListContent
        )

        XCTAssertNotNil(supervisor)

        XCTAssert(
            self.container.children.first is ItemListViewController
        )
    }

    func testSupervisor_CanEnd() throws {
        guard let supervisor = IngredientListSupervisor(
            container: self.container,
            navigationItem: self.navigationItem,
            parent: self.parent,
            content: TestAppContent.testBarListContent
        ) else {
            XCTFail("Ingredient List Supervisor failed to initialize")
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
