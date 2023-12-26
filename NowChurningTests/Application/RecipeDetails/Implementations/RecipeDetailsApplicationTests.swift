//
//  RecipeDetailsApplicationTests.swift
//  NowChurningTests
//
//  Created by Austin Dumm on 3/4/23.
//

import XCTest
@testable import NowChurning

final class RecipeDetailsApplicationTests: XCTestCase {

    var application: RecipeDetailsApplication!
    var displayModelSink: RecipeDetailsDisplayModelSinkMock!
    var storeActionSink: RecipeDetailsStoreActionSinkMock!
    var delegate: RecipeDetailsApplicationDelegateMock!

    var testRecipeModel: RecipeDetailsModel {
        .init(
            recipe: self.testRecipe,
            stockedIngredientIds: [
                RecipeDetailsApplicationTests.testId: RecipeDetailsApplicationTests.testIngredient
            ]
        )
    }
    static var testId: ID<Ingredient> {
        .init()
    }
    static var testIngredient: Ingredient {
        Ingredient(
            id: RecipeDetailsApplicationTests.testId,
            name: "First",
            description: "Desc",
            tags: []
        )
    }

    var testRecipe = Recipe(
        name: "Test Recipe Name",
        description: "Test Recipe Description",
        recipeDetails: .init(
            steps: [
                .ingredient(
                    .init(
                        ingredient: RecipeDetailsApplicationTests.testIngredient,
                        measure: .any
                    )
                ),
                .ingredient(
                    .init(
                        ingredient: .init(
                            id: RecipeDetailsApplicationTests.testId,
                            name: "Second",
                            description: "Desc",
                            tags: []
                        ),
                        measure: .count(.init(
                            value: 3.0,
                            unit: .init(symbol: "")
                        ), "Test Count Description")
                    )
                ),
                .ingredient(
                    .init(
                        ingredient: .init(
                            name: "Third",
                            description: "Desc",
                            tags: []
                        ),
                        measure: .volume(.init(
                            value: 5.25,
                            unit: .fluidOunces)
                        )
                    )
                ),
                .instruction("Test Instruction"),
                .ingredient(
                    .init(
                        ingredient: .init(
                            name: "Fourth",
                            description: "Desc",
                            tags: [.init(name: "Tag")]
                        ),
                        measure: .any
                    )
                ),
                .ingredientTags(
                    [.init(name: "Test Tag")],
                    .count(.init(value: 15, unit: .count), "Test Count")
                )
            ]
        )
    )

    var testContent = RecipeDetailsApplication.Content(
        invalidityText: { reason in
            switch reason {
            case .emptyName:
                return "Test Empty Name"
            }
        },
        byTagPrefix: "Test Tag Prefix",
        byTagEmpty: "Test Tag Empty"
    )

    override func setUpWithError() throws {
        self.application = .init(content: testContent)
        self.displayModelSink = .init()
        self.storeActionSink = .init()
        self.delegate = .init()

        self.application.displayModelSink = self.displayModelSink
        self.application.storeActionSink = self.storeActionSink
        self.application.delegate = self.delegate
    }

    func assert(
        isExpectedDisplayModel displayModel: RecipeDetailsDisplayModel,
        forDomainModel domainModel: Recipe
    ) {
        XCTAssertEqual(
            displayModel.name.data,
            domainModel.name
        )

        XCTAssertEqual(
            displayModel.description,
            domainModel.description
        )

        let expected: [RecipeDetailsDisplayModel.RecipeStep] = domainModel
            .recipeDetails?
            .steps
            .map {
                switch $0 {
                case .ingredient(let measure):
                    return expectedIngredientStep(forMeasure: measure)
                case .ingredientTags(let tags, let amount):
                    return expectedTagsStep(
                        forTags: tags,
                        measurement: amount
                    )
                case .instruction(let instruction):
                    return .init(isStocked: true, canPreview: false, name: instruction)
                }
            } ?? []
        XCTAssertEqual(
            displayModel.recipeSteps,
            expected
        )
    }

    func expectedIngredientStep(
        forMeasure measure: Measure
    ) -> RecipeDetailsDisplayModel.RecipeStep {
        .init(
            isStocked: measure.ingredient.id == Self.testId,
            canPreview: true,
            name: expectedString(
                forStepText: measure.ingredient.name,
                measurement: measure.measure
            )
        )
    }

    func expectedTagsStep(
        forTags tags: [Tag<Ingredient>],
        measurement: MeasurementType
    ) -> RecipeDetailsDisplayModel.RecipeStep {
        let tagsText = tags
            .map { "#\($0.name)" }
            .joined(separator: ", ")

        return .init(
            isStocked: false,
            canPreview: true,
            name: expectedString(
                forStepText: "\(self.testContent.byTagPrefix) \(tagsText)",
                measurement: measurement
            )
        )
    }

    func expectedString(
        forStepText stepText: String,
        measurement: MeasurementType
    ) -> String {
        switch measurement {
        case .volume(let measurement):
            let measureText = MeasurementFormatter.volumeFormatter.string(from: measurement)
            return "\(measureText) - \(stepText)"
        case .count(let measurement, let description):
            let measureText = NumberFormatter.countFormatter.string(from: measurement.value as NSNumber) ?? String(measurement.value)
            return [
                measureText,
                description,
                "-",
                stepText,
            ].compactMap { $0 }.joined(separator: " ")
        case .any:
            return stepText
        }
    }

    func testApplication_WhenSentRecipe_DoesSendDisplayModel() throws {
        let expectation = XCTestExpectation()
        self.displayModelSink.sendDisplayModelClosure = { displayModel in
            self.assert(
                isExpectedDisplayModel: displayModel,
                forDomainModel: self.testRecipe
            )
            expectation.fulfill()
        }
        self.displayModelSink.sendEditModeDisplayModelClosure = { displayModel in
            XCTAssertFalse(displayModel.isEditing)
            XCTAssertFalse(displayModel.canSave)
            expectation.fulfill()
        }

        self.application.send(domainModel: self.testRecipeModel)
        wait(for: [expectation], timeout: 0.0)
    }

    func testApplication_WhenSentRecipeNoRecipe_DoesSendDisplayModel() throws {
        var noRecipe = self.testRecipe
        noRecipe.recipeDetails = nil

        let expectation = XCTestExpectation()
        self.displayModelSink.sendDisplayModelClosure = { displayModel in
            self.assert(
                isExpectedDisplayModel: displayModel,
                forDomainModel: noRecipe
            )
            expectation.fulfill()
        }
        self.displayModelSink.sendEditModeDisplayModelClosure = { displayModel in
            XCTAssertFalse(displayModel.isEditing)
            XCTAssertFalse(displayModel.canSave)
            expectation.fulfill()
        }

        self.application.send(domainModel: .init(recipe: noRecipe, stockedIngredientIds: [:]))
        wait(for: [expectation], timeout: 0.0)
    }

    func testApplication_WhenGivenDisplayModelSink_DoesSendDisplayModel() throws {
        self.application.send(domainModel: self.testRecipeModel)

        let expectation = XCTestExpectation()
        expectation.expectedFulfillmentCount = 2
        let newSink = RecipeDetailsDisplayModelSinkMock()
        newSink.sendDisplayModelClosure = { displayModel in
            self.assert(
                isExpectedDisplayModel: displayModel,
                forDomainModel: self.testRecipe
            )
            expectation.fulfill()
        }
        newSink.sendEditModeDisplayModelClosure = { displayModel in
            XCTAssertFalse(displayModel.isEditing)
            XCTAssertFalse(displayModel.canSave)
            expectation.fulfill()
        }

        self.application.displayModelSink = newSink

        wait(for: [expectation], timeout: 0.0)
    }

    func testApplication_WhenEditActionAndNotEditing_DoesSaveChange() throws {
        self.application
            .send(domainModel: self.testRecipeModel)

        let expectation = XCTestExpectation()
        let badExpectation = XCTestExpectation()
        badExpectation.isInverted = true
        self.displayModelSink.sendDisplayModelClosure = { _ in
            badExpectation.fulfill()
        }
        self.storeActionSink.sendActionClosure = { _ in
            expectation.fulfill()
        }

        self.application
            .send(action: .editName("Anything"))
        self.application
            .send(action: .editDescription("Anything"))

        wait(for: [expectation], timeout: 0.0)
    }

    func testApplication_WhenEditActionAndEditing_SendsOnlyDisplayModel() throws {
        self.application
            .send(domainModel: self.testRecipeModel)

        self.application
            .send(editModeAction: .startEditing)

        let badExpectation = XCTestExpectation()
        badExpectation.isInverted = true
        let expectation = XCTestExpectation()
        expectation.expectedFulfillmentCount = 2
        self.displayModelSink.sendDisplayModelClosure = { _ in
            expectation.fulfill()
        }
        self.storeActionSink.sendActionClosure = { _ in
            badExpectation.fulfill()
        }

        self.application
            .send(action: .editName("Anything"))
        self.application
            .send(action: .editDescription("Anything"))

        wait(for: [expectation, badExpectation], timeout: 0.0)
    }

    func testApplication_WhenEditActionAndCancels_DoesNotSave() throws {
        self.application
            .send(domainModel: self.testRecipeModel)

        self.application
            .send(editModeAction: .startEditing)

        let expectation = XCTestExpectation()
        expectation.isInverted = true
        self.storeActionSink.sendActionClosure = { _ in
            expectation.fulfill()
        }

        self.application
            .send(action: .editName("Anything"))
        self.application
            .send(action: .editDescription("Anything"))
        self.application
            .send(editModeAction: .finishEditing(.cancel))

        wait(for: [expectation], timeout: 0.0)
    }

    func testApplication_WhenCancelsNoChanges_DoesCallDelegate() throws {
        self.application
            .send(domainModel: self.testRecipeModel)

        self.application
            .send(editModeAction: .startEditing)

        let expectation = XCTestExpectation()
        self.delegate.didFinishEditByClosure = { _ in
            expectation.fulfill()
        }

        self.application
            .send(editModeAction: .finishEditing(.cancel))

        wait(for: [expectation], timeout: 0.0)
    }

    func testApplication_WhenCancelsWithChanges_DoesShowAlert() throws {
        self.application
            .send(domainModel: self.testRecipeModel)

        self.application
            .send(editModeAction: .startEditing)

        let expectation = XCTestExpectation()
        expectation.isInverted = true
        self.delegate.didFinishEditByClosure = { _ in
            expectation.fulfill()
        }

        let alertExpectation = XCTestExpectation()
        self.displayModelSink.sendAlertDisplayModelDidConfirmClosure = { type, _ in
            XCTAssertEqual(
                type,
                .cancel
            )
            alertExpectation.fulfill()
        }

        self.application
            .send(action: .editName("Anything"))
        self.application
            .send(action: .editDescription("Anything"))
        self.application
            .send(editModeAction: .finishEditing(.cancel))

        wait(for: [expectation, alertExpectation], timeout: 0.0)
    }

    func testApplication_WhenCancelsAndConfirms_DoesSendDisplay() throws {
        self.application
            .send(domainModel: self.testRecipeModel)

        self.application
            .send(editModeAction: .startEditing)

        self.application
            .send(action: .editName("Anything"))
        self.application
            .send(action: .editDescription("Anything"))

        let expectation = XCTestExpectation()
        self.displayModelSink.sendDisplayModelClosure = { displayModel in
            self.assert(
                isExpectedDisplayModel: displayModel,
                forDomainModel: self.testRecipe
            )
            expectation.fulfill()
        }

        let alertExpectation = XCTestExpectation()
        self.displayModelSink.sendAlertDisplayModelDidConfirmClosure = { type, callback in
            XCTAssertEqual(
                type,
                .cancel
            )
            callback(true)
            alertExpectation.fulfill()
        }

        self.application
            .send(editModeAction: .finishEditing(.cancel))

        wait(for: [expectation, alertExpectation], timeout: 0.0)
    }

    func testApplication_WhenSavesWithNothing_DoesNotSendStore() throws {
        self.application
            .send(editModeAction: .startEditing)

        let expectation = XCTestExpectation()
        expectation.isInverted = true
        self.storeActionSink.sendActionClosure = { _ in
            expectation.fulfill()
        }

        self.application
            .send(editModeAction: .finishEditing(.save))
        wait(for: [expectation], timeout: 0.0)
    }

    func testApplication_WhenStartEditing_SendsCannotSave() throws {
        self.application
            .send(domainModel: self.testRecipeModel)

        let expectation = XCTestExpectation()
        self.displayModelSink
            .sendEditModeDisplayModelClosure = { displayModel in
                XCTAssert(displayModel.isEditing)
                XCTAssertFalse(displayModel.canSave)
                expectation.fulfill()
            }

        self.application
            .send(editModeAction: .startEditing)

        wait(for: [expectation], timeout: 0.0)
    }

    func testApplication_WhenEditChanges_SendsCanSave() throws {
        self.application
            .send(domainModel: self.testRecipeModel)

        self.application
            .send(editModeAction: .startEditing)

        let expectation = XCTestExpectation()
        self.displayModelSink
            .sendEditModeDisplayModelClosure = { displayModel in
                XCTAssert(displayModel.isEditing)
                XCTAssert(displayModel.canSave)
                expectation.fulfill()
            }

        self.application
            .send(action: .editName("A different name here"))
        wait(for: [expectation], timeout: 0.0)
    }

    func testApplication_WhenEditToNoName_SendsCannotSave() throws {
        self.application
            .send(domainModel: self.testRecipeModel)

        self.application
            .send(editModeAction: .startEditing)

        let expectation = XCTestExpectation()
        self.displayModelSink
            .sendEditModeDisplayModelClosure = { displayModel in
                XCTAssert(displayModel.isEditing)
                XCTAssertFalse(displayModel.canSave)
                expectation.fulfill()
            }

        self.application
            .send(action: .editName(""))
        wait(for: [expectation], timeout: 0.0)
    }

    func testApplication_WhenSavesChanges_SendsStoreNewData() throws {
        self.application
            .send(domainModel: self.testRecipeModel)

        self.application
            .send(editModeAction: .startEditing)

        let testName = "Test updated name"
        let expectedRecipe = Recipe(
            id: self.testRecipe.id,
            name: testName,
            description: self.testRecipe.description,
            recipeDetails: self.testRecipe.recipeDetails
        )
        self.application
            .send(action: .editName(testName))

        let expectation = XCTestExpectation()
        self.storeActionSink.sendActionClosure = { action in
            switch action {
            case .save(recipe: let recipe):
                XCTAssertEqual(
                    recipe,
                    expectedRecipe
                )
                expectation.fulfill()
            default:
                XCTFail("Expected .save(recipe). Found: \(action)")
                return
            }
        }

        self.application
            .send(editModeAction: .finishEditing(.save))
        
        wait(for: [expectation], timeout: 0.0)
    }

    func testApplication_SendsInvalidity_OnlyAfterEditing() throws {
        let firstExpectation = XCTestExpectation()
        self.displayModelSink.sendDisplayModelClosure = { displayModel in
            XCTAssert(displayModel.name.isValid)
            firstExpectation.fulfill()
        }

        self.application.send(domainModel: .init(
            recipe: .init(
                name: "",
                description: ""
            ),
            stockedIngredientIds: [:]
        ))

        self.application.send(editModeAction: .startEditing)
        wait(for: [firstExpectation], timeout: 0.0)

        let secondExpectation = XCTestExpectation()
        self.displayModelSink.sendDisplayModelClosure = {
            displayModel in
            XCTAssertFalse(displayModel.name.isValid)
            secondExpectation.fulfill()
        }
        self.application.send(action: .editName(""))

        wait(for: [secondExpectation], timeout: 0.0)
    }

    func testWhenNoEditSelectMeasureStep_AlertsDelegate() {
        self.application.send(domainModel: self.testRecipeModel)
        let selectionIndex = 1
        guard
            case let .ingredient(expectedMeasure) = self.testRecipe.recipeDetails?.steps[safe: 1]
        else {
            XCTFail("Could not retrieve expected step measure")
            return
        }

        let expectation = XCTestExpectation()
        self.delegate.previewStepClosure = { step in
            guard case let .ingredient(measure) = step else {
                XCTFail("Expected ingredient. Found: \(step)")
                return
            }

            XCTAssertEqual(
                measure.ingredient,
                expectedMeasure.ingredient
            )
            expectation.fulfill()
        }

        self.application
            .send(action: .selectStep(selectionIndex))
        wait(for: [expectation], timeout: 0.0)
    }

    func testWhenEditingSelectMeasureStep_DoesNotAlertsDelegate() {
        self.application.send(domainModel: self.testRecipeModel)
        let selectionIndex = 1

        let expectation = XCTestExpectation()
        expectation.isInverted = true
        self.delegate.previewStepClosure = { _ in
            expectation.fulfill()
        }

        self.application
            .send(editModeAction: .startEditing)
        self.application
            .send(action: .selectStep(selectionIndex))
        wait(for: [expectation], timeout: 0.0)
    }

    func testWhenSelectMeasureStepOutOfBounds_DoesNotAlertsDelegate() {
        self.application.send(domainModel: self.testRecipeModel)
        let selectionIndex = 12965

        let expectation = XCTestExpectation()
        expectation.isInverted = true
        self.delegate.previewStepClosure = { _ in
            expectation.fulfill()
        }

        self.application
            .send(action: .selectStep(selectionIndex))
        wait(for: [expectation], timeout: 0.0)
    }

    func testWhenDeleteStep_DoesAlertStore() {
        self.application.send(domainModel: self.testRecipeModel)
        let deletionIndex = 1
        var expectedRecipe = self.testRecipe
        expectedRecipe.recipeDetails?.steps.remove(at: deletionIndex)

        let expectation = XCTestExpectation()
        self.storeActionSink.sendActionClosure = { action in
            switch action {
            case .save(recipe: expectedRecipe):
                expectation.fulfill()
            default:
                XCTFail("Expected .save(\(expectedRecipe)). Found: \(action)")
            }
        }

        self.application.send(action: .deleteStep(deletionIndex))
        self.application.send(editModeAction: .finishEditing(.save))
        wait(for: [expectation], timeout: 0.0)
    }

    func testWhenDeleteStep_DoesUpdateDisplaySink() {
        self.application.send(domainModel: self.testRecipeModel)
        let deletionIndex = 1
        var expectedRecipe = self.testRecipe
        expectedRecipe.recipeDetails?.steps.remove(at: deletionIndex)

        let expectation = XCTestExpectation()
        self.displayModelSink.sendDisplayModelClosure = { displayModel in
            self.assert(
                isExpectedDisplayModel: displayModel,
                forDomainModel: expectedRecipe
            )
            expectation.fulfill()
        }

        self.application.send(action: .deleteStep(deletionIndex))
        self.application.send(editModeAction: .finishEditing(.save))
        wait(for: [expectation], timeout: 0.0)
    }

    func testWhenDeleteOutOfBoundsStep_DoesNotAlertStore() {
        self.application.send(domainModel: self.testRecipeModel)
        let deletionIndex = 158205

        let expectation = XCTestExpectation()
        expectation.isInverted = true
        self.storeActionSink.sendActionClosure = { action in
            expectation.fulfill()
        }

        self.application.send(action: .deleteStep(deletionIndex))
        self.application.send(editModeAction: .finishEditing(.save))
        wait(for: [expectation], timeout: 0.0)
    }

    func testWhenMoveRecipeStep_AlertsStore() {
        self.application.send(domainModel: self.testRecipeModel)
        let from = 2
        let to = 0
        var expectedRecipe = self.testRecipe
        var recipe = expectedRecipe.recipeDetails!
        recipe.steps.move(fromOffsets: [from], toOffset: to)
        expectedRecipe.recipeDetails = recipe

        let expectation = XCTestExpectation()
        self.storeActionSink.sendActionClosure = { action in
            switch action {
            case .save(recipe: expectedRecipe):
                expectation.fulfill()
            default:
                XCTFail("Expected .save(\(expectation)). Found: \(action)")
            }
        }

        self.application.send(editModeAction: .startEditing)
        self.application.send(action: .moveStep(from: from, to: to))
        self.application.send(editModeAction: .finishEditing(.save))

        wait(for: [expectation], timeout: 0.0)
    }

    func testWhenMoveRecipeStepFromOutOfBounds_DoesNotAlertsStore() {
        self.application.send(domainModel: self.testRecipeModel)
        let from = 2000
        let to = 0

        let expectation = XCTestExpectation()
        expectation.isInverted = true
        self.storeActionSink.sendActionClosure = { action in
            expectation.fulfill()
        }

        self.application.send(editModeAction: .startEditing)
        self.application.send(action: .moveStep(from: from, to: to))
        self.application.send(editModeAction: .finishEditing(.save))

        wait(for: [expectation], timeout: 0.0)
    }

    func testWhenMoveRecipeStepToOutOfBounds_DoesNotAlertsStore() {
        self.application.send(domainModel: self.testRecipeModel)
        let from = 2
        let to = 582895

        let expectation = XCTestExpectation()
        expectation.isInverted = true
        self.storeActionSink.sendActionClosure = { action in
            expectation.fulfill()
        }

        self.application.send(editModeAction: .startEditing)
        self.application.send(action: .moveStep(from: from, to: to))
        self.application.send(editModeAction: .finishEditing(.save))

        wait(for: [expectation], timeout: 0.0)
    }

    func testWhenMoveRecipeStep_SendsDisplayModel() {
        self.application.send(domainModel: self.testRecipeModel)
        let from = 2
        let to = 0
        var expectedRecipe = self.testRecipe
        var recipe = expectedRecipe.recipeDetails!
        recipe.steps.move(fromOffsets: [from], toOffset: to)
        expectedRecipe.recipeDetails = recipe

        let expectation = XCTestExpectation()
        self.displayModelSink.sendDisplayModelClosure = { displayModel in
            self.assert(
                isExpectedDisplayModel: displayModel,
                forDomainModel: expectedRecipe
            )
            expectation.fulfill()
        }

        self.application.send(editModeAction: .startEditing)
        self.application.send(action: .moveStep(from: from, to: to))

        wait(for: [expectation], timeout: 0.0)
    }

    func testWhenAddStepSent_AlertsDelegate() {
        self.application.send(domainModel: self.testRecipeModel)

        let expectation = XCTestExpectation()
        self.delegate.addStepClosure = {
            expectation.fulfill()
        }

        self.application.send(action: .addStep)
        wait(for: [expectation], timeout: 0.0)
    }

    func testWhenOpenStepInfo_AlertsDelegate() {
        let expectedIndex = 1
        self.application.send(domainModel: self.testRecipeModel)

        let expectation = XCTestExpectation()
        self.delegate.editStepForRecipeAtIndexClosure = { _, index in
            XCTAssertEqual(
                index,
                expectedIndex
            )

            expectation.fulfill()
        }

        self.application.send(action: .openInfo(forStep: expectedIndex))
        wait(for: [expectation], timeout: 0.0)
    }

}
