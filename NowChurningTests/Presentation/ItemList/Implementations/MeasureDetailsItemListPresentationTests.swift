//
//  MeasureDetailsItemListPresentationTests.swift
//  NowChurningTests
//
//  Created by Austin Dumm on 5/14/23.
//

import XCTest
@testable import NowChurning

final class MeasureDetailsItemListPresentationTests: XCTestCase {

    var presentation: MeasureDetailsItemListPresentation!
    var mockItemListViewModelSink: ItemListViewModelSinkMock!
    var mockNavBarViewModelSink: NavBarViewModelSinkMock!
    var mockActionSink: MeasureDetailsActionSinkMock!

    let contentContainer = TestAppContent.testMeasureDetailsContent

    let testDisplayModel = MeasureDetailsDisplayModel(
        name: .valid("Test Name"),
        description: "This is the test description",
        tagNames: ["Tag", "Name"],
        measurementDescription: "This is the measurement description"
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
        expectedFor displayModel: MeasureDetailsDisplayModel,
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
        expectedFor displayModel: MeasureDetailsDisplayModel,
        received viewModel: ItemListViewModel
    ) {
        let shouldHaveSection = [
            true, // name section
            !displayModel.description.isEmpty,
            displayModel.tagNames.count != 0,
            displayModel.measurementDescription != nil
        ]
        let sectionCount = shouldHaveSection.filter { $0 }.count

        XCTAssertEqual(
            viewModel.sections.count,
            sectionCount
        )

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

        assertValidViewingMeasureSection(
            received: viewModel,
            for: displayModel
        )
    }

    func assertValidReadOnlyNameSection(
        expectedFor displayModel: MeasureDetailsDisplayModel,
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
        expectedFor displayModel: MeasureDetailsDisplayModel,
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
            case .editMultiline,
                    .editSingleline,
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
        expectedFor displayModel: MeasureDetailsDisplayModel,
        received viewModel: ItemListViewModel
    ) {
        XCTAssertEqual(
            4,
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

        assertValidEditingMeasureSection(
            received: viewModel,
            for: displayModel
        )
    }

    func assertValidEditableNameSection(
        expectedFor displayModel: MeasureDetailsDisplayModel,
        received viewModel: ItemListViewModel
    ) {
        if let nameSection = viewModel.sections.first(where: { section in
            section.title == "\(self.contentContainer.sectionTitles.nameLabelText) \(self.contentContainer.sectionTitles.requiredSectionSuffix)"
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

            case .editMultiline, .text, .attributedText, .message:
                XCTFail("Expected text items, found editable items")
            }

        } else {
            XCTFail("Could not find valid title for name section")
        }
    }

    func assertValidEditableDescriptionSection(
        expectedFor displayModel: MeasureDetailsDisplayModel,
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
            case .text, .editSingleline, .attributedText, .message:
                XCTFail("Expected text item. Found: editable")
            }

        } else {
            XCTFail("Could not find valid title for description section")
        }
    }

    func assertValidTagsSection(
        expectedFor displayModel: MeasureDetailsDisplayModel,
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
                    case .editMultiline,
                            .editSingleline,
                            .attributedText,
                            .message:
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

    func assertValidMeasureSection(
        received viewModel: ItemListViewModel,
        for displayModel: MeasureDetailsDisplayModel,
        isEditing: Bool
    ) {
        if isEditing {
            assertValidEditingMeasureSection(
                received: viewModel,
                for: displayModel
            )
        } else {
            assertValidViewingMeasureSection(
                received: viewModel,
                for: displayModel
            )
        }
    }

    func assertValidViewingMeasureSection(
        received viewModel: ItemListViewModel,
        for displayModel: MeasureDetailsDisplayModel
    ) {
        guard let section = viewModel.sections.first(
            where: { section in section.title == self.contentContainer.sectionTitles.measurementSectionText }
        ) else {
            if displayModel.measurementDescription != nil {
                XCTFail("Could not find section of header: \(self.contentContainer.sectionTitles.measurementSectionText)")
            }

            return
        }

        XCTAssertEqual(
            section.title,
            self.contentContainer.sectionTitles.measurementSectionText
        )

        XCTAssertEqual(
            section.items.count,
            1
        )

        let item = section.items[0]
        XCTAssertEqual(
            item.context.count,
            0
        )

        XCTAssertEqual(
            item.indentation,
            0
        )

        switch item.type {
        case .text(displayModel.measurementDescription):
            break
        default:
            XCTFail("Expected item type: text(\(displayModel.measurementDescription.debugDescription). Found: \(item.type)")
        }
    }

    func assertValidEditingMeasureSection(
        received viewModel: ItemListViewModel,
        for displayModel: MeasureDetailsDisplayModel
    ) {
        guard let section = viewModel.sections.first(
            where: { section in section.title == "\(self.contentContainer.sectionTitles.measurementSectionText) \(self.contentContainer.sectionTitles.optionalSectionSuffix)" }
        ) else {
            XCTFail("Could not find section of header: \(self.contentContainer.sectionTitles.measurementSectionText)")
            return
        }

        XCTAssertEqual(
            section.items.count,
            1
        )

        let item = section.items[0]
        XCTAssertEqual(
            item.context.count,
            1
        )
        switch item.context[safe: 0] {
        case .navigate:
            break
        default:
            XCTFail("Expected navigate context. Found: \(item.context[safe: 0].debugDescription)")
        }

        XCTAssertEqual(
            item.indentation,
            0
        )

        switch item.type {
        case .text(displayModel.measurementDescription):
            break
        default:
            XCTFail("Expected item type: text(\(displayModel.measurementDescription.debugDescription). Found: \(item.type)")
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

        self.presentation.send(measureDisplayModel: self.testDisplayModel)
        wait(for: [expectation], timeout: 0.0)
    }

    func testReadPresentation_WhenGivenNoDesc_DoesSendVMNoDesc() {
        let noDescDisplayModel = MeasureDetailsDisplayModel(
            name: .valid("NoDesc Name"),
            description: "",
            tagNames: ["NoDesc Tag"],
        measurementDescription: "NYI"
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

        self.presentation.send(measureDisplayModel: noDescDisplayModel)
        wait(for: [expectation], timeout: 0.0)
    }

    func testReadPresentation_WhenGivenNoTags_DoesSendViewModelNoTags() throws {
        let noTagsDisplayModel = MeasureDetailsDisplayModel(
            name: .valid("NoTag Name"),
            description: "NoTag description",
            tagNames: [],
            measurementDescription: "NYI"
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

        self.presentation.send(measureDisplayModel: noTagsDisplayModel)
        wait(for: [expectation], timeout: 0.0)
    }

    func testReadPresentation_WhenOnlyName_DoesSendVSOnlyName() throws {
        let onlyNameDisplayModel = MeasureDetailsDisplayModel(
            name: .valid("NoTag Name"),
            description: "",
            tagNames: [],
            measurementDescription: "NYI"
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

        self.presentation.send(measureDisplayModel: onlyNameDisplayModel)
        wait(for: [expectation], timeout: 0.0)
    }

    func testReadPresentation_WhenGivenNewSink_DoesSendViewModel() throws {
        self.presentation.send(measureDisplayModel: self.testDisplayModel)

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
                self.contentContainer.ingredientDetailsContent.headerTitle,
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

        self.presentation.send(measureDisplayModel: self.testDisplayModel)
        wait(for: [expectation], timeout: 0.0)
    }

    func testEditPresentation_WhenGivenOnlyNameDisplayModel_DoesSendViewModel() throws {
        let onlyNameDisplayModel = MeasureDetailsDisplayModel(
            name: .valid("Only Name"),
            description: "",
            tagNames: [],
            measurementDescription: "NYI"
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

        self.presentation.send(measureDisplayModel: onlyNameDisplayModel)
        wait(for: [expectation], timeout: 0.0)
    }

    func testEditPresentation_WhenGivenNewSink_DoesSendViewModel() throws {
        self.presentation.send(measureDisplayModel: self.testDisplayModel)

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
        self.presentation.send(measureDisplayModel: self.testDisplayModel)

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
        self.presentation.send(measureDisplayModel: self.testDisplayModel)
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
        self.presentation.send(measureDisplayModel: self.testDisplayModel)

        wait(for: [oldExpectation], timeout: 0.0)
    }

    // MARK: Event to Action Tests
    func testPresentation_WhenSentSelectionEvent_DoesNotSendAction() throws {
        let expectation = XCTestExpectation()
        expectation.isInverted = true
        self.mockActionSink.sendMeasureActionClosure = { action in
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

        self.mockActionSink.sendMeasureActionClosure = { action in
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

        self.mockActionSink.sendMeasureActionClosure = { action in
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

    func testPresentation_WhenSentInvalidEditIndexPath_SendsDescEditAction() throws {
        let expectation = XCTestExpectation()
        expectation.isInverted = true

        self.mockActionSink.sendMeasureActionClosure = { _ in
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
        self.presentation.send(measureDisplayModel: self.testDisplayModel)
        let startEditExpectation = XCTestExpectation(description: "Fulfill when edit starting")
        self.mockNavBarViewModelSink.sendNavBarViewModelClosure = { viewModel in
            XCTAssertEqual(
                self.contentContainer.ingredientDetailsContent.headerTitle,
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
            measureDisplayModel: .init(
                name: .valid(newTitle),
                description: self.testDisplayModel.description,
                tagNames: self.testDisplayModel.tagNames,
                measurementDescription: "NYI"
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
                self.testDisplayModel.name.data,
                viewModel.title
            )
            cancelledTitleExpectation.fulfill()
        }
        self.presentation.send(
            measureDisplayModel: self.testDisplayModel
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
        self.mockActionSink.sendMeasureActionClosure = { action in
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

    func testPresentation_WhenTapFooterWithFooterError_SendsAction() throws {
        self.presentation
            .send(editModeDisplayModel: .init(isEditing: true, canSave: true))
        self.presentation
            .send(viewModel: .init(
                sections: [
                    .init(
                        title: "Name",
                        items: [
                            .init(type: .editMultiline("Text", purpose: "text"), context: [])
                        ],
                        footerErrorMessage: .init(message: "Test Error")
                    )
                ],
                isEditing: true
            ))

        let expectation = XCTestExpectation()
        self.mockActionSink.sendMeasureActionClosure = { action in
            guard case .action(.nameFooterTap) = action else {
                XCTFail("Expected 'changeEditToMatchingName' action. Found: \(action)")
                return
            }

            expectation.fulfill()
        }

        self.presentation.send(
            event: .selectFooter(forSection: 0)
        )
        wait(for: [expectation], timeout: 0.0)
    }
}
