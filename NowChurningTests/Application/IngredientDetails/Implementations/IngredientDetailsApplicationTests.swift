//
//  IngredientDetailsApplicationTests.swift
//  NowChurningTests
//
//  Created by Austin Dumm on 12/16/22.
//

import XCTest
@testable import NowChurning

final class IngredientDetailsApplicationTests: XCTestCase {

    let testName = "Testing Ingredient Name"
    let testDescription = "This is a test description of a test ingredient."
    let testTags: [Tag<Ingredient>] = [
        Tag(name: "First"),
        Tag(name: "Second"),
        Tag(name: "Third"),
    ]
    var testIngredient: Ingredient!
    var usedNames: [String: ID<Ingredient>] = [
        "Other": .init(),
        "Next": .init(),
        "Final": .init(),
    ]
    var testStoredData: IngredientDetailsStoredModel {
        .init(
            ingredient: self.testIngredient,
            usedNames: self.usedNames
        )
    }
    var expectedDisplayModel: IngredientDetailsDisplayModel!

    var application: IngredientDetailsApplication!
    var mockIngredientDisplayModelSink: IngredientDetailsDisplayModelSinkMock!
    var mockModelStore: IngredientStoreActionSinkMock!
    var mockDelegate: IngredientDetailsApplicationDelegateMock!

    override func setUp() {
        self.testIngredient = .init(
            name: self.testName,
            description: self.testDescription,
            tags: self.testTags
        )
        self.expectedDisplayModel = .init(
            name: .valid(self.testIngredient.name),
            description: self.testIngredient.description,
            tagNames: self.testIngredient.tags.map { $0.name }
        )

        self.application = IngredientDetailsApplication(content: TestAppContent.testIngredientDetailsApplicationContent)
        self.mockIngredientDisplayModelSink = .init()
        self.mockModelStore = .init()
        self.mockDelegate = .init()

        self.application
            .displayModelSink = self.mockIngredientDisplayModelSink
        self.application.domainModelStore = self.mockModelStore
        self.application.delegate = mockDelegate
    }

    func assertMatchingDisplayModel(
        expected: IngredientDetailsDisplayModel,
        received: IngredientDetailsDisplayModel
    ) {
        XCTAssertEqual(
            expected.name,
            received.name
        )
        XCTAssertEqual(
            expected.description,
            received.description
        )
        XCTAssertEqual(
            expected.tagNames,
            received.tagNames
        )
    }

    // MARK: Display Tests
    func testApplication_WhenGivenIngredient_SendsMatchingDisplayModel() throws {
        let expectation = XCTestExpectation()
        self.mockIngredientDisplayModelSink.sendIngredientDisplayModelClosure = { displayModel in
            self.assertMatchingDisplayModel(
                expected: self.expectedDisplayModel,
                received: displayModel
            )
            expectation.fulfill()
        }

        self.application.send(domainModel: self.testStoredData)

        wait(for: [expectation], timeout: 0.0)
    }

    func testApplication_WhenGivenNewDisplayModelSink_SendsDisplayModel() throws {
        self.application.send(domainModel: self.testStoredData)

        let newDisplayModelSink = IngredientDetailsDisplayModelSinkMock()
        let expectation = XCTestExpectation()
        expectation.expectedFulfillmentCount = 2
        newDisplayModelSink.sendIngredientDisplayModelClosure = { displayModel in
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
        let newDisplayModelSink = IngredientDetailsDisplayModelSinkMock()
        self.application.displayModelSink = newDisplayModelSink

        let oldExpectation = XCTestExpectation()
        oldExpectation.isInverted = true
        self.mockIngredientDisplayModelSink.sendIngredientDisplayModelClosure = { _ in
            oldExpectation.fulfill()
        }

        self.application.send(domainModel: self.testStoredData)

        wait(for: [oldExpectation], timeout: 0.0)
    }

    // MARK: Action Tests
    func testApplication_WhenSentUpdateNameNotEditing_DoesSaveWithNewName() throws {
        self.application.send(domainModel: self.testStoredData)

        let newName = "New testing name"
        var expectedIngredient = self.testIngredient!
        expectedIngredient.name = newName

        let expectation = XCTestExpectation()
        self.mockModelStore.sendActionClosure = { action in
            switch action {
            case .save(ingredient: let newIngredient):
                XCTAssertEqual(
                    expectedIngredient,
                    newIngredient
                )
                expectation.fulfill()
            }
        }

        self.application.send(ingredientAction: .edit(.name(newName)))
        wait(for: [expectation], timeout: 0.0)
    }

    func testApplication_WhenSentUpdateNameAndEditing_DoesNotSaveWithNewName() throws {
        self.application.send(domainModel: self.testStoredData)
        self.application.send(editModeAction: .startEditing)

        let newName = "New testing name"
        var expectedIngredient = self.testIngredient!
        expectedIngredient.name = newName

        let expectation = XCTestExpectation()
        expectation.isInverted = true
        self.mockModelStore.sendActionClosure = { action in
            expectation.fulfill()
        }

        self.application.send(ingredientAction: .edit(.name(newName)))
        wait(for: [expectation], timeout: 0.0)
    }

    func testApplication_WhenStartsEditing_DoesSendCannotSave() throws {
        self.application.send(domainModel: self.testStoredData)

        let newName = "New testing name"
        var expectedIngredient = self.testIngredient!
        expectedIngredient.name = newName

        let expectation = XCTestExpectation()
        self.mockIngredientDisplayModelSink
            .sendEditModeDisplayModelClosure = { displayModel in
                XCTAssertFalse(displayModel.canSave)
                expectation.fulfill()
            }

        self.application.send(editModeAction: .startEditing)

        wait(for: [expectation], timeout: 0.0)
    }

    func testApplication_WhenSentUpdateNameAndEditing_DoesSendCanSave() throws {
        self.application.send(domainModel: self.testStoredData)
        self.application.send(editModeAction: .startEditing)

        let newName = "New testing name"
        var expectedIngredient = self.testIngredient!
        expectedIngredient.name = newName

        let expectation = XCTestExpectation()
        self.mockIngredientDisplayModelSink
            .sendEditModeDisplayModelClosure = { displayModel in
                XCTAssert(displayModel.canSave)
                expectation.fulfill()
        }

        self.application.send(ingredientAction: .edit(.name(newName)))
        wait(for: [expectation], timeout: 0.0)
    }

    func testApplication_WhenSentUpdateNameToSameAndEditing_DoesSendCanSave() throws {
        self.application.send(domainModel: self.testStoredData)
        self.application.send(editModeAction: .startEditing)

        let newName = "New testing name"
        var expectedIngredient = self.testIngredient!
        expectedIngredient.name = newName

        let expectation = XCTestExpectation()
        self.mockIngredientDisplayModelSink
            .sendEditModeDisplayModelClosure = { displayModel in
                XCTAssertFalse(displayModel.canSave)
                expectation.fulfill()
            }

        self.application.send(ingredientAction: .edit(.name(self.testName)))
        wait(for: [expectation], timeout: 0.0)
    }

    func testApplication_WhenSentUpdateDescNotEditing_DoesSaveWithNewDesc() throws {
        self.application.send(domainModel: self.testStoredData)

        let newDescription = "New testing description"
        var expectedIngredient = self.testIngredient!
        expectedIngredient.description = newDescription

        let expectation = XCTestExpectation()
        self.mockModelStore.sendActionClosure = { action in
            switch action {
            case .save(ingredient: let newIngredient):
                XCTAssertEqual(
                    expectedIngredient,
                    newIngredient
                )
                expectation.fulfill()
            }
        }

        self.application.send(
            ingredientAction: .edit(.description(newDescription))
        )
        wait(for: [expectation], timeout: 0.0)
    }

    func testApplication_WhenSentUpdateDescAndEditing_DoesNotSaveWithNewDesc() throws {
        self.application.send(domainModel: self.testStoredData)
        self.application.send(editModeAction: .startEditing)

        let newDescription = "New testing description"
        var expectedIngredient = self.testIngredient!
        expectedIngredient.description = newDescription

        let expectation = XCTestExpectation()
        expectation.isInverted = true
        self.mockModelStore.sendActionClosure = { action in
            expectation.fulfill()
        }

        self.application.send(
            ingredientAction: .edit(.description(newDescription))
        )
        wait(for: [expectation], timeout: 0.0)
    }

    func testApplication_WhenSentUpdateDescAndEditing_DoesSendCanSave() throws {
        self.application.send(domainModel: self.testStoredData)
        self.application.send(editModeAction: .startEditing)

        let newDesc = "New testing desc"
        var expectedIngredient = self.testIngredient!
        expectedIngredient.description = newDesc

        let expectation = XCTestExpectation()
        self.mockIngredientDisplayModelSink
            .sendEditModeDisplayModelClosure = { displayModel in
                XCTAssert(displayModel.canSave)
                expectation.fulfill()
            }

        self.application.send(ingredientAction: .edit(.description(newDesc)))
        wait(for: [expectation], timeout: 0.0)
    }

    func testApplication_WhenSentUpdateDescToSameAndEditing_DoesSendCanSave() throws {
        self.application.send(domainModel: self.testStoredData)
        self.application.send(editModeAction: .startEditing)

        let expectation = XCTestExpectation()
        self.mockIngredientDisplayModelSink
            .sendEditModeDisplayModelClosure = { displayModel in
                XCTAssertFalse(displayModel.canSave)
                expectation.fulfill()
            }

        self.application.send(
            ingredientAction: .edit(.description(self.testDescription))
        )
        wait(for: [expectation], timeout: 0.0)
    }

    func testApplication_WhenGivenNewStore_DoesNotSendActions() throws {
        self.application.send(domainModel: self.testStoredData)
        self.application.send(ingredientAction: .edit(.name("Blah")))

        let newStore = IngredientStoreActionSinkMock()
        let badExpectation = XCTestExpectation()
        badExpectation.isInverted = true

        newStore.sendActionClosure = { _ in badExpectation.fulfill() }

        self.application.domainModelStore = newStore
        wait(for: [badExpectation], timeout: 0.0)
    }

    func testApplication_WhenSentStartEditing_DoesSendCanEdit() throws {
        self.application.send(domainModel: self.testStoredData)

        let expectation = XCTestExpectation()
        self.mockIngredientDisplayModelSink
            .sendEditModeDisplayModelClosure = { displayModel in
                XCTAssert(displayModel.isEditing)
                expectation.fulfill()
            }

        self.application.send(editModeAction: .startEditing)
        wait(for: [expectation], timeout: 0.0)
    }

    func testApplication_WhenWithChangesSentCancelEditing_DoesFollowDelegate() throws {
        let alertSink = IngredientDetailsDisplayModelSinkMock()
        self.application.displayModelSink = alertSink

        self.application.send(domainModel: self.testStoredData)

        self.application.send(editModeAction: .startEditing)
        self.application.send(ingredientAction: .edit(.name("Changed")))

        let expectation = XCTestExpectation()
        expectation.isInverted = true
        self.mockIngredientDisplayModelSink
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
        self.application.send(domainModel: self.testStoredData)

        self.application.send(editModeAction: .startEditing)
        self.application.send(ingredientAction: .edit(.description("NEW")))
        self.application.send(ingredientAction: .edit(.name("NEW")))

        let expectation = XCTestExpectation()
        self.mockIngredientDisplayModelSink
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
        self.application.send(domainModel: self.testStoredData)

        self.application.send(editModeAction: .startEditing)

        let expectation = XCTestExpectation()
        self.mockIngredientDisplayModelSink
            .sendEditModeDisplayModelClosure = { displayModel in
                XCTAssertFalse(displayModel.isEditing)
                expectation.fulfill()
            }

        self.application.send(editModeAction: .finishEditing(.save))
        wait(for: [expectation], timeout: 0.0)
    }

    func testApplication_WhenWithAlertSentCompleteEditing_DoesNotAlertAndSendCanEditFalse() throws {
        self.application.send(domainModel: self.testStoredData)

        self.application.send(editModeAction: .startEditing)

        let expectation = XCTestExpectation()
        self.mockIngredientDisplayModelSink
            .sendEditModeDisplayModelClosure = { displayModel in
                XCTAssertFalse(displayModel.isEditing)
                expectation.fulfill()
            }

        let badExpectation = XCTestExpectation()
        badExpectation.isInverted = true
        self.mockIngredientDisplayModelSink
            .sendAlertDisplayModelDidConfirmClosure = { _, _ in
            badExpectation.fulfill()
        }

        self.application.send(editModeAction: .finishEditing(.save))
        wait(for: [expectation, badExpectation], timeout: 0.0)
    }

    func testApplication_WhenSentCompleteEditing_DoesSendSaveToStore() throws {
        self.application.send(domainModel: self.testStoredData)

        self.application.send(editModeAction: .startEditing)
        let newIngredient = Ingredient(
            id: testIngredient.id,
            name: "NEW",
            description: "NEW",
            tags: self.testTags
        )

        self.application.send(
            ingredientAction: .edit(.name(
                newIngredient.name
            )
        ))
        self.application.send(
            ingredientAction: .edit(.description(
                newIngredient.description
            )
        ))

        let expectation = XCTestExpectation()
        self.mockModelStore.sendActionClosure = { action in
            switch action {
            case .save(ingredient: let receivedIngredient):
                XCTAssertEqual(
                    newIngredient,
                    receivedIngredient
                )
                expectation.fulfill()
            }
        }

        self.application.send(editModeAction: .finishEditing(.save))
        wait(for: [expectation], timeout: 0.0)
    }

    func testApplication_WhenEditingSentAddTag_DoesSendToDelegate() throws {
        self.application.send(domainModel: self.testStoredData)
        
        self.application.send(editModeAction: .startEditing)

        let expectation = XCTestExpectation()
        self.mockDelegate.requestEditTagsForIngredientClosure = { _ in
            expectation.fulfill()
        }

        self.application.send(ingredientAction: .action(.addTag))

        wait(for: [expectation], timeout: 0.0)
    }

    func testApplication_WhenNotEditingSentAddTag_DoesSendToDelegate() throws {
        self.application.send(domainModel: self.testStoredData)

        let expectation = XCTestExpectation()
        self.mockDelegate.requestEditTagsForIngredientClosure = { _ in
            expectation.fulfill()
        }

        self.application.send(ingredientAction: .action(.addTag))

        wait(for: [expectation], timeout: 0.0)
    }

    func testApplication_SendsInvalidity_OnlyAfterEditing() throws {
        let firstExpectation = XCTestExpectation()
        self.mockIngredientDisplayModelSink.sendIngredientDisplayModelClosure = { displayModel in
            XCTAssert(displayModel.name.isValid)
            firstExpectation.fulfill()
        }

        self.application.send(domainModel: .init(
            ingredient: .init(
                name: "",
                description: "",
                tags: []
            ),
            usedNames: self.usedNames
        ))

        self.application.send(editModeAction: .startEditing)
        wait(for: [firstExpectation], timeout: 0.0)

        let secondExpectation = XCTestExpectation()
        self.mockIngredientDisplayModelSink.sendIngredientDisplayModelClosure = {
            displayModel in
            XCTAssertFalse(displayModel.name.isValid)
            secondExpectation.fulfill()
        }
        self.application.send(ingredientAction: .edit(.name("")))

        wait(for: [secondExpectation], timeout: 0.0)
    }

    func testApplication_IfEditToExistingName_SendsCannotSave() throws {
        self.application.send(domainModel: self.testStoredData)
        self.application.send(editModeAction: .startEditing)
        let expectation = XCTestExpectation()
        self.mockIngredientDisplayModelSink.sendEditModeDisplayModelClosure = { displayModel in
            XCTAssertFalse(displayModel.canSave)
            expectation.fulfill()
        }

        self.application.send(
            ingredientAction: .edit(.name(self.usedNames.first!.key))
        )

        wait(for: [expectation], timeout: 0.0)
    }

    func testApplication_IfEditToExistingName_SendsInvalidData() throws {
        self.application.send(editModeAction: .startEditing)
        let expectation = XCTestExpectation()
        self.mockIngredientDisplayModelSink.sendIngredientDisplayModelClosure = { displayModel in
            XCTAssertEqual(
                displayModel.name.invalidityReason?.error,
                TestAppContent.testIngredientDetailsApplicationContent.existingNameInvalidDescription
            )
            XCTAssertEqual(
                displayModel.name.invalidityReason?.suggestion,
                TestAppContent.testIngredientDetailsApplicationContent.existingNameInvalidSuggestion
            )
            expectation.fulfill()
        }

        self.application.send(
            ingredientAction: .edit(.name(self.usedNames.first!.key))
        )

        wait(for: [expectation], timeout: 0.0)
    }
}
