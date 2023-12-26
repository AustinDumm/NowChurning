//
//  MeasurementEditApplicationTests.swift
//  NowChurningTests
//
//  Created by Austin Dumm on 5/28/23.
//

import XCTest
@testable import NowChurning

final class MeasurementEditApplicationTests: XCTestCase {

    var volumeApplication: MeasurementEditApplication!
    var countApplication: MeasurementEditApplication!
    var displayModelSink: MeasurementEditDisplayModelSinkMock!
    var delegate: MeasurementEditDelegateMock!

    var testVolume = Measurement(value: 10.25, unit: UnitVolume.fluidOunces)
    var testVolumeType: MeasurementType {
        .volume(self.testVolume)
    }

    var testCount = Measurement(value: 1.7, unit: .count)
    var testDescription = "Test Description"
    var testCountType: MeasurementType {
        .count(self.testCount, self.testDescription)
    }

    override func setUpWithError() throws {
        self.displayModelSink = .init()
        self.delegate = .init()

        self.volumeApplication = .init(
            initialMeasure: self.testVolumeType,
            content: TestAppContent.testMeasurementEditApplication
        )
        self.volumeApplication.displayModelSink = self.displayModelSink
        self.volumeApplication.delegate = self.delegate

        self.countApplication = .init(
            initialMeasure: self.testCountType,
            content: TestAppContent.testMeasurementEditApplication
        )
        self.countApplication.displayModelSink = self.displayModelSink
        self.countApplication.delegate = self.delegate
    }

    override func tearDownWithError() throws {
        self.volumeApplication = nil
        self.displayModelSink = nil
    }

    func assertVolume(
        isExpectedDisplayModel displayModel: MeasurementEditDisplayModel,
        forModel domainModel: MeasurementType
    ) {
        guard case let .volume(domainVolumeData) = domainModel else {
            XCTFail("Expected volume measure type. Found: \(domainModel)")
            return
        }

        XCTAssertEqual(
            displayModel.validTypes,
            [
                TestAppContent.testMeasurementEditApplication.anyMeasurementDescription,
                TestAppContent.testMeasurementEditApplication.volumeMeasurementDescription,
                TestAppContent.testMeasurementEditApplication.countMeasurementDescription
            ]
        )

        switch displayModel.displayType {
        case .volume(let volumeData):
            XCTAssertEqual(
                volumeData.scalar,
                self.testVolume.value,
                accuracy: .ulpOfOne
            )

            XCTAssertEqual(
                volumeData.selectedUnitIndex,
                TestAppContent.testMeasurementEditApplication.validVolumeUnits.firstIndex(of: domainVolumeData.unit)
            )

            XCTAssertEqual(
                volumeData.validUnits,
                TestAppContent
                    .testMeasurementEditApplication
                    .validVolumeUnits
                    .map { $0.symbol }
            )
        default:
            XCTFail("Expected volume display type. Found: \(displayModel.displayType)")
        }
    }

    func assertCount(
        isExpectedDisplayModel displayModel: MeasurementEditDisplayModel,
        forModel domainModel: MeasurementType
    ) {
        XCTAssertEqual(
            displayModel.validTypes,
            [
                TestAppContent.testMeasurementEditApplication.anyMeasurementDescription,
                TestAppContent.testMeasurementEditApplication.volumeMeasurementDescription,
                TestAppContent.testMeasurementEditApplication.countMeasurementDescription
            ]
        )

        switch displayModel.displayType {
        case .count(let count, let description):
            XCTAssertEqual(
                count,
                self.testCount.value,
                accuracy: .ulpOfOne
            )
            XCTAssertEqual(
                description,
                self.testDescription
            )

        default:
            XCTFail("Expected count display type. Found: \(displayModel.displayType)")
        }
    }

    func testWhenGivenNewSink_SendsDisplayModel() throws {
        let newSink = MeasurementEditDisplayModelSinkMock()

        let expectation = XCTestExpectation()
        newSink.sendDisplayModelClosure = { displayModel in
            self.assertVolume(
                isExpectedDisplayModel: displayModel,
                forModel: self.testVolumeType
            )
            expectation.fulfill()
        }

        self.volumeApplication
            .displayModelSink = newSink

        wait(for: [expectation], timeout: 0.0)
    }

    func testWhenGivenNewSink_SendsCountDisplayModel() throws {
        let newSink = MeasurementEditDisplayModelSinkMock()

        let expectation = XCTestExpectation()
        newSink.sendDisplayModelClosure = { displayModel in
            self.assertCount(
                isExpectedDisplayModel: displayModel,
                forModel: self.testVolumeType
            )
            expectation.fulfill()
        }

        self.countApplication
            .displayModelSink = newSink

        wait(for: [expectation], timeout: 0.0)
    }

    func testWhenNewTypeSelected_SendsNewDisplayModel() throws {
        let expectation = XCTestExpectation()
        expectation.expectedFulfillmentCount = 3
        self.displayModelSink.sendDisplayModelClosure = { displayModel in
            switch displayModel.displayType {
            case .unspecified:
                expectation.fulfill()
            default:
                XCTFail("Expected display type of unspecified. Found: \(displayModel.displayType)")
            }
        }

        self.volumeApplication.send(action: .changeType(atIndex: 0))

        self.displayModelSink.sendDisplayModelClosure = { displayModel in
            switch displayModel.displayType {
            case .volume(_):
                expectation.fulfill()
            default:
                XCTFail("Expected display type of volume. Found: \(displayModel.displayType)")
            }
        }

        self.volumeApplication.send(action: .changeType(atIndex: 1))

        self.displayModelSink.sendDisplayModelClosure = { displayModel in
            switch displayModel.displayType {
            case .count:
                expectation.fulfill()
            default:
                XCTFail("Expected display type of count. Found: \(displayModel.displayType)")
            }
        }

        self.volumeApplication.send(action: .changeType(atIndex: 2))
        wait(for: [expectation], timeout: 0.0)
    }

    func testWhenNewTypeOutOfBoundsSelected_SendsNothing() throws {
        let expectation = XCTestExpectation()
        expectation.isInverted = true
        self.displayModelSink.sendDisplayModelClosure = { displayModel in
            expectation.fulfill()
        }

        self.volumeApplication.send(action: .changeType(atIndex: 2850))
        wait(for: [expectation], timeout: 0.0)
    }

    func testWhenNewUnitSelected_SendsNewDisplayModel() throws {
        let testIndex = 4
        let expectation = XCTestExpectation()
        self.displayModelSink.sendDisplayModelClosure = { displayModel in
            switch displayModel.displayType {
            case .volume(let data):
                XCTAssertEqual(
                    data.selectedUnitIndex,
                    testIndex
                )
                expectation.fulfill()
            default:
                XCTFail("Expected display type of unspecified. Found: \(displayModel.displayType)")
            }
        }

        self.volumeApplication.send(action: .changeVolumeUnit(atIndex: testIndex))
        wait(for: [expectation], timeout: 0.0)
    }

    func testWhenNewAmountGiven_SendsNewDisplayModel() throws {
        let newAmount = 5.25
        let expectation = XCTestExpectation()
        expectation.expectedFulfillmentCount = 2
        self.displayModelSink.sendDisplayModelClosure = { displayModel in
            switch displayModel.displayType {
            case .volume(let data):
                XCTAssertEqual(
                    data.scalar,
                    newAmount,
                    accuracy: .ulpOfOne
                )
                expectation.fulfill()
            default:
                XCTFail("Expected volume with new Amount. Found: \(displayModel.displayType)")
            }
        }

        self.volumeApplication
            .send(action: .changeAmount(newAmount))

        self.displayModelSink.sendDisplayModelClosure = { displayModel in
            switch displayModel.displayType {
            case .count(let amount, _):
                XCTAssertEqual(
                    amount,
                    newAmount,
                    accuracy: .ulpOfOne
                )
                expectation.fulfill()
            default:
                XCTFail("Expected count with new Amount. Found: \(displayModel.displayType)")
            }
        }

        self.countApplication
            .send(action: .changeAmount(newAmount))
        wait(for: [expectation], timeout: 0.0)
    }

    func testWhenNewDescriptionGiven_SendsNewDisplayModel() throws {
        let newDescription = "New Description"

        let expectation = XCTestExpectation()
        self.displayModelSink.sendDisplayModelClosure = { displayModel in
            switch displayModel.displayType {
            case .count(_, let description):
                XCTAssertEqual(
                    description,
                    newDescription
                )
                expectation.fulfill()
            default:
                XCTFail("Expected count with new Description. Found: \(displayModel.displayType)")
            }
        }

        self.countApplication
            .send(action: .changeDescription(newDescription))
        wait(for: [expectation], timeout: 0.0)
    }

    func testWhenNewUnitOutOfBoundsSelected_SendsNothing() throws {
        let expectation = XCTestExpectation()
        expectation.isInverted = true
        self.displayModelSink.sendDisplayModelClosure = { displayModel in
            expectation.fulfill()
        }

        self.volumeApplication.send(action: .changeVolumeUnit(atIndex: 10682))
        wait(for: [expectation], timeout: 0.0)
    }

    func testWhenCancel_AlertsDelegate() throws {
        let expectation = XCTestExpectation()
        self.delegate.didCancelClosure = {
            expectation.fulfill()
        }

        self.volumeApplication.send(editModeAction: .finishEditing(.cancel))
        wait(for: [expectation], timeout: 0.0)
    }

    func testWhenDone_AlertsDelegate() throws {
        let expectation = XCTestExpectation()
        self.delegate.didEnterMeasurementClosure = { _ in
            expectation.fulfill()
        }

        self.volumeApplication.send(editModeAction: .finishEditing(.save))
        wait(for: [expectation], timeout: 0.0)
    }

}
