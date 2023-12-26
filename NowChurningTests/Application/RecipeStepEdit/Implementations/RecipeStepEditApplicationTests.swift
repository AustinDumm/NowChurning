//
//  RecipeStepEditApplication.swift
//  NowChurningTests
//
//  Created by Austin Dumm on 7/8/23.
//

import XCTest
@testable import NowChurning

final class RecipeStepEditApplicationTests: XCTestCase {

    var application: RecipeStepEditApplication!

    var displayModelSink: RecipeStepEditDisplayModelSinkMock!
    var storeActionSink: RecipeStepEditStoreActionSinkMock!
    var delegate: RecipeStepEditApplicationDelegateMock!

    let testMeasure = Measure(
        ingredient: .init(name: "Test Measure", description: "", tags: [.init(name: "First")]),
        measure: .volume(.init(value: 6.5, unit: .fluidOunces))
    )

    let content = RecipeStepEditApplication.Content(
        anyMeasureDescription: "Test Unspecified",
        countMeasureDescription: "Test By Count",
        volumeMeasureDescription: "Test By Volume",
        byIngredientName: "Test Ingredient",
        byTagName: "Test Tag",
        instructionName: "Test Instruction"
    )

    func assert(
        expectedDisplayModel displayModel: RecipeStepEditDisplayModel,
        forModel domainModel: Measure
    ) {
        XCTAssertEqual(
            displayModel.stepName,
            domainModel.ingredient.name
        )

        switch domainModel.measure {
        case .any:
            XCTAssertEqual(
                displayModel.measurementDescription,
                self.content.anyMeasureDescription
            )

        case .count(let count, let description):
            let countFormatted = MeasurementFormatter.countFormatter.string(from: count)
            XCTAssertEqual(
                displayModel.measurementDescription,
                [
                    "\(self.content.countMeasureDescription) - \(countFormatted)",
                    description
                ].compactMap { $0 }.joined(separator: " ")
            )

        case .volume(let volume):
            let volumeFormatted = MeasurementFormatter.volumeFormatter.string(from: volume)
            XCTAssertEqual(
                displayModel.measurementDescription,
                "\(self.content.volumeMeasureDescription) - \(volumeFormatted)"
            )
        }
    }

    override func setUpWithError() throws {
        self.displayModelSink = .init()
        self.storeActionSink = .init()
        self.delegate = .init()

        self.application = .init(content: self.content)
        self.application.displaySink = self.displayModelSink
        self.application.storeSink = self.storeActionSink
        self.application.delegate = self.delegate
    }

    func testWhenGivenModel_SendsDisplayModel() throws {
        let expectation = XCTestExpectation()
        self.displayModelSink.sendDisplayModelClosure = { displayModel in
            self.assert(
                expectedDisplayModel: displayModel,
                forModel: self.testMeasure
            )
            expectation.fulfill()
        }

        self.application.send(step: .ingredient(self.testMeasure))
        wait(for: [expectation], timeout: 0.0)
    }

    func testWhenGivenNewSink_SendsDisplayModel() throws {
        self.application.send(step: .ingredient(self.testMeasure))

        let expectation = XCTestExpectation()
        let newSink = RecipeStepEditDisplayModelSinkMock()
        newSink.sendDisplayModelClosure = { displayModel in
            self.assert(
                expectedDisplayModel: displayModel,
                forModel: self.testMeasure
            )
            expectation.fulfill()
        }

        self.application.displaySink = newSink

        wait(for: [expectation], timeout: 0.0)
    }

    func testWhenGivenNewIngredient_SendsDisplayModel() throws {
        self.application.send(step: .ingredient(self.testMeasure))

        var newMeasure = self.testMeasure
        let newIngredient = Ingredient(name: "New", description: "", tags: [])
        newMeasure.ingredient = newIngredient

        let expectation = XCTestExpectation()
        self.displayModelSink.sendDisplayModelClosure = { displayModel in
            self.assert(
                expectedDisplayModel: displayModel,
                forModel: newMeasure
            )
            expectation.fulfill()
        }

        self.application.send(ingredient: newIngredient)

        wait(for: [expectation], timeout: 0.0)
    }

    func testWhenGivenNewMeasurement_SendsDisplayModel() throws {
        self.application.send(step: .ingredient(self.testMeasure))

        var newMeasure = self.testMeasure
        let newMeasurement = MeasurementType.count(.init(value: 3, unit: .count), "Test Count")
        newMeasure.measure = newMeasurement

        let expectation = XCTestExpectation()
        self.displayModelSink.sendDisplayModelClosure = { displayModel in
            self.assert(
                expectedDisplayModel: displayModel,
                forModel: newMeasure
            )
            expectation.fulfill()
        }

        self.application.send(measurement: newMeasurement)

        wait(for: [expectation], timeout: 0.0)
    }

    func testWhenSentEditIngredient_AlertsDelegate() throws {
        self.application.send(step: .ingredient(self.testMeasure))

        let expectation = XCTestExpectation()
        self.delegate.editIngredientClosure = { ingredient in
            XCTAssertEqual(
                ingredient,
                self.testMeasure.ingredient
            )

            expectation.fulfill()
        }

        self.application.send(action: .editMainStepData)

        wait(for: [expectation], timeout: 0.0)
    }

    func testWhenSentEditMeasurement_AlertsDelegate() throws {
        self.application.send(step: .ingredient(self.testMeasure))

        let expectation = XCTestExpectation()
        self.delegate.editMeasurementClosure = { measurement in
            XCTAssertEqual(
                measurement,
                self.testMeasure.measure
            )

            expectation.fulfill()
        }

        self.application.send(action: .editMeasurement)

        wait(for: [expectation], timeout: 0.0)
    }

    func testWhenSentCancel_AlertsDelegateNoSave() throws {
        self.application.send(step: .ingredient(self.testMeasure))

        let badExpectation = XCTestExpectation()
        badExpectation.isInverted = true
        self.storeActionSink.sendActionClosure = { _ in
            badExpectation.fulfill()
        }

        let expectation = XCTestExpectation()
        self.delegate.didEndClosure = {
            expectation.fulfill()
        }

        self.application.send(action: .cancelEdit)

        wait(for: [expectation], timeout: 0.0)
    }

    func testWhenSentSave_AlertsDelegateAndSaves() throws {
        self.application.send(step: .ingredient(self.testMeasure))

        let expectation = XCTestExpectation()
        self.storeActionSink.sendActionClosure = { action in
            switch action {
            case .saveStep(.ingredient(self.testMeasure)):
                expectation.fulfill()
            default:
                XCTFail("Expected .saveMeasure(\(self.testMeasure)). Found: \(action)")
            }
            expectation.fulfill()
        }

        self.delegate.didEndClosure = {
            expectation.fulfill()
        }

        self.application.send(action: .finishEdit)

        wait(for: [expectation], timeout: 0.0)
    }
}
