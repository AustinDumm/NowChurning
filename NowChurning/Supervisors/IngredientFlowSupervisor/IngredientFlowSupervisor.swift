//
//  IngredientFlowSupervisor.swift
//  NowChurning
//
//  Created by Austin Dumm on 2/23/23.
//

import UIKit
import CoreData
import Factory

protocol IngredientFlowSupervisorParent: ParentSupervisor {
    func navigate(forEditDoneType: EditModeAction.DoneType)
    func addToInventory(ingredient: Ingredient)
}

class IngredientFlowSupervisor: NSObject, Supervisor {
    struct Content {
        let detailsContent: IngredientDetailsSupervisor.Content
        let tagSelectorContent: TagSelectorContent
    }

    private enum State {
        case ingredientDetails(
            (IngredientDetailsSupervisor, UIViewController)
        )
        case tagSelector(
            (IngredientDetailsSupervisor, UIViewController),
            IngredientTagSelectorSupervisor
        )
    }
    weak var parent: IngredientFlowSupervisorParent?
    private let navigator: UINavigationController
    private weak var oldNavigatorDelegate: UINavigationControllerDelegate?

    private var state: State?
    private let content: Content

    private var detailsViewController: UIViewController? {
        switch self.state {
        case .ingredientDetails((_, let viewController)),
                .tagSelector((_, let viewController), _):
            return viewController
        case .none:
            return nil
        }
    }

    init(
        parent: IngredientFlowSupervisorParent? = nil,
        navigator: UINavigationController,
        ingredient: Ingredient? = nil,
        ingredientStore: IngredientListStoreActionSink,
        content: Content
    ) {
        self.parent = parent
        self.navigator = navigator
        self.oldNavigatorDelegate = self
            .navigator
            .delegate

        self.content = content

        super.init()

        let container = UIViewController()
        self.state = .ingredientDetails(
            (IngredientDetailsSupervisor(
                container: container,
                navigationItem: container.navigationItem,
                parent: self,
                ingredientId: ingredient?.id,
                ingredientListStore: ingredientStore,
                shownAsModal: navigator.viewControllers.isEmpty,
                canResolveNameError: false,
                content: content.detailsContent
            ), container)
        )

        self.navigator
            .delegate = self
        self.navigator
            .pushViewController(
                container,
                animated: true
            )
    }

    func canEnd() -> Bool {
        switch self.state {
        case .ingredientDetails((let supervisor, _)):
            return supervisor.canEnd()
        case .tagSelector(_, let supervisor):
            return supervisor.canEnd()
        case .none:
            return true
        }
    }

    func requestEnd(
        onEnd: @escaping () -> Void
    ) {
        switch self.state {
        case .tagSelector(
            let (supervisor, container),
            _
        ):
            self.navigator.dismiss(animated: true)
            self.state = .ingredientDetails((supervisor, container))

            fallthrough
        case .ingredientDetails(let (supervisor, _)):
            supervisor.requestEnd(onEnd: onEnd)
        case .none:
            break
        }
    }

    private func endSelf() {
        self.navigator
            .delegate = self.oldNavigatorDelegate
        self.parent?
            .childDidEnd(supervisor: self)
    }
}

extension IngredientFlowSupervisor: ParentSupervisor {
    func childDidEnd(supervisor child: Supervisor) {
        switch self.state {
        case .ingredientDetails(
            (let expected, _)
        ) where expected === child:
            self.endSelf()
        case .tagSelector(
            let ingredientDetails,
            let expected
        ) where expected === child:
            self.navigator
                .dismiss(
                    animated: true
                )
            self.state = .ingredientDetails(
                ingredientDetails
            )
        default:
            self.handle(
                error: .ingredientEndStateFailure
            )
        }
    }

    func recover(
        fromError error: AppError,
        on child: Supervisor?
    ) {
        self.handle(error: error)
    }

    private func handle(error: AppError) {
        switch self.state {
        case .ingredientDetails(let (ingredientDetails, detailsContainer)),
                .tagSelector(let (ingredientDetails, detailsContainer), _):
            _ = self.navigator
                .popToViewController(
                    detailsContainer,
                    animated: true
                )
            error.showAsAlert(on: self.navigator)
            self.state = .ingredientDetails(
                (ingredientDetails, detailsContainer)
            )
        default:
            self.parent?
                .recover(
                    fromError: error,
                    on: self
                )
        }
    }
}

extension IngredientFlowSupervisor: IngredientDetailsSupervisorParent {
    func navigateForDoneEditing(doneType: EditModeAction.DoneType) {
        self.parent?.navigate(forEditDoneType: doneType)
    }

    func navigateToTagSelector(forIngredient ingredient: Ingredient) {
        let container = UIViewController()
        let modalNavigation = UINavigationController(rootViewController: container)

        guard
            case .ingredientDetails(
                let ingredientDetails
            ) = self.state,
            let supervisor = IngredientTagSelectorSupervisor(
                container: container,
                navigationItem: container.navigationItem,
                initialTags: ingredient.tags,
                parent: self,
                content: self.content.tagSelectorContent
            )
        else {
            self.handle(
                error: .ingredientTagSelPushStateFailure
            )

            return
        }

        self.state = .tagSelector(
            ingredientDetails,
            supervisor
        )

        modalNavigation
            .presentationController?
            .delegate = self
        self.navigator
            .present(
                modalNavigation,
                animated: true
            )
    }

    func navigate(forEditDoneType doneType: EditModeAction.DoneType) {
        self.parent?.navigate(forEditDoneType: doneType)
    }

    func addToInventory(ingredient: Ingredient) {
        self.parent?.addToInventory(ingredient: ingredient)
    }
}

extension IngredientFlowSupervisor: TagSelectorSupervisorParent {
    func didSelect(tags: [Tag<Ingredient>]?) {
        switch self.state {
        case .tagSelector(let (ingredientDetails, container), _),
                .ingredientDetails(let (ingredientDetails, container)):
            self.handleTagUpdate(
                to: tags,
                for: ingredientDetails,
                in: container
            )
        default:
            self.handle(
                error: .ingredientTagSelectionStateFailure
            )
        }
    }

    private func handleTagUpdate(
        to tags: [Tag<Ingredient>]?,
        for detailsSupervisor: IngredientDetailsSupervisor,
        in container: UIViewController
    ) {
        if let tags {
            detailsSupervisor
                .updateTags(to: tags)
        }

        self.navigator
            .dismiss(animated: true)
        self.state = .ingredientDetails(
            (detailsSupervisor, container)
        )
    }
}

extension IngredientFlowSupervisor: UINavigationControllerDelegate {
    func navigationController(
        _ navigationController: UINavigationController,
        didShow viewController: UIViewController,
        animated: Bool
    ) {
        if let detailsViewController,
           !navigationController
            .viewControllers
            .contains(detailsViewController) {
            self.endSelf()
            self.oldNavigatorDelegate?.navigationController?(
                navigationController,
                didShow: viewController,
                animated: animated
            )
        }
    }
}

extension IngredientFlowSupervisor: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(
        _ presentationController: UIPresentationController
    ) {
        guard case let .tagSelector(
            details,
            _
        ) = self.state else {
            return
        }

        self.state = .ingredientDetails(details)
    }
}
