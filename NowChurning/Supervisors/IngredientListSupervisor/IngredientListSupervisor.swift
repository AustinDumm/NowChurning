//
//  IngredientListSupervisor.swift
//  NowChurning
//
//  Created by Austin Dumm on 2/15/23.
//

import UIKit
import CoreData
import Factory

protocol IngredientListSupervisorParent: ParentSupervisor, IngredientListAppNavDelegate {}

class IngredientListSupervisor: NSObject, Supervisor {
    typealias Content = IngredientListItemListPresentation.Content

    private let application: IngredientListApplication
    private let presentation: IngredientListItemListPresentation
    private let navBarManager: NavBarManager
    let listStore: IngredientListCoreDataStore
    private let listView: ItemListViewController

    private var childSupervisor: Supervisor?
    private weak var parentSupervisor: IngredientListSupervisorParent?

    init?(
        container: UIViewController,
        navigationItem: UINavigationItem,
        parent: IngredientListSupervisorParent,
        content: Content
    ) {
        self.parentSupervisor = parent
        self.application = .init()

        guard let listStore = IngredientListCoreDataStore(
            sink: application,
            storeUser: Container.shared.coreDataUserManager().user,
            managedObjectContext: Container.shared.managedObjectContext()
        ) else {
            return nil
        }
        self.listStore = listStore
        self.application.storeActionSink = self.listStore

        self.presentation = .init(
            actionSink: self.application,
            content: content
        )
        self.application.displayModelSink = self.presentation

        self.listView = .init(
            eventSink: self.presentation
        )
        self.listView.title = content.listTitle
        self.presentation.viewModelSink = self.listView

        self.navBarManager = .init(
            navigationItem: navigationItem,
            alertViewDelegate: self.listView,
            providedButtonBuilder: ProvidedBarButtonBuilder(
                backButton: self.listView.navigationItem.backBarButtonItem
            ),
            systemButtonBuilder: NavBarSystemButtonBuilder(),
            eventSink: self.presentation
        )
        self.presentation.navBarViewModelSink = self.navBarManager

        self.application.delegate = parent
        container
            .insetChild(self.listView)
    }

    func canEnd() -> Bool {
        !self.application.hasChanges
    }

    func requestEnd(
        onEnd: @escaping () -> Void
    ) {
        onEnd()
    }
}
