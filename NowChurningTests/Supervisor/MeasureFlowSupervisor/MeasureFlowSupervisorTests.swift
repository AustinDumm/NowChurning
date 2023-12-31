//
//  MeasureFlowSupervisorTests.swift
//  NowChurningTests
//
//  Created by Austin Dumm on 5/25/23.
//

import XCTest
import Factory
@testable import NowChurning

final class MeasureFlowSupervisorTests: SupervisorTests {

    var parent: MeasureFlowSupervisorParentMock!
    var navigator: SegmentedNavigationController!
    var store: StockedMeasureListCoreDataStore!

    var testMeasure: Measure {
        self.testMeasureList[1]
    }
    let testMeasureList: [Measure] = [
        .init(
            ingredient: .init(name: "1", description: "", tags: []),
            measure: .volume(.init(value: 2.5, unit: .fluidOunces))
        ),
        .init(
            ingredient: .init(name: "2", description: "", tags: []),
            measure: .count(.init(value: 1, unit: .count), "Test Count")
        ),
        .init(
            ingredient: .init(name: "3", description: "", tags: []),
            measure: .any
        ),
    ]

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.parent = .init()
        self.navigator = SegmentedNavigationController(rootViewController: .init())
        self.store = .init(
            domainModelSink: MeasureListDomainModelSinkMock(),
            user: Container.shared.coreDataUserManager().user,
            context: Container.shared.managedObjectContext())
    }

    func test_Initializes() throws {
        let _ = MeasureFlowSupervisor(
            parent: self.parent,
            navigator: self.navigator,
            measure: .existingMeasure(self.testMeasure),
            measureStore: self.store,
            content: TestAppContent.testEditMeasureDetailsContent
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

    func test_InitializesWithExistingIngredient() throws {
        let _ = MeasureFlowSupervisor(
            parent: self.parent,
            navigator: self.navigator,
            measure: .existingIngredient(self.testMeasure.ingredient),
            measureStore: self.store,
            content: TestAppContent.testEditMeasureDetailsContent
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

    func test_InitializesWithNew() throws {
        let _ = MeasureFlowSupervisor(
            parent: self.parent,
            navigator: self.navigator,
            measure: .newIngredient,
            measureStore: self.store,
            content: TestAppContent.testEditMeasureDetailsContent
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

    func test_CanEndImmediately() throws {
        let supervisor = MeasureFlowSupervisor(
            parent: self.parent,
            navigator: self.navigator,
            measure: .newIngredient,
            measureStore: self.store,
            content: TestAppContent.testEditMeasureDetailsContent
        )

        XCTAssert(supervisor.canEnd())
    }

    func test_WhenGivenDidSave_DoesTellParentEnd() throws {
        let supervisor = MeasureFlowSupervisor(
            parent: self.parent,
            navigator: self.navigator,
            measure: .newIngredient,
            measureStore: self.store,
            content: TestAppContent.testEditMeasureDetailsContent
        )

        let expectation = XCTestExpectation()
        self.parent.navigateForEditDoneTypeClosure = { _ in
            expectation.fulfill()
        }

        supervisor.navigate(forDoneType: .save)
        wait(for: [expectation], timeout: 0.0)
    }

    func test_WhenGivenDidCancel_DoesTellParent() throws {
        let supervisor = MeasureFlowSupervisor(
            parent: self.parent,
            navigator: self.navigator,
            measure: .newIngredient,
            measureStore: self.store,
            content: TestAppContent.testEditMeasureDetailsContent
        )

        let expectation = XCTestExpectation()
        self.parent.navigateForEditDoneTypeClosure = { _ in
            expectation.fulfill()
        }

        supervisor.navigate(forDoneType: .cancel)
        wait(for: [expectation], timeout: 0.0)
    }

    func test_WhenNavigationPopped_DoesTellParentEnd() throws {
        let supervisor = MeasureFlowSupervisor(
            parent: self.parent,
            navigator: self.navigator,
            measure: .newIngredient,
            measureStore: self.store,
            content: TestAppContent.testEditMeasureDetailsContent
        )

        let expectation = XCTestExpectation()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            self.parent.childDidEndSupervisorClosure = { child in
                XCTAssertIdentical(
                    child,
                    supervisor
                )
                expectation.fulfill()
            }

            _ = self.navigator.popViewController(animated: false)
            self.navigator
                .delegate?
                .navigationController?(
                    self.navigator,
                    didShow: .init(),
                    animated: false
                )
        }

        wait(for: [expectation], timeout: 2.0)
    }

    func test_WhenNavigationPopped_DoesReplaceNavigationDelegate() throws {
        let mockDelegate = MockStackNavigationDelegate()
        self.navigator.pushDelegate(mockDelegate)
        let supervisor = MeasureFlowSupervisor(
            parent: self.parent,
            navigator: self.navigator,
            measure: .newIngredient,
            measureStore: self.store,
            content: TestAppContent.testEditMeasureDetailsContent
        )
        _ = supervisor

        let expectation = XCTestExpectation()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            _ = self.navigator.popViewController(animated: false)
            self.navigator
                .delegate?
                .navigationController?(
                    self.navigator,
                    didShow: .init(),
                    animated: false
                )

            XCTAssertIdentical(
                self.navigator.topDelegate,
                mockDelegate
            )
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2.0)
    }

}
