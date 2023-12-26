//
//  MainFlowSupervisor.swift
//  NowChurning
//
//  Created by Austin Dumm on 2/16/23.
//

import UIKit
import CoreData
import Factory

class MainFlowSupervisor: NSObject, Supervisor {
    struct Content {
        let mainScreenContent: MainScreenSupervisor.Content

        let inventoryContent: InventorySupervisor.Content
        let myRecipesContent: RecipesSupervisor.Content
    }

    private enum FlowState {
        case mainScreen(
            MainScreenSupervisor
        )

        case inventory(
            MainScreenSupervisor,
            InventorySupervisor
        )

        case myRecipes(
            MainScreenSupervisor,
            RecipesSupervisor
        )
    }

    private let window: UIWindow
    @Injected(\.coreDataUserManager)
        private var userManager: CoreDataUserManager
    @Injected(\.managedObjectContext)
        private var managedObjectContext: NSManagedObjectContext

    private let navigator: UINavigationController
    private var state: FlowState

    private let content: Content

    init(
        window: UIWindow,
        content: Content
    ) {
        self.window = window

        self.navigator = UINavigationController()
        self.navigator.navigationBar.prefersLargeTitles = true

        self.window.rootViewController = self.navigator

        let mainScreenSupervisor = MainScreenSupervisor(
            navigator: self.navigator,
            content: content.mainScreenContent
        )
        self.window.makeKeyAndVisible()

        self.state = .mainScreen(mainScreenSupervisor)
        self.content = content

        super.init()

        mainScreenSupervisor.navigationHandler = self
    }

    func canEnd() -> Bool {
        false
    }

    func requestEnd(
        onEnd _: @escaping () -> Void
    ) {
        assertionFailure("MainFlowSupervisor should never be requested to end.")
    }
}

extension MainFlowSupervisor: MainScreenAppNavDelegate {
    func navigateTo(action: MainScreenApplication.Action) {
        switch action {
        case .inventory:
            self.openInventory()
        case .myRecipes:
            self.openMyRecipes()
        }
    }

    private func openInventory() {
        let inventorySupervisor = InventorySupervisor(
            parent: self,
            navigator: self.navigator,
            content: self.content.inventoryContent
        )

        guard
            case let .mainScreen(
                mainScreenSupervisor
            ) = self.state,
            inventorySupervisor.start()
        else {
            self.handle(error: .mainInventoryPushStateFailure)
            return
        }

        self.state = .inventory(
            mainScreenSupervisor,
            inventorySupervisor
        )
    }

    private func openMyRecipes() {
        guard
            case let .mainScreen(
                mainScreenSupervisor
            ) = self.state,
            let myRecipesSupervisor = RecipesSupervisor(
                parent: self,
                navigator: self.navigator,
                content: self.content.myRecipesContent
            )
        else {
            self.handle(error: .mainMyRecipesPushStateFailure)
            return
        }

        self.state = .myRecipes(
            mainScreenSupervisor,
            myRecipesSupervisor
        )
    }
}

extension MainFlowSupervisor: ParentSupervisor {
    func childDidEnd(supervisor child: Supervisor) {
        switch self.state {
        case .inventory(
            let mainScreenSupervisor,
            let expected
        ) where expected === child:
            self.state = .mainScreen(mainScreenSupervisor)

        case .myRecipes(
            let mainScreen,
            let expected
        ) where expected === child:
            self.state = .mainScreen(
                mainScreen
            )

        default:
            self.handle(error: .mainEndStateFailure)
        }
    }

    func recover(
        fromError error: AppError,
        on child: Supervisor?
    ) {
        self.handle(error: error)
    }

    private func handle(error: AppError) {
        _ = self.navigator
            .popToRootViewController(animated: true)
        switch self.state {
        case .mainScreen(let mainScreen),
                .inventory(let mainScreen, _),
                .myRecipes(let mainScreen, _):
            self.state = .mainScreen(mainScreen)
        }

        error.showAsAlert(on: self.navigator)
    }
}

extension MainFlowSupervisor: RecipesSupervisorParent {
    func switchToEditing(ingredient: Ingredient) {
        guard case let .myRecipes(mainScreen, _) = self.state else {
            return
        }

        self.state = .mainScreen(mainScreen)
        self.navigator.popToRootViewController(animated: true) { [weak self] in
            guard let self else {
                return
            }

            let inventory = InventorySupervisor(
                parent: self,
                navigator: self.navigator,
                content: self.content.inventoryContent
            )

            guard inventory.startEdit(ingredient: ingredient) else {
                return
            }

            self.state = .inventory(mainScreen, inventory)
        }
    }

    func switchToAdd(ingredient: Ingredient) {
        guard case let .myRecipes(mainScreen, _) = self.state else {
            return
        }

        self.state = .mainScreen(mainScreen)
        self.navigator.popToRootViewController(animated: true) { [weak self] in
            guard let self else {
                return
            }

            let inventory = InventorySupervisor(
                parent: self,
                navigator: self.navigator,
                content: self.content.inventoryContent
            )

            guard inventory.startAdd(ingredient: ingredient) else {
                return
            }

            self.state = .inventory(mainScreen, inventory)
        }
    }
}
