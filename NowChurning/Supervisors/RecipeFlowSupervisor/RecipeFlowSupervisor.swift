//
//  RecipeFlowSupervisor.swift
//  NowChurning
//
//  Created by Austin Dumm on 3/4/23.
//

import UIKit
import Factory

protocol RecipeFlowSupervisorParent: ParentSupervisor {
    func didFinishEdit(by finishType: EditModeAction.DoneType)
    func didSave(recipe: Recipe)
    func switchToEditing(ingredient: Ingredient)
    func switchToAdd(ingredient: Ingredient)
}

class RecipeFlowSupervisor: NSObject, Supervisor {
    struct Content {
        let recipeDetailsContent: RecipeDetailsSupervisor.Content
        let previewContent: RecipeStepPreviewSupervisor.Content
        let addStepContent: AddRecipeStepSupervisor.Content
        let editStepContent: EditRecipeStepSupervisor.Content
    }

    private enum State {
        case recipeDetails((RecipeDetailsSupervisor, UIViewController))
        case stepPreview(
            (RecipeDetailsSupervisor, UIViewController),
            RecipeStepPreviewSupervisor
        )
        case addStep(
            (RecipeDetailsSupervisor, UIViewController),
            AddRecipeStepSupervisor
        )
        case editStep(
            (RecipeDetailsSupervisor, UIViewController),
            (EditRecipeStepSupervisor, Int)
        )
    }

    private weak var parent: RecipeFlowSupervisorParent?
    private let navigator: StackNavigation
    private let topViewController: UIViewController?

    private var state: State?
    private let recipeListStore: RecipeListCoreDataStore
    private let content: Content
    private var recipeContainer: UIViewController? {
        switch self.state {
        case .recipeDetails((_, let container)),
                .stepPreview((_, let container), _),
                .addStep((_, let container), _),
                .editStep((_, let container), _):
            return container
        case .none:
            return nil
        }
    }

    init(
        parent: RecipeFlowSupervisorParent,
        navigator: StackNavigation,
        recipe: Recipe? = nil,
        recipeListStore: RecipeListCoreDataStore,
        content: Content
    ) {
        self.parent = parent
        self.content = content
        self.navigator = navigator
        self.topViewController = navigator.topViewController
        self.recipeListStore = recipeListStore

        super.init()

        let container = UIViewController()
        self.state = .recipeDetails(
            (.init(
                container: container,
                navigationItem: container.navigationItem,
                parent: self,
                recipe: recipe,
                recipeListStore: recipeListStore,
                content: content.recipeDetailsContent
            ), container)
        )

        self.navigator.pushDelegate(self)
        self.navigator
            .pushViewController(
                container,
                animated: true
            )
    }

    func canEnd() -> Bool {
        switch self.state {
        case .recipeDetails((let supervisor, _)):
            return supervisor.canEnd()

        case .stepPreview((let detailsSupervisor, _), let previewSupervisor):
            return detailsSupervisor.canEnd() && previewSupervisor.canEnd()

        case .addStep((let detailsSupervisor, _), let addStepSupervisor):
            return detailsSupervisor.canEnd() && addStepSupervisor.canEnd()

        case .editStep((let detailsSupervisor, _), (let editStepSupervisor, _)):
            return detailsSupervisor.canEnd() && editStepSupervisor.canEnd()
        case .none:
            return true
        }
    }

    func requestEnd(
        onEnd: @escaping () -> Void
    ) {
        switch self.state {
        case .recipeDetails(let (supervisor, _)):
            supervisor.requestEnd(onEnd: onEnd)

        case .stepPreview(let (supervisor, _), let preview):
            preview.requestEnd { [weak self] in
                self?.navigator.dismiss(animated: true) {
                    supervisor.requestEnd(onEnd: onEnd)
                }
            }

        case .addStep(let (supervisor, _), let addStep):
            addStep.requestEnd { [weak self] in
                self?.navigator.dismiss(animated: true) {
                    supervisor.requestEnd(onEnd: onEnd)
                }
            }

        case .editStep(
            (let supervisor, _),
            (let addStep, _)
        ):
            addStep.requestEnd {
                supervisor.requestEnd(onEnd: onEnd)
            }

        case .none:
            self.parent?.recover(
                fromError: .recipeFlowEndStateFailure,
                on: self
            )
        }
    }

    private func handle(error: AppError) {
        switch error {
        case .recipeFlowEndStateFailure:
            guard let topViewController = self.topViewController else {
                self.parent?
                    .recover(
                        fromError: error,
                        on: self
                    )
                return
            }

            _ = self.navigator
                .popToViewController(
                    topViewController,
                    animated: true
                )
            error.showAsAlert(on: self.navigator)
            self.endSelf()
        default:
            self.parent?
                .recover(
                    fromError: error,
                    on: self
                )
        }
    }

    private func endSelf() {
        self.navigator.popDelegate()
        self.parent?.childDidEnd(supervisor: self)
    }
}

extension RecipeFlowSupervisor: RecipeDetailsSupervisorParent {
    func childDidEnd(supervisor child: Supervisor) {
        switch self.state {
        case .recipeDetails(
            let (expected, container)
        ) where expected === child:
            if self.navigator.topViewController === container {
                _ = self.navigator
                    .popViewController(animated: true)
                self.endSelf()
            } else {
                self.handle(error: .recipeFlowEndStateFailure)
            }

        case .stepPreview(
            let detailsPair,
            let expected
        ) where expected === child:
            self.recipeListStore.send(storeAction: .refresh)
            detailsPair.0.refresh()
            self.state = .recipeDetails(detailsPair)

        case .addStep(
            let detailsPair,
            let expected
        ) where expected === child:
            detailsPair.0.refresh()
            self.navigator.dismiss(animated: true)
            self.state = .recipeDetails(detailsPair)

        case .editStep(
            let detailsPair,
            (let expected, _)
        ) where expected === child:
            detailsPair.0.refresh()
            self.state = .recipeDetails(detailsPair)

        default:
            self.handle(error: .recipeFlowEndStateFailure)
        }
    }

    func recover(
        fromError error: AppError,
        on child: Supervisor?
    ) {
        self.handle(error: error)
    }

    func didFinishEdit(by finishType: EditModeAction.DoneType) {
        self.parent?
            .didFinishEdit(by: finishType)
    }

    func didSave(recipe: Recipe) {
        self.parent?.didSave(recipe: recipe)
    }

    func preview(step: RecipeDetails.Step) {
        guard case let .recipeDetails(detailsPair) = self.state else {
            return
        }

        guard let previewSupervisor = RecipeStepPreviewSupervisor(
            parent: self,
            navigator: self.navigator,
            recipeStep: step,
            content: self.content.previewContent
        ) else {
            return
        }

        self.state = .stepPreview(
            detailsPair,
            previewSupervisor
        )
    }

    func addStep() {
        guard case let .recipeDetails(detailsPair) = self.state else {
            return
        }

        let modalNavigation = StackNavigation()

        let addStepSupervisor = AddRecipeStepSupervisor(
            navigator: modalNavigation,
            parent: self,
            content: self.content.addStepContent
        )

        modalNavigation.presentationController?.delegate = self

        self.navigator.present(modalNavigation, animated: true)
        self.state = .addStep(detailsPair, addStepSupervisor)
    }

    func editStep(forRecipe recipe: Recipe, atIndex index: Int) {
        guard
            case .recipeDetails(let detailsPair) = self.state,
            let step = recipe.recipeDetails?.steps[safe: index]
        else {
            return
        }

        let editStepSupervisor = EditRecipeStepSupervisor(
            navigator: self.navigator,
            step: step,
            parent: self,
            content: self.content.editStepContent
        )

        self.state = .editStep(
            detailsPair,
            (editStepSupervisor, index)
        )
    }
}

extension RecipeFlowSupervisor: MeasurePreviewSupervisorParent {
    func switchToEditing(ingredient: Ingredient) {
        self.navigator.dismiss(
            animated: true
        ) { [weak self] in
            self?.parent?.switchToEditing(ingredient: ingredient)
        }
    }
}

extension RecipeFlowSupervisor: RecipeStepPreviewSupervisorParent {
    func navigateToIngredient(_ ingredient: Ingredient) {
        self.navigator.dismiss(animated: true) { [weak self] in
            self?.parent?.switchToEditing(ingredient: ingredient)
        }
    }

    func switchToAdd(ingredient: Ingredient) {
        self.navigator.dismiss(animated: true) { [weak self] in
            self?.parent?.switchToAdd(ingredient: ingredient)
        }
    }
}

extension RecipeFlowSupervisor: AddRecipeStepSupervisorParent {
    func addIngredientStep(measure: Measure) {
        guard case let .addStep((detailsSupervisor, _), _) = self.state else {
            return
        }

        detailsSupervisor.appendStep(.ingredient(measure))
    }

    func addByTagStep(tags: [Tag<Ingredient>], measurementType: MeasurementType) {
        guard case let .addStep((detailsSupervisor, _), _) = self.state else {
            return
        }

        detailsSupervisor.appendStep(.ingredientTags(tags, measurementType))
    }

    func addInstructionStep(instruction: String) {
        guard case let .addStep((detailsSupervisor, _), _) = self.state else {
            return
        }

        detailsSupervisor.appendStep(.instruction(instruction))
    }
}

extension RecipeFlowSupervisor: EditRecipeStepSupervisorParent {
    func saveStep(step: RecipeDetails.Step) {
        guard case .editStep(
            let (detailsSupervisor, _),
            let (_, stepIndex)
        ) = self.state else {
            return
        }

        detailsSupervisor.replaceStep(at: stepIndex, with: step)
    }
}

extension RecipeFlowSupervisor: UINavigationControllerDelegate {
    func navigationController(
        _ navigationController: UINavigationController,
        didShow viewController: UIViewController,
        animated: Bool
    ) {
        guard let recipeContainer else {
            self.handle(error: .recipeFlowEndStateFailure)
            return
        }

        if !navigationController
            .viewControllers
            .contains(recipeContainer) {
            self.endSelf()
            navigationController.delegate?.navigationController?(
                navigationController,
                didShow: viewController,
                animated: animated
            )
        }
    }
}

extension RecipeFlowSupervisor: UIAdaptivePresentationControllerDelegate {
    // TODO: Implement swipe down support
}
