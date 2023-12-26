//
//  MeasureListSupervisorTests.swift
//  NowChurningTests
//
//  Created by Austin Dumm on 5/25/23.
//

import XCTest
@testable import NowChurning

final class MeasureListSupervisorTests: SupervisorTests {

    var container: UIViewController!
    var navigatorItem: UINavigationItem!
    var parent: MeasureListSupervisorParentMock!

    override func setUpWithError() throws {
        try super.setUpWithError()
        
        self.container = .init()
        self.navigatorItem = .init()
        self.parent = .init()
    }

    func test_Initializes() throws {
        let _ = MeasureListSupervisor(
            container: self.container,
            navigationItem: self.navigatorItem,
            content: .init(presentationContent: TestAppContent.testMeasureListContent)
        )

        XCTAssert(
            self.container
                .children
                .first is ItemListViewController
        )
    }

    func test_CanImmediatelyEnd() throws {
        let supervisor = MeasureListSupervisor(
            container: self.container,
            navigationItem: self.navigatorItem,
            content: .init(presentationContent: TestAppContent.testMeasureListContent)
        )

        XCTAssert(supervisor?.canEnd() ?? false)
    }

}
