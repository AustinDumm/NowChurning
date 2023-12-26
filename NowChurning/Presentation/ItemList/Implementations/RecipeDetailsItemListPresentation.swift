//
//  RecipeDetailsItemListPresentation.swift
//  NowChurning
//
//  Created by Austin Dumm on 3/4/23.
//

import Foundation

class RecipeDetailsItemListPresentation {
    struct Content {
        let sectionTitles: SectionTitles
        let editingHeaderTitle: String
        let addStepCellTitle: String
        let unstockedMessage: String
        let unstockedResolution: String
        let alertContent: AlertContent
    }

    struct SectionTitles {
        let nameLabelText: String
        let descriptionLabelText: String
        let recipeLabelText: String

        let requiredSectionSuffix: String
    }

    weak var viewModelSink: ItemListViewModelSink? {
        didSet {
            self.updateViewModelSink()
        }
    }
    weak var navBarViewModelSink: NavBarViewModelSink? {
        didSet {
            self.updateNavBarViewModelSink()
        }
    }

    private let actionSink: RecipeDetailsActionSink
    private let content: Content

    private var displayModel: RecipeDetailsDisplayModel?
    private var editModeDisplayModel: EditModeDisplayModel?

    init(
        actionSink: RecipeDetailsActionSink,
        content: Content
    ) {
        self.actionSink = actionSink
        self.content = content
    }

    private func updateViewModelSink() {
        guard let displayModel = self.displayModel else {
            return
        }

        self.viewModelSink?.send(
            viewModel: Self.viewModel(
                fromDisplayModel: displayModel,
                content: self.content,
                isEditing: self.editModeDisplayModel?.isEditing ?? false
            )
        )
    }

    private func updateNavBarViewModelSink() {
        guard
            let editModel = self.editModeDisplayModel
        else {
            return
        }

        self.navBarViewModelSink?
            .send(
                navBarViewModel: Self.navBarViewModel(
                    editModeDisplayModel: editModel,
                    forItemName: self.displayModel?.name.data ?? "",
                    editingHeader: self.content.editingHeaderTitle
                )
            )
    }
}

extension RecipeDetailsItemListPresentation: RecipeDetailsDisplayModelSink {
    func send(displayModel: RecipeDetailsDisplayModel) {
        self.displayModel = displayModel
        self.updateViewModelSink()
        self.updateNavBarViewModelSink()
    }

    func highlightStep(at index: Int) {
        guard
            let stepSection = self.stepSectionIndex()
        else {
            return
        }

        self.viewModelSink?.scrollTo(
            .init(item: index, section: stepSection)
        )
    }

    func send(editModeDisplayModel: EditModeDisplayModel) {
        self.editModeDisplayModel = editModeDisplayModel
        self.updateNavBarViewModelSink()
        self.updateViewModelSink()
    }

    func send(
        alertDisplayModel: EditModeAction.DoneType,
        didConfirm: @escaping (Bool) -> Void
    ) {
        let content = self.content.alertContent
        let buttonSide: NavBarViewModel.Side =
            alertDisplayModel == .cancel ? .left : .right

        self.navBarViewModelSink?
            .send(
                alertViewModel: .init(
                    title: nil,
                    message: content.descriptionText,
                    side: buttonSide,
                    buttonIndex: 0,
                    actions: [
                        .init(
                            title: content.cancelText,
                            type: .cancel,
                            callback: { didConfirm(false) }
                        ),
                        .init(
                            title: content.confirmText,
                            type: .confirm(isDestructive: true),
                            callback: { didConfirm(true) }
                        ),
                    ]
                )
            )
    }
}

extension RecipeDetailsItemListPresentation: ItemListEventSink {
    func send(event: ItemListEvent) {
        switch event {
        case .edit(let name, .init(item: 0, section: 0)):
            self.actionSink
                .send(
                    action: .editName(name)
                )

        case .edit(let description, .init(item: 0, section: 1)):
            self.actionSink
                .send(
                    action: .editDescription(description)
                )

        case .select(itemAt: let indexPath)
            where self.isStepSection(indexPath.section):
            handleRecipeStepSelect(indexPath)

        case .delete(itemAt: let indexPath)
            where self.isStepSection(indexPath.section):
            self.actionSink
                .send(action: .deleteStep(indexPath.item - self.addButtonOffset()))

        case .move(let from, let to)
            where self.isStepSection(from.section) && self.isStepSection(to.section):
            self.actionSink
                .send(action: .moveStep(
                    from: from.item - self.addButtonOffset(),
                    to: to.item - self.addButtonOffset()
                ))

        case .openInfo(itemAt: let indexPath)
            where self.isStepSection(indexPath.section):
            self.actionSink
                .send(action: .openInfo(forStep: indexPath.item - 1))

        case .resolveAlert(itemAt: let indexPath)
            where self.isStepSection(indexPath.section):
            self.actionSink
                .send(action: .addToInventory(forStep: indexPath.row))

        default:
            break
        }
    }

    private func stepSectionIndex() -> Int? {
        if self.editModeDisplayModel?.isEditing ?? false {
            return 2
        }

        guard let displayModel else {
            return nil
        }

        let sections = [
            displayModel.name.data.isEmpty ? nil : false,
            displayModel.description.isEmpty ? nil : false,
            true
        ].compactMap { $0 }

        return sections.firstIndex(where: { $0 })
    }

    private func isStepSection(_ section: Int) -> Bool {
        section == stepSectionIndex()
    }

    private func addButtonOffset() -> Int {
        self.editModeDisplayModel.flatMap { $0.isEditing ? 1 : nil } ?? 0
    }

    private func handleRecipeStepSelect(_ indexPath: IndexPath) {
        if self.editModeDisplayModel?.isEditing ?? false {
            if indexPath.item == 0 {
                self.actionSink.send(action: .addStep)
            } else {
                self.actionSink.send(action: .selectStep(indexPath.item - 1))
            }
        } else {
            self.actionSink
                .send(action: .selectStep(indexPath.item))
        }
    }
}

extension RecipeDetailsItemListPresentation: NavBarEventSink {
    func send(navBarEvent: NavBarEvent) {
        guard let canEdit = self.editModeDisplayModel?.isEditing else {
            return
        }

        if canEdit {
            self.handleEditingNavEvent(navBarEvent)
        } else {
            self.handleViewingNavEvent(navBarEvent)
        }
    }

    private func handleEditingNavEvent(_ event: NavBarEvent) {
        switch event {
        case .tap(.right, 0):
            self.actionSink
                .send(editModeAction: .finishEditing(.save))
        case .tap(.left, index: 0):
            self.actionSink
                .send(editModeAction: .finishEditing(.cancel))
        default:
            break
        }
    }

    private func handleViewingNavEvent(_ event: NavBarEvent) {
        switch event {
        case .tap(.right, 0):
            self.actionSink
                .send(editModeAction: .startEditing)
        default:
            break
        }
    }
}

// MARK: Model Transforms
extension RecipeDetailsItemListPresentation {
    private static func viewModel(
        fromDisplayModel displayModel: RecipeDetailsDisplayModel,
        content: Content,
        isEditing: Bool
    ) -> ItemListViewModel {
        if isEditing {
            return self.editingViewModel(
                fromDisplayModel: displayModel,
                content: content
            )
        } else {
            return self.viewingViewModel(
                fromDisplayModel: displayModel,
                content: content
            )
        }
    }

    private static func editingViewModel(
        fromDisplayModel displayModel: RecipeDetailsDisplayModel,
        content: Content
    ) -> ItemListViewModel {
        .init(
            sections: [
                .init(
                    title: "\(content.sectionTitles.nameLabelText) \(content.sectionTitles.requiredSectionSuffix)",
                    items: [
                        .init(
                            id: Self.editingId(fromPurpose: content.sectionTitles.nameLabelText),
                            type: .editSingleline(
                                displayModel.name.data,
                                purpose: content.sectionTitles.nameLabelText
                            ),
                            context: [])
                    ],
                    footerErrorMessage: displayModel.name.invalidityReason.map { .init(message: $0.error) }
                ),
                .init(
                    title: content.sectionTitles.descriptionLabelText,
                    items: [
                        .init(
                            id: Self.editingId(fromPurpose: content.sectionTitles.descriptionLabelText),
                            type: .editMultiline(
                                displayModel.description,
                                purpose: content.sectionTitles.descriptionLabelText
                            ),
                            context: [])
                    ]
                ),
                Self.editingRecipeViewModelSection(
                    steps: displayModel.recipeSteps,
                    content: content
                )
            ].compactMap { $0 },
            isEditing: true
        )
    }

    private static func viewingViewModel(
        fromDisplayModel displayModel: RecipeDetailsDisplayModel,
        content: Content
    ) -> ItemListViewModel {
        .init(
            sections: [
                self.viewingNameViewModelSection(
                    fromDisplayModel: displayModel,
                    content: content.sectionTitles
                ),
                self.viewingDescriptionViewModelSection(
                    fromDisplayModel: displayModel,
                    content: content.sectionTitles
                ),
                self.viewingRecipeViewModelSection(
                    steps: displayModel.recipeSteps,
                    sectionHeader: content.sectionTitles.recipeLabelText,
                    unstockedMessage: content.unstockedMessage,
                    unstockedResolution: content.unstockedResolution
                )
            ].compactMap { $0 },
            isEditing: false
        )
    }

    private static func viewingNameViewModelSection(
        fromDisplayModel displayModel: RecipeDetailsDisplayModel,
        content: SectionTitles
    ) -> ItemListViewModel.Section {
        .init(
            title: content.nameLabelText,
            items: [
                .init(
                    id: Self.viewingId(fromPurpose: content.nameLabelText),
                    type: .text(displayModel.name.data),
                    context: [])
            ]
        )
    }

    private static func viewingDescriptionViewModelSection(
        fromDisplayModel displayModel: RecipeDetailsDisplayModel,
        content: SectionTitles
    ) -> ItemListViewModel.Section? {
        if displayModel.description.isEmpty {
            return nil
        } else {
            return .init(
                title: content.descriptionLabelText,
                items: [
                    .init(
                        id: Self.viewingId(fromPurpose: content.descriptionLabelText),
                        type: .text(displayModel.description),
                        context: []
                    )
                ]
            )
        }
    }

    private static func viewingRecipeViewModelSection(
        steps: [RecipeDetailsDisplayModel.RecipeStep],
        sectionHeader: String,
        unstockedMessage: String,
        unstockedResolution: String
    ) -> ItemListViewModel.Section? {
        if steps.isEmpty {
            return nil
        } else {
            return .init(
                title: sectionHeader,
                items: steps.enumerated()
                    .map { (index, step) in
                        let text: ItemListViewModel.ItemType = .text(step.name)
                        let context: [ItemListViewModel.Context] = [
                            step.isStocked ? nil : .alert(
                                .init(
                                    message: unstockedMessage,
                                    actionDescription: unstockedResolution,
                                    icon: .add
                                )
                            ),
                            step.canPreview ? .navigate : nil,
                            .delete,
                        ].compactMap { $0 }

                        return .init(
                            id: String(index),
                            type: text,
                            indentation: 0,
                            context: context
                        )
                    }
            )
        }
    }

    private static func editingRecipeViewModelSection(
        steps: [RecipeDetailsDisplayModel.RecipeStep],
        content: Content
    ) -> ItemListViewModel.Section? {
        let addStepItem = ItemListViewModel.Item(
            id: "AddStepItem",
            type: .text(content.addStepCellTitle),
            context: [.add]
        )

        return .init(
            title: content.sectionTitles.recipeLabelText,
            items: [addStepItem] + steps.enumerated().map { (index, step) in
                let text: ItemListViewModel.ItemType = .text(step.name)

                return .init(
                    id: step.name + String(index) + "_edit",
                    type: text,
                    indentation: 0,
                    context: [
                        .delete,
                        .info,
                        .reorder(.init(sections: .set(
                            [2: .set(Set(1...(steps.count + 1)))]
                        )))
                    ]
                )
            }
        )
    }

    private static func navBarViewModel(
        editModeDisplayModel: EditModeDisplayModel,
        forItemName name: String,
        editingHeader: String
    ) -> NavBarViewModel {
        if editModeDisplayModel.isEditing {
            return self.editingNavBarViewModel(
                editModeDisplayModel: editModeDisplayModel,
                headerTitle: editingHeader
            )
        } else {
            return self.viewingNavBarViewModel(
                editModeDisplayModel: editModeDisplayModel,
                headerTitle: name
            )
        }
    }

    private static func editingNavBarViewModel(
        editModeDisplayModel: EditModeDisplayModel,
        headerTitle: String
    ) -> NavBarViewModel {
        .init(
            title: headerTitle,
            leftButtons: [
                .init(
                    type: .cancel,
                    isEnabled: true
                )
            ],
            rightButtons: [
                .init(
                    type: .save,
                    isEnabled: editModeDisplayModel.canSave
                )
            ]
        )
    }

    private static func viewingNavBarViewModel(
        editModeDisplayModel: EditModeDisplayModel,
        headerTitle: String
    ) -> NavBarViewModel {
        .init(
            title: headerTitle,
            leftButtons: [
                .init(
                    type: .back,
                    isEnabled: true
                )
            ],
            rightButtons: [
                .init(
                    type: .edit,
                    isEnabled: true
                )
            ]
        )
    }

    private static func editingId(fromPurpose purpose: String) -> String {
        purpose + "_edit"
    }

    private static func viewingId(fromPurpose purpose: String) -> String {
        purpose + "_view"
    }
}
