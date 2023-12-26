//
//  RecipeDetailsItemListPresentationTests.swift
//  NowChurningTests
//
//  Created by Austin Dumm on 3/4/23.
//

import XCTest
@testable import NowChurning

final class RecipeDetailsItemListPresentationTests: XCTestCase {

    var presentation: RecipeDetailsItemListPresentation!
    var viewModelSink: ItemListViewModelSinkMock!
    var navBarViewModelSink: NavBarViewModelSinkMock!
    var actionSink: RecipeDetailsActionSinkMock!

    var testDisplayModel = RecipeDetailsDisplayModel(
        name: .valid("Test Recipe Name"),
        description: "Test Recipe Description",
        recipeSteps: [
            .init(isStocked: true, canPreview: true, name: "First step"),
            .init(isStocked: true, canPreview: true, name: "Second step"),
            .init(isStocked: true, canPreview: true, name: "Third step"),
        ]
    )

    var content = RecipeDetailsItemListPresentation.Content(
        sectionTitles: .init(
            nameLabelText: "Test Name Title",
            descriptionLabelText: "Test Description Title",
            recipeLabelText: "Test Recipe Title",
            requiredSectionSuffix: "Test Required"
        ),
        editingHeaderTitle: "Test Editing",
        addStepCellTitle: "Test Add Step",
        unstockedMessage: "Test Unstocked",
        unstockedResolution: "Test Resolution",
        alertContent: .init(
            descriptionText: "Test Alert Description",
            confirmText: "Test Alert Confirm",
            cancelText: "Test Alert Cancel"
        )
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

    func assert(
        isExpectedViewModel viewModel: ItemListViewModel,
        forDisplayModel displayModel: RecipeDetailsDisplayModel,
        isEditing: Bool = false
    ) {
        if isEditing {
            assertEditing(
                isExpectedViewModel: viewModel,
                forDisplayModel: displayModel
            )
        } else {
            assertViewing(
                isExpectedViewModel: viewModel,
                forDisplayModel: displayModel
            )
        }
    }

    func assertEditing(
        isExpectedViewModel viewModel: ItemListViewModel,
        forDisplayModel displayModel: RecipeDetailsDisplayModel
    ) {
        let sectionAssertions: [(ItemListViewModel.Section, RecipeDetailsDisplayModel) -> Void] = [
            assertEditing(isExpectedNameSection:forDisplayModel:),
            assertEditing(isExpectedDescriptionSection:forDisplayModel:),
            assertEditing(isExpectedRecipeSection:forDisplayModel:)
        ]

        let expectedData = [
            displayModel.name.data,
            displayModel.description.isEmpty ? nil : displayModel.description,
            displayModel.recipeSteps.isEmpty ? nil : displayModel.recipeSteps as Any
        ]

        let activeAssertions = zip(sectionAssertions, expectedData)
            .filter { (_, data) in
                data != nil
            }
            .map { (assertion, _ ) in assertion }


        XCTAssertEqual(
            viewModel.sections.count,
            activeAssertions.count
        )

        let pairedAsserts = zip(activeAssertions, viewModel.sections)

        for (assert, section) in pairedAsserts {
            assert(
                section,
                displayModel
            )
        }
    }

    func assertEditing(
        isExpectedNameSection section: ItemListViewModel.Section,
        forDisplayModel displayModel: RecipeDetailsDisplayModel
    ) {
        XCTAssertEqual(
            section.title,
            "\(self.content.sectionTitles.nameLabelText) \(self.content.sectionTitles.requiredSectionSuffix)"
        )

        XCTAssertEqual(
            section.items.count,
            1
        )

        let type = section.items[0].type
        switch type {
        case .editSingleline(let text, let purpose):
            XCTAssertEqual(
                text,
                displayModel.name.data
            )

            XCTAssertEqual(
                purpose,
                self.content.sectionTitles.nameLabelText
            )
        default:
            XCTFail("Expected text item. Found: \(type)")
        }

        XCTAssertEqual(
            section.items[0].context.count,
            0
        )
    }

    func assertEditing(
        isExpectedDescriptionSection section: ItemListViewModel.Section,
        forDisplayModel displayModel: RecipeDetailsDisplayModel
    ) {
        XCTAssertEqual(
            section.title,
            self.content.sectionTitles.descriptionLabelText
        )

        XCTAssertEqual(
            section.items.count,
            1
        )

        let type = section.items[0].type
        switch type {
        case .editMultiline(let text, let purpose):
            XCTAssertEqual(
                text,
                displayModel.description
            )

            XCTAssertEqual(
                purpose,
                self.content.sectionTitles.descriptionLabelText
            )
        default:
            XCTFail("Expected text item. Found: \(type)")
        }

        XCTAssertEqual(
            section.items[0].context.count,
            0
        )
    }

    func assertViewing(
        isExpectedViewModel viewModel: ItemListViewModel,
        forDisplayModel displayModel: RecipeDetailsDisplayModel
    ) {
        let sectionAssertions: [(ItemListViewModel.Section, RecipeDetailsDisplayModel) -> Void] = [
            assertViewing(isExpectedNameSection:forDisplayModel:),
            assertViewing(isExpectedDescriptionSection:forDisplayModel:),
            assertViewing(isExpectedRecipeSection:forDisplayModel:)
        ]

        let expectedData = [
            displayModel.name.data,
            displayModel.description.isEmpty ? nil : displayModel.description,
            displayModel.recipeSteps.isEmpty ? nil : displayModel.recipeSteps as Any
        ]

        let activeAssertions = zip(sectionAssertions, expectedData)
            .filter { (_, data) in
                data != nil
            }
            .map { (assertion, _ ) in assertion }


        XCTAssertEqual(
            viewModel.sections.count,
            activeAssertions.count
        )

        let pairedAsserts = zip(activeAssertions, viewModel.sections)

        for (assert, section) in pairedAsserts {
            assert(
                section,
                displayModel
            )
        }
    }

    func assertViewing(
        isExpectedNameSection section: ItemListViewModel.Section,
        forDisplayModel displayModel: RecipeDetailsDisplayModel
    ) {
        XCTAssertEqual(
            section.title,
            self.content.sectionTitles.nameLabelText
        )

        XCTAssertEqual(
            section.items.count,
            1
        )

        let type = section.items[0].type
        switch type {
        case .text(let text):
            XCTAssertEqual(
                text,
                displayModel.name.data
            )
        default:
             XCTFail("Expected text item. Found: \(type)")
        }

        XCTAssertEqual(
            section.items[0].context.count,
            0
        )
    }

    func assertViewing(
        isExpectedDescriptionSection section: ItemListViewModel.Section,
        forDisplayModel displayModel: RecipeDetailsDisplayModel
    ) {
        XCTAssertEqual(
            section.title,
            self.content.sectionTitles.descriptionLabelText
        )

        XCTAssertEqual(
            section.items.count,
            1
        )

        let type = section.items[0].type
        switch type {
        case .text(let text):
            XCTAssertEqual(
                text,
                displayModel.description
            )
        default:
            XCTFail("Expected text item. Found: \(type)")
        }

        XCTAssertEqual(
            section.items[0].context.count,
            0
        )
    }

    func assert(
        isExpectedNavBarViewModel viewModel: NavBarViewModel,
        content: RecipeDetailsItemListPresentation.Content,
        forDisplayModel displayModel: RecipeDetailsDisplayModel,
        editModeDisplayModel: EditModeDisplayModel
    ) {
        if editModeDisplayModel.isEditing {
            XCTAssertEqual(
                viewModel.title,
                content.editingHeaderTitle
            )

            XCTAssertEqual(
                viewModel.leftButtons,
                [.init(
                    type: .cancel,
                    isEnabled: true
                )]
            )

            XCTAssertEqual(
                viewModel.rightButtons,
                [.init(
                    type: .save,
                    isEnabled: editModeDisplayModel.canSave
                )]
            )
        } else {
            XCTAssertEqual(
                viewModel.title,
                displayModel.name.data
            )

            XCTAssertEqual(
                viewModel.leftButtons,
                [.init(
                    type: .back,
                    isEnabled: true
                )]
            )

            XCTAssertEqual(
                viewModel.rightButtons,
                [.init(
                    type: .edit,
                    isEnabled: editModeDisplayModel.canSave
                )]
            )
        }
    }

    func assertEditing(
        isExpectedRecipeSection viewModel: ItemListViewModel.Section,
        forDisplayModel displayModel: RecipeDetailsDisplayModel
    ) {
        XCTAssertEqual(
            viewModel.title,
            self.content.sectionTitles.recipeLabelText
        )

        if let addStep = viewModel.items.first {
            switch addStep.type {
            case .text(self.content.addStepCellTitle):
                break
            default:
                XCTFail("Expected .text(\(self.content.addStepCellTitle)). Found: \(addStep.type)")
            }

            XCTAssertEqual(
                addStep.context,
                [.add]
            )
        }

        for (item, stepText) in zip(Array(viewModel.items.dropFirst()), displayModel.recipeSteps) {
            XCTAssertEqual(
                item.context,
                [.delete, .info, .reorder(
                    .init(sections: .set([2: .set(Set(1...viewModel.items.count))]))
                )]
            )

            XCTAssertEqual(
                item.indentation,
                0
            )

            guard case .text(let text) = item.type else {
                XCTFail("Expected item of type .attributedText(\(stepText)). Found \(item.type)")
                return
            }

            XCTAssertEqual(
                text,
                stepText.name
            )
        }
    }

    func assertViewing(
        isExpectedRecipeSection viewModel: ItemListViewModel.Section,
        forDisplayModel displayModel: RecipeDetailsDisplayModel
    ) {
        XCTAssertEqual(
            viewModel.title,
            self.content.sectionTitles.recipeLabelText
        )

        for (item, stepText) in zip(viewModel.items, displayModel.recipeSteps) {
            XCTAssertEqual(
                item.context,
                (stepText.canPreview ? [.navigate] : []) + [.delete]
            )

            XCTAssertEqual(
                item.indentation,
                0
            )

            guard case .text(let text) = item.type else {
                XCTFail("Expected item of type .attributedText(\(stepText)). Found \(item.type)")
                return
            }

            XCTAssertEqual(
                text,
                stepText.name
            )
        }
    }

    func testPresentation_WhenGivenDisplayModel_DoesSendViewModel() throws {
        let expectation = XCTestExpectation()
        self.viewModelSink.sendViewModelClosure = { viewModel in
            self.assert(
                isExpectedViewModel: viewModel,
                forDisplayModel: self.testDisplayModel
            )
            expectation.fulfill()
        }

        self.presentation.send(displayModel: self.testDisplayModel)
        wait(for: [expectation], timeout: 0.0)
    }

    func testPresentation_WhenGivenDisplayModelEmptyDesc_DoesSendViewModel() throws {
        let emptyDesc = RecipeDetailsDisplayModel(
            name: .valid("Test Empty Desc Name"),
            description: "",
            recipeSteps: [
                .init(isStocked: true, canPreview: true, name: "First step"),
                .init(isStocked: true, canPreview: true, name: "Second step"),
                .init(isStocked: true, canPreview: true, name: "Third step")
            ]
        )

        let expectation = XCTestExpectation()
        self.viewModelSink.sendViewModelClosure = { viewModel in
            self.assert(
                isExpectedViewModel: viewModel,
                forDisplayModel: emptyDesc
            )
            expectation.fulfill()
        }

        self.presentation.send(displayModel: emptyDesc)
        wait(for: [expectation], timeout: 0.0)
    }

    func testPresentation_WhenNewViewModelSink_DoesSendViewModel() throws {
        self.presentation.send(displayModel: self.testDisplayModel)

        let expectation = XCTestExpectation()
        let newSink = ItemListViewModelSinkMock()
        newSink.sendViewModelClosure = { viewModel in
            self.assert(
                isExpectedViewModel: viewModel,
                forDisplayModel: self.testDisplayModel
            )
            expectation.fulfill()
        }

        self.presentation.viewModelSink = newSink
        wait(for: [expectation], timeout: 0.0)
    }

    func testPresentation_WhenSentEditModel_DoesSendNavBarModel() throws {
        let testEditModeDisplayModel = EditModeDisplayModel(
            isEditing: true,
            canSave: true
        )
        self.presentation
            .send(displayModel: self.testDisplayModel)

        let expectation = XCTestExpectation()
        self.navBarViewModelSink.sendNavBarViewModelClosure = { viewModel in
            self.assert(
                isExpectedNavBarViewModel: viewModel,
                content: self.content,
                forDisplayModel: self.testDisplayModel,
                editModeDisplayModel: testEditModeDisplayModel
            )
            expectation.fulfill()
        }

        self.presentation
            .send(editModeDisplayModel: testEditModeDisplayModel)
        wait(for: [expectation], timeout: 0.0)
    }

    func testPresentation_WhenSentEditModel_DoesSendEditListModel() throws {
        let testEditModeDisplayModel = EditModeDisplayModel(
            isEditing: true,
            canSave: true
        )
        self.presentation
            .send(displayModel: self.testDisplayModel)

        let expectation = XCTestExpectation()
        self.viewModelSink.sendViewModelClosure = { viewModel in
            self.assert(
                isExpectedViewModel: viewModel,
                forDisplayModel: self.testDisplayModel,
                isEditing: true
            )
            expectation.fulfill()
        }

        self.presentation
            .send(editModeDisplayModel: testEditModeDisplayModel)
        wait(for: [expectation], timeout: 0.0)
    }

    func testPresentation_WhenSentNotEditingModel_DoesSendNavBarModel() throws {
        let testEditModeDisplayModel = EditModeDisplayModel(
            isEditing: false,
            canSave: true
        )
        self.presentation
            .send(displayModel: self.testDisplayModel)

        let expectation = XCTestExpectation()
        self.navBarViewModelSink.sendNavBarViewModelClosure = { viewModel in
            self.assert(
                isExpectedNavBarViewModel: viewModel,
                content: self.content,
                forDisplayModel: self.testDisplayModel,
                editModeDisplayModel: testEditModeDisplayModel
            )
            expectation.fulfill()
        }

        self.presentation
            .send(editModeDisplayModel: testEditModeDisplayModel)
        wait(for: [expectation], timeout: 0.0)
    }

    func testPresentation_WhenSentEditNoSaveModel_DoesSendNavBarModel() throws {
        let testEditModeDisplayModel = EditModeDisplayModel(
            isEditing: true,
            canSave: false
        )
        self.presentation
            .send(displayModel: self.testDisplayModel)

        let expectation = XCTestExpectation()
        self.navBarViewModelSink.sendNavBarViewModelClosure = { viewModel in
            self.assert(
                isExpectedNavBarViewModel: viewModel,
                content: self.content,
                forDisplayModel: self.testDisplayModel,
                editModeDisplayModel: testEditModeDisplayModel
            )
            expectation.fulfill()
        }

        self.presentation
            .send(editModeDisplayModel: testEditModeDisplayModel)
        wait(for: [expectation], timeout: 0.0)
    }

    func testPresentation_WhenSetNavBarSink_DoesSendNavBarModel() throws {
        let testEditModeDisplayModel = EditModeDisplayModel(
            isEditing: true,
            canSave: false
        )
        self.presentation
            .send(displayModel: self.testDisplayModel)
        self.presentation
            .send(editModeDisplayModel: testEditModeDisplayModel)

        let newNavBarSink = NavBarViewModelSinkMock()
        let expectation = XCTestExpectation()
        newNavBarSink.sendNavBarViewModelClosure = { viewModel in
            self.assert(
                isExpectedNavBarViewModel: viewModel,
                content: self.content,
                forDisplayModel: self.testDisplayModel,
                editModeDisplayModel: testEditModeDisplayModel
            )
            expectation.fulfill()
        }

        self.presentation
            .navBarViewModelSink = newNavBarSink
        wait(for: [expectation], timeout: 0.0)
    }

    func testPresentation_WhenEditNavAction_DoesSendStartEdit() throws {
        self.presentation
            .send(
                editModeDisplayModel: .init(
                    isEditing: false,
                    canSave: true
                )
            )

        let expectation = XCTestExpectation()
        self.actionSink.sendEditModeActionClosure = { action in
            switch action {
            case .startEditing:
                break
            default:
                XCTFail("Expected startEditing. Found: \(action)")
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

    func testPresentation_WhenSaveNavAction_DoesSendStartEdit() throws {
        self.presentation
            .send(
                editModeDisplayModel: .init(
                    isEditing: true,
                    canSave: true
                )
            )

        let expectation = XCTestExpectation()
        self.actionSink.sendEditModeActionClosure = { action in
            switch action {
            case .finishEditing(.save):
                break
            default:
                XCTFail("Expected startEditing. Found: \(action)")
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

    func testPresentation_WhenCancelNavAction_DoesSendStartEdit() throws {
        self.presentation
            .send(
                editModeDisplayModel: .init(
                    isEditing: true,
                    canSave: true
                )
            )

        let expectation = XCTestExpectation()
        self.actionSink.sendEditModeActionClosure = { action in
            switch action {
            case .finishEditing(.cancel):
                break
            default:
                XCTFail("Expected startEditing. Found: \(action)")
            }

            expectation.fulfill()
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

    func testPresentation_WhenSentAlert_DoesSendAlert() throws {
        let expectation = XCTestExpectation()
        self.navBarViewModelSink
            .sendAlertViewModelClosure = { _ in
                expectation.fulfill()
            }

        self.presentation
            .send(
                alertDisplayModel: .cancel,
                didConfirm: { _ in }
            )
        wait(for: [expectation], timeout: 0.0)
    }

    func testPresentation_WhenEditNameEvent_DoesSendAction() throws {
        let testText = "Updated text"
        let namePath = IndexPath(item: 0, section: 0)
        let expectation = XCTestExpectation()
        self.actionSink.sendActionClosure = { action in
            switch action {
            case .editName(let received):
                XCTAssertEqual(
                    received,
                    testText
                )
                expectation.fulfill()
            default:
                XCTFail("Expected editName. Found: \(action)")
            }
        }

        self.presentation
            .send(
                event: .edit(
                    string: testText,
                    forItemAt: namePath
                )
            )
        wait(for: [expectation], timeout: 0.0)
    }

    func testPresentation_WhenEditDescriptionEvent_DoesSendAction() throws {
        let testText = "Updated text"
        let descriptionPath = IndexPath(item: 0, section: 1)
        let expectation = XCTestExpectation()
        self.actionSink.sendActionClosure = { action in
            switch action {
            case .editDescription(let received):
                XCTAssertEqual(
                    received,
                    testText
                )
                expectation.fulfill()
            default:
                XCTFail("Expected editDescription. Found: \(action)")
            }
        }

        self.presentation
            .send(
                event: .edit(
                    string: testText,
                    forItemAt: descriptionPath
                )
            )
        wait(for: [expectation], timeout: 0.0)
    }

    func testPresentation_WhenEditingGivenInvalidName_DoesSendErrorFooter() throws {
        self.presentation.send(editModeDisplayModel: .init(isEditing: true, canSave: false))
        let testInvalidityReason = "Test invalidity reason"

        let expectation = XCTestExpectation()
        self.viewModelSink.sendViewModelClosure = { viewModel in
            XCTAssertEqual(
                viewModel.sections[0].footerErrorMessage?.message,
                testInvalidityReason
            )
            expectation.fulfill()
        }

        self.presentation
            .send(displayModel: .init(
                name: .invalid("", .init(error: testInvalidityReason)),
                description: "",
                recipeSteps: []
            ))
        wait(for: [expectation], timeout: 0.0)
    }

    func testPresentation_WhenNotEditingGivenInvalidName_DoesNotSendErrorFooter() throws {
        let testInvalidityReason = "Test invalidity reason"

        let expectation = XCTestExpectation()
        self.viewModelSink.sendViewModelClosure = { viewModel in
            XCTAssertNil(viewModel.sections[0].footerErrorMessage)
            expectation.fulfill()
        }

        self.presentation
            .send(displayModel: .init(
                name: .invalid("", .init(error: testInvalidityReason)),
                description: "",
                recipeSteps: []
            ))
        wait(for: [expectation], timeout: 0.0)
    }

    func testWhenSelectRecipeStep_SendsAction() throws {
        self.presentation.send(displayModel: self.testDisplayModel)
        let stepIndex = 2
        let expectation = XCTestExpectation()
        self.actionSink.sendActionClosure = { action in
            switch action {
            case .selectStep(stepIndex):
                expectation.fulfill()
            default:
                XCTFail("Expected selectStep(\(stepIndex)). Found: \(action)")
                return
            }
        }

        self.presentation.send(
            event: .select(itemAt: .init(item: stepIndex, section: 2))
        )
        wait(for: [expectation], timeout: 0.0)
    }

    func testWhenDeleteRecipeStep_SendsAction() throws {
        self.presentation.send(displayModel: self.testDisplayModel)
        let stepIndex = 2
        let expectation = XCTestExpectation()
        self.actionSink.sendActionClosure = { action in
            switch action {
            case .deleteStep(stepIndex):
                expectation.fulfill()
            default:
                XCTFail("Expected deleteStep(\(stepIndex)). Found: \(action)")
                return
            }
        }

        self.presentation.send(
            event: .delete(itemAt: .init(item: stepIndex, section: 2))
        )
        wait(for: [expectation], timeout: 0.0)
    }

    func testWhenEditingDeleteRecipeStep_SendsActionWithOffset() throws {
        self.presentation.send(editModeDisplayModel: .init(isEditing: true, canSave: true))

        let stepIndex = 2
        let expectation = XCTestExpectation()
        self.actionSink.sendActionClosure = { action in
            switch action {
            case .deleteStep(stepIndex - 1):
                expectation.fulfill()
            default:
                XCTFail("Expected deleteStep(\(stepIndex)). Found: \(action)")
                return
            }
        }

        self.presentation.send(
            event: .delete(itemAt: .init(item: stepIndex, section: 2))
        )
        wait(for: [expectation], timeout: 0.0)
    }

    func testWhenMoveRecipeStep_SendsAction() throws {
        self.presentation.send(displayModel: self.testDisplayModel)
        let from = IndexPath(item: 2, section: 2)
        let to = IndexPath(item: 0, section: 2)

        let expectation = XCTestExpectation()
        self.actionSink.sendActionClosure = { action in
            switch action {
            case .moveStep(from.item, to.item):
                expectation.fulfill()
            default:
                XCTFail("Expected moveStep(\(from), \(to)). Found: \(action)")
                return
            }
        }

        self.presentation.send(
            event: .move(from: from, to: to)
        )
        wait(for: [expectation], timeout: 0.0)
    }

    func testWhenEditingAndMoveRecipeStep_SendsActionWithOffset() throws {
        self.presentation.send(editModeDisplayModel: .init(isEditing: true, canSave: true))
        let from = IndexPath(item: 3, section: 2)
        let to = IndexPath(item: 1, section: 2)

        let expectation = XCTestExpectation()
        self.actionSink.sendActionClosure = { action in
            switch action {
            case .moveStep(from.item - 1, to.item - 1):
                expectation.fulfill()
            default:
                XCTFail("Expected moveStep(\(from), \(to)). Found: \(action)")
                return
            }
        }

        self.presentation.send(
            event: .move(from: from, to: to)
        )
        wait(for: [expectation], timeout: 0.0)
    }

    func testWhenTapAddStepCell_SendsAddStepAction() throws {
        let expectation = XCTestExpectation()
        self.actionSink.sendActionClosure = { action in
            switch action {
            case .addStep:
                expectation.fulfill()
            default:
                XCTFail("Expected addStep. Found: \(action)")
            }
        }

        self.presentation.send(editModeDisplayModel: .init(isEditing: true, canSave: true))
        self.presentation.send(event: .select(itemAt: .init(item: 0, section: 2)))
        wait(for: [expectation], timeout: 0.0)
    }

    func testEditingNoRecipe_ShowsAddStep() throws {
        self.presentation.send(displayModel: .init(
            name: .valid("Test Name"),
            description: "",
            recipeSteps: []
        ))

        let expectation = XCTestExpectation()
        self.viewModelSink.sendViewModelClosure = { viewModel in
            guard
                let recipeSection = viewModel.sections[safe: 2]
            else {
                XCTFail("Could not find recipe section")
                return
            }

            XCTAssertEqual(
                recipeSection.items.count,
                1
            )

            let item = recipeSection.items[0]
            switch item.type {
            case .text(self.content.addStepCellTitle):
                break
            default:
                XCTFail("Expected .text(\(self.content.addStepCellTitle)). Found: \(item.type)")
            }

            XCTAssertEqual(
                item.context,
                [.add]
            )

            expectation.fulfill()
        }

        self.presentation.send(editModeDisplayModel: .init(isEditing: true, canSave: true))
        wait(for: [expectation], timeout: 0.0)
    }

    func testEditingTapInfo_SendsOpenInfo() throws {
        let infoIndex = 2
        self.presentation.send(editModeDisplayModel: .init(isEditing: true, canSave: true))

        let expectation = XCTestExpectation()
        self.actionSink.sendActionClosure = { action in
            switch action {
            case .openInfo(forStep: infoIndex - 1):
                expectation.fulfill()
            default:
                XCTFail("Expected .openInfo(\(infoIndex - 1)). Found: \(action)")
            }
        }

        self.presentation.send(event: .openInfo(itemAt: .init(item: infoIndex, section: 2)))
        wait(for: [expectation], timeout: 0.0)
    }

}
