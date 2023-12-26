//
//  TagSelectorSelectionListPresentationTests.swift
//  NowChurningTests
//
//  Created by Austin Dumm on 2/20/23.
//

import XCTest
@testable import NowChurning

final class TagSelectorSelectionListPresentationTests: XCTestCase {
    typealias TagBase = Int

    var presentation: TagSelectorSelectionListPresentation<TagBase>!
    var mockActionSink: TagSelectorActionSinkMock!

    var mockViewModelSink: SelectionListViewModelSinkMock!
    var mockNavBarModelSink: NavBarViewModelSinkMock!

    var testDisplayModel = TagSelectorDisplayModel<TagBase>(tagSelections: [
        .init(tag: .init(name: "0"), isSelected: true),
        .init(tag: .init(name: "1"), isSelected: true),
        .init(tag: .init(name: "2"), isSelected: false),
        .init(tag: .init(name: "3"), isSelected: false),
        .init(tag: .init(name: "4"), isSelected: true),
        .init(tag: .init(name: "5"), isSelected: true),
        .init(tag: .init(name: "6"), isSelected: false),
    ])

    var expectedTitle = "TEST TITLE"
    var expectedViewModel: SelectionListViewModel {
        .init(
            items: self.testDisplayModel
                .tagSelections
                .map {
                    SelectionListViewModel.Item(
                        title: "#\($0.tag.name)",
                        isSelected: $0.isSelected
                    )
                }
        )
    }

    var expectedNavBarModel = NavBarViewModel(
        title: "",
        leftButtons: [.init(type: .cancel, isEnabled: true)],
        rightButtons: [.init(type: .done, isEnabled: true)]
    )

    override func setUpWithError() throws {
        self.mockActionSink = .init()
        self.mockViewModelSink = .init()
        self.mockNavBarModelSink = .init()

        self.presentation = .init(
            application: self.mockActionSink,
            content: .init(barTitle: self.expectedTitle)
        )
        self.presentation.viewModelSink = self.mockViewModelSink
        self.presentation.navBarManager = self.mockNavBarModelSink
    }


    func testPresentation_WhenSentDisplayModel_DoesSendViewModel() throws {
        let expectation = XCTestExpectation()
        self.mockViewModelSink.sendViewModelClosure = { viewModel in
            XCTAssertEqual(
                self.expectedViewModel.items,
                viewModel.items
            )

            XCTAssert(viewModel
                .items
                .map { $0.title }
                .isSorted { lhs, rhs in
                    lhs.localizedCaseInsensitiveCompare(rhs) == .orderedAscending
                }
            )

            expectation.fulfill()
        }

        self.presentation
            .send(displayModel: self.testDisplayModel)
        wait(for: [expectation], timeout: 0.0)
    }

    func testPresentation_WhenViewModelSinkSet_DoesSendViewModel() throws {
        self.presentation
            .send(displayModel: self.testDisplayModel)

        let expectation = XCTestExpectation()
        let newViewModelSink = SelectionListViewModelSinkMock()
        newViewModelSink.sendViewModelClosure = { viewModel in
            XCTAssertEqual(
                self.expectedViewModel.items,
                viewModel.items
            )

            XCTAssert(viewModel
                .items
                .map { $0.title }
                .isSorted { lhs, rhs in
                    lhs.localizedCaseInsensitiveCompare(rhs) == .orderedAscending
                }
            )

            expectation.fulfill()
        }

        self.presentation
            .viewModelSink = newViewModelSink

        wait(for: [expectation], timeout: 0.0)
    }

    func testPresentation_WhenNavBarSinkSet_DoesSendNavBarModel() throws {
        let expectation = XCTestExpectation()
        let newNavBarModelSink = NavBarViewModelSinkMock()
        newNavBarModelSink.sendNavBarViewModelClosure = { viewModel in
            XCTAssertEqual(
                self.expectedTitle,
                viewModel.title
            )
            
            XCTAssertEqual(
                self.expectedNavBarModel.leftButtons,
                viewModel.leftButtons
            )

            XCTAssertEqual(
                self.expectedNavBarModel.rightButtons,
                viewModel.rightButtons
            )

            expectation.fulfill()
        }

        self.presentation
            .navBarManager = newNavBarModelSink

        wait(for: [expectation], timeout: 0.0)
    }

    func testPresentation_WhenSelectionEvent_DoesNotSendAction() throws {
        let expectation = XCTestExpectation()
        expectation.isInverted = true
        self.mockActionSink.sendActionClosure = { action in
            expectation.fulfill()
        }

        self.presentation
            .send(event: .changeSelection(indices: [0, 2, 3]))
        wait(for: [expectation], timeout: 0.0)
    }

    func testPresentation_WhenBarConfirm_DoesSendConfirmAction() throws {
        let testIndicies = [0, 2, 3]
        self.presentation
            .send(displayModel: self.testDisplayModel)
        self.presentation
            .send(event: .changeSelection(indices: testIndicies))

        let expectation = XCTestExpectation()
        self.mockActionSink.sendActionClosure = { action in
            switch action {
            case .select(tagIndices: let receivedIndices):
                XCTAssertEqual(
                    testIndicies,
                    receivedIndices
                )
                expectation.fulfill()
            default:
                XCTFail("Expected select action. Found: \(action)")
            }

            expectation.fulfill()
        }

        self.presentation
            .send(navBarEvent: .tap(.right, index: 0))

        wait(for: [expectation], timeout: 0.0)
    }

    func testPresentation_WhenBarCancel_DoesSendCancel() throws {
        let testIndicies = [0, 2, 3]
        self.presentation
            .send(event: .changeSelection(indices: testIndicies))

        let expectation = XCTestExpectation()
        self.mockActionSink.sendActionClosure = { action in
            switch action {
            case .cancel:
                expectation.fulfill()
            default:
                XCTFail("Expected select action. Found: \(action)")
            }

            expectation.fulfill()
        }

        self.presentation
            .send(navBarEvent: .tap(.left, index: 0))

        wait(for: [expectation], timeout: 0.0)
    }
}
