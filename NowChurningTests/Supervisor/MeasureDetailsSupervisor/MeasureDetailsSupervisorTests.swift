//
//  MeasureDetailsSupervisorTests.swift
//  NowChurningTests
//
//  Created by Austin Dumm on 5/25/23.
//

import XCTest
import Factory
@testable import NowChurning

final class MeasureDetailsSupervisorTests: SupervisorTests {
    var container: UIViewController!
    var navigatorItem: UINavigationItem!
    var parent: MeasureDetailsSupervisorParentMock!
    var store: StockedMeasureListCoreDataStore!

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.container = .init()
        self.navigatorItem = .init()
        self.parent = .init()
        self.store = .init(
            domainModelSink: MeasureListDomainModelSinkMock(),
            user: Container.shared.coreDataUserManager().user,
            context: Container.shared.managedObjectContext()
        )
    }

    func test_InitializesNew() throws {
        let _ = MeasureDetailsSupervisor(
            container: self.container,
            navigationItem: self.navigatorItem,
            measure: .newIngredient,
            listStore: self.store,
            content: .init(applicationContent: TestAppContent.testMeasureApplicationContent, presentationContent: TestAppContent.testMeasureDetailsContent)
        )

        XCTAssert(
            self.container
                .children
                .first is ItemListViewController
        )
    }

    func test_InitializesExistingIngredient() throws {
        let _ = MeasureDetailsSupervisor(
            container: self.container,
            navigationItem: self.navigatorItem,
            measure: .existingIngredient(.init(name: "", description: "", tags: [])),
            listStore: self.store,
            content: .init(applicationContent: TestAppContent.testMeasureApplicationContent, presentationContent: TestAppContent.testMeasureDetailsContent)
        )

        XCTAssert(
            self.container
                .children
                .first is ItemListViewController
        )
    }

    func test_InitializesExistingMeasure() throws {
        let _ = MeasureDetailsSupervisor(
            container: self.container,
            navigationItem: self.navigatorItem,
            measure: .existingMeasure(.init(ingredient: .init(name: "", description: "", tags: []), measure: .any)),
            listStore: self.store,
            content: .init(applicationContent: TestAppContent.testMeasureApplicationContent, presentationContent: TestAppContent.testMeasureDetailsContent)
        )

        XCTAssert(
            self.container
                .children
                .first is ItemListViewController
        )
    }

    func test_CanImmediatelyEnd() throws {
        let supervisor = MeasureDetailsSupervisor(
            container: self.container,
            navigationItem: self.navigatorItem,
            measure: .newIngredient,
            listStore: self.store,
            content: .init(applicationContent: TestAppContent.testMeasureApplicationContent, presentationContent: TestAppContent.testMeasureDetailsContent)
        )

        XCTAssert(
            supervisor.canEnd()
        )
    }

}
