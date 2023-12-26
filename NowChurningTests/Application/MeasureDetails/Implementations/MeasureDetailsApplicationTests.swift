//
//  MeasureDetailsApplicationTests.swift
//  NowChurningTests
//
//  Created by Austin Dumm on 5/14/23.
//

import XCTest
@testable import NowChurning

final class MeasureDetailsApplicationTests: XCTestCase {

    let testName = "Testing Ingredient Name"
    let testDescription = "This is a test description of a test ingredient."
    let testTags: [Tag<Ingredient>] = [
        Tag(name: "First"),
        Tag(name: "Second"),
        Tag(name: "Third"),
    ]
    var testIngredient: Ingredient!
    var testMeasure: Measure!
    var expectedDisplayModel: MeasureDetailsDisplayModel!

    var application: MeasureDetailsApplication!
    var mockMeasureDisplayModelSink: MeasureDetailsDisplayModelSinkMock!
    var mockModelStore: MeasureStoreActionSinkMock!
    var mockDelegate: MeasureDetailsApplicationDelegateMock!

    let testContent = MeasureDetailsApplication.Content(
        invalidityText: { reason in
            switch reason {
            case .invalidMeasure(.negativeCount):
                return "Test Negative Count"
            case .invalidMeasure(.negativeVolume):
                return "Test Negative Volume"
            case .invalidIngredient(.emptyName):
                return "Test Empty Name"
            }
        },
        existingNameInvalidDescription: "Test Name Already Exists",
        existingNameInvalidSuggestion: "Test Name Already Suggestions"
    )

    override func setUp() {
        self.testIngredient = .init(
            name: self.testName,
            description: self.testDescription,
            tags: self.testTags
        )
        self.testMeasure = .init(
            ingredient: self.testIngredient,
            measure: .volume(.init(value: 2.75, unit: .fluidOunces))
        )
        self.expectedDisplayModel = .init(
            name: .valid(self.testIngredient.name),
            description: self.testIngredient.description,
            tagNames: self.testIngredient.tags.map { $0.name },
            measurementDescription: self
                .testMeasure
                .measure
                .map {
                    switch $0 {
                    case .any:
                        return nil
                    case .volume(let volume):
                        return MeasurementFormatter
                            .volumeFormatter
                            .string(from: volume)
                    case .count(let count, let description):
                        if count.unit.symbol.isEmpty {
                            return NumberFormatter
                                .countFormatter
                                .string(from: count.value as NSNumber)
                        } else {
                            return [
                                MeasurementFormatter
                                    .countFormatter
                                    .string(from: count),
                                description
                            ].compactMap { $0 }.joined(separator: " ")
                        }
                    }
                }
        )

        self.application = .init(content: testContent)
        self.mockMeasureDisplayModelSink = .init()
        self.mockModelStore = .init()
        self.mockDelegate = .init()

        self.application
            .displayModelSink = self.mockMeasureDisplayModelSink
        self.application.domainModelStore = self.mockModelStore
        self.application.delegate = mockDelegate
    }

    func assertMatchingDisplayModel(
        expected: MeasureDetailsDisplayModel,
        received: MeasureDetailsDisplayModel
    ) {
        XCTAssertEqual(
            received.name,
            expected.name
        )
        XCTAssertEqual(
            received.description,
            expected.description
        )
        XCTAssertEqual(
            received.tagNames,
            expected.tagNames
        )
        XCTAssertEqual(
            received.measurementDescription,
            expected.measurementDescription
        )
    }

    // MARK: Display Tests
    func testApplication_WhenGivenIngredient_SendsMatchingDisplayModel() throws {
        let expectation = XCTestExpectation()
        self.mockMeasureDisplayModelSink.sendMeasureDisplayModelClosure = { displayModel in
            self.assertMatchingDisplayModel(
                expected: self.expectedDisplayModel,
                received: displayModel
            )
            expectation.fulfill()
        }

        self.application.send(
            domainModel: self.testMeasure,
            ingredientNameLookup: [:]
        )

        wait(for: [expectation], timeout: 0.0)
    }

    func testApplication_WhenGivenNewDisplayModelSink_SendsDisplayModel() throws {
        self.application.send(
            domainModel: self.testMeasure,
            ingredientNameLookup: [:]
        )

        let newDisplayModelSink = MeasureDetailsDisplayModelSinkMock()
        let expectation = XCTestExpectation()
        expectation.expectedFulfillmentCount = 2
        newDisplayModelSink.sendMeasureDisplayModelClosure = { displayModel in
            self.assertMatchingDisplayModel(
                expected: self.expectedDisplayModel,
                received: displayModel
            )
            expectation.fulfill()
        }
        newDisplayModelSink.sendEditModeDisplayModelClosure = {
            displayModel in
            XCTAssertFalse(displayModel.isEditing)

            expectation.fulfill()
        }

        self.application.displayModelSink = newDisplayModelSink

        wait(for: [expectation], timeout: 0.0)
    }

    func testApplication_WhenGivenNewDisplayModelSink_StopsSendingToOldSink() throws {
        let newDisplayModelSink = MeasureDetailsDisplayModelSinkMock()
        self.application.displayModelSink = newDisplayModelSink

        let oldExpectation = XCTestExpectation()
        oldExpectation.isInverted = true
        self.mockMeasureDisplayModelSink.sendMeasureDisplayModelClosure = { _ in
            oldExpectation.fulfill()
        }

        self.application.send(
            domainModel: self.testMeasure,
            ingredientNameLookup: [:]
        )
        wait(for: [oldExpectation], timeout: 0.0)
    }

    // MARK: Action Tests
    func testApplication_WhenSentUpdateNameNotEditing_DoesSaveWithNewName() throws {
        self.application.send(
            domainModel: self.testMeasure,
            ingredientNameLookup: [:]
        )

        let newName = "New testing name"
        var expectedMeasure = self.testMeasure!
        expectedMeasure.ingredient.name = newName

        let expectation = XCTestExpectation()
        self.mockModelStore.sendActionClosure = { action in
            switch action {
            case .save(measure: let newMeasure):
                XCTAssertEqual(
                    expectedMeasure,
                    newMeasure
                )
                expectation.fulfill()
            }
        }

        self.application.send(measureAction: .edit(.name(newName)))
        wait(for: [expectation], timeout: 0.0)
    }

    func testApplication_WhenSentUpdateNameAndEditing_DoesNotSaveWithNewName() throws {
        self.application.send(
            domainModel: self.testMeasure,
            ingredientNameLookup: [:]
        )
        self.application.send(editModeAction: .startEditing)

        let newName = "New testing name"
        var expectedMeasure = self.testMeasure!
        expectedMeasure.ingredient.name = newName

        let expectation = XCTestExpectation()
        expectation.isInverted = true
        self.mockModelStore.sendActionClosure = { action in
            expectation.fulfill()
        }

        self.application.send(measureAction: .edit(.name(newName)))
        wait(for: [expectation], timeout: 0.0)
    }

    func testApplication_WhenStartsEditing_DoesSendCannotSave() throws {
        self.application.send(
            domainModel: self.testMeasure,
            ingredientNameLookup: [:]
        )

        let newName = "New testing name"
        var expectedIngredient = self.testIngredient!
        expectedIngredient.name = newName

        let expectation = XCTestExpectation()
        self.mockMeasureDisplayModelSink
            .sendEditModeDisplayModelClosure = { displayModel in
                XCTAssertFalse(displayModel.canSave)
                expectation.fulfill()
            }

        self.application.send(editModeAction: .startEditing)

        wait(for: [expectation], timeout: 0.0)
    }

    func testApplication_WhenSentUpdateNameAndEditing_DoesSendCanSave() throws {
        self.application.send(
            domainModel: self.testMeasure,
            ingredientNameLookup: [:]
        )
        self.application.send(editModeAction: .startEditing)

        let newName = "New testing name"
        var expectedMeasure = self.testMeasure!
        expectedMeasure.ingredient.name = newName

        let expectation = XCTestExpectation()
        self.mockMeasureDisplayModelSink
            .sendEditModeDisplayModelClosure = { displayModel in
                XCTAssert(displayModel.canSave)
                expectation.fulfill()
            }

        self.application.send(measureAction: .edit(.name(newName)))
        wait(for: [expectation], timeout: 0.0)
    }

    func testApplication_WhenSentUpdateNameToSameAndEditing_DoesSendCanSave() throws {
        self.application.send(
            domainModel: self.testMeasure,
            ingredientNameLookup: [:]
        )
        self.application.send(editModeAction: .startEditing)

        let newName = "New testing name"
        var expectedMeasure = self.testMeasure!
        expectedMeasure.ingredient.name = newName

        let expectation = XCTestExpectation()
        self.mockMeasureDisplayModelSink
            .sendEditModeDisplayModelClosure = { displayModel in
                XCTAssertFalse(displayModel.canSave)
                expectation.fulfill()
            }

        self.application.send(measureAction: .edit(.name(self.testName)))
        wait(for: [expectation], timeout: 0.0)
    }

    func testApplication_WhenSentUpdateDescNotEditing_DoesSaveWithNewDesc() throws {
        self.application.send(
            domainModel: self.testMeasure,
            ingredientNameLookup: [:]
        )

        let newDescription = "New testing description"
        var expectedMeasure = self.testMeasure!
        expectedMeasure.ingredient.description = newDescription

        let expectation = XCTestExpectation()
        self.mockModelStore.sendActionClosure = { action in
            switch action {
            case .save(measure: let newMeasure):
                XCTAssertEqual(
                    expectedMeasure,
                    newMeasure
                )
                expectation.fulfill()
            }
        }

        self.application.send(
            measureAction: .edit(.description(newDescription))
        )
        wait(for: [expectation], timeout: 0.0)
    }

    func testApplication_WhenSentUpdateDescAndEditing_DoesNotSaveWithNewDesc() throws {
        self.application.send(
            domainModel: self.testMeasure,
            ingredientNameLookup: [:]
        )
        self.application.send(editModeAction: .startEditing)

        let newDescription = "New testing description"
        var expectedMeasure = self.testMeasure!
        expectedMeasure.ingredient.description = newDescription

        let expectation = XCTestExpectation()
        expectation.isInverted = true
        self.mockModelStore.sendActionClosure = { action in
            expectation.fulfill()
        }

        self.application.send(
            measureAction: .edit(.description(newDescription))
        )
        wait(for: [expectation], timeout: 0.0)
    }

    func testApplication_WhenSentUpdateDescAndEditing_DoesSendCanSave() throws {
        self.application.send(
            domainModel: self.testMeasure,
            ingredientNameLookup: [:]
        )
        self.application.send(editModeAction: .startEditing)

        let newDesc = "New testing desc"
        var expectedMeasure = self.testMeasure!
        expectedMeasure.ingredient.description = newDesc

        let expectation = XCTestExpectation()
        self.mockMeasureDisplayModelSink
            .sendEditModeDisplayModelClosure = { displayModel in
                XCTAssert(displayModel.canSave)
                expectation.fulfill()
            }

        self.application.send(measureAction: .edit(.description(newDesc)))
        wait(for: [expectation], timeout: 0.0)
    }

    func testApplication_WhenSentUpdateDescToSameAndEditing_DoesSendCanSave() throws {
        self.application.send(
            domainModel: self.testMeasure,
            ingredientNameLookup: [:]
        )
        self.application.send(editModeAction: .startEditing)

        let expectation = XCTestExpectation()
        self.mockMeasureDisplayModelSink
            .sendEditModeDisplayModelClosure = { displayModel in
                XCTAssertFalse(displayModel.canSave)
                expectation.fulfill()
            }

        self.application.send(
            measureAction: .edit(.description(self.testDescription))
        )
        wait(for: [expectation], timeout: 0.0)
    }

    func testApplication_WhenGivenNewStore_DoesNotSendActions() throws {
        self.application.send(
            domainModel: self.testMeasure,
            ingredientNameLookup: [:]
        )
        self.application.send(measureAction: .edit(.name("Blah")))

        let newStore = MeasureStoreActionSinkMock()
        let badExpectation = XCTestExpectation()
        badExpectation.isInverted = true

        newStore.sendActionClosure = { _ in badExpectation.fulfill() }

        self.application.domainModelStore = newStore
        wait(for: [badExpectation], timeout: 0.0)
    }

    func testApplication_WhenSentStartEditing_DoesSendCanEdit() throws {
        self.application.send(
            domainModel: self.testMeasure,
            ingredientNameLookup: [:]
        )

        let expectation = XCTestExpectation()
        self.mockMeasureDisplayModelSink
            .sendEditModeDisplayModelClosure = { displayModel in
                XCTAssert(displayModel.isEditing)
                expectation.fulfill()
            }

        self.application.send(editModeAction: .startEditing)
        wait(for: [expectation], timeout: 0.0)
    }

    func testApplication_WhenWithChangesSentCancelEditing_DoesFollowDelegate() throws {
        let alertSink = MeasureDetailsDisplayModelSinkMock()
        self.application.displayModelSink = alertSink

        self.application.send(
            domainModel: self.testMeasure,
            ingredientNameLookup: [:]
        )

        self.application.send(editModeAction: .startEditing)
        self.application.send(measureAction: .edit(.name("Changed")))

        let expectation = XCTestExpectation()
        expectation.isInverted = true
        self.mockMeasureDisplayModelSink
            .sendEditModeDisplayModelClosure = { displayModel in
                expectation.fulfill()
            }

        let alertExpectation = XCTestExpectation()
        alertSink.sendAlertDisplayModelDidConfirmClosure = { (model, closure) in
            switch model {
            case .cancel:
                closure(false)
                alertExpectation.fulfill()
            case .save:
                XCTFail("Expected cancel action. Found: save")
                return
            }
        }

        self.application.send(editModeAction: .finishEditing(.cancel))
        wait(for: [expectation, alertExpectation], timeout: 0.0)
    }

    func testApplication_WhenSentCancelEditing_DoesSendAlert() throws {
        self.application.send(
            domainModel: self.testMeasure,
            ingredientNameLookup: [:]
        )

        self.application.send(editModeAction: .startEditing)
        self.application.send(measureAction: .edit(.description("NEW")))
        self.application.send(measureAction: .edit(.name("NEW")))

        let expectation = XCTestExpectation()
        self.mockMeasureDisplayModelSink
            .sendAlertDisplayModelDidConfirmClosure = { _, _ in
                expectation.fulfill()
            }

        self.application.send(editModeAction: .finishEditing(.cancel))
        wait(for: [expectation], timeout: 0.0)
    }

    func testApplication_WhenCancelNoChanges_AlertsDelegate() throws {
        self.application.send(editModeAction: .startEditing)

        let expectation = XCTestExpectation()
        self.mockDelegate.navigateForEditDoneTypeClosure = { _ in
            expectation.fulfill()
        }

        self.application.send(editModeAction: .finishEditing(.cancel))
        wait(for: [expectation], timeout: 0.0)
    }

    func testApplication_WhenNoAlertSentCompleteEditing_DoesSendCanEditFalse() throws {
        self.application.send(
            domainModel: self.testMeasure,
            ingredientNameLookup: [:]
        )

        self.application.send(editModeAction: .startEditing)

        let expectation = XCTestExpectation()
        self.mockMeasureDisplayModelSink
            .sendEditModeDisplayModelClosure = { displayModel in
                XCTAssertFalse(displayModel.isEditing)
                expectation.fulfill()
            }

        self.application.send(editModeAction: .finishEditing(.save))
        wait(for: [expectation], timeout: 0.0)
    }

    func testApplication_WhenWithAlertSentCompleteEditing_DoesNotAlertAndSendCanEditFalse() throws {
        self.application.send(
            domainModel: self.testMeasure,
            ingredientNameLookup: [:]
        )

        self.application.send(editModeAction: .startEditing)

        let expectation = XCTestExpectation()
        self.mockMeasureDisplayModelSink
            .sendEditModeDisplayModelClosure = { displayModel in
                XCTAssertFalse(displayModel.isEditing)
                expectation.fulfill()
            }

        let badExpectation = XCTestExpectation()
        badExpectation.isInverted = true
        self.mockMeasureDisplayModelSink
            .sendAlertDisplayModelDidConfirmClosure = { _, _ in
                badExpectation.fulfill()
            }

        self.application.send(editModeAction: .finishEditing(.save))
        wait(for: [expectation, badExpectation], timeout: 0.0)
    }

    func testApplication_WhenSentCompleteEditing_DoesSendSaveToStore() throws {
        self.application.send(
            domainModel: self.testMeasure,
            ingredientNameLookup: [:]
        )

        self.application.send(editModeAction: .startEditing)
        let newIngredient = Ingredient(
            id: testIngredient.id,
            name: "NEW",
            description: "NEW",
            tags: self.testTags
        )
        let newMeasure = Measure(
            ingredient: newIngredient,
            measure: self.testMeasure.measure
        )

        self.application.send(
            measureAction: .edit(.name(
                newIngredient.name
            ))
        )
        self.application.send(
            measureAction: .edit(.description(
                newIngredient.description
            ))
        )

        let expectation = XCTestExpectation()
        self.mockModelStore.sendActionClosure = { action in
            switch action {
            case .save(measure: let receivedMeasure):
                XCTAssertEqual(
                    newMeasure,
                    receivedMeasure
                )
                expectation.fulfill()
            }
        }

        self.application.send(editModeAction: .finishEditing(.save))
        wait(for: [expectation], timeout: 0.0)
    }

    func testApplication_WhenEditingSentAddTag_DoesSendToDelegate() throws {
        self.application.send(
            domainModel: self.testMeasure,
            ingredientNameLookup: [:]
        )

        self.application.send(editModeAction: .startEditing)

        let expectation = XCTestExpectation()
        self.mockDelegate.requestEditTagsForMeasureClosure = { _ in
            expectation.fulfill()
        }

        self.application.send(measureAction: .action(.addTag))

        wait(for: [expectation], timeout: 0.0)
    }

    func testApplication_WhenNotEditingSentAddTag_DoesSendToDelegate() throws {
        self.application.send(
            domainModel: self.testMeasure,
            ingredientNameLookup: [:]
        )

        let expectation = XCTestExpectation()
        self.mockDelegate.requestEditTagsForMeasureClosure = { _ in
            expectation.fulfill()
        }

        self.application.send(measureAction: .action(.addTag))

        wait(for: [expectation], timeout: 0.0)
    }

    func testApplication_SendsInvalidity_OnlyAfterEditing() throws {
        let firstExpectation = XCTestExpectation()
        self.mockMeasureDisplayModelSink.sendMeasureDisplayModelClosure = { displayModel in
            XCTAssert(displayModel.name.isValid)
            firstExpectation.fulfill()
        }
        
        self.application.send(
            domainModel: .init(
                ingredient: .init(
                    name: "",
                    description: "",
                    tags: []),
                measure: .any
            ),
            ingredientNameLookup: [:]
        )
        self.application.send(editModeAction: .startEditing)
        wait(for: [firstExpectation], timeout: 0.0)

        let secondExpectation = XCTestExpectation()
        self.mockMeasureDisplayModelSink.sendMeasureDisplayModelClosure = {
            displayModel in
            XCTAssertFalse(displayModel.name.isValid)
            secondExpectation.fulfill()
        }
        self.application.send(measureAction: .edit(.name("")))

        wait(for: [secondExpectation], timeout: 0.0)
    }

    func testApplication_WhenIngredientNameCollision_SendsCannotSave() throws {
        let ingredientLookup: [String: ID<Ingredient>] = [
            "1": .init(),
            "2": .init(),
            "3": .init(),
            "4": .init(),
        ]

        self.application.send(editModeAction: .startEditing)
        self.application.send(
            domainModel: self.testMeasure,
            ingredientNameLookup: ingredientLookup
        )

        let expectation = XCTestExpectation()
        self.mockMeasureDisplayModelSink.sendEditModeDisplayModelClosure = { displayModel in
            XCTAssertFalse(displayModel.canSave)
            expectation.fulfill()
        }

        self.application
            .send(measureAction: .edit(.name(ingredientLookup.first!.key)))
        wait(for: [expectation], timeout: 0.0)
    }

    func testApplication_WhenIngredientNameCollision_SendsInvalid() throws {
        let ingredientLookup: [String: ID<Ingredient>] = [
            "1": .init(),
            "2": .init(),
            "3": .init(),
            "4": .init(),
        ]

        self.application.send(editModeAction: .startEditing)
        self.application.send(
            domainModel: self.testMeasure,
            ingredientNameLookup: ingredientLookup
        )

        let expectation = XCTestExpectation()
        self.mockMeasureDisplayModelSink.sendMeasureDisplayModelClosure = { displayModel in
            XCTAssertEqual(
                displayModel.name.invalidityReason?.error,
                TestAppContent.testMeasureApplicationContent.existingNameInvalidDescription
            )
            XCTAssertEqual(
                displayModel.name.invalidityReason?.suggestion,
                "\(TestAppContent.testMeasureApplicationContent.existingNameInvalidSuggestion) \"\(ingredientLookup.first!.key)\""
            )
            expectation.fulfill()
        }

        self.application
            .send(measureAction: .edit(.name(ingredientLookup.first!.key)))
        wait(for: [expectation], timeout: 0.0)
    }

    func testApplication_WhenNameFooterTapNoCollision_SendsNothing() throws {
        let expectation = XCTestExpectation()
        expectation.isInverted = true
        self.mockDelegate.switchEditingToMeasureForIngredientIdClosure = { _ in
            expectation.fulfill()
        }

        self.application
            .send(measureAction: .action(.nameFooterTap))
        wait(for: [expectation], timeout: 0.0)
    }

    func testApplication_WhenNameFooterTapWithCollision_SendsDelegatation() throws {
        let ingredientLookup: [String: ID<Ingredient>] = [
            "1": .init(),
            "2": .init(),
            "3": .init(),
            "4": .init(),
        ]
        var measure = self.testMeasure!
        measure.ingredient.name = ingredientLookup.first!.key

        self.application.send(editModeAction: .startEditing)
        self.application.send(
            domainModel: self.testMeasure,
            ingredientNameLookup: ingredientLookup
        )
        self.application.setMeasure(measure: measure)

        let expectation = XCTestExpectation()
        self.mockDelegate.switchEditingToMeasureForIngredientIdClosure = { id in
            XCTAssertEqual(
                id,
                ingredientLookup.first!.value
            )
            expectation.fulfill()
        }

        self.application
            .send(measureAction: .action(.nameFooterTap))
        wait(for: [expectation], timeout: 0.0)
    }

}
