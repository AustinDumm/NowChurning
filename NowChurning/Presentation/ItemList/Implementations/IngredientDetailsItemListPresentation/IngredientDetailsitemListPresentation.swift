//
//  IngredientDetailsitemListPresentation.swift
//  NowChurning
//
//  Created by Austin Dumm on 7/18/23.
//

import Foundation

class IngredientDetailsItemListPresentation {
    struct Content {
        var partialContent: IngredientPartialItemListPresentation.Content
        var addToInventoryButtonText: String
    }

    weak var itemListSink: ItemListViewModelSink? {
        didSet {
            self.sendDetailsModel()
        }
    }
    weak var navBarSink: NavBarViewModelSink? {
        didSet {
            self.sendEditModeModel()
        }
    }

    private let actionSink: IngredientDetailsActionSink
    private let internalPresentation: IngredientPartialItemListPresentation
    private let content: Content

    private var displayModel: IngredientDetailsDisplayModel?
    private var editModeModel: EditModeDisplayModel?
    private var addedAddToInventoryIndex: Int?

    init(
        itemListSink: ItemListViewModelSink? = nil,
        navBarSink: NavBarViewModelSink? = nil,
        actionSink: IngredientDetailsActionSink,
        shownAsModal: Bool = false,
        content: Content
    ) {
        self.itemListSink = itemListSink
        self.navBarSink = navBarSink
        self.actionSink = actionSink
        self.content = content

        self.internalPresentation = .init(
            actionSink: actionSink,
            shownAsModal: shownAsModal,
            contentContainer: content.partialContent
        )

        self.internalPresentation.viewModelSink = self
        self.internalPresentation.editViewModelSink = self
    }

    private func sendDetailsModel() {
        guard let displayModel else { return }

        self.internalPresentation.send(ingredientDisplayModel: displayModel)
    }

    private func sendEditModeModel() {
        guard let editModeModel else { return }

        self.internalPresentation.send(editModeDisplayModel: editModeModel)
    }

    private func shouldAddAddToInventory() -> Bool {
        self.editModeModel.map { !$0.isEditing }  ?? false
    }
}

extension IngredientDetailsItemListPresentation: IngredientDetailsDisplayModelSink {
    func send(
        ingredientDisplayModel: IngredientDetailsDisplayModel
    ) {
        self.displayModel = ingredientDisplayModel

        self.sendDetailsModel()
    }

    func send(
        editModeDisplayModel: EditModeDisplayModel
    ) {
        self.editModeModel = editModeDisplayModel

        self.sendEditModeModel()
    }

    func send(
        alertDisplayModel: EditModeAction.DoneType,
        didConfirm: @escaping (Bool) -> Void
    ) {
        self.internalPresentation.send(
            alertDisplayModel: alertDisplayModel,
            didConfirm: didConfirm
        )
    }
}

extension IngredientDetailsItemListPresentation: ItemListViewModelSink,
                                                 NavBarViewModelSink {
    func send(viewModel: ItemListViewModel) {
        self.itemListSink?.send(viewModel: viewModel)
    }

    func scrollTo(_ indexPath: IndexPath) {
        self.itemListSink?.scrollTo(indexPath)
    }

    func send(navBarViewModel: NavBarViewModel) {
        var viewModel = navBarViewModel

        if self.shouldAddAddToInventory() {
            self.addedAddToInventoryIndex = viewModel.rightButtons.count
            viewModel.rightButtons.append(.init(
                type: .add,
                displayTitle: self.content.addToInventoryButtonText,
                isEnabled: true
            ))
        } else {
            self.addedAddToInventoryIndex = nil
        }

        self.navBarSink?.send(navBarViewModel: viewModel)
    }

    func send(alertViewModel: NavBarAlertViewModel) {
        self.navBarSink?.send(alertViewModel: alertViewModel)
    }
}

extension IngredientDetailsItemListPresentation: ItemListEventSink,
                                                 NavBarEventSink {
    func send(event: ItemListEvent) {
        self.internalPresentation.send(event: event)
    }

    func send(navBarEvent: NavBarEvent) {
        switch navBarEvent {
        case .tap(.right, index: self.addedAddToInventoryIndex):
            self.actionSink.send(ingredientAction: .action(.addToInventory))
        default:
            self.internalPresentation.send(navBarEvent: navBarEvent)
        }
    }
}
