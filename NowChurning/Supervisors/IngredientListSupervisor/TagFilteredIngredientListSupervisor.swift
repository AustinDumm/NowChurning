//
//  TagFilteredIngredientListSupervisor.swift
//  NowChurning
//
//  Created by Austin Dumm on 6/29/23.
//

import UIKit
import Factory

protocol TagFilteredIngredientListParent: ParentSupervisor {
    func navigateTo(ingredient: Ingredient)
    func addNewIngredient(withTags: [Tag<Ingredient>])
}

class TagFilteredIngredientListSupervisor: Supervisor {
    struct Content {
        var presentationContent: IngredientListItemListPresentation.Content
        var openIngredientAlert: AlertContent
        var addIngredientAlert: AlertContent
        var title: String
    }

    weak var parent: TagFilteredIngredientListParent?

    private let container: UIViewController

    private let application: IngredientListApplication
    private let presentation: IngredientListItemListPresentation
    private let store: TagFilteredIngredientListCoreDataStore
    private let view: ItemListViewController
    private var navBarManager: NavBarManager?
    private let tags: [Tag<Ingredient>]

    private let content: Content

    init?(
        container: UIViewController,
        tags: [Tag<Ingredient>],
        parent: TagFilteredIngredientListParent? = nil,
        content: Content
    ) {
        self.container = container
        self.content = content
        self.parent = parent
        self.tags = tags

        self.application = .init()

        guard let store = TagFilteredIngredientListCoreDataStore(
            tags: tags,
            sink: self.application,
            storeUser: Container.shared.coreDataUserManager().user,
            managedObjectContext: Container.shared.managedObjectContext()
        ) else {
            return nil
        }
        self.store = store

        self.presentation = .init(
            actionSink: self.application,
            content: content.presentationContent
        )
        self.application.displayModelSink = self.presentation

        self.view = .init(eventSink: self.presentation)
        self.presentation.viewModelSink = self.view

        container.insetChild(self.view)
        self.application.delegate = self

        self.navBarManager = .init(
            navigationItem: container.navigationItem,
            alertViewDelegate: container,
            providedButtonBuilder: ProvidedBarButtonBuilder(backButton: container.navigationItem.backBarButtonItem),
            systemButtonBuilder: NavBarSystemButtonBuilder(),
            eventSink: WeakNavBarEventSink(eventSink: self)
        )
        self.navBarManager!.send(
            navBarViewModel: .init(
                title: self.content.title,
                leftButtons: [.init(type: .done, isEnabled: true)],
                rightButtons: [.init(type: .add, isEnabled: true)]
            )
        )
    }

    func canEnd() -> Bool {
        true
    }

    func requestEnd(onEnd: @escaping () -> Void) {
        onEnd()
    }
}

extension TagFilteredIngredientListSupervisor: NavBarEventSink {
    func send(navBarEvent: NavBarEvent) {
        switch navBarEvent {
        case .tap(.left, 0):
            self.parent?.childDidEnd(supervisor: self)
        case .tap(.right, index: 0):
            self.handleAddNewIngredient()
        default:
            break
        }
    }

    private func handleAddNewIngredient() {
        let content = self.content.addIngredientAlert
        let tags = self.tags
        self.navBarManager?.send(alertViewModel: .init(
            title: nil,
            message: content.descriptionText,
            side: .right,
            buttonIndex: 0,
            actions: [
                .init(
                    title: content.cancelText,
                    type: .cancel,
                    callback: {}
                ),
                .init(
                    title: content.confirmText,
                    type: .confirm(isDestructive: true),
                    callback: { [weak self] in
                        self?.parent?
                            .addNewIngredient(withTags: tags)
                    }
                )
            ]
        ))
    }
}

extension TagFilteredIngredientListSupervisor: IngredientListAppNavDelegate {
    func navigateTo(ingredient: Ingredient) {
        self.parent?.navigateTo(ingredient: ingredient)
    }

    func navigateToAddIngredient() {}
}
