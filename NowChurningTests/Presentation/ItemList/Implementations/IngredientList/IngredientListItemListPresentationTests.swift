//
//  IngredientListItemListPresentationTests.swift
//  NowChurningTests
//
//  Created by Austin Dumm on 12/17/22.
//

import XCTest
@testable import NowChurning

final class IngredientListItemListPresentationTests: XCTestCase {

    var presentation: IngredientListItemListPresentation!
    var mockViewModelSink: ItemListViewModelSinkMock!
    var mockNavBarViewModelSink: NavBarViewModelSinkMock!
    var mockActionSink: IngredientListActionSinkMock!

    let testDisplayModel = IngredientListDisplayModel(
        inventorySections: [
            .init(
                title: "First",
                items: [
                    .init(title: "First1"),
                    .init(title: "First2"),
                    .init(title: "First3")
                ]
            ),
            .init(
                title: "Second",
                items: [
                    .init(title: "Second1"),
                    .init(title: "Second2"),
                    .init(title: "Second3")
                ]
            ),
            .init(
                title: "Third",
                items: [
                    .init(title: "Third1"),
                    .init(title: "Third2"),
                    .init(title: "Third3")
                ]
            ),
        ]
    )
    let testAlertContent = AlertContent(
        descriptionText: "TEST DESCRIPTION",
        confirmText: "TEST CONFIRM",
        cancelText: "TEST CANCEL"
    )

    lazy var expectedContent = IngredientListItemListPresentation.Content(
        listTitle: "TEST TITLE",
        alertContent: self.testAlertContent,
        emptyListMessage: "Test Empty"
    )

    override func setUp() {
        self.mockActionSink = .init()
        self.presentation = .init(
            actionSink: self.mockActionSink,
            content: self.expectedContent
        )
        self.mockViewModelSink = .init()
        self.mockNavBarViewModelSink = .init()
        self.presentation.viewModelSink = self.mockViewModelSink
        self.presentation.navBarViewModelSink = mockNavBarViewModelSink
    }

    func assertMatchingViewModel(
        expectedFor displayModel: IngredientListDisplayModel,
        receieved viewModel: ItemListViewModel,
        isEditing: Bool
    ) {
        XCTAssertEqual(
            displayModel.inventorySections.count,
            viewModel.sections.count
        )

        for (displaySection, viewSection)
                in zip(displayModel.inventorySections, viewModel.sections) {
            XCTAssertEqual(
                displaySection.title,
                viewSection.title
            )

            for (displayItem, viewItem)
                    in zip(displaySection.items, viewSection.items) {
                XCTAssertEqual(
                    isEditing ? [.delete] : [.navigate, .delete],
                    viewItem.context
                )

                switch viewItem.type {
                case .text(let text), .message(let text):
                    XCTAssertEqual(
                        displayItem.title,
                        text
                    )

                case .editSingleline,
                        .attributedText,
                        .editMultiline:
                    XCTFail("Expected text item. Found editable item")
                }
            }
        }
    }

    func testPresentation_WhenGivenDisplayModel_DoesSendViewModel() throws {
        let expectation = XCTestExpectation()
        self.mockViewModelSink.sendViewModelClosure = { receivedViewModel in
            self.assertMatchingViewModel(
                expectedFor: self.testDisplayModel,
                receieved: receivedViewModel,
                isEditing: false
            )
            expectation.fulfill()
        }

        self.presentation.send(displayModel: self.testDisplayModel)
        wait(for: [expectation], timeout: 0.0)
    }

    func testPresentation_WhenGivenDisplayModelAndEditing_DoesSendViewModel() throws {
        self.presentation
            .send(
                editModeDisplayModel: .init(
                    isEditing: true,
                    canSave: true
                )
            )
        let expectation = XCTestExpectation()
        self.mockViewModelSink.sendViewModelClosure = { receivedViewModel in
            self.assertMatchingViewModel(
                expectedFor: self.testDisplayModel,
                receieved: receivedViewModel,
                isEditing: true
            )
            expectation.fulfill()
        }

        self.presentation.send(displayModel: self.testDisplayModel)
        wait(for: [expectation], timeout: 0.0)
    }

    func testPresentation_WhenGivenNewSink_DoesSendViewModel() throws {
        self.presentation.send(displayModel: self.testDisplayModel)

        let newSink = ItemListViewModelSinkMock()
        let expectation = XCTestExpectation()
        newSink.sendViewModelClosure = { receivedViewModel in
            self.assertMatchingViewModel(
                expectedFor: self.testDisplayModel,
                receieved: receivedViewModel,
                isEditing: false
            )

            expectation.fulfill()
        }

        self.presentation.viewModelSink = newSink
        wait(for: [expectation], timeout: 0.0)
    }

    func testPresentation_WhenGivenNewSink_DoesNotSendToOldSink() throws {
        let newSink = ItemListViewModelSinkMock()
        let oldExpectation = XCTestExpectation()
        oldExpectation.isInverted = true
        self.mockViewModelSink.sendViewModelClosure = { _ in
            oldExpectation.fulfill()
        }

        self.presentation.viewModelSink = newSink
        self.presentation.send(displayModel: self.testDisplayModel)

        wait(for: [oldExpectation], timeout: 0.0)
    }

    func testPresentation_WhenSentEvent_DoesSendActionToSink() throws {
        let expectation = XCTestExpectation()
        let testIndexPath = IndexPath(
            item: 1,
            section: 0
        )

        self.mockActionSink.sendActionClosure = { action in
            switch action {
            case .selectItem(
                inSection: let section,
                atIndex: let index
            ):
                XCTAssertEqual(
                    testIndexPath.section,
                    section
                )

                XCTAssertEqual(
                    testIndexPath.item,
                    index
                )
                expectation.fulfill()
            case .newIngredient,
                    .deleteItem(inSection: _, atIndex: _):
                XCTFail("Expected select item action")
            }
        }

        self.presentation.send(event: .select(itemAt: testIndexPath))
        wait(for: [expectation], timeout: 0.0)
    }

    func testPresentation_WhenNavBarVMSinkSet_DoesSendViewModel() throws {
        let expectation = XCTestExpectation()
        self.mockNavBarViewModelSink.sendNavBarViewModelClosure = { received in
            XCTAssertEqual(
                self.expectedContent.listTitle,
                received.title
            )

            XCTAssertEqual(
                1,
                received.leftButtons.count
            )

            let receivedBackButton = received.leftButtons[0]
            XCTAssertEqual(
                .back,
                receivedBackButton.type
            )

            XCTAssert(receivedBackButton.isEnabled)

            XCTAssertEqual(
                2,
                received.rightButtons.count
            )

            let receivedAddButton = received.rightButtons[0]
            XCTAssertEqual(
                .add,
                receivedAddButton.type
            )

            guard let receivedEditButton = received.rightButtons[safe: 1] else {
                XCTFail("Expected right button at index 1")
                return
            }
            XCTAssertEqual(
                .edit,
                receivedEditButton.type
            )

            XCTAssert(receivedAddButton.isEnabled)
            expectation.fulfill()
        }

        self.presentation.navBarViewModelSink = self.mockNavBarViewModelSink
        wait(for: [expectation], timeout: 0.0)
    }

    func testPresentation_WhenEditChangedNoIngr_SendsNoEditButton() throws {
        self.presentation
            .send(
                displayModel: .init(inventorySections: [])
            )
        let expectation = XCTestExpectation()
        self.mockNavBarViewModelSink.sendNavBarViewModelClosure = { viewModel in
            XCTAssertEqual(
                1,
                viewModel.rightButtons.count
            )
            XCTAssertEqual(
                NavBarViewModel.ButtonType.add,
                viewModel.rightButtons.first?.type
            )
            expectation.fulfill()
        }

        self.presentation
            .send(
                editModeDisplayModel: .init(
                    isEditing: false,
                    canSave: true
                )
            )

        wait(
            for: [expectation],
            timeout: 0.0
        )
    }

    func testPresentation_WhenDisplayModelChangedNoIngr_SendsNoEditButton() throws {
        let expectation = XCTestExpectation()
        self.mockNavBarViewModelSink.sendNavBarViewModelClosure = { viewModel in
            XCTAssertEqual(
                1,
                viewModel.rightButtons.count
            )
            XCTAssertEqual(
                NavBarViewModel.ButtonType.add,
                viewModel.rightButtons.first?.type
            )
            expectation.fulfill()
        }

        self.presentation
            .send(
                displayModel: .init(inventorySections: [])
            )

        wait(
            for: [expectation],
            timeout: 0.0
        )
    }

    func testPresentation_WhenEditUpdated_DoesSendNavBarViewModel() throws {
        self.presentation.navBarViewModelSink = self.mockNavBarViewModelSink

        let expectation = XCTestExpectation()
        self.mockNavBarViewModelSink.sendNavBarViewModelClosure = { received in
            XCTAssertEqual(
                self.expectedContent.listTitle,
                received.title
            )

            XCTAssertEqual(
                1,
                received.leftButtons.count
            )

            let receivedBackButton = received.leftButtons[0]
            XCTAssertEqual(
                .cancel,
                receivedBackButton.type
            )

            XCTAssert(receivedBackButton.isEnabled)

            XCTAssertEqual(
                1,
                received.rightButtons.count
            )

            let receivedSaveButton = received.rightButtons[0]
            XCTAssertEqual(
                .save,
                receivedSaveButton.type
            )

            XCTAssert(receivedSaveButton.isEnabled)
            expectation.fulfill()
        }

        self.presentation.send(
            editModeDisplayModel: .init(
                isEditing: true,
                canSave: true
            )
        )
        wait(for: [expectation], timeout: 0.0)
    }

    func testPresentation_WhenEditUpdatedNoSave_DoesSendNavBarViewModel() throws {
        self.presentation.navBarViewModelSink = self.mockNavBarViewModelSink

        let expectation = XCTestExpectation()
        self.mockNavBarViewModelSink.sendNavBarViewModelClosure = { received in
            XCTAssertEqual(
                self.expectedContent.listTitle,
                received.title
            )

            XCTAssertEqual(
                1,
                received.leftButtons.count
            )

            let receivedBackButton = received.leftButtons[0]
            XCTAssertEqual(
                .cancel,
                receivedBackButton.type
            )

            XCTAssert(receivedBackButton.isEnabled)

            XCTAssertEqual(
                1,
                received.rightButtons.count
            )

            let receivedSaveButton = received.rightButtons[0]
            XCTAssertEqual(
                .save,
                receivedSaveButton.type
            )

            XCTAssertFalse(receivedSaveButton.isEnabled)
            expectation.fulfill()
        }

        self.presentation.send(
            editModeDisplayModel: .init(
                isEditing: true,
                canSave: false
            )
        )
        wait(for: [expectation], timeout: 0.0)
    }

    func testPresentation_WhenAddButtonTapEvent_DoesSendAction() throws {
        let expectation = XCTestExpectation()
        self.mockActionSink.sendActionClosure = { action in
            switch action {
            case .newIngredient:
                expectation.fulfill()
            case .selectItem,
                    .deleteItem:
                XCTFail("Expected newIngredient action")
            }
        }

        self.presentation.send(
            navBarEvent: .tap(
                .right,
                index: 0
            )
        )
        wait(for: [expectation], timeout: 0.0)
    }

    func testPresentation_WhenDeleteItemEvent_DoesSendAction() throws {
        let sentIndexPath = IndexPath(
            item: 2,
            section: 1
        )

        let expectation = XCTestExpectation()
        self.mockActionSink.sendActionClosure = { action in
            switch action {
            case .deleteItem(
                inSection: let section,
                atIndex: let index
            ):
                XCTAssertEqual(
                    sentIndexPath.section,
                    section
                )

                XCTAssertEqual(
                    sentIndexPath.item,
                    index
                )

                expectation.fulfill()
            case .newIngredient,
                    .selectItem:
                XCTFail("Expected delete item action")
            }
        }

        self.presentation.send(
            event: .delete(
                itemAt: sentIndexPath
            )
        )

        wait(for: [expectation], timeout: 0.0)
    }

    func testPresentation_WhenGivenEditModeModel_DoesSendListViewModel() throws {
        self.presentation.send(displayModel: self.testDisplayModel)

        let expectation = XCTestExpectation()
        self.mockViewModelSink.sendViewModelClosure = { viewModel in
            XCTAssert(viewModel.isEditing)
            expectation.fulfill()
        }

        self.presentation.send(
            editModeDisplayModel: .init(
                isEditing: true,
                canSave: false
            )
        )
        wait(for: [expectation], timeout: 0.0)
    }

    func testPresentation_WhenNavEditEventSent_DoesSendEditAction() throws {
        self.presentation.send(displayModel: self.testDisplayModel)

        let expectation = XCTestExpectation()
        self.mockActionSink.sendEditModeActionClosure = { action in
            switch action {
            case .startEditing:
                expectation.fulfill()
            case .finishEditing(_):
                XCTFail("Expected start editing action")
            }
        }

        self.presentation.send(
            navBarEvent: .tap(
                .right,
                index: 1
            )
        )
        wait(for: [expectation], timeout: 0.0)
    }

    func testPresentation_WhenNavSaveEventSent_DoesSendEditAction() throws {
        self.presentation.send(displayModel: self.testDisplayModel)

        self.presentation.send(
            editModeDisplayModel: .init(
                isEditing: true,
                canSave: true
            )
        )

        let expectation = XCTestExpectation()
        self.mockActionSink.sendEditModeActionClosure = { action in
            switch action {
            case .finishEditing(.save):
                expectation.fulfill()
            case .finishEditing(.cancel),
                    .startEditing:
                XCTFail("Expected finish editing by cancel action")
            }
        }

        self.presentation.send(
            navBarEvent: .tap(
                .right,
                index: 0
            )
        )
        wait(for: [expectation], timeout: 0.0)
    }

    func testPresentation_WhenNavCancelEventSent_DoesSendEditAction() throws {
        self.presentation.send(displayModel: self.testDisplayModel)

        self.presentation.send(
            editModeDisplayModel: .init(
                isEditing: true,
                canSave: true
            )
        )

        let expectation = XCTestExpectation()
        self.mockActionSink.sendEditModeActionClosure = { action in
            switch action {
            case .finishEditing(.cancel):
                expectation.fulfill()
            case .finishEditing(.save),
                    .startEditing:
                XCTFail("Expected finish editing by cancel action")
            }
        }

        self.presentation.send(
            navBarEvent: .tap(
                .left,
                index: 0
            )
        )
        wait(for: [expectation], timeout: 0.0)
    }

    func testPresentation_WhenSentCancelAlert_DoesSendAlertToNavBar() throws {
        let expectation = XCTestExpectation()
        expectation.expectedFulfillmentCount = 2
        self.mockNavBarViewModelSink.sendAlertViewModelClosure = { alertVM in
            alertVM.actions[1].callback()

            XCTAssertEqual(
                self.testAlertContent.descriptionText,
                alertVM.message
            )

            XCTAssertEqual(
                self.testAlertContent.cancelText,
                alertVM.actions[0].title
            )

            XCTAssertEqual(
                self.testAlertContent.confirmText,
                alertVM.actions[1].title
            )

            expectation.fulfill()
        }

        self.presentation.send(
            alertDisplayModel: .cancel,
            didConfirm: { didConfirm in
                XCTAssert(didConfirm)
                expectation.fulfill()
            }
        )

        wait(for: [expectation], timeout: 0.0)
    }
}
