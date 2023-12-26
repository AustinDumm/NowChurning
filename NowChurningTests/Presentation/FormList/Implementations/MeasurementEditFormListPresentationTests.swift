//
//  MeasurementEditFormListPresentationTests.swift
//  NowChurningTests
//
//  Created by Austin Dumm on 5/29/23.
//

import XCTest
@testable import NowChurning

final class MeasurementEditFormListPresentationTests: XCTestCase {

    let content = TestAppContent.testMeasurementEditPresentation

    var presentation: MeasurementEditFormListPresentation!

    var viewModelSink: FormListViewModelSinkMock!
    var navBarViewModelSink: NavBarViewModelSinkMock!
    var actionSink: MeasurementEditActionSinkMock!

    static let validTypes = ["testVolume", "testAny", "testCount"]
    var testVolumeDisplayModel = MeasurementEditDisplayModel(
        validTypes: MeasurementEditFormListPresentationTests.validTypes,
        displayType: .volume(
            .init(
                scalar: 1.582,
                selectedUnitIndex: 0,
                validUnits: ["Things", "Stuff", "Volumes"]
            )
        )
    )

    var testCountDisplayModel = MeasurementEditDisplayModel(
        validTypes: MeasurementEditFormListPresentationTests.validTypes,
        displayType: .count(7.5, "Test Count")
    )

    var testAnyDisplayModel = MeasurementEditDisplayModel(
        validTypes: MeasurementEditFormListPresentationTests.validTypes,
        displayType: .unspecified
    )

    override func setUpWithError() throws {
        self.viewModelSink = .init()
        self.navBarViewModelSink = .init()
        self.actionSink = .init()

        self.presentation = .init(
            actionSink: self.actionSink,
            content: self.content
        )
        self.presentation.viewModelSink = self.viewModelSink
        self.presentation.navBarViewModelSink = self.navBarViewModelSink
    }

    override func tearDownWithError() throws {
        self.presentation = nil

        self.viewModelSink = nil
        self.actionSink = nil
    }

    func assert(
        isExpectedViewModel viewModel: FormListViewModel,
        forDisplayModel displayModel: MeasurementEditDisplayModel
    ) {
        XCTAssertEqual(
            viewModel.sections.count,
            1
        )

        let expectedTypeSelection: Int
        switch displayModel.displayType {
        case .unspecified:
            expectedTypeSelection = 0
        case .volume:
            expectedTypeSelection = 1
        case .count:
            expectedTypeSelection = 2
        }

        let measureTypeItem = viewModel.sections[safe: 0]?.items[safe: 0]?.type
        switch measureTypeItem {
        case .labeledSelection(
            label: self.content.itemTitles.typeTitle,
            options: displayModel.validTypes,
            selection: expectedTypeSelection
        ):
            break
        default:
            XCTFail("Expected label section. Found: \(measureTypeItem.debugDescription)")
        }

        switch displayModel.displayType {
        case .volume(let data):
            assertVolume(
                isExpectedViewModel: viewModel,
                forDisplayModel: data
            )
        case .count(let amount, _):
            assertCount(
                isExpectedViewModel: viewModel,
                forDisplayModel: amount
            )
        case .unspecified:
            assertUnspecified(isExpectedViewModel: viewModel)
        }
    }

    func assertVolume(
        isExpectedViewModel viewModel: FormListViewModel,
        forDisplayModel displayModel: MeasurementEditDisplayModel.VolumeTypeData
    ) {
        XCTAssertEqual(
            viewModel.sections[safe: 0]?.items.count,
            3
        )

        let unitCell = viewModel.sections[safe: 0]?.items[safe: 1]?.type
        switch unitCell {
        case .labeledSelection(
            label: self
                .content
                .itemTitles
                .unitTitle,
            options: displayModel.validUnits,
            selection: 0
        ):
            break
        default:
            XCTFail("Expected labeled selection unit cell. Found: \(unitCell.debugDescription)")
        }

        let valueCell = viewModel.sections[safe: 0]?.items[safe: 2]?.type
        switch valueCell {
        case .labeledNumber(
            label: self
                .content
                .itemTitles
                .valueTitle,
            content: displayModel.scalar
        ):
            break
        default:
            XCTFail("Expected labeledNumber cell for scalar. Found: \(valueCell.debugDescription)")
        }
    }

    func assertCount(
        isExpectedViewModel viewModel: FormListViewModel,
        forDisplayModel displayModel: Double
    ) {
        XCTAssertEqual(
            viewModel.sections[safe: 0]?.items.count,
            3
        )

        let valueCell = viewModel.sections[safe: 0]?.items[safe: 1]?.type
        switch valueCell {
        case .labeledNumber(
            label: self
                .content
                .itemTitles
                .valueTitle,
            content: displayModel
        ):
            break
        default:
            XCTFail("Expected labeledNumber cell for count. Found: \(valueCell.debugDescription)")
        }
    }

    func assertUnspecified(
        isExpectedViewModel viewModel: FormListViewModel
    ) {
        XCTAssertEqual(
            viewModel.sections[safe: 0]?.items.count,
            1
        )
    }

    func testWhenGivenNewViewModelSink_SendsViewModel() throws {
        let expectation = XCTestExpectation()
        expectation.expectedFulfillmentCount = 3
        let newSink1 = FormListViewModelSinkMock()
        newSink1.sendViewModelClosure = { viewModel in
            self.assert(
                isExpectedViewModel: viewModel,
                forDisplayModel: self.testVolumeDisplayModel
            )
            expectation.fulfill()
        }
        self.presentation.send(displayModel: self.testVolumeDisplayModel)
        self.presentation.viewModelSink = newSink1

        self.presentation.viewModelSink = nil
        let newSink2 = FormListViewModelSinkMock()
        newSink2.sendViewModelClosure = { viewModel in
            self.assert(
                isExpectedViewModel: viewModel,
                forDisplayModel: self.testCountDisplayModel
            )
            expectation.fulfill()
        }
        self.presentation.send(displayModel: self.testCountDisplayModel)
        self.presentation.viewModelSink = newSink2

        self.presentation.viewModelSink = nil
        let newSink3 = FormListViewModelSinkMock()
        newSink3.sendViewModelClosure = { viewModel in
            self.assert(
                isExpectedViewModel: viewModel,
                forDisplayModel: self.testAnyDisplayModel
            )
            expectation.fulfill()
        }
        self.presentation.send(displayModel: self.testAnyDisplayModel)
        self.presentation.viewModelSink = newSink3

        wait(for: [expectation], timeout: 0.0)
    }

    func testWhenGivenNewDisplayModel_SendsViewModel() throws {
        let expectation = XCTestExpectation()
        expectation.expectedFulfillmentCount = 3
        self.viewModelSink.sendViewModelClosure = { viewModel in
            self.assert(
                isExpectedViewModel: viewModel,
                forDisplayModel: self.testVolumeDisplayModel
            )
            expectation.fulfill()
        }
        self.presentation.send(displayModel: self.testVolumeDisplayModel)

        self.presentation.viewModelSink = nil
        self.viewModelSink.sendViewModelClosure = { viewModel in
            self.assert(
                isExpectedViewModel: viewModel,
                forDisplayModel: self.testCountDisplayModel
            )
            expectation.fulfill()
        }
        self.presentation.send(displayModel: self.testCountDisplayModel)
        self.presentation.viewModelSink = self.viewModelSink

        self.presentation.viewModelSink = nil
        self.viewModelSink.sendViewModelClosure = { viewModel in
            self.assert(
                isExpectedViewModel: viewModel,
                forDisplayModel: self.testAnyDisplayModel
            )
            expectation.fulfill()
        }
        self.presentation.send(displayModel: self.testAnyDisplayModel)
        self.presentation.viewModelSink = self.viewModelSink

        wait(for: [expectation], timeout: 0.0)
    }

    func testWhenChangeType_SendsAction() throws {
        self.presentation.send(displayModel: self.testCountDisplayModel)
        let expectation = XCTestExpectation()
        expectation.expectedFulfillmentCount = 3

        for testTypeIndex in (0..<3) {
            self.actionSink.sendActionClosure = { action in
                switch action {
                case .changeType(atIndex: testTypeIndex):
                    expectation.fulfill()
                default:
                    XCTFail("Expected changeType(atIndex: \(testTypeIndex)). Found: \(action)")
                }
            }

            self.presentation
                .send(event: .updateSelection(
                    item: 0,
                    section: 0,
                    selection: testTypeIndex
                ))

            switch testTypeIndex {
            case 0:
                self.presentation.send(displayModel: self.testAnyDisplayModel)
            case 1:
                self.presentation.send(displayModel: self.testVolumeDisplayModel)
            case 2:
                self.presentation.send(displayModel: self.testCountDisplayModel)
            default:
                break
            }
        }

        wait(for: [expectation], timeout: 0.0)
    }

    func testWhenChangeValue_SendsAction() throws {
        self.presentation.send(displayModel: self.testCountDisplayModel)
        let expectation = XCTestExpectation()
        expectation.expectedFulfillmentCount = 2

        // Volume Type
        let newVolume = 7.751
        self.presentation.send(displayModel: self.testVolumeDisplayModel)
        self.actionSink.sendActionClosure = { action in
            switch action {
            case .changeAmount(newVolume):
                expectation.fulfill()
            default:
                XCTFail("Expected changeAmount(\(newVolume)). Found: \(action)")
            }
        }
        self.presentation.send(
            event: .updateNumber(item: 2, section: 0, number: newVolume)
        )
        self.actionSink.sendActionClosure = nil

        // Count Type
        let newCount = 10.5
        self.presentation.send(displayModel: self.testCountDisplayModel)
        self.actionSink.sendActionClosure = { action in
            switch action {
            case .changeAmount(newCount):
                expectation.fulfill()
            default:
                XCTFail("Expected changeAmount(\(newCount)). Found: \(action)")
            }
        }
        self.presentation.send(
            event: .updateNumber(item: 1, section: 0, number: newCount)
        )

        wait(for: [expectation], timeout: 0.0)
    }

    func testWhenChangeUnit_SendsAction() throws {
        self.presentation.send(displayModel: self.testVolumeDisplayModel)

        let newUnitIndex = 3
        let expectation = XCTestExpectation()
        self.actionSink.sendActionClosure = { action in
            switch action {
            case .changeVolumeUnit(atIndex: newUnitIndex):
                expectation.fulfill()
            default:
                XCTFail("Expected changeVolumeUnit(atIndex: \(newUnitIndex)). Found: \(action)")
            }
        }

        self.presentation.send(event: .updateSelection(
            item: 1,
            section: 0,
            selection: newUnitIndex
        ))
        wait(for: [expectation], timeout: 0.0)
    }

    func testWhenNavBarSet_SendsViewModel() {
        let expectation = XCTestExpectation()
        self.navBarViewModelSink.sendNavBarViewModelClosure = { viewModel in
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

        self.presentation.navBarViewModelSink = self.navBarViewModelSink
        wait(for: [expectation], timeout: 0.0)
    }

    func testWhenTapLeftButton_DoesCancel() {
        self.presentation.send(displayModel: self.testCountDisplayModel)
        let expectation = XCTestExpectation()
        self.actionSink.sendEditModeActionClosure = { action in
            switch action {
            case .finishEditing(.cancel):
                expectation.fulfill()
            default:
                XCTFail("Expected cancel. Found: \(action)")
            }
        }

        self.presentation
            .send(navBarEvent: .tap(.left, index: 0))
        wait(for: [expectation], timeout: 0.0)
    }

    func testWhenTapRightButton_DoesSave() {
        self.presentation.send(displayModel: self.testCountDisplayModel)
        let expectation = XCTestExpectation()
        self.actionSink.sendEditModeActionClosure = { action in
            switch action {
            case .finishEditing(.save):
                expectation.fulfill()
            default:
                XCTFail("Expected cancel. Found: \(action)")
            }
        }

        self.presentation
            .send(navBarEvent: .tap(.right, index: 0))
        wait(for: [expectation], timeout: 0.0)
    }
}
