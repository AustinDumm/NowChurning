//
//  RecipesSupervisor.swift
//  NowChurning
//
//  Created by Austin Dumm on 3/21/23.
//

import UIKit
import CoreData
import Factory

protocol RecipesSupervisorParent: ParentSupervisor {
    func switchToEditing(ingredient: Ingredient)
    func switchToAdd(ingredient: Ingredient)
}

class RecipesSupervisor: NSObject {
    struct Content {
        let recipeListContent: RecipeListSupervisor.Content

        let editDetailsContent: RecipeFlowSupervisor.Content
        let createRecipeContent: RecipeFlowSupervisor.Content
    }

    private enum State {
        case myRecipes(
            (RecipeListSupervisor, UIViewController)
        )
        case addRecipe(
            (RecipeListSupervisor, UIViewController),
            RecipeFlowSupervisor
        )
        case recipeDetails(
            (RecipeListSupervisor, UIViewController),
            RecipeFlowSupervisor
        )
    }

    weak var parent: RecipesSupervisorParent?

    private let navigator: StackNavigation
    private let oldAccent: UIColor?
    private let rootTopController: UIViewController?
    private let content: Content

    @Injected(\.coreDataUserManager)
        private var userManager: CoreDataUserManager
    @Injected(\.managedObjectContext)
        private var managedObjectContext: NSManagedObjectContext

    private var state: State?

    private var listStore: RecipeListCoreDataStore? {
        switch self.state {
        case .myRecipes((let supervisor, _)),
                .recipeDetails((let supervisor, _), _),
                .addRecipe((let supervisor, _), _):
            return supervisor.modelStore
        case .none:
            return nil
        }
    }

    init?(
        parent: RecipesSupervisorParent?,
        navigator: StackNavigation,
        content: Content
    ) {
        self.parent = parent

        self.navigator = navigator
        self.rootTopController = self.navigator.topViewController

        self.oldAccent = self.navigator.view.tintColor
        UINavigationBar.appearance().tintColor = .Accent.recipes
        self.navigator.navigationBar.tintColor = .Accent.recipes
        self.navigator.view.tintColor = .Accent.recipes

        self.content = content

        super.init()

        let container = UIViewController()
        container.navigationItem.largeTitleDisplayMode = .never
        guard let supervisor = RecipeListSupervisor(
            container: container,
            navigationItem: container.navigationItem,
            parent: self,
            content: content.recipeListContent
        ) else {
            return nil
        }

        self.state = .myRecipes(
            (supervisor, container)
        )

        self.navigator.pushViewController(
            container,
            withAssociatedNavigationDelegate: self,
            animated: true
        )
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
        self.navigator.view.tintColor = self.oldAccent
        self.navigator.navigationBar.tintColor = self.oldAccent
        self.parent?.childDidEnd(supervisor: self)
    }
}

extension RecipesSupervisor: ParentSupervisor {
    func childDidEnd(supervisor child: Supervisor) {
        switch self.state {
        case .myRecipes(
            (let expected, let container)
        ) where expected === child:
            assert(container === self.navigator.topViewController)
            _ = self.navigator.popViewController(animated: true)
            self.endSelf()

        case .recipeDetails(
            let recipeListPair,
            let expected
        ) where expected === child:
            self.state = .myRecipes(recipeListPair)

        case .addRecipe(
            let recipeListPair,
            _
        ):
            self.navigator.dismiss(animated: true)
            self.state = .myRecipes(recipeListPair)

        default:
            self.errorExit(.myRecipesSupervisorEndStateFailure)
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
                    fromError: .myRecipesSupervisorEndStateFailure,
                    on: self
                )
            return
        }

        self.childDidEnd(supervisor: child)
    }

    func canEnd() -> Bool {
        switch self.state {
        case .myRecipes((let supervisor as Supervisor, _)),
                .recipeDetails(_, let supervisor as Supervisor),
                .addRecipe(_, let supervisor as Supervisor):
            return supervisor.canEnd()
        case .none:
            return true
        }
    }

    func requestEnd(
        onEnd: @escaping () -> Void
    ) {
        switch self.state {
        case .myRecipes((let supervisor as Supervisor, _)):
            supervisor.requestEnd(onEnd: onEnd)
        case .recipeDetails((let listSupervisor, _), let supervisor as Supervisor),
                .addRecipe((let listSupervisor, _), let supervisor as Supervisor):
            supervisor.requestEnd {
                listSupervisor.requestEnd(onEnd: onEnd)
            }
        case .none:
            AppError.myRecipesSupervisorEndStateFailure
                .showAsAlert(on: self.navigator)
            onEnd()
        }
    }
}

extension RecipesSupervisor: RecipeListSupervisorParent {
    func navigateToDetails(forRecipe recipe: Recipe) {
        guard let listStore = self.listStore else {
            self.errorExit(.myRecipesDetailPushStateFailure)
            return
        }

        switch self.state {
        case .myRecipes(
            let recipeListPair
        ):
            let supervisor = RecipeFlowSupervisor(
                parent: self,
                navigator: self.navigator,
                recipe: recipe,
                recipeListStore: listStore,
                content: self.content.editDetailsContent
            )

            self.state = .recipeDetails(
                recipeListPair,
                supervisor
            )
        default:
            self.errorExit(.myRecipesDetailPushStateFailure)
        }
    }

    func navigateToAddRecipe() {
        guard let listStore = self.listStore else {
            self.errorExit(.myRecipesDetailPushStateFailure)
            return
        }

        switch self.state {
        case .myRecipes(
            let recipeListPair
        ):
            let modalNavigation = StackNavigation()
            let supervisor = RecipeFlowSupervisor(
                parent: self,
                navigator: modalNavigation,
                recipeListStore: listStore,
                content: self.content.createRecipeContent
            )
            modalNavigation
                .presentationController?
                .delegate = self

            self.state = .addRecipe(
                recipeListPair,
                supervisor
            )

            self.navigator
                .present(modalNavigation, animated: true)

        default:
            self.errorExit(.myRecipesDetailPushStateFailure)
        }
    }
}

extension RecipesSupervisor: RecipeFlowSupervisorParent {
    func didFinishEdit(by finishType: EditModeAction.DoneType) {
        guard
            case let .addRecipe(
                recipeListPair,
                _
            ) = self.state
        else {
            return
        }

        self.navigator
            .dismiss(animated: true)

        self.state = .myRecipes(recipeListPair)
    }

    func didSave(recipe: Recipe) {
        switch self.state {
        case .none:
            break
        case .myRecipes((let listSupervisor, _)),
                .recipeDetails((let listSupervisor, _), _),
                .addRecipe((let listSupervisor, _), _):
            Task.detached { @MainActor in
                try await Task.sleep(nanoseconds: 500_000_000)
                listSupervisor.scrollTo(recipe: recipe)
            }
        }
    }

    func switchToEditing(ingredient: Ingredient) {
        self.parent?.switchToEditing(ingredient: ingredient)
    }

    func switchToAdd(ingredient: Ingredient) {
        self.parent?.switchToAdd(ingredient: ingredient)
    }
}

extension RecipesSupervisor: StackNavigationDelegate {
    func didDisconnectDelegate(fromNavigationController: StackNavigation) {
        self.endSelf()
    }
}

extension RecipesSupervisor: UIAdaptivePresentationControllerDelegate {
    func presentationControllerShouldDismiss(
        _ presentationController: UIPresentationController
    ) -> Bool {
        guard
            case let .addRecipe(_, supervisor) = self.state
        else {
            return true
        }

        return supervisor.canEnd()
    }

    func presentationControllerDidAttemptToDismiss(
        _ presentationController: UIPresentationController
    ) {
        guard
            case let .addRecipe(_, supervisor) = self.state
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
            case let .addRecipe(recipeListPair, _) = self.state
        else {
            return
        }

        self.state = .myRecipes(recipeListPair)
    }
}
