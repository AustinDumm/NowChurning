//
//  RecipeListItemListPresentation.swift
//  NowChurning
//
//  Created by Austin Dumm on 3/3/23.
//

import Foundation

class RecipeListItemListPresentation {
    struct Content {
        let listTitle: String
        let alertContent: AlertContent
        let emptyListMessage: String
        let addNewRecipeText: String
        let editListText: String
        let exportListText: String
        let exportingListTitle: String
    }

    weak var itemListViewModelSink: ItemListViewModelSink? {
        didSet {
            self.updateItemListViewModelSink()
        }
    }
    weak var navBarViewModelSink: NavBarViewModelSink? {
        didSet {
            self.updateNavBarViewModelSink()
        }
    }

    private let actionSink: RecipeListActionSink
    private var displayModel: RecipeListDisplayModel?
    private var editModeDisplayModel: EditModeDisplayModel?
    private var isExporting = false
    private let content: Content

    private var isEditing: Bool {
        self.editModeDisplayModel?.isEditing ?? false
    }

    init(
        actionSink: RecipeListActionSink,
        content: Content
    ) {
        self.actionSink = actionSink
        self.content = content
    }

    private func updateItemListViewModelSink() {
        guard let displayModel = self.displayModel else {
            return
        }

        self.itemListViewModelSink?
            .send(
                viewModel: Self.viewModel(
                    fromDisplayModel: displayModel,
                    isEditing: self.isEditing,
                    isExporting: self.isExporting,
                    content: self.content
                )
            )
    }

    private func updateNavBarViewModelSink() {
        guard
            let editModeDisplayModel = self.editModeDisplayModel,
            let listDisplayModel = self.displayModel
        else {
            return
        }

        self.navBarViewModelSink?
            .send(
                navBarViewModel: Self.navBarModel(
                    from: editModeDisplayModel,
                    listDisplayModel: listDisplayModel,
                    content: self.content
                )
            )
    }
}

extension RecipeListItemListPresentation: RecipeListDisplayModelSink {
    func send(displayModel: RecipeListDisplayModel) {
        self.displayModel = displayModel
        self.updateItemListViewModelSink()
        self.updateNavBarViewModelSink()
    }

    func scrollTo(section: Int, item: Int) {
        self.itemListViewModelSink?.scrollTo(
            .init(item: item, section: section)
        )
    }

    func send(editModeDisplayModel: EditModeDisplayModel) {
        let hasChangedEditing = self.isEditing != editModeDisplayModel.isEditing

        self.editModeDisplayModel = editModeDisplayModel
        self.updateNavBarViewModelSink()

        if hasChangedEditing {
            self.updateItemListViewModelSink()
        }
    }

    func send(
        alertDisplayModel: EditModeAction.DoneType,
        didConfirm: @escaping (Bool) -> Void
    ) {
        let side: NavBarViewModel.Side = (alertDisplayModel == .save) ? .right : .left

        self.navBarViewModelSink?
            .send(
                alertViewModel: .init(
                    title: nil,
                    message: self.content.alertContent.descriptionText,
                    side: side,
                    buttonIndex: 0,
                    actions: [
                        .init(
                            title: self.content.alertContent.cancelText,
                            type: .cancel,
                            callback: {
                                didConfirm(false)
                            }
                        ),
                        .init(
                            title: self.content.alertContent.confirmText,
                            type: .confirm(isDestructive: true),
                            callback: {
                                didConfirm(true)
                            }
                        )
                    ]
                )
            )
    }
}

extension RecipeListItemListPresentation: ItemListEventSink {
    func send(event: ItemListEvent) {
        switch event {
        case .select(
            itemAt: let indexPath
        ) where !self.isEditing:
            self.actionSink
                .send(
                    action: .selectedItem(
                        inSection: indexPath.section,
                        atIndex: indexPath.item
                    )
                )
        case .delete(
            itemAt: let indexPath
        ):
            self.actionSink
                .send(
                    action: .deleteItem(
                        inSection: indexPath.section,
                        atIndex: indexPath.item
                    )
                )
        default:
            break
        }
    }
}

extension RecipeListItemListPresentation: NavBarEventSink {
    func send(navBarEvent: NavBarEvent) {
        if self.editModeDisplayModel?.isEditing ?? false {
            self.isEditingEvent(navBarEvent: navBarEvent)
        } else if self.isExporting {
            self.isExportingEvent(navBarEvent: navBarEvent)
        } else {
            self.isViewingEvent(navBarEvent: navBarEvent)
        }
    }

    private func isEditingEvent(navBarEvent: NavBarEvent) {
        switch navBarEvent {
        case .tap(.left, 0):
            self.actionSink
                .send(editModeAction: .finishEditing(.cancel))
        case .tap(.right, index: 0):
            self.actionSink
                .send(editModeAction: .finishEditing(.save))
        default:
            break
        }
    }

    private func isExportingEvent(navBarEvent: NavBarEvent) {
        switch navBarEvent {
        case .tap(.left, index: 0):
            self.cancelExport()
        case .tap(.right, index: 0):
            self.confirmExport()

        default:
            break
        }
    }

    private func isViewingEvent(navBarEvent: NavBarEvent) {
        switch navBarEvent {
        case .tap(.right, index: 0):
            self.actionSink
                .send(action: .newRecipe)
        case .tap(.right, index: 1):
            self.actionSink
                .send(editModeAction: .startEditing)
        case .tap(.right, index: 2):
            self.startExporting()
        default:
            break
        }
    }

    private func startExporting() {
        self.isExporting = true
        self.navBarViewModelSink?.send(navBarViewModel: .init(
            title: self.content.exportingListTitle,
            leftButtons: [.init(type: .cancel, isEnabled: true)],
            rightButtons: [.init(type: .exportTextOnly, isEnabled: true)]
        ))

        self.updateItemListViewModelSink()
    }

    private func cancelExport() {
        self.isExporting = false
        self.updateNavBarViewModelSink()
        self.updateItemListViewModelSink()
    }

    private func confirmExport() {
        self.isExporting = false
        self.updateNavBarViewModelSink()
        self.updateItemListViewModelSink()

        self.actionSink.send(action: .exportRecipes([]))
    }
}

// MARK: Model Transforms
extension RecipeListItemListPresentation {
    private static func viewModel(
        fromDisplayModel displayModel: RecipeListDisplayModel,
        isEditing: Bool,
        isExporting: Bool,
        content: Content
    ) -> ItemListViewModel {
        if displayModel.recipeSections.isEmpty && !isEditing {
            return emptyViewModel(
                isEditing: isEditing,
                content: content
            )
        } else {
            return populatedViewModel(
                fromDisplayModel: displayModel,
                isEditing: isEditing,
                isExporting: isExporting
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
                            type: .message(content.emptyListMessage),
                            context: [])
                    ])
            ],
            isEditing: isEditing
        )
    }

    private static func populatedViewModel(
        fromDisplayModel displayModel: RecipeListDisplayModel,
        isEditing: Bool,
        isExporting: Bool
    ) -> ItemListViewModel {
        .init(
            sections: displayModel
                .recipeSections
                .map { section in
                    self.viewModelSection(
                        fromDisplayModelSection: section,
                        isEditing: isEditing,
                        isExporting: isExporting
                    )
                },
            isEditing: isEditing
        )
    }

    private static func viewModelSection(
        fromDisplayModelSection section: RecipeListDisplayModel.Section,
        isEditing: Bool,
        isExporting: Bool
    ) -> ItemListViewModel.Section {
        let contexts: [ItemListViewModel.Context]
        if isEditing {
            contexts = [.delete]
        } else if isExporting {
            contexts = [.multiselect]
        } else {
            contexts = [.navigate, .delete]
        }

        return .init(
            title: section.title,
            items: section
                .items
                .map { .init(
                    id: $0.id.rawId.uuidString,
                    type: .text($0.title),
                    context: contexts
                )}
        )
    }

    private static func navBarModel(
        from editModeDisplayModel: EditModeDisplayModel,
        listDisplayModel: RecipeListDisplayModel,
        content: Content
    ) -> NavBarViewModel {
        if editModeDisplayModel.isEditing {
            return editingNavBarModel(
                from: editModeDisplayModel,
                content: content
            )
        } else {
            return viewingNavBarModel(
                from: editModeDisplayModel,
                listDisplayModel: listDisplayModel,
                content: content
            )
        }
    }

    private static func editingNavBarModel(
        from editModeDisplayModel: EditModeDisplayModel,
        content: Content
    ) -> NavBarViewModel {
        .init(
            title: content.listTitle,
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
            ])
    }

    private static func viewingNavBarModel(
        from editModeDisplayModel: EditModeDisplayModel,
        listDisplayModel: RecipeListDisplayModel,
        content: Content
    ) -> NavBarViewModel {
        let rightButtons: [NavBarViewModel.Button]
        if listDisplayModel.recipeSections.isEmpty {
            rightButtons = [
                .init(type: .add, isEnabled: true)
            ]
        } else {
            rightButtons = [
                .init(
                    type: .add,
                    displayTitle: content.addNewRecipeText,
                    isEnabled: true
                ),
                .init(
                    type: .edit,
                    displayTitle: content.editListText,
                    isEnabled: true
                ),
                .init(
                    type: .export,
                    displayTitle: content.exportListText,
                    isEnabled: true
                )
            ]
        }

        return .init(
            title: content.listTitle,
            leftButtons: [
                .init(
                    type: .back,
                    isEnabled: true
                )
            ],
            rightButtons: rightButtons
        )
    }
}
