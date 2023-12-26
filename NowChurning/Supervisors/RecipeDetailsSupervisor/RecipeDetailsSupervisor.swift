//
//  RecipeDetailsSupervisor.swift
//  NowChurning
//
//  Created by Austin Dumm on 3/4/23.
//

import UIKit
import Factory

protocol RecipeDetailsSupervisorParent: ParentSupervisor, RecipeDetailsApplicationDelegate {}

class RecipeDetailsSupervisor: NSObject, Supervisor {
    struct Content {
        var applicationContent: RecipeDetailsApplication.Content
        var presentationContent: RecipeDetailsItemListPresentation.Content
    }

    private typealias Store = (RecipeDetailsStoreActionSink & RecipeListDomainModelSink)

    private weak var parent: ParentSupervisor?

    private let application: RecipeDetailsApplication

    private let presentation: RecipeDetailsItemListPresentation
    private let view: ItemListViewController
    private let navBarManager: NavBarManager

    private let recipeStore: Store

    init(
        container: UIViewController,
        navigationItem: UINavigationItem,
        parent: RecipeDetailsSupervisorParent,
        recipe: Recipe? = nil,
        recipeListStore: RecipeListCoreDataStore,
        content: Content
    ) {
        self.parent = parent

        self.application = .init(
            content: content.applicationContent
        )

        self.presentation = .init(
            actionSink: self.application,
            content: content.presentationContent
        )
        self.application.displayModelSink = self.presentation

        self.view = .init(
            eventSink: self.presentation,
            initialSelection: recipe == nil ? .init(item: 0, section: 0) : nil
        )
        self.presentation.viewModelSink = self.view

        self.navBarManager = .init(
            navigationItem: navigationItem,
            alertViewDelegate: self.view,
            providedButtonBuilder: ProvidedBarButtonBuilder(
                backButton: self.view.navigationItem.backBarButtonItem
            ),
            systemButtonBuilder: NavBarSystemButtonBuilder(),
            eventSink: self.presentation
        )
        self.presentation.navBarViewModelSink = self.navBarManager

        if let recipe {
            self.recipeStore = RecipeFromListStore(
                user: Container.shared.coreDataUserManager().user,
                modelSink: self.application,
                storeSink: recipeListStore,
                id: recipe.id
            )
        } else {
            self.recipeStore = NewRecipeFromListStore(
                user: Container.shared.coreDataUserManager().user,
                modelSink: self.application,
                storeSink: recipeListStore
            )
            self.application.send(editModeAction: .startEditing)
        }

        self.application.storeActionSink = self.recipeStore
        recipeListStore.registerWeak(sink: self.recipeStore)

        super.init()

        self.application.delegate = parent
        container
            .insetChild(
                self.view
            )
    }

    func refresh() {
        self.recipeStore.send(action: .refresh)
    }

    func appendStep(_ step: RecipeDetails.Step) {
        self.application.appendStep(step)
    }

    func replaceStep(at index: Int, with step: RecipeDetails.Step) {
        self.application.replaceStep(at: index, with: step)
    }

    func canEnd() -> Bool {
        return !self.application.hasChanges
    }

    func requestEnd(
        onEnd: @escaping () -> Void
    ) {
        if !self.application.hasChanges {
            onEnd()
            return
        }

        self.application
            .confirmEditCancel {
                onEnd()
            }
    }
}
