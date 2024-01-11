//
//  ReadOnlyIngredientListItemListPresentation.swift
//  NowChurning
//
//  Created by Austin Dumm on 5/22/23.
//

import Foundation

class ReadOnlyIngredientListItemListPresentation {
    struct Content {
        let listTitle: String
        let addIngredientInstruction: String
        let ingredientSectionsHeader: String
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

    private let actionSink: IngredientListActionSink
    private let content: Content

    private var displayModel: IngredientListDisplayModel?
    private let canAddIngredient: Bool

    init(
        viewModelSink: ItemListViewModelSink? = nil,
        canAddIngredient: Bool = true,
        actionSink: IngredientListActionSink,
        content: Content
    ) {
        self.viewModelSink = viewModelSink
        self.canAddIngredient = canAddIngredient
        self.actionSink = actionSink
        self.content = content
    }

    private func updateViewModelSink() {
        guard let displayModel else { return }

        self.viewModelSink?
            .send(viewModel: Self.viewModel(
                forDisplayModel: displayModel,
                canAddIngredient: self.canAddIngredient,
                content: self.content
            ))
    }

    private func updateNavBarViewModelSink() {
        self.navBarViewModelSink?
            .send(navBarViewModel: .init(
                title: self.content.listTitle,
                leftButtons: [.init(type: .back, isEnabled: true)],
                rightButtons: []
            ))
    }
}

// MARK: Model Transforms
extension ReadOnlyIngredientListItemListPresentation {
    private static func viewModel(
        forDisplayModel displayModel: IngredientListDisplayModel,
        canAddIngredient: Bool,
        content: Content
    ) -> ItemListViewModel {
        let addSection = canAddIngredient ? [Self.addIngredientViewModelSection(content: content)] : []
        return .init(
            sections: addSection +
                Self.ingredientSections(
                    forDisplayModel: displayModel,
                    content: content
                ),
            isEditing: false
        )
    }

    private static func addIngredientViewModelSection(
        content: Content
    ) -> ItemListViewModel.Section {
        .init(
            title: "",
            items: [
                .init(
                    type: .text(content.addIngredientInstruction),
                    context: [.add]
                )
            ]
        )
    }

    private static func ingredientSections(
        forDisplayModel displayModel: IngredientListDisplayModel,
        content: Content
    ) -> [ItemListViewModel.Section] {
        var sections: [ItemListViewModel.Section] = displayModel.inventorySections.map {
            .init(
                title: $0.title,
                items: Self.ingredientItems(forDisplayModel: $0.items)
            )
        }

        if !sections.isEmpty {
            sections[0].title = content.ingredientSectionsHeader
        }

        return sections
    }

    private static func ingredientItems(
        forDisplayModel displayModel: [IngredientListDisplayModel.Item]
    ) -> [ItemListViewModel.Item] {
        displayModel.map {
            .init(
                id: $0.id.rawId.uuidString,
                type: .text($0.title),
                context: [.navigate]
            )
        }
    }
}

extension ReadOnlyIngredientListItemListPresentation: IngredientListDisplayModelSink {
    func send(
        displayModel: IngredientListDisplayModel
    ) {
        self.displayModel = displayModel
        self.updateViewModelSink()
    }

    // Both editModeDisplayModel and alertDisplayModel deal with save and
    // cancel editing. This presentation does not support edit mode
    func send(
        editModeDisplayModel: EditModeDisplayModel
    ) {}
    func send(
        alertDisplayModel: EditModeAction.DoneType,
        didConfirm: @escaping (Bool) -> Void
    ) {}
}

extension ReadOnlyIngredientListItemListPresentation: ItemListEventSink {
    func send(event: ItemListEvent) {
        switch event {
        case .select(itemAt: let indexPath):
            self.handleSelect(at: indexPath)
        case .delete,
                .edit,
                .selectFooter,
                .move,
                .openInfo,
                .resolveAlert,
                .multiselectUpdate:
            // Noop as this Presentation does not handle editing
            break
        }
    }

    private func isAddIngredientRow(at indexPath: IndexPath) -> Bool {
        indexPath.section == 0 && indexPath.row == 0 && self.canAddIngredient
    }

    private func handleSelect(at indexPath: IndexPath) {
        if self.isAddIngredientRow(at: indexPath) {
            self.actionSink.send(action: .newIngredient)
            return
        }

        self.actionSink
            .send(action: .selectItem(
                inSection: indexPath.section - self.sectionShift(),
                atIndex: indexPath.item
            ))
    }

    private func sectionShift() -> Int {
        self.canAddIngredient ? 1 : 0
    }
}

extension ReadOnlyIngredientListItemListPresentation: NavBarEventSink {
    func send(navBarEvent: NavBarEvent) {
        switch navBarEvent {
        case .tap:
            // No nav bar events should direct here
            break
        }
    }
}
