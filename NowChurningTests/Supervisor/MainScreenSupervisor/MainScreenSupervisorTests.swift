//
//  MainScreenSupervisorTests.swift
//  NowChurningTests
//
//  Created by Austin Dumm on 4/17/23.
//

import XCTest

@testable import NowChurning

final class MainScreenSupervisorTests: SupervisorTests {

    var navigation: StackNavigation!
    var delegate: MainScreenAppNavDelegateMock!

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.navigation = StackNavigation()
        self.delegate = .init()
    }

    func testSupervisor_Initializes() throws {
        let _ = MainScreenSupervisor(
            navigator: self.navigation,
            navigationHandler: self.delegate,
            content: TestAppContent.testMainScreenContent
        )

        XCTAssert(
            self.navigation.topViewController is TileViewController
        )
    }

    func testSupervisor_CannotEnd() throws {
        let supervisor = MainScreenSupervisor(
            navigator: self.navigation,
            navigationHandler: self.delegate,
            content: TestAppContent.testMainScreenContent
        )

        XCTAssertFalse(supervisor.canEnd())
    }

}
