//
//  IngredientPartialItemListPresentation.swift
//  NowChurning
//
//  Created by Austin Dumm on 12/17/22.
//

import Foundation

/// Presentation for the parts of Ingredient presentation displayed for both
/// Measure Details and sole Ingredient Details. Displays edit mode actions
/// as well as Name, Description, and Tags in Item list. To be wrapped and
/// extended for display of Measures (with measurement amount section),
/// full Ingredient display (with 'Add to Inventory' support), or any other
/// extended use.
class IngredientPartialItemListPresentation {
    struct Content {
        let sectionTitles: SectionTitles
        let headerTitle: String
        let editDescription: String
        let alertContainer: AlertContent
    }

    struct SectionTitles {
        let nameLabelText: String
        let descriptionLabelText: String
        let tagsLabelText: String
        let editTagsLabelText: String

        let requiredSectionSuffix: String
    }

    private static let tagsSectionIndex = 2

    // MARK: View Dependencies
    weak var viewModelSink: ItemListViewModelSink? {
        didSet {
            self.onSetViewModelSink()
        }
    }

    weak var editViewModelSink: NavBarViewModelSink? {
        didSet {
            self.onSetEditViewModelSink()
        }
    }

    // MARK: Local Models
    private let actionSink: IngredientDetailsActionSink?
    private let shownAsModal: Bool
    private let contentContainer: Content
    private var displayModel: IngredientDetailsDisplayModel?

    private var editModeDisplayModel: EditModeDisplayModel?

    private var isEditing: Bool {
        self.editModeDisplayModel?.isEditing ?? false
    }

    init(
        actionSink: IngredientDetailsActionSink?,
        shownAsModal: Bool = false,
        contentContainer: Content
    ) {
        self.actionSink = actionSink
        self.shownAsModal = shownAsModal
        self.contentContainer = contentContainer
    }

    // MARK: DidSet Event Handlers
    private func onSetViewModelSink() {
        self.sendViewModel()
    }

    private func onSetEditViewModelSink() {
        guard let editModeDisplayModel = self.editModeDisplayModel else {
            return
        }

        let viewModel = Self.editViewModel(
            fromDisplayModel: editModeDisplayModel,
            forItemName: self.displayModel?.name.data ?? "",
            shownAsModal: self.shownAsModal,
            headerTitle: self.contentContainer.headerTitle,
            editButtonDescription: self.contentContainer.editDescription
        )
        self.editViewModelSink?
            .send(
                navBarViewModel: viewModel
            )
    }

    // MARK: Senders
    private func sendViewModel() {
        guard
            let sink = self.viewModelSink,
            let displayModel = self.displayModel
        else {
            return
        }

        let viewModel = Self.viewModel(
            fromDisplayModel: displayModel,
            isEditing: self.editModeDisplayModel?.isEditing ?? false,
            contentContainer: self.contentContainer
        )
        sink.send(viewModel: viewModel)
    }
}

extension IngredientPartialItemListPresentation: IngredientDetailsDisplayModelSink {
    func send(
        ingredientDisplayModel: IngredientDetailsDisplayModel
    ) {
        self.displayModel = ingredientDisplayModel

        self.sendViewModel()
        self.sendNavBarViewModel()
    }
}

extension IngredientPartialItemListPresentation: ItemListEventSink {
    func send(event: ItemListEvent) {
        guard
            let action = Self.action(
                from: event,
                isEditMode: self.isEditing
            )
        else {
            return
        }

        self.actionSink?.send(ingredientAction: action)
    }

    private static func action(
        from event: ItemListEvent,
        isEditMode: Bool
    ) -> IngredientDetailsAction? {
        switch event {
        case .select(IndexPath(row: 0, section: self.tagsSectionIndex)):
            return .action(.addTag)
        case .selectFooter(forSection: 0):
            return .action(.nameFooterTap)
        case .select,
                .selectFooter,
                .delete,
                .move,
                .openInfo,
                .resolveAlert:
            return nil
        case .edit(string: let newString,
                   forItemAt: let indexPath):
            switch (indexPath.section, indexPath.row) {
            case (0, 0): // Name section
                return .edit(.name(newString))
            case (1, 0): // Description section
                return .edit(.description(newString))
            default:
                return nil
            }
        }
    }
}

extension IngredientPartialItemListPresentation: EditModeDisplayModelSink {
    func send(
        editModeDisplayModel: EditModeDisplayModel
    ) {
        self.editModeDisplayModel = editModeDisplayModel
        self.sendNavBarViewModel()
        self.sendViewModel()
    }

    func send(
        alertDisplayModel: EditModeAction.DoneType,
        didConfirm: @escaping (Bool) -> Void
    ) {
        let alertContainer = self.contentContainer.alertContainer

        self.editViewModelSink?
            .send(
                alertViewModel: .init(
                    title: nil,
                    message: alertContainer.descriptionText,
                    side: Self.getButtonSide(forDoneType: alertDisplayModel),
                    buttonIndex: 0,
                    actions: [
                        .init(
                            title: alertContainer.cancelText,
                            type: .cancel,
                            callback: { didConfirm(false) }
                        ),
                        .init(
                            title: alertContainer.confirmText,
                            type: .confirm(isDestructive: true),
                            callback: { didConfirm(true) }
                        ),
                    ]
                )
            )
    }

    private static func getButtonSide(
        forDoneType doneType: EditModeAction.DoneType
    ) -> NavBarViewModel.Side {
        switch doneType {
        case .save:
            return .right
        case .cancel:
            return .left
        }
    }

    private func sendNavBarViewModel() {
        guard
            let editModeDisplayModel = self.editModeDisplayModel
        else {
            return
        }

        self.editViewModelSink?.send(
            navBarViewModel: Self.editViewModel(
                fromDisplayModel: editModeDisplayModel,
                forItemName: self.displayModel?.name.data ?? "",
                shownAsModal: self.shownAsModal,
                headerTitle: self.contentContainer.headerTitle,
                editButtonDescription: self.contentContainer.editDescription
            )
        )
    }
}

extension IngredientPartialItemListPresentation: NavBarEventSink {
    func send(navBarEvent: NavBarEvent) {
        switch navBarEvent {
        case .tap(.left, index: 0) where self.isEditing:
            self.handleCancel()
        case .tap(.left, index: 0) where !self.isEditing && self.shownAsModal:
            self.handleExit()
        case .tap(.right, index: 0) where self.isEditing:
            self.handleSave()
        case .tap(.right, index: 0) where !self.isEditing:
            self.handleEdit()
        default:
            return
        }
    }

    private func handleCancel() {
        self.actionSink?
            .send(
                editModeAction: .finishEditing(.cancel)
            )
    }

    private func handleExit() {
        self.actionSink?
            .send(ingredientAction: .action(.exit))
    }

    private func handleSave() {
        self.actionSink?
            .send(
                editModeAction: .finishEditing(.save)
            )
    }

    private func handleEdit() {
        self.actionSink?
            .send(
                editModeAction: .startEditing
            )
    }
}
