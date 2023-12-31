//
//  RecipeStepPreviewSupervisor.swift
//  NowChurning
//
//  Created by Austin Dumm on 6/30/23.
//

import UIKit
import Factory

protocol RecipeStepPreviewSupervisorParent: ParentSupervisor {
    func navigateToIngredient(_ ingredient: Ingredient)
    func switchToAdd(ingredient: Ingredient)
}

class RecipeStepPreviewSupervisor: NSObject, Supervisor {
    struct Content {
        let measurePreviewContent: MeasurePreviewSupervisor.Content
        let ingredientFlowContent: IngredientFlowSupervisor.Content
        let tagPreviewContent: TagFilteredIngredientListSupervisor.Content
        let addStockAlert: AlertContent
    }

    private enum State {
        case measurePreview(
            (MeasurePreviewSupervisor, StockedMeasureListCoreDataStore)
        )
        case ingredientPreview(
            (IngredientFlowSupervisor, IngredientListCoreDataStore)
        )
        case tagPreview(
            TagFilteredIngredientListSupervisor
        )
        case tagMeasurePreview(
            TagFilteredIngredientListSupervisor,
            (MeasurePreviewSupervisor, StockedMeasureListCoreDataStore, UIViewController)
        )
        case tagIngredientPreview(
            TagFilteredIngredientListSupervisor,
            (IngredientFlowSupervisor, IngredientListCoreDataStore)
        )
    }

    weak var parent: RecipeStepPreviewSupervisorParent?

    private var state: State?
    private let content: Content
    private let navigator: SegmentedNavigationController
    private var modalNavigator: SegmentedNavigationController!

    init?(
        parent: RecipeStepPreviewSupervisorParent? = nil,
        navigator: SegmentedNavigationController,
        recipeStep: RecipeDetails.Step,
        content: Content
    ) {
        self.parent = parent
        self.navigator = navigator
        self.content = content

        switch recipeStep {
        case .ingredient(let measure):
            let user = Container.shared.coreDataUserManager().user
            let context = Container.shared.managedObjectContext()

            if user.stockedIngredientIds().keys.contains(
                measure.ingredient.id
            ) {
                super.init()
                guard let listStore = StockedMeasureListCoreDataStore(
                    domainModelSink: nil,
                    user: user,
                    context: context
                ) else {
                    return nil
                }

                let container = UIViewController()
                self.modalNavigator = .init(rootViewController: container)
                let supervisor = MeasurePreviewSupervisor(
                    ingredient: measure.ingredient,
                    container: container,
                    navigationItem: container.navigationItem,
                    listStore: listStore,
                    content: self.content.measurePreviewContent
                )
                self.state = .measurePreview((supervisor, listStore))

                supervisor.parent = self
                self.navigator.present(
                    self.modalNavigator,
                    animated: true
                )
            } else {
                super.init()
                guard let listStore = IngredientListCoreDataStore(
                    sink: nil,
                    storeUser: user,
                    managedObjectContext: context
                ) else {
                    return nil
                }

                self.modalNavigator = .init()
                let supervisor = IngredientFlowSupervisor(
                    navigator: modalNavigator,
                    ingredient: measure.ingredient,
                    ingredientStore: listStore,
                    content: self.content.ingredientFlowContent
                )

                self.state = .ingredientPreview(
                    (supervisor, listStore)
                )

                self.navigator.present(modalNavigator, animated: true)
                supervisor.parent = self
            }

        case .ingredientTags(let tags, _):
            let container = UIViewController()
            self.modalNavigator = .init(rootViewController: container)
            guard let supervisor = TagFilteredIngredientListSupervisor(
                container: container,
                tags: tags,
                content: self.content.tagPreviewContent
            ) else {
                return nil
            }

            self.state = .tagPreview(supervisor)
            super.init()

            supervisor.parent = self
            self.navigator.present(self.modalNavigator, animated: true)

        case .instruction(let instruction):
            // There is no way to preview an instruction as all of the
            // instruction text is visible already
            return nil
        }

        self.modalNavigator.presentationController?.delegate = self
        self.modalNavigator.startSegment(withDelegate: self)
    }

    func canEnd() -> Bool {
        switch self.state {
        case .ingredientPreview((let supervisor as Supervisor, _)),
                .measurePreview((let supervisor as Supervisor, _)),
                .tagPreview(let supervisor as Supervisor):
            return supervisor.canEnd()

        case .tagMeasurePreview(
            let listSupervisor,
            (let measureSupervisor, _, _)
        ):
            return listSupervisor.canEnd() && measureSupervisor.canEnd()

        case .tagIngredientPreview(
            let listSupervisor,
            (let stockSupervisor, _)
        ):
            return listSupervisor.canEnd() && stockSupervisor.canEnd()

        case .none:
            return true
        }
    }

    func requestEnd(onEnd: @escaping () -> Void) {
        switch self.state {
        case .ingredientPreview((let supervisor as Supervisor, _)),
                .measurePreview((let supervisor as Supervisor, _)),
                .tagPreview(let supervisor as Supervisor):
            supervisor.requestEnd { [weak self] in
                self?.navigator.dismiss(
                    animated: true,
                    completion: onEnd
                )
            }

        case .tagMeasurePreview(
            let listSupervisor,
            (let measureSupervisor, _, _)
        ):
            measureSupervisor.requestEnd { [weak self] in
                self?.modalNavigator.popViewController(animated: true)
                self?.state = .tagPreview(listSupervisor)
                listSupervisor.requestEnd(onEnd: onEnd)
            }

        case .tagIngredientPreview(
            let listSupervisor,
            (let ingredientSupervisor, _)
        ):
            ingredientSupervisor.requestEnd { [weak self] in
                self?.modalNavigator.popViewController(animated: true)
                self?.state = .tagPreview(listSupervisor)
                listSupervisor.requestEnd(onEnd: onEnd)
            }

        case .none:
            onEnd()
        }
    }

    private class func addStockAlert(
        onCancel: @escaping (UIAlertAction) -> Void,
        onConfirm: @escaping (UIAlertAction) -> Void,
        content: AlertContent
    ) -> UIAlertController {
        let alertController = UIAlertController(
            title: nil,
            message: content.descriptionText,
            preferredStyle: .alert
        )
        alertController.addAction(.init(
            title: content.cancelText,
            style: .cancel,
            handler: onCancel
        ))
        alertController.addAction(.init(
            title: content.confirmText,
            style: .default,
            handler: onConfirm
        ))

        return alertController
    }
}

extension RecipeStepPreviewSupervisor: ParentSupervisor {
    func childDidEnd(supervisor: Supervisor) {
        switch self.state {
        case .ingredientPreview,
                .measurePreview,
                .tagPreview,
                .none:
            self.endSelf()
        case .tagIngredientPreview(
            let tag,
            (let expected as Supervisor, _)
        ) where expected === supervisor,
                .tagMeasurePreview(
                    let tag,
                    (let expected as Supervisor, _, _)
                )
            where expected === supervisor:
            self.modalNavigator.popViewController(animated: true)
            self.state = .tagPreview(tag)

        case .tagIngredientPreview, .tagMeasurePreview:
            break
        }
    }

    func recover(fromError error: AppError, on child: Supervisor?) {
    }

    private func endSelf() {
        self.navigator.dismiss(
            animated: true,
            completion: { [weak self] in
                guard let self else { return }

                self.parent?.childDidEnd(supervisor: self)
            }
        )
    }
}

extension RecipeStepPreviewSupervisor: MeasurePreviewSupervisorParent {
    func switchToEditing(ingredient: Ingredient) {
        self.parent?.navigateToIngredient(ingredient)
    }
}

extension RecipeStepPreviewSupervisor: TagFilteredIngredientListParent {
    func navigateTo(ingredient: Ingredient) {
        guard case let .tagPreview(supervisor) = self.state else {
            return
        }

        if Container
            .shared
            .coreDataUserManager()
            .user
            .stockedIngredientIds()
            .keys
            .contains(ingredient.id) {
            self.showTagStockedIngredientPreview(
                for: ingredient,
                onSupervisor: supervisor
            )
        } else {
            self.tagIngredientPreview(
                ingredient: ingredient,
                onSupervisor: supervisor
            )
        }
    }

    func addNewIngredient(withTags tags: [Tag<Ingredient>]) {
        self.parent?.switchToAdd(ingredient: .init(
            name: "",
            description: "",
            tags: tags
        ))
    }

    private func showTagStockedIngredientPreview(
        for ingredient: Ingredient,
        onSupervisor tagPreviewSupervisor: TagFilteredIngredientListSupervisor
    ) {
        guard let listStore = StockedMeasureListCoreDataStore(
            domainModelSink: nil,
            user: Container.shared.coreDataUserManager().user,
            context: Container.shared.managedObjectContext()
        ) else {
            return
        }

        let container = UIViewController()
        let supervisor = MeasurePreviewSupervisor(
            ingredient: ingredient,
            container: container,
            navigationItem: container.navigationItem,
            listStore: listStore,
            parent: self,
            content: self.content.measurePreviewContent
        )

        self.state = .tagMeasurePreview(
            tagPreviewSupervisor,
            (supervisor, listStore, container))
        self.modalNavigator.pushViewController(
            container,
            animated: true
        )
    }

    private func tagIngredientPreview(
        ingredient: Ingredient,
        onSupervisor tagPreviewSupervisor: TagFilteredIngredientListSupervisor
    ) {
        guard let listStore = IngredientListCoreDataStore(
            sink: nil,
            storeUser: Container.shared.coreDataUserManager().user,
            managedObjectContext: Container.shared.managedObjectContext()
        ) else {
            return
        }

        let supervisor = IngredientFlowSupervisor(
            parent: self,
            navigator: self.modalNavigator,
            ingredient: ingredient,
            ingredientStore: listStore,
            content: self.content.ingredientFlowContent
        )

        self.state = .tagIngredientPreview(
            tagPreviewSupervisor,
            (supervisor, listStore)
        )
    }
}

extension RecipeStepPreviewSupervisor: IngredientFlowSupervisorParent {
    func addToInventory(ingredient: Ingredient) {
        self.parent?.switchToAdd(ingredient: ingredient)
    }

    func navigate(forEditDoneType doneType: EditModeAction.DoneType) {}
}

extension RecipeStepPreviewSupervisor: SegmentedNavigationControllerDelegate {
    func didDisconnectDelegate(fromNavigationController: SegmentedNavigationController) {
        self.endSelf()
    }

    func navigationController(
        _ navigationController: UINavigationController,
        didShow viewController: UIViewController,
        animated: Bool
    ) {
        switch self.state {
        // All of these are root supervisors for the navigation stack
        case .tagPreview,
                .ingredientPreview,
                .measurePreview,
                .tagIngredientPreview,
                .none:
            break
        case .tagMeasurePreview(
            let tagFiltered,
            (_, _, let container)
        ):
            if !navigationController
                .viewControllers
                .contains(container) {
                self.state = .tagPreview(tagFiltered)
            }
        }
    }
}

extension RecipeStepPreviewSupervisor: UIPopoverPresentationControllerDelegate {
    func presentationControllerShouldDismiss(
        _ presentationController: UIPresentationController
    ) -> Bool {
        switch self.state {
        case .none:
            return true
        case .ingredientPreview((let supervisor as Supervisor, _)),
                .measurePreview((let supervisor as Supervisor, _)),
                .tagPreview(let supervisor as Supervisor):
            return supervisor.canEnd()

        case .tagMeasurePreview(
            let tag as Supervisor,
            (let supervisor as Supervisor, _, _)),
                .tagIngredientPreview(
                    let tag as Supervisor,
                    (let supervisor as Supervisor, _)):
            return tag.canEnd() && supervisor.canEnd()
        }
    }

    func presentationControllerDidAttemptToDismiss(
        _ presentationController: UIPresentationController
    ) {
        switch self.state {
        case .none:
            return endSelf()
        case .ingredientPreview((let supervisor as Supervisor, _)),
                .measurePreview((let supervisor as Supervisor, _)),
                .tagPreview(let supervisor as Supervisor):
            supervisor.requestEnd { [weak self] in
                self?.navigator.dismiss(animated: true) {
                    self?.endSelf()
                }
            }
        case .tagMeasurePreview(
            let tag as Supervisor,
            (let supervisor as Supervisor, _, _)),
                .tagIngredientPreview(
                    let tag as Supervisor,
                    (let supervisor as Supervisor, _)):
            supervisor.requestEnd { [weak self] in
                self?.modalNavigator.popViewController(
                    animated: true
                ) { [weak self] in
                    tag.requestEnd {
                        self?.navigator.dismiss(animated: true) {
                            self?.endSelf()
                        }
                    }
                }
            }
        }
    }

    func presentationControllerDidDismiss(
        _ presentationController: UIPresentationController
    ) {
        self.parent?.childDidEnd(supervisor: self)
    }
}
