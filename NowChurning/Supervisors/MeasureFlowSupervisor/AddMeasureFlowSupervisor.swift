//
//  AddMeasureFlowSupervisor.swift
//  NowChurning
//
//  Created by Austin Dumm on 5/22/23.
//

import UIKit
import CoreData
import Factory

protocol AddMeasureFlowSupervisorParent: ParentSupervisor {
    func didSaveMeasure(withIngredientId id: ID<Ingredient>)
    func navigate(forEditDoneType: EditModeAction.DoneType)
    func switchEditing(toMeasureForIngredientId: ID<Ingredient>)
}

class AddMeasureFlowSupervisor: Supervisor {
    struct Content {
        var ingredientListContent: ReadOnlyUnstockedIngredientListSupervisor.Content
        var measureFlowSupervisorContent: MeasureFlowSupervisor.Content
        var measurementEditContent: MeasurementEditSupervisor.Content
    }

    private enum State {
        case ingredientList(
            (ReadOnlyUnstockedIngredientListSupervisor, UIViewController)
        )
        case existingAmount(
            (ReadOnlyUnstockedIngredientListSupervisor, UIViewController),
            (MeasurementEditSupervisor, Ingredient)
        )
        case addNew(
            (ReadOnlyUnstockedIngredientListSupervisor, UIViewController),
            MeasureFlowSupervisor
        )
        case onlyAddNew(
            MeasureFlowSupervisor
        )
    }

    weak var parent: AddMeasureFlowSupervisorParent?
    private var state: State
    private let content: Content
    private let navigator: StackNavigation

    private let initialTop: UIViewController?

    private let measureListStore: StockedMeasureListCoreDataStore

    init?(
        measureListStore: StockedMeasureListCoreDataStore,
        parent: AddMeasureFlowSupervisorParent? = nil,
        navigator: StackNavigation,
        content: Content
    ) {
        self.measureListStore = measureListStore
        self.parent = parent
        self.navigator = navigator
        self.initialTop = navigator.topViewController
        self.content = content

        let user = Container.shared.coreDataUserManager().user
        let shouldShowList = user.hasUnstockedIngredients()

        if shouldShowList {
            let container = UIViewController()

            guard let supervisor = ReadOnlyUnstockedIngredientListSupervisor(
                container: container,
                navigationItem: container.navigationItem,
                content: content.ingredientListContent
            ) else { return nil }

            self.state = .ingredientList((supervisor, container))
            supervisor.parentSupervisor = self

            self.navigator.pushViewController(
                container,
                animated: true
            )

            container
                .navigationItem
                .leftBarButtonItem = .init(
                    barButtonSystemItem: .cancel,
                    target: self,
                    action: #selector(cancel)
                )
        } else {
            let supervisor = MeasureFlowSupervisor(
                navigator: self.navigator,
                measure: .newIngredient,
                measureStore: measureListStore,
                content: content.measureFlowSupervisorContent
            )

            self.state = .onlyAddNew(supervisor)
            supervisor.parent = self
        }
    }

    init(
        toAddNewFrom measureType: MeasureFlowSupervisor.InitialMeasureType,
        measureListStore: StockedMeasureListCoreDataStore,
        parent: AddMeasureFlowSupervisorParent? = nil,
        navigator: StackNavigation,
        content: Content
    ) {
        let supervisor = MeasureFlowSupervisor(
            navigator: navigator,
            measure: measureType,
            measureStore: measureListStore,
            content: content.measureFlowSupervisorContent
        )

        self.state = .onlyAddNew(supervisor)
        self.measureListStore = measureListStore
        self.parent = parent
        self.navigator = navigator
        self.content = content
        self.initialTop = navigator.topViewController

        supervisor.parent = self
    }

    func canEnd() -> Bool {
        switch self.state {
        case .ingredientList:
            return true
        case .existingAmount(_, let (supervisor, _)):
            return supervisor.canEnd()
        case .addNew(_, let measureFlow),
                .onlyAddNew(let measureFlow):
            return measureFlow.canEnd()
        }
    }

    func requestEnd(onEnd: @escaping () -> Void) {
        switch self.state {
        case .ingredientList:
            onEnd()
        case .existingAmount(_, let (supervisor, _)):
            supervisor.requestEnd(onEnd: onEnd)
        case .addNew(_, let measureFlow),
                .onlyAddNew(let measureFlow):
            return measureFlow.requestEnd(onEnd: onEnd)
        }
    }

    @objc func cancel() {
        self.parent?.childDidEnd(supervisor: self)
    }
}

extension AddMeasureFlowSupervisor: ParentSupervisor {
    func childDidEnd(
        supervisor: Supervisor
    ) {
        switch self.state {
        case .ingredientList(let (expected, _))
            where expected === supervisor:
            self.parent?.childDidEnd(supervisor: self)

        case .existingAmount(
            let ingredientList,
            (let expected, _)
        ) where expected === supervisor:
            self.navigator.popViewController(animated: true)
            self.state = .ingredientList(ingredientList)

        case .onlyAddNew(let expected)
            where expected === supervisor:
            self.parent?.childDidEnd(supervisor: self)

        case .addNew(
            let ingredientList,
            let expected
        ) where expected === supervisor:
            self.state = .ingredientList(ingredientList)

        default:
            self.parent?
                .recover(
                    fromError: .addMeasureEndStateFailure,
                    on: self
                )
        }
    }

    func recover(
        fromError error: AppError,
        on child: Supervisor?
    ) {

    }
}

extension AddMeasureFlowSupervisor: ReadOnlyIngredientListSupervisorParent {
    func navigateTo(ingredient: Ingredient) {
        guard case let .ingredientList(listPair) = self.state else { return }
        let container = UIViewController()
        let measurementEdit = MeasurementEditSupervisor(
            container: container,
            initialMeasure: nil,
            parent: self,
            content: self.content.measurementEditContent
        )
        self.state = .existingAmount(
            listPair,
            (measurementEdit, ingredient)
        )
        self.navigator.pushViewController(container, animated: true)
    }

    func navigateToAddIngredient() {
        guard
            case let .ingredientList(ingredientList) = self.state
        else {
            if let initialTop {
                _ = self.navigator
                    .popToViewController(initialTop, animated: true)
                self.parent?
                    .childDidEnd(supervisor: self)
            } else {
                self.parent?
                    .recover(
                        fromError: .addMeasureNewIngredientPushFailure,
                        on: self
                    )
            }
            return
        }

        self.state = .addNew(
            ingredientList,
            .init(
                parent: self,
                navigator: self.navigator,
                measure: .newIngredient,
                measureStore: self.measureListStore,
                content: self.content.measureFlowSupervisorContent
            ))
    }
}

extension AddMeasureFlowSupervisor: MeasureFlowSupervisorParent {
    func navigate(forEditDoneType doneType: EditModeAction.DoneType) {
        switch (self.state, doneType) {
        case (.onlyAddNew, _),
            (.addNew, .save),
            (.existingAmount, .save):
            self.parent?.navigate(forEditDoneType: doneType)
        case (.addNew, .cancel),
            (.existingAmount, .cancel):
            _ = self.navigator.popViewController(animated: true)
        case (.ingredientList, _):
            break
        }
    }

    func switchEditing(
        toMeasureForIngredientId ingredientId: ID<Ingredient>
    ) {
        let user = Container.shared.coreDataUserManager().user
        if user.stockedMeasure(
            forIngredientId: ingredientId
        ) != nil {
            self.parent?.switchEditing(
                toMeasureForIngredientId: ingredientId
            )
        } else if let ingredient = user.ingredient(forId: ingredientId) {
            switch self.state {
            case .addNew(
                let (supervisor, container),
                let flow
            ):
                flow.requestEnd { [weak self] in
                    guard let self else { return }

                    self.switchFromAddNewToNewIngredient(
                        ingredient,
                        store: self.measureListStore,
                        listSupervisor: supervisor,
                        container: container
                    )
                }
            case .onlyAddNew(let flow):
                flow.requestEnd { [weak self] in
                    guard let self else { return }

                    self.switchFromOnlyAddToNewIngredient(
                        ingredient,
                        store: self.measureListStore
                    )
                }
            case .ingredientList, .existingAmount:
                break
            }
        }
    }

    func didSaveMeasure(withIngredientId id: ID<Ingredient>) {
        self.parent?.didSaveMeasure(withIngredientId: id)
    }

    private func switchFromAddNewToNewIngredient(
        _ ingredient: Ingredient,
        store: StockedMeasureListCoreDataStore,
        listSupervisor: ReadOnlyUnstockedIngredientListSupervisor,
        container: UIViewController
    ) {
        self.navigator.popToViewController(
            container,
            animated: true
        ) { [weak self] in
                guard let self else { return }

                let supervisor = MeasureFlowSupervisor(
                    parent: self,
                    navigator: self.navigator,
                    measure: .existingIngredient(ingredient),
                    measureStore: store,
                    content: self.content.measureFlowSupervisorContent
                )
                self.state = .addNew(
                    (listSupervisor, container),
                    supervisor
                )
            }
    }

    private func switchFromOnlyAddToNewIngredient(
        _ ingredient: Ingredient,
        store: StockedMeasureListCoreDataStore
    ) {
        self.navigator.popViewController(
            animated: true
        ) { [weak self] in
            guard let self else { return }

            let supervisor = MeasureFlowSupervisor(
                parent: self,
                navigator: self.navigator,
                measure: .existingIngredient(ingredient),
                measureStore: store,
                content: self.content.measureFlowSupervisorContent
            )
            self.state = .onlyAddNew(
                supervisor
            )
        }
    }
}

extension AddMeasureFlowSupervisor: MeasurementEditSupervisorParent {
    func updateMeasurement(to measurementType: MeasurementType) {
        guard
            case let .existingAmount(_, (_, ingredient)) = self.state
        else { return }

        let newMeasureStore = NewMeasureFromListStore(
            modelSink: nil,
            storeSink: self.measureListStore
        )
        self.measureListStore.registerSink(asWeak: newMeasureStore)
        newMeasureStore
            .send(
                action: .save(
                    measure: .init(
                        ingredient: ingredient,
                        measure: measurementType
                    )
                )
            )
        self.parent?
            .childDidEnd(supervisor: self)
    }
}
