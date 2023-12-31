//
//  InventorySupervisor.swift
//  NowChurning
//
//  Created by Austin Dumm on 3/21/23.
//

import UIKit
import CoreData
import Factory

class InventorySupervisor: NSObject {
    struct Content {
        let barListContent: IngredientListSupervisor.Content
        let measureListContent: MeasureListSupervisor.Content

        let editDetailsContent: MeasureFlowSupervisor.Content
        let addMeasureContent: AddMeasureFlowSupervisor.Content

        let navigateAlert: AlertContent
    }

    private enum State {
        case inventoryList(
            (MeasureListSupervisor, UIViewController)
        )

        case measureDetails(
            (MeasureListSupervisor, UIViewController),
            MeasureFlowSupervisor
        )

        case addMeasure(
            (MeasureListSupervisor, UIViewController),
            AddMeasureFlowSupervisor
        )
    }

    weak var parent: ParentSupervisor?

    private let navigator: SegmentedNavigationController
    private let oldAccent: UIColor?
    private let rootTopController: UIViewController?

    @Injected(\.coreDataUserManager)
        private var userManager: CoreDataUserManager
    @Injected(\.managedObjectContext)
        private var managedObjectContext: NSManagedObjectContext
    private let content: Content

    private var state: State?

    private var listStore: StockedMeasureListCoreDataStore? {
        switch self.state {
        case .inventoryList((let supervisor, _)),
                .measureDetails((let supervisor, _), _),
                .addMeasure((let supervisor, _), _):
            return supervisor.listStore
        case .none:
            return nil
        }
    }

    init(
        parent: ParentSupervisor?,
        navigator: SegmentedNavigationController,
        content: Content
    ) {
        self.parent = parent

        self.navigator = navigator
        self.rootTopController = self.navigator.topViewController

        self.oldAccent = self.navigator.view.tintColor
        UINavigationBar.appearance().tintColor = .Accent.inventory
        self.navigator.navigationBar.tintColor = .Accent.inventory
        self.navigator.view.tintColor = .Accent.inventory
        self.content = content
    }

    func start() -> Bool {
        let container = UIViewController()
        guard let supervisor = MeasureListSupervisor(
            container: container,
            navigationItem: container.navigationItem,
            parent: self,
            content: self.content.measureListContent
        ) else {
            return false
        }

        self.state = .inventoryList(
            (supervisor, container)
        )

        container.navigationItem.largeTitleDisplayMode = .never
        self.navigator.pushViewController(
            container,
            startingNewSegmentWithDelegate: self,
            animated: true
        )
        return true
    }

    func startEdit(ingredient: Ingredient) -> Bool {
        let listContainer = UIViewController()
        listContainer.navigationItem.largeTitleDisplayMode = .never
        guard
            let listSupervisor = MeasureListSupervisor(
                container: listContainer,
                navigationItem: listContainer.navigationItem,
                parent: self,
                content: self.content.measureListContent
            ),
            let measure = userManager.user.stockedMeasure(forIngredientId: ingredient.id)
        else {
            return false
        }
        let listInsertIndex = self.navigator.viewControllers.count

        let detailsSupervisor = MeasureFlowSupervisor(
            parent: self,
            navigator: self.navigator,
            measure: .editingExisting(measure),
            measureStore: listSupervisor.listStore,
            content: self.content.editDetailsContent
        ) { [weak self] in
            guard let self else { return }

            self.navigator.insertViewController(
                listContainer,
                atStackIndex: listInsertIndex,
                startingNewSegmentWithDelegate: self
            )
        }

        self.state = .measureDetails(
            (listSupervisor, listContainer),
            detailsSupervisor
        )

        return true
    }

    func startAdd(ingredient: Ingredient) -> Bool {
        let listContainer = UIViewController()
        listContainer.navigationItem.largeTitleDisplayMode = .never
        guard
            let listSupervisor = MeasureListSupervisor(
                container: listContainer,
                navigationItem: listContainer.navigationItem,
                parent: self,
                content: self.content.measureListContent
            )
        else {
            return false
        }

        let modalNavigation = SegmentedNavigationController()
        let addMeasure = AddMeasureFlowSupervisor(
            toAddNewFrom: .existingIngredient(ingredient),
            measureListStore: listSupervisor.listStore,
            parent: self,
            navigator: modalNavigation,
            content: self.content.addMeasureContent
        )

        self.state = .addMeasure(
            (listSupervisor, listContainer),
            addMeasure
        )
        self.navigator.pushViewController(
            listContainer,
            startingNewSegmentWithDelegate: self,
            animated: true
        ) { [weak self] in
            self?.navigator.present(
                modalNavigation,
                animated: true
            )
        }

        return true
    }

    private func errorExit(_ error: AppError) {
        error.showAsAlert(on: self.navigator)
        self.navigator.dismiss(animated: true)

        if let root = self.rootTopController {
            _ = self.navigator
                .popToViewController(root, animated: true)
        } else {
            _ = self.navigator
                .popToRootViewController(animated: true)
        }

        self.endSelf()
    }

    private func endSelf() {
        UINavigationBar.appearance().tintColor = self.oldAccent
        self.navigator.navigationBar.tintColor = self.oldAccent
        self.navigator.navigationBar.tintColor = self.oldAccent
        self.parent?.childDidEnd(supervisor: self)
    }
}

extension InventorySupervisor: ParentSupervisor {
    func childDidEnd(supervisor child: Supervisor) {
        switch self.state {
        case .inventoryList(
            let (expected, container)
        ) where expected === child:
            assert(self.navigator.topViewController === container)
            _ = self.navigator
                .popViewController(animated: true)
            self.endSelf()

        case .measureDetails(
            let inventoryListPair,
            let expected
        ) where expected === child:
            self.state = .inventoryList(inventoryListPair)

        case .addMeasure(
            let inventoryListPair,
            let expected
        ) where expected === child:
            self.navigator
                .dismiss(animated: true)
            self.state = .inventoryList(inventoryListPair)
        default:
            self.errorExit(.inventorySupervisorEndStateFailure)
        }
    }

    func recover(
        fromError error: AppError,
        on child: Supervisor?
    ) {
        error.showAsAlert(on: self.navigator)

        guard let child else {
            self.parent?
                .recover(
                    fromError: .inventorySupervisorEndStateFailure,
                    on: self
                )
            return
        }

        self.childDidEnd(supervisor: child)
    }

    func canEnd() -> Bool {
        switch self.state {
        case .inventoryList((let supervisor as Supervisor, _)),
                .measureDetails(_, let supervisor as Supervisor),
                .addMeasure(_, let supervisor as Supervisor):
            return supervisor.canEnd()
        case .none:
            return true
        }
    }

    func requestEnd(
        onEnd: @escaping () -> Void
    ) {
        switch self.state {
        case .inventoryList((let supervisor, _)):
            supervisor.requestEnd(onEnd: onEnd)
        case .measureDetails(
            (let listSupervisor, _),
            let supervisor as Supervisor
        ), .addMeasure(
            (let listSupervisor, _),
            let supervisor as Supervisor
        ):
            supervisor.requestEnd {
                listSupervisor.requestEnd(onEnd: onEnd)
            }
        case .none:
            AppError.inventorySupervisorEndStateFailure.showAsAlert(on: self.navigator)
            onEnd()
        }
    }
}

extension InventorySupervisor: MeasureListSupervisorParent {
    func navigateToDetails(forMeasure measure: Measure) {
        guard let store = self.listStore else {
            self.errorExit(.inventoryIngredientDetailPushStateFailure)
            return
        }

        switch self.state {
        case .inventoryList(let inventoryPair):
            let supervisor = MeasureFlowSupervisor(
                parent: self,
                navigator: self.navigator,
                measure: .existingMeasure(measure),
                measureStore: store,
                content: self.content.editDetailsContent
            )
            self.state = .measureDetails(inventoryPair, supervisor)
        default:
            self.errorExit(.inventoryIngredientDetailPushStateFailure)
        }
    }

    func navigateToAddMeasure() {
        guard let store = self.listStore else {
            self.errorExit(.inventoryAddIngredientPushStateFailure)
            return
        }

        switch self.state {
        case .inventoryList(let inventoryPair):
            let modalNavigation = SegmentedNavigationController()
            guard let supervisor = AddMeasureFlowSupervisor(
                measureListStore: store,
                parent: self,
                navigator: modalNavigation,
                content: self.content.addMeasureContent
            ) else {
                return
            }

            modalNavigation
                .presentationController?
                .delegate = self

            self.state = .addMeasure(inventoryPair, supervisor)
            self.navigator
                .present(
                    modalNavigation,
                    animated: true
                )
        default:
            self.errorExit(.inventoryAddIngredientPushStateFailure)
            return
        }
    }
}

extension InventorySupervisor: SegmentedNavigationControllerDelegate {
    func didDisconnectDelegate(fromNavigationController: SegmentedNavigationController) {
        self.endSelf()
    }
}

extension InventorySupervisor: UIAdaptivePresentationControllerDelegate {
    func presentationControllerShouldDismiss(
        _ presentationController: UIPresentationController
    ) -> Bool {
        guard
            case let .addMeasure(_, supervisor) = self.state
        else {
            return true
        }

        return supervisor.canEnd()
    }

    func presentationControllerDidAttemptToDismiss(
        _ presentationController: UIPresentationController
    ) {
        guard
            case let .addMeasure(_, supervisor) = self.state
        else {
            return
        }

        supervisor.requestEnd { [weak self] in
            self?.childDidEnd(supervisor: supervisor)
        }
    }

    func presentationControllerDidDismiss(
        _ presentationController: UIPresentationController
    ) {
        guard
            case let .addMeasure(inventoryListPair, _) = self.state
        else {
            return
        }

        self.state = .inventoryList(inventoryListPair)
    }
}

extension InventorySupervisor: MeasureFlowSupervisorParent, AddMeasureFlowSupervisorParent {
    func navigate(forEditDoneType doneType: EditModeAction.DoneType) {
        guard case let .addMeasure(
            inventoryListPair,
            _
        ) = self.state else {
            return
        }

        self.navigator.dismiss(animated: true)
        self.state = .inventoryList(inventoryListPair)
    }

    func switchEditing(
        toMeasureForIngredientId ingredientId: ID<Ingredient>
    ) {
        switch self.state {
        case .measureDetails(
            let (measureListSupervisor, measureListContainer),
            let currentMeasureDetails
        ):
            currentMeasureDetails.requestEnd { [weak self] in
                self?.switchFromEditExisting(
                    withId: ingredientId,
                    measureListSupervisor: measureListSupervisor,
                    measureListContainer: measureListContainer
                )
            }
        case .addMeasure(
            _,
            let currentAddMeasure
        ):
            currentAddMeasure.requestEnd { [weak self] in
                self?.switchFromCreateToEditExisting(withId: ingredientId)
            }
        case .inventoryList, .none:
            break
        }
    }

    func didSaveMeasure(withIngredientId id: ID<Ingredient>) {
        switch self.state {
        case .none:
            break
        case .inventoryList((let listSupervisor, _)),
                .addMeasure((let listSupervisor, _), _),
                .measureDetails((let listSupervisor, _), _):

            Task.detached { @MainActor in
                try await Task.sleep(nanoseconds: 500_000_000)
                listSupervisor.scrollToMeasure(withIngredientId: id)
            }
        }
    }

    private func navigateConfirmation(
        confirmCallback: @escaping () -> Void
    ) {
        let alertController = UIAlertController(
            title: nil,
            message: self.content.navigateAlert.descriptionText,
            preferredStyle: .alert
        )
        let cancel = UIAlertAction(
            title: self.content.navigateAlert.cancelText,
            style: .cancel
        )
        let confirm = UIAlertAction(
            title: self.content.navigateAlert.confirmText,
            style: .destructive) { _ in
                confirmCallback()
            }
        alertController.addAction(cancel)
        alertController.addAction(confirm)

        self.navigator.present(alertController, animated: true)
    }

    private func switchFromEditExisting(
        withId ingredientId: ID<Ingredient>,
        measureListSupervisor: MeasureListSupervisor,
        measureListContainer: UIViewController
    ) {
        guard
            let listStore
        else {
            return
        }

        if let stockedMeasure = self
            .userManager
            .user
            .stockedMeasure(forIngredientId: ingredientId) {
            self.switchToEditExisting(
                measure: stockedMeasure,
                store: listStore,
                measureListSupervisor: measureListSupervisor,
                measureListContainer: measureListContainer
            )
        } else if let existingIngredient = self
            .userManager
            .user
            .ingredient(forId: ingredientId) {
            self.switchToCreateFromExisting(
                ingredient: existingIngredient,
                store: listStore,
                measureListSupervisor: measureListSupervisor,
                measureListContainer: measureListContainer
            )
        }
    }

    private func switchFromCreateToEditExisting(
        withId ingredientId: ID<Ingredient>
    ) {
        guard
            let listStore,
            let existingMeasure = self.userManager.user.stockedMeasure(forIngredientId: ingredientId),
            case let .addMeasure(listPair, _) = self.state
        else {
            return
        }

        self.navigator.dismiss(animated: true) { [weak self] in
            guard let self else { return }

            let measureDetails = MeasureFlowSupervisor(
                parent: self,
                navigator: self.navigator,
                measure: .editingExisting(existingMeasure),
                measureStore: listStore,
                content: self.content.editDetailsContent
            )
            self.state = .measureDetails(
                listPair,
                measureDetails
            )
        }
    }

    private func switchToEditExisting(
        measure: Measure,
        store: StockedMeasureListCoreDataStore,
        measureListSupervisor: MeasureListSupervisor,
        measureListContainer: UIViewController
    ) {
        self.navigator
            .popToViewController(
                measureListContainer,
                animated: true
            ) { [weak self] in
                guard let self else { return }

                let measureFlowSupervisor = MeasureFlowSupervisor(
                    parent: self,
                    navigator: self.navigator,
                    measure: .editingExisting(measure),
                    measureStore: store,
                    content: self.content.editDetailsContent
                )

                self.state = .measureDetails(
                    (measureListSupervisor, measureListContainer),
                    measureFlowSupervisor
                )
            }
    }

    private func switchToCreateFromExisting(
        ingredient: Ingredient,
        store: StockedMeasureListCoreDataStore,
        measureListSupervisor: MeasureListSupervisor,
        measureListContainer: UIViewController
    ) {
        self.navigator
            .popToViewController(
                measureListContainer,
                animated: true
            ) { [weak self] in
                guard let self else { return }
                let modalNavigation = SegmentedNavigationController()
                let addMeasureSupervisor = AddMeasureFlowSupervisor(
                    toAddNewFrom: .existingIngredient(ingredient),
                    measureListStore: store,
                    parent: self,
                    navigator: modalNavigation,
                    content: self.content.addMeasureContent
                )
                modalNavigation.presentationController?.delegate = self


                self.navigator.present(
                    modalNavigation,
                    animated: true
                )
                self.state = .addMeasure(
                    (measureListSupervisor, measureListContainer),
                    addMeasureSupervisor
                )
            }
    }
}
