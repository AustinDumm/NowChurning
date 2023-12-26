//
//  IngredientTagSelectorSupervisor.swift
//  NowChurning
//
//  Created by Austin Dumm on 2/20/23.
//

import UIKit
import CoreData
import Factory

protocol TagSelectorSupervisorParent: AnyObject, ParentSupervisor {
    func didSelect(tags: [Tag<Ingredient>]?)
}

class IngredientTagSelectorSupervisor: Supervisor {
    typealias Presentation = TagSelectorSelectionListPresentation<Ingredient>
    typealias Application = TagSelectorApplication<Presentation, IngredientTagSelectorSupervisor>
    typealias Store = IngredientTagCoreDataStore<Application>

    private let tagSelectorApplication: Application
    private let store: Store
    private let presentation: Presentation
    private let navBarManager: NavBarManager
    private let selectionView: SelectionListViewController

    private weak var parent: TagSelectorSupervisorParent?

    init?(
        container: UIViewController,
        navigationItem: UINavigationItem,
        initialTags: [Tag<Ingredient>],
        parent: TagSelectorSupervisorParent,
        content: TagSelectorContent
    ) {
        self.parent = parent

        self.tagSelectorApplication = .init(initialSelection: initialTags)

        guard let store: Store = .init(
            tagModelSink: self.tagSelectorApplication,
            user: Container.shared.coreDataUserManager().user,
            managedObjectContext: Container.shared.managedObjectContext()
        ) else {
            return nil
        }
        self.store = store

        self.presentation = .init(
            application: self.tagSelectorApplication,
            content: content
        )
        self.tagSelectorApplication.displayModelSink = self.presentation

        self.selectionView = .init(eventSink: self.presentation)
        self.presentation.viewModelSink = self.selectionView

        self.navBarManager = .init(
            navigationItem: navigationItem,
            alertViewDelegate: self.selectionView,
            providedButtonBuilder: ProvidedBarButtonBuilder(
                backButton: self
                    .selectionView
                    .navigationItem
                    .backBarButtonItem
            ),
            systemButtonBuilder: NavBarSystemButtonBuilder(),
            eventSink: self.presentation
        )
        self.presentation.navBarManager = self.navBarManager

        self.tagSelectorApplication.delegate = self

        container
            .insetChild(
                self.selectionView
            )
    }

    func canEnd() -> Bool {
        true
    }

    func requestEnd(
        onEnd: @escaping () -> Void
    ) {
        onEnd()
    }
}

extension IngredientTagSelectorSupervisor: TagSelectorDelegate {
    func didSelect(tags: [Tag<Ingredient>]) {
        self.parent?.didSelect(tags: tags)
    }

    func cancelTagSelection() {
        self.parent?.didSelect(tags: nil)
    }
}
