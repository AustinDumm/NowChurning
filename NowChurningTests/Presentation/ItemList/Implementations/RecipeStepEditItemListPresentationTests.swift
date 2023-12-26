//
//  RecipeStepEditItemListPresentationTests.swift
//  NowChurningTests
//
//  Created by Austin Dumm on 7/8/23.
//

import XCTest
@testable import NowChurning

final class RecipeStepEditItemListPresentationTests: XCTestCase {

    var presentation: RecipeStepEditItemListPresentation!

    var actionSink: RecipeStepEditActionSinkMock!
    var navBarSink: NavBarViewModelSinkMock!
    var itemListSink: ItemListViewModelSinkMock!

    var content = RecipeStepEditItemListPresentation.Content(
        sectionTitles: .init(
            measurementSection: "Test Measurement"
        ),
        screenTitle: "Test Screen Title",
        cancelAlert: .init(
            descriptionText: "Test Description",
            confirmText: "Test Confirm",
            cancelText: "Test Cancel"
        )
    )

    var testDisplayModel = RecipeStepEditDisplayModel(
        stepTypeName: "Test Header",
        stepName: "Test Ingredient Name",
        isStepNameEditable: false,
        measurementDescription: "Test Measurement 5 fl oz"
    )

    override func setUpWithError() throws {
        self.actionSink = .init()
        self.navBarSink = .init()
        self.itemListSink = .init()

        self.presentation = .init(
            actionSink: self.actionSink,
            content: self.content
        )
        self.presentation.itemListSink = self.itemListSink
        self.presentation.navBarSink = self.navBarSink
    }

    func assert(
        expectedViewModel: ItemListViewModel,
        forDisplayModel displayModel: RecipeStepEditDisplayModel
    ) {
        XCTAssertEqual(
            expectedViewModel.sections.count,
            2
        )

        XCTAssertFalse(expectedViewModel.isEditing)

        self.assert(
            expectedNameSection: expectedViewModel.sections[0],
            forDisplayModel: displayModel
        )

        self.assert(
            expectedMeasurementSection: expectedViewModel.sections[1],
            forDisplayModel: displayModel
        )
    }

    func assert(
        expectedNameSection: ItemListViewModel.Section,
        forDisplayModel displayModel: RecipeStepEditDisplayModel
    ) {
        XCTAssertEqual(
            expectedNameSection.title,
            displayModel.stepTypeName
        )

        XCTAssertEqual(
            expectedNameSection.items.count,
            1
        )

        guard let item = expectedNameSection.items[safe: 0] else {
            XCTFail("Could not get item 0 from name section")
            return
        }

        XCTAssertEqual(
            item.context,
            [.navigate]
        )

        switch item.type {
        case .text(displayModel.stepName):
            break
        default:
            XCTFail("Expected .text(\(displayModel.stepName)). Found: \(item.type)")
        }
    }

    func assert(
        expectedMeasurementSection: ItemListViewModel.Section,
        forDisplayModel displayModel: RecipeStepEditDisplayModel
    ) {
        XCTAssertEqual(
            expectedMeasurementSection.title,
            self.content.sectionTitles.measurementSection
        )

        XCTAssertEqual(
            expectedMeasurementSection.items.count,
            1
        )

        guard let item = expectedMeasurementSection.items[safe: 0] else {
            XCTFail("Could not get item 0 from measurement section")
            return
        }

        XCTAssertEqual(
            item.context,
            [.navigate]
        )

        switch item.type {
        case .text(displayModel.measurementDescription):
            break
        default:
            XCTFail("Expected .text(\(displayModel.stepName)). Found: \(item.type)")
        }
    }

    func testWhenSentDisplayModel_SendsItemListViewModel() throws {
        let expectation = XCTestExpectation()
        self.itemListSink.sendViewModelClosure = { viewModel in
            self.assert(
                expectedViewModel: viewModel,
                forDisplayModel: self.testDisplayModel
            )
            expectation.fulfill()
        }

        self.presentation.send(displayModel: self.testDisplayModel)
        wait(for: [expectation], timeout: 0.0)
    }

    func testWhenGivenNewSink_SendsItemListViewModel() throws {
        self.presentation.send(displayModel: self.testDisplayModel)

        let expectation = XCTestExpectation()
        let newSink = ItemListViewModelSinkMock()
        newSink.sendViewModelClosure = { viewModel in
            self.assert(
                expectedViewModel: viewModel,
                forDisplayModel: self.testDisplayModel
            )
            expectation.fulfill()
        }

        self.presentation.itemListSink = newSink

        wait(for: [expectation], timeout: 0.0)
    }

    func testWhenGivenNavBar_SendsNavBarViewModel() throws {
        let expectation = XCTestExpectation()
        let newSink = NavBarViewModelSinkMock()
        newSink.sendNavBarViewModelClosure = { viewModel in
            XCTAssertEqual(
                viewModel.leftButtons,
                [.init(type: .cancel, isEnabled: true)]
            )

            XCTAssertEqual(
                viewModel.rightButtons,
                [.init(type: .done, isEnabled: true)]
            )

            expectation.fulfill()
        }

        self.presentation.navBarSink = newSink
        wait(for: [expectation], timeout: 0.0)
    }

    func testWhenSentSelectNameItem_SendsIngrEdit() throws {
        let expectation = XCTestExpectation()
        self.actionSink.sendActionClosure = { action in
            switch action {
            case .editMainStepData:
                expectation.fulfill()
            default:
                XCTFail("Expected .editIngredient. Found: \(action)")
            }
        }

        self.presentation.send(
            event: .select(itemAt: .init(item: 0, section: 0))
        )
        wait(for: [expectation], timeout: 0.0)
    }

    func testWhenSentSelectMeasurementItem_SendsMeasurementEdit() throws {
        let expectation = XCTestExpectation()
        self.actionSink.sendActionClosure = { action in
            switch action {
            case .editMeasurement:
                expectation.fulfill()
            default:
                XCTFail("Expected .editMeasurement. Found: \(action)")
            }
        }

        self.presentation.send(
            event: .select(itemAt: .init(item: 0, section: 1))
        )
        wait(for: [expectation], timeout: 0.0)
    }

    func testWhenSentTapDoneButton_SendsFinishEdit() throws {
        let expectation = XCTestExpectation()
        self.actionSink.sendActionClosure = { action in
            switch action {
            case .finishEdit:
                expectation.fulfill()
            default:
                XCTFail("Expected .finishEdit. Found: \(action)")
            }
        }

        self.presentation.send(
            navBarEvent: .tap(.right, index: 0)
        )
        wait(for: [expectation], timeout: 0.0)
    }

    func testWhenSentTapCancelButton_SendsFinishEdit() throws {
        let expectation = XCTestExpectation()
        self.actionSink.sendActionClosure = { action in
            switch action {
            case .cancelEdit:
                expectation.fulfill()
            default:
                XCTFail("Expected .cancelEdit. Found: \(action)")
            }
        }

        self.presentation.send(
            navBarEvent: .tap(.left, index: 0)
        )
        wait(for: [expectation], timeout: 0.0)
    }
}
