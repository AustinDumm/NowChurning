//
//  MainFlowSupervisorTests.swift
//  NowChurningTests
//
//  Created by Austin Dumm on 4/17/23.
//

import XCTest

@testable import NowChurning

final class MainFlowSupervisorTests: SupervisorTests {

    var window: UIWindow!

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.window = .init()
    }

    func testSupervisor_Initializes() throws {
        let _ = MainFlowSupervisor(
            window: self.window,
            content: TestAppContent.testMainFlowContent
        )

        XCTAssert(
            self.window.rootViewController is UINavigationController
        )

        XCTAssert(
            (self.window.rootViewController as! UINavigationController)
                .topViewController is TileViewController
        )
    }

    func testSupervisor_ToInventory() throws {
        let supervisor = MainFlowSupervisor(
            window: self.window,
            content: TestAppContent.testMainFlowContent
        )
        supervisor.navigateTo(action: .inventory)

        let expectation = XCTestExpectation()
        DispatchQueue.main.async {
            XCTAssert(
                (self.window.rootViewController as! UINavigationController)
                    .topViewController?
                    .children
                    .first is ItemListViewController
            )
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 0.2)
    }

    func testSupervisor_ToMyRecipes() throws {
        let supervisor = MainFlowSupervisor(
            window: self.window,
            content: TestAppContent.testMainFlowContent
        )
        supervisor.navigateTo(action: .myRecipes)

        let expectation = XCTestExpectation()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            XCTAssert(
                (self.window.rootViewController as! UINavigationController)
                    .topViewController?
                    .children
                    .first is ItemListViewController
            )
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 0.5)
    }

}
