//
//  MeasureListItemListPresentation.swift
//  NowChurning
//
//  Created by Austin Dumm on 5/14/23.
//

import Foundation

class MeasureDetailsItemListPresentation {
    struct Content {
        let sectionTitles: SectionTitles
        let headerTitle: String
        let alertContainer: AlertContent

        let ingredientDetailsContent: IngredientPartialItemListPresentation.Content

        let unspecifiedMeasurementText: String
    }

    struct SectionTitles {
        let nameLabelText: String
        let descriptionLabelText: String
        let tagsLabelText: String
        let editTagsLabelText: String
        let measurementSectionText: String

        let requiredSectionSuffix: String
        let optionalSectionSuffix: String
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
    private let actionSink: MeasureDetailsActionSink?
    private let contentContainer: Content
    private var displayModel: MeasureDetailsDisplayModel?

    private var ingredientPresentation: IngredientPartialItemListPresentation!

    private var editModeDisplayModel: EditModeDisplayModel?

    private class WeakPresentationAdapter: IngredientDetailsActionSink {
        weak var presentation: IngredientDetailsActionSink?

        init(presentation: IngredientDetailsActionSink?) {
            self.presentation = presentation
        }

        func send(ingredientAction: IngredientDetailsAction) {
            self.presentation?.send(ingredientAction: ingredientAction)
        }

        func send(editModeAction: EditModeAction) {
            self.presentation?.send(editModeAction: editModeAction)
        }
    }
    private lazy var adapter = WeakPresentationAdapter(presentation: self)

    init(
        actionSink: MeasureDetailsActionSink?,
        contentContainer: Content
    ) {
        self.actionSink = actionSink
        self.contentContainer = contentContainer

        self.ingredientPresentation = .init(
            actionSink: self.adapter,
            contentContainer: contentContainer.ingredientDetailsContent
        )
        self.ingredientPresentation.viewModelSink = self
        self.ingredientPresentation.editViewModelSink = self
    }

    // MARK: DidSet Event Handlers
    private func onSetViewModelSink() {
        self.sendViewModel()
    }

    private func onSetEditViewModelSink() {
        self.sendNavBarViewModel()
    }

    // MARK: Senders
    private func sendViewModel() {
        guard
            let displayModel = self.displayModel
        else {
            return
        }

        self.ingredientPresentation
            .send(ingredientDisplayModel: .init(
                name: displayModel.name,
                description: displayModel.description,
                tagNames: displayModel.tagNames
            ))
    }
}

extension MeasureDetailsItemListPresentation: MeasureDetailsDisplayModelSink {
    func send(
        measureDisplayModel: MeasureDetailsDisplayModel
    ) {
        self.displayModel = measureDisplayModel

        self.sendViewModel()
        self.sendNavBarViewModel()
    }
}

extension MeasureDetailsItemListPresentation: ItemListEventSink {
    func send(event: ItemListEvent) {
        switch event {
        case .select(.init(row: 0, section: 3)):
            self.actionSink?.send(measureAction: .action(.editMeasurement))
        default:
            self.ingredientPresentation
                .send(event: event)
        }
    }
}

extension MeasureDetailsItemListPresentation: EditModeDisplayModelSink {
    func send(
        editModeDisplayModel: EditModeDisplayModel
    ) {
        self.editModeDisplayModel = editModeDisplayModel
        self.sendNavBarViewModel()
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

        self.ingredientPresentation
            .send(editModeDisplayModel: editModeDisplayModel)
    }
}

extension MeasureDetailsItemListPresentation: NavBarEventSink {
    func send(navBarEvent: NavBarEvent) {
        self.ingredientPresentation
            .send(navBarEvent: navBarEvent)
    }
}

extension MeasureDetailsItemListPresentation: IngredientDetailsActionSink {
    func send(ingredientAction: IngredientDetailsAction) {
        switch ingredientAction {
        case .edit(.name(let newName)):
            self.actionSink?.send(measureAction: .edit(.name(newName)))
        case .edit(.description(let newDescription)):
            self.actionSink?.send(measureAction: .edit(.description(newDescription)))

        case .action(.addTag):
            self.actionSink?.send(measureAction: .action(.addTag))
        case .action(.nameFooterTap):
            self.actionSink?
                .send(
                    measureAction: .action(.nameFooterTap)
                )
        case .action(.exit):
            self.actionSink?
                .send(measureAction: .action(.exit))
        case .action(.addToInventory):
            // Measures are already in the inventory or part of a recipe
            break
        }
    }

    func send(editModeAction: EditModeAction) {
        self.actionSink?.send(editModeAction: editModeAction)
    }
}

extension MeasureDetailsItemListPresentation: NavBarViewModelSink {
    func send(navBarViewModel: NavBarViewModel) {
        self.editViewModelSink?.send(navBarViewModel: navBarViewModel)
    }

    // Internal IngredientPresentation isn't involved in sending our alert VMs
    func send(alertViewModel: NavBarAlertViewModel) {}
}

extension MeasureDetailsItemListPresentation: ItemListViewModelSink {
    func send(viewModel: ItemListViewModel) {
        guard
            let displayModel
        else {
            self.viewModelSink?.send(viewModel: viewModel)
            return
        }

        self.viewModelSink?.send(
            viewModel: Self.addMeasureSection(
                toViewModel: viewModel,
                displayModel: displayModel,
                isEditing: self.editModeDisplayModel?.isEditing ?? false,
                content: self.contentContainer
            )
        )
    }

    func scrollTo(_ indexPath: IndexPath) {
        self.viewModelSink?.scrollTo(indexPath)
    }
}

// MARK: Model Transforms
extension MeasureDetailsItemListPresentation {
    private static func addMeasureSection(
        toViewModel viewModel: ItemListViewModel,
        displayModel: MeasureDetailsDisplayModel,
        isEditing: Bool,
        content: Content
    ) -> ItemListViewModel {
        if isEditing {
            return self.addEditingMeasureSection(
                toViewModel: viewModel,
                displayModel: displayModel,
                content: content
            )
        } else {
            return self.addViewingMeasureSection(
                toViewModel: viewModel,
                displayModel: displayModel,
                content: content
            )
        }
    }

    private static func addViewingMeasureSection(
        toViewModel viewModel: ItemListViewModel,
        displayModel: MeasureDetailsDisplayModel,
        content: Content
    ) -> ItemListViewModel {
        guard let measurementDescription = displayModel.measurementDescription else {
            return viewModel
        }

        var viewModel = viewModel

        viewModel.sections.append(
            .init(
                title: content.sectionTitles.measurementSectionText,
                items: [.init(
                    type: .text(measurementDescription),
                    context: []
                )]
            )
        )

        return viewModel
    }

    private static func addEditingMeasureSection(
        toViewModel viewModel: ItemListViewModel,
        displayModel: MeasureDetailsDisplayModel,
        content: Content
    ) -> ItemListViewModel {
        var viewModel = viewModel

        viewModel.sections.append(
            .init(
                title: "\(content.sectionTitles.measurementSectionText) \(content.sectionTitles.optionalSectionSuffix)",
                items: [
                    .init(
                        type: .text(displayModel.measurementDescription ?? content.unspecifiedMeasurementText),
                        context: [.navigate])
                ])
        )

        return viewModel
    }
}
