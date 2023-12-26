//
//  RecipeListSupervisor.swift
//  NowChurning
//
//  Created by Austin Dumm on 3/3/23.
//

import UIKit
import CoreData
import Factory

protocol RecipeListSupervisorParent: ParentSupervisor, RecipeListApplicationDelegate {}

class RecipeListSupervisor: NSObject, Supervisor {
    typealias Content = RecipeListItemListPresentation.Content

    private let application: RecipeListApplication

    private let presentation: RecipeListItemListPresentation
    private let view: ItemListViewController
    private let navBarManager: NavBarManager

    let modelStore: RecipeListCoreDataStore

    private weak var parent: RecipeListSupervisorParent?

    init?(
        container: UIViewController,
        navigationItem: UINavigationItem,
        parent: RecipeListSupervisorParent,
        content: Content
    ) {
        self.application = .init()
        self.application.delegate = parent
        self.parent = parent

        self.presentation = .init(
            actionSink: self.application,
            content: content
        )
        self.application.displayModelSink = self.presentation

        self.view = .init(eventSink: self.presentation)
        self.presentation.itemListViewModelSink = self.view

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

        guard let modelStore = RecipeListCoreDataStore(
            sink: self.application,
            storeUser: Container.shared.coreDataUserManager().user,
            objectContext: Container.shared.managedObjectContext()
        ) else {
            return nil
        }
        self.modelStore = modelStore

        self.application.storeActionSink = self.modelStore

        container
            .insetChild(self.view)

        super.init()
    }

    func canEnd() -> Bool {
        return !self.application.hasChanges
    }

    func requestEnd(
        onEnd: @escaping () -> Void
    ) {
        onEnd()
    }

    func scrollTo(recipe: Recipe) {
        self.application.scrollTo(recipe: recipe)
    }
}
