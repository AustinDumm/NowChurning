//
//  MeasureDetailsSupervisor.swift
//  NowChurning
//
//  Created by Austin Dumm on 5/14/23.
//

import UIKit
import Factory

protocol MeasureDetailsSupervisorParent: ParentSupervisor {
    func requestEditTags(forMeasure: Measure)
    func requestMeasurementEdit(forMeasure: Measure)
    func navigate(forDoneType: EditModeAction.DoneType)
    func switchEditing(toMeasureForIngredientId: ID<Ingredient>)
    func didSaveMeasure(withIngredientId id: ID<Ingredient>)
}

class MeasureDetailsSupervisor: Supervisor {
    struct Content {
        let applicationContent: MeasureDetailsApplication.Content
        let presentationContent: MeasureDetailsItemListPresentation.Content
    }

    enum InitialMeasureType {
        case newIngredient
        case existingIngredient(Ingredient)
        case existingMeasure(Measure)
        case editingExisting(Measure)
    }

    private typealias Store = (MeasureListDomainModelSink & MeasureStoreActionSink & IngredientListDomainModelSink)

    weak var parent: MeasureDetailsSupervisorParent?

    private let application: MeasureDetailsApplication

    private let store: Store
    private let allIngredientStore: IngredientListCoreDataStore?

    private let presentation: MeasureDetailsItemListPresentation

    private let view: ItemListViewController
    private let navBarManager: NavBarManager

    init(
        container: UIViewController,
        navigationItem: UINavigationItem,
        measure: InitialMeasureType,
        listStore: MeasureListStoreActionSink,
        parent: MeasureDetailsSupervisorParent? = nil,
        content: Content
    ) {
        self.application = .init(content: content.applicationContent)
        self.parent = parent
        let initialSelection: IndexPath?

        switch measure {
        case .editingExisting(let measure):
            self.application.send(editModeAction: .startEditing)
            self.application.setMeasure(measure: measure)
            fallthrough
        case .existingMeasure(let measure):
            self.store = MeasureFromListStore(
                id: measure.ingredient.id,
                modelSink: self.application,
                storeSink: listStore
            )
            initialSelection = nil
        case .newIngredient:
            self.store = NewMeasureFromListStore(
                modelSink: self.application,
                storeSink: listStore
            )
            self.application.send(editModeAction: .startEditing)
            initialSelection = .init(item: 0, section: 0)
        case .existingIngredient(let ingredient):
            self.store = NewMeasureFromListStore(
                modelSink: self.application,
                storeSink: listStore
            )
            self.application.send(editModeAction: .startEditing)
            self.application.setMeasure(measure: .init(ingredient: ingredient, measure: .any))
            initialSelection = nil
        }

        listStore.registerSink(asWeak: self.store)
        self.application.domainModelStore = self.store
        self.allIngredientStore = .init(
            sink: self.store,
            storeUser: Container.shared.coreDataUserManager().user,
            managedObjectContext: Container.shared.managedObjectContext()
        )

        self.presentation = .init(
            actionSink: self.application,
            contentContainer: content.presentationContent
        )
        self.application.displayModelSink = self.presentation

        self.view = .init(
            eventSink: self.presentation,
            initialSelection: initialSelection
        )
        self.presentation.viewModelSink = self.view

        self.navBarManager = .init(
            navigationItem: navigationItem,
            alertViewDelegate: container,
            providedButtonBuilder: ProvidedBarButtonBuilder(
                backButton: navigationItem.backBarButtonItem
            ),
            systemButtonBuilder: NavBarSystemButtonBuilder(),
            eventSink: self.presentation
        )
        self.presentation.editViewModelSink = self.navBarManager

        container.insetChild(self.view)
        self.application.delegate = self
    }

    func setTags(to tags: [Tag<Ingredient>]) {
        self.application.setTags(tags)
    }

    func setMeasurement(to measurement: MeasurementType) {
        self.application.setMeasurement(measurement: measurement)
    }

    func canEnd() -> Bool {
        !self.application.hasChanges
    }

    func requestEnd(onEnd: @escaping () -> Void) {
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

extension MeasureDetailsSupervisor: MeasureDetailsApplicationDelegate {
    func requestEditTags(forMeasure measure: Measure) {
        self.parent?
            .requestEditTags(forMeasure: measure)
    }

    func requestMeasurementEdit(forMeasure measure: Measure) {
        self.parent?
            .requestMeasurementEdit(forMeasure: measure)
    }

    func navigate(forEditDoneType doneType: EditModeAction.DoneType) {
        self.parent?
            .navigate(forDoneType: doneType)
    }

    func didSaveMeasure(withIngredientId id: ID<Ingredient>) {
        self.parent?.didSaveMeasure(withIngredientId: id)
    }

    func switchEditing(
        toMeasureForIngredientId ingredientId: ID<Ingredient>
    ) {
        self.parent?
            .switchEditing(toMeasureForIngredientId: ingredientId)
    }

    func exit() {
        self.parent?.childDidEnd(supervisor: self)
    }
}
