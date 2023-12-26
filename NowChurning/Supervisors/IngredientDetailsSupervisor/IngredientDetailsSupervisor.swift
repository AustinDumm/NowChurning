//
//  IngredientListSupervisor.swift
//  NowChurning
//
//  Created by Austin Dumm on 2/15/23.
//

import UIKit

protocol IngredientDetailsSupervisorParent: ParentSupervisor {
    func navigateToTagSelector(forIngredient: Ingredient)
    func navigateForDoneEditing(doneType: EditModeAction.DoneType)
    func addToInventory(ingredient: Ingredient)
}

class IngredientDetailsSupervisor: Supervisor {
    struct Content {
        var applicationContent: IngredientDetailsApplication.Content
        var presentationContent: IngredientDetailsItemListPresentation.Content
    }

    weak var parent: IngredientDetailsSupervisorParent?

    private typealias Store = (IngredientStoreActionSink & IngredientListDomainModelSink)
    private let application: IngredientDetailsApplication
    private let presentation: IngredientDetailsItemListPresentation
    private let navBarManager: NavBarManager
    private let ingredientStore: Store
    private let listView: ItemListViewController

    init(
        container: UIViewController,
        navigationItem: UINavigationItem,
        parent: IngredientDetailsSupervisorParent,
        ingredientId: ID<Ingredient>?,
        ingredientListStore: IngredientListStoreActionSink,
        shownAsModal: Bool = false,
        canResolveNameError: Bool = true,
        content: Content
    ) {
        self.parent = parent

        self.application = .init(
            content: content.applicationContent,
            canResolveNameError: canResolveNameError
        )

        if let ingredientId {
            self.ingredientStore = IngredientFromListStore(
                id: ingredientId,
                modelSink: self.application,
                storeSink: ingredientListStore
            )
        } else {
            self.ingredientStore = NewIngredientFromListStore(
                modelSink: self.application,
                storeSink: ingredientListStore
            )
            self.application.send(editModeAction: .startEditing)
        }

        self.application.domainModelStore = self.ingredientStore
        ingredientListStore.registerSink(asWeak: self.ingredientStore)

//        self.presentation = .init(
//            actionSink: application,
//            shownAsModal: shownAsModal,
//            contentContainer: content.presentationContent
//        )
        self.presentation = .init(
            actionSink: application,
            shownAsModal: shownAsModal,
            content: content.presentationContent
        )
        self.application.displayModelSink = self.presentation

        self.listView = .init(eventSink: self.presentation)
        self.presentation.itemListSink = self.listView

        self.navBarManager = .init(
            navigationItem: navigationItem,
            alertViewDelegate: self.listView,
            providedButtonBuilder: ProvidedBarButtonBuilder(
                backButton: self.listView.navigationItem.backBarButtonItem
            ),
            systemButtonBuilder: NavBarSystemButtonBuilder(),
            eventSink: self.presentation
        )
        self.presentation.navBarSink = self.navBarManager

        self.application.delegate = self

        container
            .insetChild(self.listView)
    }

    func updateTags(to tags: [Tag<Ingredient>]) {
        self.application
            .setTags(tags)
    }

    func canEnd() -> Bool {
        !self.application.hasChanges
    }

    func requestEnd(
        onEnd: @escaping () -> Void
    ) {
        if !self.application.hasChanges {
            onEnd()
            return
        }

        self.application
            .cancelEditing {
                onEnd()
            }
    }
}

extension IngredientDetailsSupervisor: IngredientDetailsApplicationDelegate {
    func navigate(forEditDoneType doneType: EditModeAction.DoneType) {
        self.parent?
            .navigateForDoneEditing(doneType: doneType)
    }

    func requestEditTags(forIngredient ingredient: Ingredient) {
        self.parent?
            .navigateToTagSelector(forIngredient: ingredient)
    }

    func addToInventory(ingredient: Ingredient) {
        self.parent?.addToInventory(ingredient: ingredient)
    }

    func exit() {
        self.parent?.childDidEnd(supervisor: self)
    }
}
