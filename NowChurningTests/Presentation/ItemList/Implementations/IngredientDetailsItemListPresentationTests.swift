//
//  IngredientDetailsItemListPresentationTests.swift
//  NowChurningTests
//
//  Created by Austin Dumm on 12/17/22.
//

import XCTest
@testable import NowChurning

final class IngredientDetailsItemListPresentationTests: XCTestCase {

    var presentation: IngredientPartialItemListPresentation!
    var mockItemListViewModelSink: ItemListViewModelSinkMock!
    var mockNavBarViewModelSink: NavBarViewModelSinkMock!
    var mockActionSink: IngredientDetailsActionSinkMock!

    let contentContainer = IngredientPartialItemListPresentation.Content(
        sectionTitles: .init(
            nameLabelText: "Test Name",
            descriptionLabelText: "Test Description",
            tagsLabelText: "Test Tags",
            editTagsLabelText: "Test Edit Tags",
            requiredSectionSuffix: "Text Required"
        ),
        headerTitle: "TEST EDITING TITLE",
        editDescription: "Test Edit Ingredient",
        alertContainer: .init(
            descriptionText: "",
            confirmText: "",
            cancelText: ""
        )
    )

    let testDisplayModel = IngredientDetailsDisplayModel(
        name: .valid("Test Name"),
        description: "This is the test description",
        tagNames: ["Tag", "Name"]
    )

    override func setUp() {
        self.mockItemListViewModelSink = .init()
        self.mockNavBarViewModelSink = .init()
        self.mockActionSink = .init()

        self.presentation = .init(
            actionSink: self.mockActionSink,
            contentContainer: self.contentContainer
        )

        self.presentation.viewModelSink = self.mockItemListViewModelSink
        self.presentation.editViewModelSink = self.mockNavBarViewModelSink
    }

    func assertMatchingViewModel(
        expectedFor displayModel: IngredientDetailsDisplayModel,
        isEditing: Bool,
        received viewModel: ItemListViewModel
    ) {
        if isEditing {
            assertMatchingEditableViewModel(
                expectedFor: displayModel,
                received: viewModel
            )
        } else {
            assertMatchingReadOnlyViewModel(
                expectedFor: displayModel,
                received: viewModel
            )
        }
    }

    func assertMatchingReadOnlyViewModel(
        expectedFor displayModel: IngredientDetailsDisplayModel,
        received viewModel: ItemListViewModel
    ) {
        if displayModel.tagNames.count == 0 &&
            displayModel.description.isEmpty {
            XCTAssertEqual(
                1,
                viewModel.sections.count
            )
        } else if displayModel.tagNames.count == 0 {
            XCTAssertEqual(
                2,
                viewModel.sections.count
            )

        } else if displayModel.description.isEmpty {
            XCTAssertEqual(
                2,
                viewModel.sections.count
            )
        } else {
            XCTAssertEqual(
                3,
                viewModel.sections.count
            )
        }

        assertValidReadOnlyNameSection(
            expectedFor: displayModel,
            received: viewModel
        )

        assertValidReadOnlyDescriptionSection(
            expectedFor: displayModel,
            received: viewModel,
            isEditing: false
        )

        assertValidTagsSection(
            expectedFor: displayModel,
            received: viewModel,
            isEditing: false
        )
    }

    func assertValidReadOnlyNameSection(
        expectedFor displayModel: IngredientDetailsDisplayModel,
        received viewModel: ItemListViewModel
    ) {
        if let nameSection = viewModel.sections.first(where: { section in
            section.title == self.contentContainer.sectionTitles.nameLabelText
        }) {
            XCTAssertEqual(
                1,
                nameSection.items.count
            )

            XCTAssertEqual(
                0,
                nameSection.items[safe: 0]?.context.count
            )

            switch nameSection.items[0].type {
            case .text(let text):
                XCTAssertEqual(
                    displayModel.name.data,
                    text
                )

            case .editMultiline,
                    .editSingleline,
                    .attributedText,
                    .message:
                XCTFail("Expected text items, found editable items")
            }

        } else {
            XCTFail("Could not find valid title for name section")
        }
    }

    func assertValidReadOnlyDescriptionSection(
        expectedFor displayModel: IngredientDetailsDisplayModel,
        received viewModel: ItemListViewModel,
        isEditing: Bool
    ) {
        if let descriptionSection = viewModel.sections.first(where: { section in
            section.title == self.contentContainer.sectionTitles.descriptionLabelText
        }) {
            XCTAssertEqual(
                1,
                descriptionSection.items.count
            )

            XCTAssertEqual(
                0,
                descriptionSection.items[safe: 0]?.context.count
            )

            switch descriptionSection.items[0].type {
            case .text(let text):
                XCTAssertEqual(
                    displayModel.description,
                    text
                )
            case .editSingleline,
                    .editMultiline,
                    .attributedText,
                    .message:
                XCTFail("Expected text item. Found: editable")
            }

        } else if !isEditing && displayModel.description.isEmpty {
            // SUCCESS - No description section
        } else {
            XCTFail("Could not find valid title for description section")
        }
    }

    func assertMatchingEditableViewModel(
        expectedFor displayModel: IngredientDetailsDisplayModel,
        received viewModel: ItemListViewModel
    ) {
        XCTAssertEqual(
            3,
            viewModel.sections.count
        )

        assertValidEditableNameSection(
            expectedFor: displayModel,
            received: viewModel
        )

        assertValidEditableDescriptionSection(
            expectedFor: displayModel,
            received: viewModel
        )

        assertValidTagsSection(
            expectedFor: displayModel,
            received: viewModel,
            isEditing: true
        )
    }

    func assertValidEditableNameSection(
        expectedFor displayModel: IngredientDetailsDisplayModel,
        received viewModel: ItemListViewModel
    ) {
        let editingTitle = "\(self.contentContainer.sectionTitles.nameLabelText) \(self.contentContainer.sectionTitles.requiredSectionSuffix)"
        if let nameSection = viewModel.sections.first(where: { section in
            section.title == editingTitle
        }) {
            XCTAssertEqual(
                1,
                nameSection.items.count
            )

            XCTAssertEqual(
                0,
                nameSection.items[safe: 0]?.context.count
            )

            switch nameSection.items[0].type {
            case .editSingleline(let text, let purpose):
                XCTAssertEqual(
                    text,
                    displayModel.name.data
                )

                XCTAssertEqual(
                    purpose,
                    self.contentContainer.sectionTitles.nameLabelText
                )

            default:
                XCTFail("Expected text items, found editable items")
            }

        } else {
            XCTFail("Could not find valid title for name section")
        }
    }

    func assertValidEditableDescriptionSection(
        expectedFor displayModel: IngredientDetailsDisplayModel,
        received viewModel: ItemListViewModel
    ) {
        if let descriptionSection = viewModel.sections.first(where: { section in
            section.title == self.contentContainer.sectionTitles.descriptionLabelText
        }) {
            XCTAssertEqual(
                1,
                descriptionSection.items.count
            )

            XCTAssertEqual(
                0,
                descriptionSection.items[safe: 0]?.context.count
            )

            switch descriptionSection.items[0].type {
            case .editMultiline(let text, let purpose):
                XCTAssertEqual(
                    displayModel.description,
                    text
                )

                XCTAssertEqual(
                    purpose,
                    self.contentContainer.sectionTitles.descriptionLabelText
                )
            default:
                XCTFail("Expected text item. Found: editable")
            }

        } else {
            XCTFail("Could not find valid title for description section")
        }
    }

    func assertValidTagsSection(
        expectedFor displayModel: IngredientDetailsDisplayModel,
        received viewModel: ItemListViewModel,
        isEditing: Bool
    ) {
        if let tagsSection = viewModel.sections.first(where: { section in
            section.title == self.contentContainer.sectionTitles.tagsLabelText
        }) {
            let editRowCount = isEditing ? 1 : 0
            XCTAssertEqual(
                displayModel.tagNames.count + editRowCount, // Add tag item when editable
                tagsSection.items.count
            )

            let tagsTextItems = tagsSection
                .items
                .dropFirst(editRowCount) // Drop Add Tag row
                .compactMap {
                    switch $0.type {
                    case .text(let text):
                        return text
                    default:
                        XCTFail("Expected static text item. Found editable")
                        return nil
                    }
                }

            XCTAssert(
                tagsSection
                    .items
                    .dropFirst(editRowCount)
                    .allSatisfy { item in
                        item.context.count == 0
                    }
            )

            for (expectedTag, receivedTagText)
                    in zip(displayModel.tagNames.sorted(),
                           tagsTextItems.sorted()) {
                XCTAssertEqual(
                    expectedTag,
                    receivedTagText
                )
            }
        } else if !isEditing && displayModel.tagNames.isEmpty {
            // SUCCESS - No tag section
        } else {
            XCTFail("Could not find valid title for name section")
        }
    }

    // MARK: Display Tests
    func testReadPresentation_WhenGivenDisplayModel_DoesSendViewModel() throws {
        let expectation = XCTestExpectation()
        self.mockItemListViewModelSink.sendViewModelClosure = { receivedViewModel in
            self.assertMatchingViewModel(
                expectedFor: self.testDisplayModel,
                isEditing: false,
                received: receivedViewModel
            )
            expectation.fulfill()
        }

        self.presentation.send(ingredientDisplayModel: self.testDisplayModel)
        wait(for: [expectation], timeout: 0.0)
    }

    func testReadPresentation_WhenGivenNoDesc_DoesSendVMNoDesc() {
        let noDescDisplayModel = IngredientDetailsDisplayModel(
            name: .valid("NoDesc Name"),
            description: "",
            tagNames: ["NoDesc Tag"]
        )

        let expectation = XCTestExpectation()
        self.mockItemListViewModelSink.sendViewModelClosure = { receivedViewModel in
            self.assertMatchingViewModel(
                expectedFor: noDescDisplayModel,
                isEditing: false,
                received: receivedViewModel
            )
            expectation.fulfill()
        }

        self.presentation.send(ingredientDisplayModel: noDescDisplayModel)
        wait(for: [expectation], timeout: 0.0)
    }

    func testReadPresentation_WhenGivenNoTags_DoesSendViewModelNoTags() throws {
        let noTagsDisplayModel = IngredientDetailsDisplayModel(
            name: .valid("NoTag Name"),
            description: "NoTag description",
            tagNames: []
        )

        let expectation = XCTestExpectation()
        self.mockItemListViewModelSink.sendViewModelClosure = { receivedViewModel in
            self.assertMatchingViewModel(
                expectedFor: noTagsDisplayModel,
                isEditing: false,
                received: receivedViewModel
            )
            expectation.fulfill()
        }

        self.presentation.send(ingredientDisplayModel: noTagsDisplayModel)
        wait(for: [expectation], timeout: 0.0)
    }

    func testReadPresentation_WhenOnlyName_DoesSendVSOnlyName() throws {
        let onlyNameDisplayModel = IngredientDetailsDisplayModel(
            name: .valid("NoTag Name"),
            description: "",
            tagNames: []
        )

        let expectation = XCTestExpectation()
        self.mockItemListViewModelSink.sendViewModelClosure = { receivedViewModel in
            self.assertMatchingViewModel(
                expectedFor: onlyNameDisplayModel,
                isEditing: false,
                received: receivedViewModel
            )
            expectation.fulfill()
        }

        self.presentation.send(ingredientDisplayModel: onlyNameDisplayModel)
        wait(for: [expectation], timeout: 0.0)
    }

    func testReadPresentation_WhenGivenNewSink_DoesSendViewModel() throws {
        self.presentation.send(ingredientDisplayModel: self.testDisplayModel)

        let newSink = ItemListViewModelSinkMock()
        let expectation = XCTestExpectation()
        newSink.sendViewModelClosure = { receivedViewModel in
            self.assertMatchingViewModel(
                expectedFor: self.testDisplayModel,
                isEditing: false,
                received: receivedViewModel
            )

            expectation.fulfill()
        }

        self.presentation.viewModelSink = newSink
        wait(for: [expectation], timeout: 0.0)
    }

    func testReadPresentation_WhenGivenNewNavBarSink_DoesSendViewModel() throws {
        self.presentation.send(
            editModeDisplayModel: .init(
                isEditing: true,
                canSave: true
            )
        )

        let newSink = NavBarViewModelSinkMock()
        let expectation = XCTestExpectation()
        newSink.sendNavBarViewModelClosure = { receivedViewModel in
            XCTAssertEqual(
                self.contentContainer.headerTitle,
                receivedViewModel.title
            )
            expectation.fulfill()
        }

        self.presentation.editViewModelSink = newSink
        wait(for: [expectation], timeout: 0.0)
    }

    func testEditPresentation_WhenGivenDisplayModel_DoesSendViewModel() throws {
        let expectation = XCTestExpectation()
        self.mockItemListViewModelSink.sendViewModelClosure = { receivedViewModel in
            self.assertMatchingViewModel(
                expectedFor: self.testDisplayModel,
                isEditing: true,
                received: receivedViewModel
            )
            expectation.fulfill()
        }

        self.presentation.send(
            editModeDisplayModel: .init(
                isEditing: true,
                canSave: false
            )
        )

        self.presentation.send(ingredientDisplayModel: self.testDisplayModel)
        wait(for: [expectation], timeout: 0.0)
    }

    func testEditPresentation_WhenGivenOnlyNameDisplayModel_DoesSendViewModel() throws {
        let onlyNameDisplayModel = IngredientDetailsDisplayModel(
            name: .valid("Only Name"),
            description: "",
            tagNames: []
        )

        let expectation = XCTestExpectation()
        self.mockItemListViewModelSink.sendViewModelClosure = { receivedViewModel in
            self.assertMatchingViewModel(
                expectedFor: onlyNameDisplayModel,
                isEditing: true,
                received: receivedViewModel
            )
            expectation.fulfill()
        }

        self.presentation.send(
            editModeDisplayModel: .init(
                isEditing: true,
                canSave: false
            )
        )

        self.presentation.send(ingredientDisplayModel: onlyNameDisplayModel)
        wait(for: [expectation], timeout: 0.0)
    }

    func testEditPresentation_WhenGivenNewSink_DoesSendViewModel() throws {
        self.presentation.send(ingredientDisplayModel: self.testDisplayModel)

        let newSink = ItemListViewModelSinkMock()
        let expectation = XCTestExpectation()
        newSink.sendViewModelClosure = { receivedViewModel in
            self.assertMatchingViewModel(
                expectedFor: self.testDisplayModel,
                isEditing: true,
                received: receivedViewModel
            )

            expectation.fulfill()
        }

        self.presentation.send(
            editModeDisplayModel: .init(
                isEditing: true,
                canSave: false
            )
        )
        self.presentation.viewModelSink = newSink
        wait(for: [expectation], timeout: 0.0)
    }

    func testPresentation_WhenChangesToEdit_DoesSendViewModel() throws {
        self.presentation.send(ingredientDisplayModel: self.testDisplayModel)

        let newSink = ItemListViewModelSinkMock()

        self.presentation.viewModelSink = newSink

        let expectation = XCTestExpectation()
        newSink.sendViewModelClosure = { receivedViewModel in
            self.assertMatchingViewModel(
                expectedFor: self.testDisplayModel,
                isEditing: true,
                received: receivedViewModel
            )

            expectation.fulfill()
        }
        self.presentation.send(
            editModeDisplayModel: .init(
                isEditing: true,
                canSave: false
            )
        )

        wait(for: [expectation], timeout: 0.0)
    }

    func testPresentation_WhenChangesToRead_DoesSendViewModel() throws {
        self.presentation.send(ingredientDisplayModel: self.testDisplayModel)
        self.presentation.send(
            editModeDisplayModel: .init(
                isEditing: true,
                canSave: false
            )
        )

        let newSink = ItemListViewModelSinkMock()

        self.presentation.viewModelSink = newSink

        let expectation = XCTestExpectation()
        newSink.sendViewModelClosure = { receivedViewModel in
            self.assertMatchingViewModel(
                expectedFor: self.testDisplayModel,
                isEditing: false,
                received: receivedViewModel
            )

            expectation.fulfill()
        }
        self.presentation.send(
            editModeDisplayModel: .init(
                isEditing: false,
                canSave: false
            )
        )

        wait(for: [expectation], timeout: 0.0)
    }

    func testPresentation_WhenGivenNewSink_DoesNotSendToOldSink() throws {
        let newSink = ItemListViewModelSinkMock()
        let oldExpectation = XCTestExpectation()
        oldExpectation.isInverted = true
        self.mockItemListViewModelSink.sendViewModelClosure = { _ in
            oldExpectation.fulfill()
        }

        self.presentation.viewModelSink = newSink
        self.presentation.send(ingredientDisplayModel: self.testDisplayModel)

        wait(for: [oldExpectation], timeout: 0.0)
    }

    // MARK: Event to Action Tests
    func testPresentation_WhenSentSelectionEvent_DoesNotSendAction() throws {
        let expectation = XCTestExpectation()
        expectation.isInverted = true
        self.mockActionSink.sendIngredientActionClosure = { action in
            expectation.fulfill()
        }

        self.presentation.send(
            event: .select(
                itemAt: IndexPath(
                    item: 1,
                    section: 1
                )
            )
        )

        wait(for: [expectation], timeout: 0.0)
    }

    func testPresentation_WhenSentNameEditEvent_SendsNameEditAction() throws {
        let expectation = XCTestExpectation()
        let expectedName = "New name to test"
        let nameIndexPath = IndexPath(
            item: 0,
            section: 0
        )

        self.mockActionSink.sendIngredientActionClosure = { action in
            switch action {
            case .edit(.name(to: let receivedName)):
                XCTAssertEqual(
                    expectedName,
                    receivedName
                )
                expectation.fulfill()
            default:
                XCTFail("Expected setName action. Received \(action)")
            }
        }

        self.presentation.send(
            editModeDisplayModel: .init(
                isEditing: true,
                canSave: true
            )
        )
        self.presentation.send(
            event: .edit(
                string: expectedName,
                forItemAt: nameIndexPath
            )
        )
        wait(for: [expectation], timeout: 0.0)
    }

    func testPresentation_WhenSentDescEditEvent_SendsDescEditAction() throws {
        let expectation = XCTestExpectation()
        let expectedDescription = "New desc to test"
        let descriptionIndexPath = IndexPath(
            item: 0,
            section: 1
        )

        self.mockActionSink.sendIngredientActionClosure = { action in
            switch action {
            case .edit(.description(to: let receivedDescription)):
                XCTAssertEqual(
                    expectedDescription,
                    receivedDescription
                )
                expectation.fulfill()
            default:
                XCTFail("Expected setName action. Received \(action)")
            }
        }

        self.presentation.send(
            event: .edit(
                string: expectedDescription,
                forItemAt: descriptionIndexPath
            )
        )
    }

    func testPresentation_WhenSentInvalidEditIndexPath_SendsNothing() throws {
        let expectation = XCTestExpectation()
        expectation.isInverted = true

        self.mockActionSink.sendIngredientActionClosure = { _ in
            expectation.fulfill()
        }

        self.presentation.send(
            event: .edit(
                string: "Placeholder",
                forItemAt: IndexPath(
                    item: 0,
                    section: 102
                )
            )
        )

        self.presentation.send(
            event: .edit(
                string: "Placeholder",
                forItemAt: IndexPath(
                    item: 100,
                    section: 0
                )
            )
        )

        self.presentation.send(
            event: .edit(
                string: "Placeholder",
                forItemAt: IndexPath(
                    item: 100,
                    section: 5203
                )
            )
        )

        wait(for: [expectation], timeout: 0.0)
    }

    // MARK: Alert Tests
    func testPresentation_WhenSentAlert_DoesSendViewModelToNavBarManager() throws {
        let testingAlert = EditModeAction.DoneType.cancel

        let expectation = XCTestExpectation()
        self.mockNavBarViewModelSink.sendAlertViewModelClosure = { viewModel in
            expectation.fulfill()
        }

        self.presentation.send(
            alertDisplayModel: testingAlert,
            didConfirm: { _ in }
        )

        wait(for: [expectation], timeout: 0.0)
    }

    func testPresentation_WhenEditModeChanges_DoesDisplayNavTitle() throws {
        self.presentation.send(ingredientDisplayModel: self.testDisplayModel)
        let startEditExpectation = XCTestExpectation(description: "Fulfill when edit starting")
        self.mockNavBarViewModelSink.sendNavBarViewModelClosure = { viewModel in
            XCTAssertEqual(
                self.contentContainer.headerTitle,
                viewModel.title
            )
            startEditExpectation.fulfill()
        }

        self.presentation.send(
            editModeDisplayModel: .init(
                isEditing: true,
                canSave: true
            )
        )

        let newTitle = "NEWTITLE"
        self.presentation.send(
            event: .edit(
                string: newTitle,
                forItemAt: .init(item: 0, section: 0)
            )
        )
        self.presentation.send(
            ingredientDisplayModel: .init(
                name: .valid(newTitle),
                description: self.testDisplayModel.description,
                tagNames: self.testDisplayModel.tagNames
            )
        )

        let editedTitleExpectation = XCTestExpectation(description: "Fulfill when stop editing with new title")
        self.mockNavBarViewModelSink.sendNavBarViewModelClosure = { viewModel in
            XCTAssertEqual(
                newTitle,
                viewModel.title
            )
            editedTitleExpectation.fulfill()
        }
        self.presentation.send(
            editModeDisplayModel: .init(
                isEditing: false,
                canSave: true
            )
        )

        self.mockNavBarViewModelSink.sendNavBarViewModelClosure = nil


        self.presentation.send(
            editModeDisplayModel: .init(
                isEditing: true,
                canSave: true
            )
        )
        self.presentation.send(
            event: .edit(
                string: "TITLE TO CANCEL",
                forItemAt: .init(item: 0, section: 0)
            )
        )
        self.presentation.send(
            editModeDisplayModel: .init(
                isEditing: false,
                canSave: true
            )
        )

        let cancelledTitleExpectation = XCTestExpectation(description: "Fulfill when returning to previous model")
        self.mockNavBarViewModelSink.sendNavBarViewModelClosure = { viewModel in
            XCTAssertEqual(
                viewModel.title,
                self.testDisplayModel.name.data
            )
            cancelledTitleExpectation.fulfill()
        }
        self.presentation.send(
            ingredientDisplayModel: self.testDisplayModel
        )

        wait(for: [
            startEditExpectation,
            editedTitleExpectation,
            cancelledTitleExpectation
        ], timeout: 0.0)
    }

    func testPresentation_WhenSentNavBarCancelTap_DoesPassActionToApp() throws {
        self.presentation.send(
            editModeDisplayModel: .init(
                isEditing: true,
                canSave: true
            )
        )

        let expectation = XCTestExpectation()
        self.mockActionSink.sendEditModeActionClosure = { action in
            switch action {
            case .finishEditing(.cancel):
                expectation.fulfill()
            case .startEditing,
                    .finishEditing(_):
                XCTFail("Expected a cancel finishEditing message")
            }
        }

        self.presentation.send(
            navBarEvent: .tap(
                .left,
                index: 0
            )
        )
        wait(for: [expectation], timeout: 0.0)
    }

    func testPresentation_WhenSentNavBarSaveTap_DoesPassActionToApp() throws {
        self.presentation.send(
            editModeDisplayModel: .init(
                isEditing: true,
                canSave: true
            )
        )

        let expectation = XCTestExpectation()
        self.mockActionSink.sendEditModeActionClosure = { action in
            switch action {
            case .finishEditing(.save):
                expectation.fulfill()
            case .startEditing,
                    .finishEditing(_):
                XCTFail("Expected a save finishEditing message")
            }
        }

        self.presentation.send(
            navBarEvent: .tap(
                .right,
                index: 0
            )
        )
        wait(for: [expectation], timeout: 0.0)
    }

    func testPresentation_WhenSentNavBarEditTap_DoesPassActionToApp() throws {
        let expectation = XCTestExpectation()
        self.mockActionSink.sendEditModeActionClosure = { action in
            switch action {
            case .startEditing:
                expectation.fulfill()
            case .finishEditing(_):
                XCTFail("Expected a startEditing message")
            }
        }

        self.presentation.send(
            navBarEvent: .tap(
                .right,
                index: 0
            )
        )
        wait(for: [expectation], timeout: 0.0)
    }

    func testPresentation_WhenSentInvalidTap_DoesNotSendAction() throws {
        let expectation = XCTestExpectation()
        expectation.isInverted = true
        self.mockActionSink.sendEditModeActionClosure = { action in
            expectation.fulfill()
        }

        self.presentation.send(
            navBarEvent: .tap(
                .left,
                index: 50
            )
        )
        self.presentation.send(
            navBarEvent: .tap(
                .right,
                index: 50
            )
        )

        wait(for: [expectation], timeout: 0.0)
    }

    func testPresentation_WhenSentAlert_DoesPassAlongClosure() throws {
        self.mockNavBarViewModelSink.sendAlertViewModelClosure = { viewModel in
            viewModel.actions[1].callback()
        }

        let expectation = XCTestExpectation()
        expectation.expectedFulfillmentCount = 2
        var mockCallback: (Bool) -> Void = { value in
            XCTAssert(value)
            expectation.fulfill()
        }

        self.presentation.send(
            alertDisplayModel: .save,
            didConfirm: mockCallback
        )

        self.mockNavBarViewModelSink.sendAlertViewModelClosure = { viewModel in
            viewModel.actions[0].callback()
        }
        mockCallback = { value in
            XCTAssertFalse(value)
            expectation.fulfill()
        }
        self.presentation.send(
            alertDisplayModel: .save,
            didConfirm: mockCallback
        )
        
        wait(for: [expectation], timeout: 0.0)
    }

    func testPresentation_WhenAddTagTapped_DoesSendAddTag() throws {
        let expectation = XCTestExpectation()
        self.mockActionSink.sendIngredientActionClosure = { action in
            switch action {
            case .action(.addTag):
                expectation.fulfill()
            default:
                XCTFail("Expected addTag action, Received: \(action)")
                return
            }
        }

        self.presentation.send(
            event: .select(
                itemAt: .init(
                    row: 0,
                    section: 2
                )
            )
        )

        wait(for: [expectation], timeout: 0.0)
    }

    func testPresentation_WhenEditingGivenInvalidName_DoesSendErrorFooter() throws {
        self.presentation.send(editModeDisplayModel: .init(isEditing: true, canSave: false))
        let testInvalidityReason = "Test invalidity reason"
        let testInvaliditySuggestion = "Test invalidity suggestion"

        let expectation = XCTestExpectation()
        self.mockItemListViewModelSink.sendViewModelClosure = { viewModel in
            XCTAssertEqual(
                viewModel.sections[0].footerErrorMessage?.message,
                testInvalidityReason
            )
            XCTAssertEqual(
                viewModel.sections[0].footerErrorMessage?.suggestion,
                testInvaliditySuggestion
            )
            expectation.fulfill()
        }

        self.presentation
            .send(ingredientDisplayModel: .init(
                name: .invalid("", .init(
                    error: testInvalidityReason,
                    suggestion: testInvaliditySuggestion
                )),
                description: "",
                tagNames: []
            ))
        wait(for: [expectation], timeout: 0.0)
    }

    func testPresentation_WhenNotEditingGivenInvalidName_DoesNotSendErrorFooter() throws {
        let testInvalidityReason = "Test invalidity reason"

        let expectation = XCTestExpectation()
        self.mockItemListViewModelSink.sendViewModelClosure = { viewModel in
            XCTAssertNil(viewModel.sections[0].footerErrorMessage)
            expectation.fulfill()
        }

        self.presentation
            .send(ingredientDisplayModel: .init(
                name: .invalid("", .init(error: testInvalidityReason)),
                description: "",
                tagNames: []
            ))
        wait(for: [expectation], timeout: 0.0)
    }
}
