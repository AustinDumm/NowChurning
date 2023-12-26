//
//  IngredientListItemListPresentation.swift
//  NowChurning
//
//  Created by Austin Dumm on 12/17/22.
//

import Foundation

class IngredientListItemListPresentation {
    struct Content {
        let listTitle: String
        let alertContent: AlertContent
        let emptyListMessage: String
    }

    weak var viewModelSink: ItemListViewModelSink? {
        didSet {
            self.onSetViewModelSink()
        }
    }

    weak var navBarViewModelSink: NavBarViewModelSink? {
        didSet {
            self.onSetNavBarViewModelSink()
        }
    }

    private var displayModel: IngredientListDisplayModel?
    private var editModeDisplayModel: EditModeDisplayModel?

    private let actionSink: IngredientListActionSink?
    private let content: Content

    init(
        actionSink: IngredientListActionSink?,
        content: Content
    ) {
        self.actionSink = actionSink
        self.content = content
    }

    private func onSetViewModelSink() {
        self.sendViewModel()
    }

    private func onSetNavBarViewModelSink() {
        self.sendNavBarViewModel()
    }

    private func sendViewModel() {
        guard let sink = self.viewModelSink,
              let displayModel = self.displayModel else {
            return
        }

        let viewModel = Self.viewModel(
            from: displayModel,
            isEditing: self.editModeDisplayModel?.isEditing ?? false,
            content: self.content
        )

        sink.send(viewModel: viewModel)
    }

    private func sendNavBarViewModel() {
        if let editModeDisplayModel = self.editModeDisplayModel,
           editModeDisplayModel.isEditing {
            self.sendEditNavBarViewModel()
        } else {
            self.sendViewingNavBarViewModel()
        }
    }

    private func sendEditNavBarViewModel() {
        self.navBarViewModelSink?.send(
            navBarViewModel: .init(
                title: self.content.listTitle,
                leftButtons: [
                    .init(
                        type: .cancel,
                        isEnabled: true
                    )
                ],
                rightButtons: [
                    .init(
                        type: .save,
                        isEnabled: self.editModeDisplayModel?.canSave ?? false
                    ),
                ]
            )
        )
    }

    private func sendViewingNavBarViewModel() {
        self.navBarViewModelSink?.send(
            navBarViewModel: .init(
                title: self.content.listTitle,
                leftButtons: [
                    .init(
                        type: .back,
                        isEnabled: true
                    )
                ],
                rightButtons: self.rightSideButtons()
            )
        )
    }

    private func rightSideButtons() -> [NavBarViewModel.Button] {
        if self.displayModel?.inventorySections.isEmpty ?? false {
            return [
                .init(
                    type: .add,
                    isEnabled: true
                )
            ]
        } else {
            return [
                .init(
                    type: .add,
                    isEnabled: true
                ),
                .init(
                    type: .edit,
                    isEnabled: true
                )
            ]
        }
    }
}

// MARK: Model transformations
extension IngredientListItemListPresentation {
    private static func viewModel(
        from displayModel: IngredientListDisplayModel,
        isEditing: Bool,
        content: Content
    ) -> ItemListViewModel {
        if displayModel.inventorySections.isEmpty && !isEditing {
            return Self.emptyViewModel(
                isEditing: isEditing,
                content: content
            )
        } else {
            return Self.populatedViewModel(
                from: displayModel,
                isEditing: isEditing
            )
        }
    }

    private static func emptyViewModel(
        isEditing: Bool,
        content: Content
    ) -> ItemListViewModel {
        .init(
            sections: [
                .init(
                    title: "",
                    items: [
                        .init(
                            type: .message(content.emptyListMessage), context: [])
                    ]
                )
            ],
            isEditing: isEditing
        )
    }

    private static func populatedViewModel(
        from displayModel: IngredientListDisplayModel,
        isEditing: Bool
    ) -> ItemListViewModel {
        .init(
            sections: displayModel
                .inventorySections
                .map { item in
                    self.viewModelSection(
                        from: item,
                        isEditing: isEditing
                    )
                },
            isEditing: isEditing
        )
    }

    private static func viewModelSection(
        from displaySection: IngredientListDisplayModel.Section,
        isEditing: Bool
    ) -> ItemListViewModel.Section {
        .init(
            title: displaySection.title,
            items: displaySection
                .items
                .map { item in
                    viewModelItem(from: item, isEditing: isEditing)
                }
        )
    }

    private static func viewModelItem(
        from displayItem: IngredientListDisplayModel.Item,
        isEditing: Bool
    ) -> ItemListViewModel.Item {
        let contexts: [ItemListViewModel.Context] = isEditing ? [
            .delete
        ] : [
            .navigate,
            .delete
        ]

        return .init(
            id: displayItem.id.rawId.uuidString,
            type: .text(displayItem.title),
            context: contexts
        )

    }
}

extension IngredientListItemListPresentation: ItemListEventSink {
    func send(
        event: ItemListEvent
    ) {
        guard let action = Self.action(fromEvent: event) else {
            return
        }

        self.actionSink?.send(action: action)
    }

    private static func action(
        fromEvent event: ItemListEvent
    ) -> IngredientListAction? {
        switch event {
        case .select(itemAt: let indexPath):
            return .selectItem(
                inSection: indexPath.section,
                atIndex: indexPath.item
            )
        case .delete(itemAt: let indexPath):
            return .deleteItem(
                inSection: indexPath.section,
                atIndex: indexPath.item
            )
        case .edit, .selectFooter, .move, .openInfo, .resolveAlert:
            return nil
        }
    }

    private static func alertViewModel(
        fromDisplayModel displayModel: EditModeAction.DoneType,
        didConfirm: @escaping (Bool) -> Void,
        alertContent: AlertContent
    ) -> NavBarAlertViewModel? {
        switch displayModel {
        case .save:
            return nil
        case .cancel:
            return .init(
                title: nil,
                message: alertContent.descriptionText,
                side: .left,
                buttonIndex: 0,
                actions: [
                    .init(
                        title: alertContent.cancelText,
                        type: .cancel,
                        callback: { didConfirm(false) }
                    ),
                    .init(
                        title: alertContent.confirmText,
                        type: .confirm(isDestructive: true),
                        callback: { didConfirm(true) }
                    ),
                ]
            )
        }

    }
}

extension IngredientListItemListPresentation: IngredientListDisplayModelSink {
    func send(displayModel: IngredientListDisplayModel) {
        self.displayModel = displayModel
        self.sendNavBarViewModel()
        self.sendViewModel()
    }


    func send(editModeDisplayModel: EditModeDisplayModel) {
        self.editModeDisplayModel = editModeDisplayModel
        self.sendNavBarViewModel()
        self.sendViewModel()
    }

    func send(
        alertDisplayModel: EditModeAction.DoneType,
        didConfirm: @escaping (Bool) -> Void
    ) {
        guard
            let alertViewModel = Self.alertViewModel(
                fromDisplayModel: alertDisplayModel,
                didConfirm: didConfirm,
                alertContent: self.content.alertContent
            )
        else {
            return
        }

        self.navBarViewModelSink?
            .send(
                alertViewModel: alertViewModel
            )
    }
}

extension IngredientListItemListPresentation: NavBarEventSink {
    func send(
        navBarEvent: NavBarEvent
    ) {
        if let displayModel = self.editModeDisplayModel,
           displayModel.isEditing {
            self.handleEditModeNavEvent(navBarEvent: navBarEvent)
        } else {
            self.handleViewModeNavEvent(navBarEvent: navBarEvent)
        }
    }

    private func handleEditModeNavEvent(
        navBarEvent: NavBarEvent
    ) {
        switch navBarEvent {
        case .tap(.left, index: 0):
            self.actionSink?.send(
                editModeAction: .finishEditing(.cancel)
            )
        case .tap(.right, index: 0):
            self.actionSink?.send(
                editModeAction: .finishEditing(.save)
            )
        default:
            return
        }
    }

    private func handleViewModeNavEvent(
        navBarEvent: NavBarEvent
    ) {
        switch navBarEvent {
        case .tap(.right, 0):
            self.actionSink?.send(action: .newIngredient)
        case .tap(.right, index: 1):
            self.actionSink?.send(editModeAction: .startEditing)
        default:
            return
        }
    }
}
