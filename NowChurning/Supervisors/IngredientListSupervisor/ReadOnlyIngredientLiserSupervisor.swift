//
//  ReadOnlyIngredientLiserSupervisor.swift
//  NowChurning
//
//  Created by Austin Dumm on 7/3/23.
//

import UIKit
import Factory

class ReadOnlyIngredientListSupervisor: NSObject, Supervisor {
    typealias Content = ReadOnlyIngredientListItemListPresentation.Content

    private let application: IngredientListApplication
    private let presentation: ReadOnlyIngredientListItemListPresentation
    private let navBarManager: NavBarManager
    private let listStore: IngredientListCoreDataStore
    private let listView: ItemListViewController

    private var childSupervisor: Supervisor?
    weak var parentSupervisor: ReadOnlyIngredientListSupervisorParent? {
        didSet {
            self.application.delegate = self.parentSupervisor
        }
    }

    init?(
        container: UIViewController,
        navigationItem: UINavigationItem,
        canAddIngredient: Bool = true,
        parent: ReadOnlyIngredientListSupervisorParent? = nil,
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
            canAddIngredient: canAddIngredient,
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
