//
//  InventorySupervisorTests.swift
//  NowChurningTests
//
//  Created by Austin Dumm on 4/17/23.
//

import XCTest

@testable import NowChurning

final class InventorySupervisorTests: SupervisorTests {

    var parent: ParentSupervisorMock!
    var navigator: StackNavigation!

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.parent = .init()
        self.navigator = .init(rootViewController: .init())
    }

    func testSupervisor_Initializes() throws {
        let supervisor = InventorySupervisor(
            parent: self.parent,
            navigator: self.navigator,
            content: TestAppContent.testInventoryContent
        )
        guard supervisor.start() else {
            XCTFail("Failed to start supervisor")
            return
        }


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
        let supervisor = InventorySupervisor(
            parent: self.parent,
            navigator: self.navigator,
            content: TestAppContent.testInventoryContent
        )

        guard supervisor.start() else {
            XCTFail("Failed to initialize My Bar Supervisor")
            return
        }

        XCTAssert(supervisor.canEnd())

        let expectation = XCTestExpectation()
        supervisor.requestEnd {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 0.0)
    }

    func testSupervisor_CanEndInIngredientDetails() throws {
        let supervisor = InventorySupervisor(
            parent: self.parent,
            navigator: self.navigator,
            content: TestAppContent.testInventoryContent
        )
        guard supervisor.start() else {
            XCTFail("Failed to initialize My Bar Supervisor")
            return
        }

        supervisor.navigateToDetails(forMeasure: Measure(
            ingredient: Ingredient(
                name: "Ingredient",
                description: "",
                tags: []
            ),
            measure: .volume(
                Measurement(
                    value: 2.75,
                    unit: .fluidOunces
                )
            )
        ))

        XCTAssert(supervisor.canEnd())

        let expectation = XCTestExpectation()
        supervisor.requestEnd {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 0.0)
    }

    func testSupervisor_WhenNavigationBack_DoesEndSelf() throws {
        let delegate = MockUINavigationControllerDelegate()
        self.navigator.pushDelegate(delegate)

        let supervisor = InventorySupervisor(
            parent: self.parent,
            navigator: self.navigator,
            content: TestAppContent.testInventoryContent
        )
        guard supervisor.start() else {
            XCTFail("Failed to initialize My Bar Supervisor")
            return
        }

        let expectation = XCTestExpectation()
        DispatchQueue.main.async {
            self.parent.childDidEndSupervisorClosure = { child in
                XCTAssertIdentical(
                    child,
                    supervisor
                )
                expectation.fulfill()
            }

            self.navigator.popViewController(animated: false)
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
