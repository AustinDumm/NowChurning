//
//  NavBarManagerTests.swift
//  NowChurningTests
//
//  Created by Austin Dumm on 12/25/22.
//

import XCTest
@testable import NowChurning

final class NavBarManagerTests: XCTestCase {

    let testTitle = "TEST TITLE"
    let cancelButton = UIBarButtonItem(systemItem: .cancel)
    let saveButton = UIBarButtonItem(systemItem: .save)
    let editButton = UIBarButtonItem(systemItem: .edit)

    let contentContainer = {
        let container = AlertContent(
            descriptionText: "DESCRIPTION",
            confirmText: "CANCEL",
            cancelText: "CONFIRM"
        )

        return container
    }()

    lazy var systemBuilder = {
        let mock = NavBarManagerSystemButtonBuilderMock()

        mock.cancelButtonActionReturnValue = self.cancelButton
        mock.saveButtonActionReturnValue = self.saveButton
        mock.editButtonActionReturnValue = self.editButton

        return mock
    }()

    func testManager_WhenGivenCanEdit_SetsBarForCanEdit() throws {
        let navigationItem = UINavigationItem()

        let mockBackButton = UIBarButtonItem()
        let buttonProvider = NavBarManagerProvidedButtonBuilderMock()
        buttonProvider.backButtonReturnValue = mockBackButton

        let navBarManager = NavBarManager(
            navigationItem: navigationItem,
            alertViewDelegate: AlertViewDelegateMock(),
            providedButtonBuilder: buttonProvider,
            systemButtonBuilder: self.systemBuilder,
            eventSink: NavBarEventSinkMock()
        )

        navBarManager.send(
            navBarViewModel: .init(
                title: self.testTitle,
                leftButtons: [.init(type: .cancel, isEnabled: true)],
                rightButtons: [.init(type: .save, isEnabled: false)]
            )
        )

        XCTAssertEqual(
            self.testTitle,
            navigationItem.title
        )

        XCTAssertIdentical(
            self.cancelButton,
            navigationItem.leftBarButtonItem
        )

        XCTAssertIdentical(
            self.saveButton,
            navigationItem.rightBarButtonItem
        )
    }

    func testManager_WhenGivenCannotEdit_SetsBarForCannotEdit() throws {
        let navigationItem = UINavigationItem()

        let mockBackButton = UIBarButtonItem()
        let buttonProvider = NavBarManagerProvidedButtonBuilderMock()
        buttonProvider.backButtonReturnValue = mockBackButton

        let navBarManager = NavBarManager(
            navigationItem: navigationItem,
            alertViewDelegate: AlertViewDelegateMock(),
            providedButtonBuilder: buttonProvider,
            systemButtonBuilder: self.systemBuilder,
            eventSink: NavBarEventSinkMock()
        )

        navBarManager.send(
            navBarViewModel: .init(
                title: self.testTitle,
                leftButtons: [.init(type: .back, isEnabled: true)],
                rightButtons: [.init(type: .edit, isEnabled: true)]
            )
        )

        XCTAssertEqual(
            self.testTitle,
            navigationItem.title
        )

        XCTAssertIdentical(
            self.editButton,
            navigationItem.rightBarButtonItem
        )
    }

    func testManager_WhenSentAlert_DoesPassToDelegate() throws {
        func testFor(side: NavBarViewModel.Side) {
            let actionCount = 4
            let expectedViewModel = NavBarAlertViewModel(
                title: "TEST-TITLE",
                message: "TEST-MESSAGE",
                side: side,
                buttonIndex: 0,
                actions: Array(
                    repeating: .init(title: "", type: .cancel, callback: {}),
                    count: actionCount
                )
            )

            let expectation = XCTestExpectation()
            alertDelegate.showActionCardOnWithDisplayClosure = { _, display in
                XCTAssertEqual(
                    expectedViewModel.title,
                    display.title
                )

                XCTAssertEqual(
                    expectedViewModel.message,
                    display.description
                )

                XCTAssertEqual(
                    actionCount,
                    display.buttons.count
                )

                expectation.fulfill()
            }

            navBarManager.send(
                alertViewModel: expectedViewModel
            )

            wait(for: [expectation], timeout: 0.0)
        }

        let navigationItem = UINavigationItem()

        let mockBackButton = UIBarButtonItem()
        let buttonProvider = NavBarManagerProvidedButtonBuilderMock()
        let alertDelegate = AlertViewDelegateMock()
        buttonProvider.backButtonReturnValue = mockBackButton

        let navBarManager = NavBarManager(
            navigationItem: navigationItem,
            alertViewDelegate: alertDelegate,
            providedButtonBuilder: buttonProvider,
            systemButtonBuilder: self.systemBuilder,
            eventSink: NavBarEventSinkMock()
        )

        navBarManager.send(
            navBarViewModel: .init(
                title: self.testTitle,
                leftButtons: [.init(type: .cancel, isEnabled: true)],
                rightButtons: [.init(type: .save, isEnabled: false)]
            )
        )

        testFor(side: .left)
        testFor(side: .right)
    }
}
