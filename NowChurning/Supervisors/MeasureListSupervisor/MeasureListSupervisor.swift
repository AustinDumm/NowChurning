//
//  MeasureListSupervisor.swift
//  NowChurning
//
//  Created by Austin Dumm on 5/13/23.
//

import UIKit
import Factory

protocol MeasureListSupervisorParent: ParentSupervisor {
    func navigateToDetails(forMeasure: Measure)
    func navigateToAddMeasure()
}

class MeasureListSupervisor: Supervisor {
    struct Content {
        let presentationContent: MeasureListItemListPresentation.Content
    }

    weak var parent: MeasureListSupervisorParent?

    var listStore: StockedMeasureListCoreDataStore {
        self.store
    }

    private let application: MeasureListApplication

    private let presentation: MeasureListItemListPresentation

    private let view: ItemListViewController
    private let navBarManager: NavBarManager

    private let store: StockedMeasureListCoreDataStore

    init?(
        container: UIViewController,
        navigationItem: UINavigationItem,
        parent: MeasureListSupervisorParent? = nil,
        content: Content
    ) {
        self.application = .init()

        guard
            let store: StockedMeasureListCoreDataStore = .init(
                domainModelSink: self.application,
                user: Container.shared.coreDataUserManager().user,
                context: Container.shared.managedObjectContext()
            )
        else {
            return nil
        }
        self.store = store
        self.application.storeActionSink = self.store

        self.presentation = .init(
            actionSink: self.application,
            content: content.presentationContent
        )
        self.application
            .displayModelSink = self.presentation

        self.view = .init(eventSink: self.presentation)
        self.presentation.viewModelSink = self.view

        self.navBarManager = .init(
            navigationItem: navigationItem,
            alertViewDelegate: self.view,
            providedButtonBuilder: ProvidedBarButtonBuilder(
                backButton: navigationItem.backBarButtonItem
            ),
            systemButtonBuilder: NavBarSystemButtonBuilder(),
            eventSink: self.presentation
        )
        self.presentation.navBarViewModelSink = self.navBarManager

        self.parent = parent

        container.insetChild(self.view)
        self.application.delegate = self
    }

    func canEnd() -> Bool {
        true
    }

    func requestEnd(onEnd: @escaping () -> Void) {
        onEnd()
    }

    func scrollToMeasure(withIngredientId id: ID<Ingredient>) {
        self.application.scrollToMeasure(withIngredientId: id)
    }
}

extension MeasureListSupervisor: MeasureListApplicationDelegate {
    func navigateToDetails(forMeasure measure: Measure) {
        self.parent?.navigateToDetails(forMeasure: measure)
    }

    func navigateToAddMeasure() {
        self.parent?.navigateToAddMeasure()
    }
}

class MeasureIngredientListStoreAdapter: IngredientListStoreActionSink, MeasureListDomainModelSink {
    weak var ingredientListModelSink: IngredientListDomainModelSink? {
        didSet {
            self.ingredientListModelSink?
                .send(
                    domainModel: self.domainModel
                        .map { $0.ingredient }
                )
        }
    }
    weak var measureListStoreActionSink: MeasureListStoreActionSink?

    private var domainModel: [Measure] = []

    func send(action: IngredientListStoreAction) {
        switch action {
        case .save(let ingredients, _):
            self.measureListStoreActionSink?
                .send(action: .save(
                    measures: ingredients
                        .map { .init(ingredient: $0, measure: .any) },
                    saver: self
                ))
        }
    }

    func registerSink(asWeak sink: IngredientListDomainModelSink) {
        self.ingredientListModelSink = sink
    }

    func send(domainModel: [Measure]) {
        self.domainModel = domainModel
        self.ingredientListModelSink?
            .send(domainModel: domainModel.map { $0.ingredient })
    }
}
