//
//  ReadOnlyIngredientListItemListPresentationTests.swift
//  NowChurningTests
//
//  Created by Austin Dumm on 5/22/23.
//

import XCTest
@testable import NowChurning

final class ReadOnlyIngredientListItemListPresentationTests: XCTestCase {

    var presentation: ReadOnlyIngredientListItemListPresentation!
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

    lazy var expectedContent = ReadOnlyIngredientListItemListPresentation.Content(
        listTitle: "TEST TITLE",
        addIngredientInstruction: "Test Add New Ingredient",
        ingredientSectionsHeader: "Test Suggestions"
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
            displayModel.inventorySections.count + 1,
            viewModel.sections.count
        )

        let expectedAddIngredientItem = viewModel.sections.first?.items.first
        guard
            case .text(self.expectedContent.addIngredientInstruction) = expectedAddIngredientItem?.type
        else {
            XCTFail("Expected first section first item to be: text(\(self.expectedContent.addIngredientInstruction). Found: \(expectedAddIngredientItem.debugDescription)")
            return
        }

        XCTAssertEqual(
            expectedAddIngredientItem?.context,
            [.add]
        )

        for (index, (displaySection, viewSection))
                in zip(displayModel.inventorySections, viewModel.sections.dropFirst()).enumerated() {
            if index == 0 {
                XCTAssertEqual(
                    viewSection.title,
                    expectedContent.ingredientSectionsHeader
                )
            } else {
                XCTAssertEqual(
                    viewSection.title,
                    viewSection.title
                )
            }

            for (displayItem, viewItem)
                    in zip(displaySection.items, viewSection.items) {
                XCTAssertEqual(
                    [.navigate],
                    viewItem.context
                )

                switch viewItem.type {
                case .text(let text):
                    XCTAssertEqual(
                        displayItem.title,
                        text
                    )

                case .editSingleline,
                        .editMultiline,
                        .attributedText,
                        .message:
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

    func testPresentation_WhenSentAddIngrEvent_DoesSendActionToSink() throws {
        let expectation = XCTestExpectation()
        let testIndexPath = IndexPath(
            item: 0,
            section: 0
        )

        self.mockActionSink.sendActionClosure = { action in
            guard case .newIngredient = action else {
                XCTFail("Expected newIngredient when tapping first item. Found: \(action)")
                return
            }
            expectation.fulfill()
        }

        self.presentation.send(event: .select(itemAt: testIndexPath))
        wait(for: [expectation], timeout: 0.0)
    }

    func testPresentation_WhenSentEvent_DoesSendActionToSink() throws {
        let expectation = XCTestExpectation()
        let testIndexPath = IndexPath(
            item: 1,
            section: 1
        )

        self.mockActionSink.sendActionClosure = { action in
            switch action {
            case .selectItem(
                inSection: let section,
                atIndex: let index
            ):
                XCTAssertEqual(
                    section,
                    testIndexPath.section - 1
                )

                XCTAssertEqual(
                    index,
                    testIndexPath.item
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
                0,
                received.rightButtons.count
            )

            expectation.fulfill()
        }

        self.presentation.navBarViewModelSink = self.mockNavBarViewModelSink
        wait(for: [expectation], timeout: 0.0)
    }

}
