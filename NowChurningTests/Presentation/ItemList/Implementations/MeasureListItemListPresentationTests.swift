//
//  MeasureListItemListPresentationTests.swift
//  NowChurningTests
//
//  Created by Austin Dumm on 5/13/23.
//

import XCTest

@testable import NowChurning

final class MeasureListItemListPresentationTests: XCTestCase {

    var presentation: MeasureListItemListPresentation!

    var actionSink: MeasureListActionSinkMock!
    var viewModelSink: ItemListViewModelSinkMock!
    var navBarViewModelSink: NavBarViewModelSinkMock!

    var testDisplayModel = MeasureListDisplayModel(
        sections: [
            .init(
                title: "A",
                items: [
                    .init(
                        title: "Aaa",
                        id: .init()
                    ),
                    .init(
                        title: "Aab",
                        id: .init()
                    ),
                    .init(
                        title: "Aca",
                        id: .init()
                    ),
                ]
            ),
            .init(
                title: "B",
                items: [
                    .init(
                        title: "Baa",
                        id: .init()
                    ),
                    .init(
                        title: "Bbb",
                        id: .init()
                    ),
                    .init(
                        title: "Bzb",
                        id: .init()
                    ),
                ]
            ),
        ]
    )

    override func setUpWithError() throws {
        self.actionSink = .init()
        self.viewModelSink = .init()
        self.navBarViewModelSink = .init()

        self.presentation = .init(
            actionSink: self.actionSink,
            content: TestAppContent.testMeasureListContent
        )
        self.presentation.viewModelSink = self.viewModelSink
        self.presentation.navBarViewModelSink = self.navBarViewModelSink
    }

    override func tearDownWithError() throws {
        self.actionSink = nil
        self.viewModelSink = nil
        self.navBarViewModelSink = nil
    }

    func assert(
        isExpectedViewModel viewModel: ItemListViewModel,
        forDisplayModel displayModel: MeasureListDisplayModel,
        isEditing: Bool = false
    ) {
        XCTAssertEqual(
            viewModel.sections.count,
            displayModel.sections.count + 1
        )

        XCTAssertEqual(
            viewModel.sections.first!,
            .init(title: "", items: [
                .init(
                    type: .message(TestAppContent.testMeasureListContent.listInstruction),
                    context: []
                )
            ])
        )

        for (viewSection, displaySection)
                in zip(viewModel.sections.dropFirst(), displayModel.sections) {
            XCTAssert(
                viewSection.title.localizedCaseInsensitiveCompare(displaySection.title) == .orderedSame
            )

            XCTAssertEqual(
                viewSection.items.count,
                displaySection.items.count
            )

            for (viewItem, displayItem) in zip(viewSection.items, displaySection.items) {
                switch viewItem.type {
                case .text(let viewText):
                    XCTAssert(
                        viewText.localizedCaseInsensitiveCompare(displayItem.title) == .orderedSame
                    )
                default:
                    XCTFail("Expected text item, found: \(viewItem.type)")
                }

                let contextCount = isEditing ? 1 : 2
                let contexts = viewItem.context
                XCTAssertEqual(
                    contexts.count,
                    contextCount
                )

                XCTAssert(
                    contexts
                        .contains(.delete)
                )

                XCTAssert(
                    contexts
                        .contains(.navigate)
                )
            }
        }
    }

    func testPresentation_WhenGivenViewModelSink_DoesSendViewModel() throws {
        self.presentation.send(displayModel: self.testDisplayModel)

        let expectation = XCTestExpectation()
        let newSink = ItemListViewModelSinkMock()
        newSink
            .sendViewModelClosure = { viewModel in
                self.assert(
                    isExpectedViewModel: viewModel,
                    forDisplayModel: self.testDisplayModel
                )
                expectation.fulfill()
            }

        self.presentation.viewModelSink = newSink
        wait(for: [expectation], timeout: 0.0)
    }

    func testPresentation_WhenSentDisplayModel_DoesSendViewModel() throws {

        let expectation = XCTestExpectation()
        self.viewModelSink
            .sendViewModelClosure = { viewModel in
                self.assert(
                    isExpectedViewModel: viewModel,
                    forDisplayModel: self.testDisplayModel
                )
                expectation.fulfill()
            }

        self.presentation.send(displayModel: self.testDisplayModel)
        wait(for: [expectation], timeout: 0.0)
    }

    func testPresentation_WhenSelectEvent_DoesSendAction() throws {
        let testSection = 1
        let testIndex = 0

        let expectation = XCTestExpectation()
        self.actionSink.sendActionClosure = { action in
            switch action {
            case .selectMeasure(
                atIndex: let index,
                inSection: let section
            ):
                XCTAssertEqual(section, testSection - 1)
                XCTAssertEqual(index, testIndex)
                expectation.fulfill()
            default:
                XCTFail("Expected selectItem action. Found: \(action)")
            }
        }

        self.presentation
            .send(
                event: .select(
                    itemAt: IndexPath(
                        item: testIndex,
                        section: testSection
                    )
                )
            )
        wait(for: [expectation], timeout: 0.0)
    }

    func testPresentation_WhenSelectEventAndEditing_DoesNotSendAction() throws {
        let testSection = 1
        let testIndex = 0

        self.presentation.send(
            editModeDisplayModel: .init(
                isEditing: true,
                canSave: true
            )
        )

        let expectation = XCTestExpectation()
        expectation.isInverted = true
        self.actionSink.sendActionClosure = { action in
            expectation.fulfill()
        }

        self.presentation
            .send(
                event: .select(
                    itemAt: IndexPath(
                        item: testIndex,
                        section: testSection
                    )
                )
            )
        wait(for: [expectation], timeout: 0.0)
    }

    func testPresentation_WhenDeleteEventAndEditing_DoesSendAction() throws {
        let testSection = 1
        let testIndex = 0

        self.presentation.send(
            editModeDisplayModel: .init(
                isEditing: true,
                canSave: true
            )
        )

        let expectation = XCTestExpectation()
        self.actionSink.sendActionClosure = { action in
            switch action {
            case .deleteMeasure(
                atIndex: let index,
                inSection: let section
            ):
                XCTAssertEqual(section, testSection - 1)
                XCTAssertEqual(index, testIndex)
                expectation.fulfill()
            default:
                XCTFail("Expected delete item. Found: \(action)")
            }
        }

        self.presentation
            .send(
                event: .delete(
                    itemAt: IndexPath(
                        item: testIndex,
                        section: testSection
                    )
                )
            )
        wait(for: [expectation], timeout: 0.0)
    }

    func testPresentation_WhenDeleteEventNotEditing_DoesSendAction() throws {
        let testSection = 1
        let testIndex = 0

        let expectation = XCTestExpectation()
        self.actionSink.sendActionClosure = { action in
            switch action {
            case .deleteMeasure(
                atIndex: testIndex,
                inSection: testSection - 1
            ):
                expectation.fulfill()
            default:
                XCTFail("Expected delete for section: \(testSection), index: \(testIndex). Found: \(action)")
            }
        }

        self.presentation
            .send(
                event: .delete(
                    itemAt: IndexPath(
                        item: testIndex,
                        section: testSection
                    )
                )
            )
        wait(for: [expectation], timeout: 0.0)
    }

    func testPresentation_WhenDisplayModelSent_DoesSendNavBarModel() throws {
        self.presentation
            .send(
                editModeDisplayModel: .init(
                    isEditing: false,
                    canSave: false
                )
            )

        let expectation = XCTestExpectation()
        self.navBarViewModelSink.sendNavBarViewModelClosure = { viewModel in
            XCTAssertEqual(
                viewModel.leftButtons.count,
                1
            )

            let leftButton = viewModel.leftButtons[safe: 0]
            switch leftButton {
            case .init(type: .back, isEnabled: true):
                break
            default:
                XCTFail("Expected enabled Back button. Found: \(leftButton.debugDescription)")
            }

            XCTAssertEqual(
                viewModel.rightButtons.count,
                2
            )

            let addButton = viewModel.rightButtons[safe: 0]
            switch addButton {
            case .init(
                type: .add,
                displayTitle: TestAppContent
                    .testMeasureListContent
                    .addToInventoryDescription,
                isEnabled: true):
                break
            default:
                XCTFail("Expected enabled Add button. Found \(addButton.debugDescription)")
            }

            let editButton = viewModel.rightButtons[safe: 1]
            switch editButton {
            case .init(
                type: .edit,
                displayTitle: TestAppContent
                    .testMeasureListContent
                    .editListDescription,
                isEnabled: true):
                break
            default:
                XCTFail("Expected enabled Add button. Found \(editButton.debugDescription)")
            }
            expectation.fulfill()
        }

        self.presentation
            .send(displayModel: self.testDisplayModel)
        wait(for: [expectation], timeout: 0.0)
    }

    func testPresentation_WhenNavBarSinkSet_DoesSendNavBarModel() throws {
        self.presentation
            .send(
                editModeDisplayModel: .init(
                    isEditing: false,
                    canSave: false
                )
            )
        self.presentation
            .send(displayModel: self.testDisplayModel)

        let expectation = XCTestExpectation()
        let newSink = NavBarViewModelSinkMock()
        newSink.sendNavBarViewModelClosure = { viewModel in
            XCTAssertEqual(
                viewModel.leftButtons.count,
                1
            )

            let leftButton = viewModel.leftButtons[safe: 0]
            switch leftButton {
            case .init(type: .back, isEnabled: true):
                break
            default:
                XCTFail("Expected enabled Back button. Found: \(leftButton.debugDescription)")
            }

            XCTAssertEqual(
                viewModel.rightButtons.count,
                2
            )

            let addButton = viewModel.rightButtons[safe: 0]
            switch addButton {
            case .init(
                type: .add,
                displayTitle: TestAppContent
                    .testMeasureListContent
                    .addToInventoryDescription,
                isEnabled: true
            ):
                break
            default:
                XCTFail("Expected enabled Add button. Found \(addButton.debugDescription)")
            }

            let editButton = viewModel.rightButtons[safe: 1]
            switch editButton {
            case .init(
                type: .edit,
                displayTitle: TestAppContent
                    .testMeasureListContent
                    .editListDescription,
                isEnabled: true
            ):
                break
            default:
                XCTFail("Expected enabled Add button. Found \(editButton.debugDescription)")
            }
            expectation.fulfill()
        }

        self.presentation
            .navBarViewModelSink = newSink
        wait(for: [expectation], timeout: 0.0)
    }

    func testPresentation_WhenNavBarSinkSetNoRecipes_DoesSendNavBarModel() throws {
        self.presentation
            .send(displayModel: .init(sections: []))
        self.presentation
            .send(
                editModeDisplayModel: .init(
                    isEditing: false,
                    canSave: false
                )
            )

        let expectation = XCTestExpectation()
        let newSink = NavBarViewModelSinkMock()
        newSink.sendNavBarViewModelClosure = { viewModel in
            XCTAssertEqual(
                viewModel.leftButtons.count,
                1
            )

            let leftButton = viewModel.leftButtons[safe: 0]
            switch leftButton {
            case .init(type: .back, isEnabled: true):
                break
            default:
                XCTFail("Expected enabled Back button. Found: \(leftButton.debugDescription)")
            }

            XCTAssertEqual(
                viewModel.rightButtons.count,
                1
            )

            let addButton = viewModel.rightButtons[safe: 0]
            switch addButton {
            case .init(type: .add, isEnabled: true):
                break
            default:
                XCTFail("Expected enabled Add button. Found \(addButton.debugDescription)")
            }

            expectation.fulfill()
        }

        self.presentation
            .navBarViewModelSink = newSink
        wait(for: [expectation], timeout: 0.0)
    }

    func testPresentation_WhenSentIsEditingNoSave_DoesSendNavBarModel() throws {
        self.presentation
            .send(displayModel: self.testDisplayModel)

        let expectation = XCTestExpectation()
        self.navBarViewModelSink.sendNavBarViewModelClosure = { viewModel in
            XCTAssertEqual(
                viewModel.leftButtons.count,
                1
            )

            let leftButton = viewModel.leftButtons[safe: 0]
            switch leftButton {
            case .init(type: .cancel, isEnabled: true):
                break
            default:
                XCTFail("Expected enabled Cancel button. Found: \(leftButton.debugDescription)")
            }

            XCTAssertEqual(
                viewModel.rightButtons.count,
                1
            )

            let rightButton = viewModel.rightButtons[safe: 0]
            switch rightButton {
            case .init(type: .save, isEnabled: false):
                break
            default:
                XCTFail("Expected disabled Save button. Found: \(rightButton.debugDescription)")
            }

            expectation.fulfill()
        }

        self.presentation
            .send(
                editModeDisplayModel: .init(
                    isEditing: true,
                    canSave: false
                )
            )
        wait(for: [expectation], timeout: 0.0)
    }

    func testPresentation_WhenSentIsEditingTwice_DoesSendsListViewModelOnce() throws {
        self.presentation
            .send(displayModel: self.testDisplayModel)

        let expectation = XCTestExpectation()
        expectation.expectedFulfillmentCount = 1
        self.viewModelSink.sendViewModelClosure = { viewModel in
            XCTAssert(viewModel.isEditing)
            expectation.fulfill()
        }

        for _ in 0..<2 {
            self.presentation
                .send(
                    editModeDisplayModel: .init(
                        isEditing: true,
                        canSave: false
                    )
                )
        }

        wait(for: [expectation], timeout: 0.0)
    }

    func testPresentation_WhenSentIsEditingCanSave_DoesSendNavBarModel() throws {
        self.presentation
            .send(displayModel: self.testDisplayModel)

        let expectation = XCTestExpectation()
        self.navBarViewModelSink.sendNavBarViewModelClosure = { viewModel in
            XCTAssertEqual(
                viewModel.leftButtons.count,
                1
            )

            let leftButton = viewModel.leftButtons[safe: 0]
            switch leftButton {
            case .init(type: .cancel, isEnabled: true):
                break
            default:
                XCTFail("Expected enabled Cancel button. Found: \(leftButton.debugDescription)")
            }

            XCTAssertEqual(
                viewModel.rightButtons.count,
                1
            )

            let rightButton = viewModel.rightButtons[safe: 0]
            switch rightButton {
            case .init(type: .save, isEnabled: true):
                break
            default:
                XCTFail("Expected enabled Save button. Found: \(rightButton.debugDescription)")
            }

            expectation.fulfill()
        }

        self.presentation
            .send(
                editModeDisplayModel: .init(
                    isEditing: true,
                    canSave: true
                )
            )
        wait(for: [expectation], timeout: 0.0)
    }

    func testPresentation_WhenNavBarSinkUpdated_DoesSendNavBarModel() throws {
        self.presentation
            .send(displayModel: self.testDisplayModel)

        self.presentation
            .send(
                editModeDisplayModel: .init(
                    isEditing: true,
                    canSave: false
                )
            )

        let expectation = XCTestExpectation()
        let newSink = NavBarViewModelSinkMock()
        newSink.sendNavBarViewModelClosure = { viewModel in
            XCTAssertEqual(
                viewModel.leftButtons.count,
                1
            )

            let leftButton = viewModel.leftButtons[safe: 0]
            switch leftButton {
            case .init(type: .cancel, isEnabled: true):
                break
            default:
                XCTFail("Expected enabled Cancel button. Found: \(leftButton.debugDescription)")
            }

            XCTAssertEqual(
                viewModel.rightButtons.count,
                1
            )

            let rightButton = viewModel.rightButtons[safe: 0]
            switch rightButton {
            case .init(type: .save, isEnabled: false):
                break
            default:
                XCTFail("Expected disabled Save button. Found: \(rightButton.debugDescription)")
            }

            expectation.fulfill()
        }

        self.presentation
            .navBarViewModelSink = newSink
        wait(for: [expectation], timeout: 0.0)
    }

    func testPresentation_WhenSentAlert_DoesSendAlert() throws {
        let expectation = XCTestExpectation()
        self.navBarViewModelSink
            .sendAlertViewModelClosure = { _ in
                expectation.fulfill()
            }

        self.presentation
            .send(alertDisplayModel: .cancel, didConfirm: { _ in })
        wait(for: [expectation], timeout: 0.0)
    }

    func testPresentation_WhenDeleteEvent_DoesSendDeleteAction() throws {
        let testSection = 0
        let testIndex = 1
        let expectation = XCTestExpectation()

        self.presentation
            .send(
                editModeDisplayModel: .init(
                    isEditing: true,
                    canSave: true
                )
            )

        self.actionSink
            .sendActionClosure = { action in
                switch action {
                case .deleteMeasure(
                    atIndex: testIndex,
                    inSection: testSection - 1
                ):
                    expectation.fulfill()
                default:
                    XCTFail("Expected delete at section: \(testSection), index: \(testIndex). Found: \(action)")
                }
            }

        self.presentation
            .send(
                event: .delete(itemAt: .init(
                    item: testIndex,
                    section: testSection
                ))
            )
        wait(for: [expectation], timeout: 0.0)
    }

    func testPresentation_WhenEditTapped_DoesStartEditing() throws {
        let expectation = XCTestExpectation()
        self.actionSink
            .sendEditModeActionClosure = { action in
                switch action {
                case .startEditing:
                    expectation.fulfill()
                default:
                    XCTFail("Expected startEditing. Found: \(action)")
                }
            }

        self.presentation
            .send(
                navBarEvent: .tap(
                    .right,
                    index: 1
                )
            )
        wait(for: [expectation], timeout: 0.0)
    }

    func testPresentation_WhenAddTapped_DoesSendAddRecipe() throws {
        let expectation = XCTestExpectation()
        self.actionSink
            .sendActionClosure = { action in
                switch action {
                case .newMeasure:
                    expectation.fulfill()
                default:
                    XCTFail("Expected newRecipe. Found: \(action)")
                }
                expectation.fulfill()
            }

        self.presentation
            .send(
                navBarEvent: .tap(
                    .right,
                    index: 0
                )
            )
        wait(for: [expectation], timeout: 0.0)
    }

    func testPresentation_WhenCancelTapped_DoesCancelEditing() throws {
        self.presentation
            .send(
                editModeDisplayModel: .init(
                    isEditing: true,
                    canSave: true
                )
            )

        let expectation = XCTestExpectation()
        self.actionSink
            .sendEditModeActionClosure = { action in
                switch action {
                case .finishEditing(.cancel):
                    expectation.fulfill()
                default:
                    XCTFail("Expected startEditing. Found: \(action)")
                }
            }

        self.presentation
            .send(
                navBarEvent: .tap(
                    .left,
                    index: 0
                )
            )
        wait(for: [expectation], timeout: 0.0)
    }

    func testPresentation_WhenSaveTapped_DoesSaveEditing() throws {
        self.presentation
            .send(
                editModeDisplayModel: .init(
                    isEditing: true,
                    canSave: true
                )
            )

        let expectation = XCTestExpectation()
        self.actionSink
            .sendEditModeActionClosure = { action in
                switch action {
                case .finishEditing(.save):
                    expectation.fulfill()
                default:
                    XCTFail("Expected startEditing. Found: \(action)")
                }
            }

        self.presentation
            .send(
                navBarEvent: .tap(
                    .right,
                    index: 0
                )
            )
        wait(for: [expectation], timeout: 0.0)
    }
}
