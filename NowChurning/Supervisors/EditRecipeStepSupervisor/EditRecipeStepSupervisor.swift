//
//  EditRecipeStepSupervisor.swift
//  NowChurning
//
//  Created by Austin Dumm on 7/9/23.
//

import UIKit

protocol EditRecipeStepSupervisorParent: ParentSupervisor {
    func saveStep(step: RecipeDetails.Step)
}

class EditRecipeStepSupervisor: NSObject, Supervisor {
    struct Content {
        let ingredientRecipeStepContent: RecipeStepDetailsSupervisor.Content
        let byTagsRecipeStepContent: RecipeStepDetailsSupervisor.Content
        let instructionStepContent: RecipeStepDetailsSupervisor.Content

        let ingredientListContent: ReadOnlyIngredientListSupervisor.Content
        let tagSelectorContent: TagSelectorContent
        let measurementContent: MeasurementEditSupervisor.Content
    }

    private enum State {
        case recipeStep((RecipeStepDetailsSupervisor, UIViewController))
        case pickIngredient(
            (RecipeStepDetailsSupervisor, UIViewController),
            ReadOnlyIngredientListSupervisor
        )
        case pickTags(
            (RecipeStepDetailsSupervisor, UIViewController),
            IngredientTagSelectorSupervisor
        )
        case editMeasurement(
            (RecipeStepDetailsSupervisor, UIViewController),
            MeasurementEditSupervisor
        )
    }

    weak var parent: EditRecipeStepSupervisorParent?

    private var state: State

    private let content: Content
    private let navigator: StackNavigation

    private let oldTop: UIViewController?

    init(
        navigator: StackNavigation,
        step: RecipeDetails.Step,
        parent: EditRecipeStepSupervisorParent? = nil,
        content: Content
    ) {
        self.navigator = navigator
        self.parent = parent
        self.content = content

        let detailsContent: RecipeStepDetailsSupervisor.Content
        switch step {
        case .ingredient:
            detailsContent = self.content.ingredientRecipeStepContent
        case .ingredientTags:
            detailsContent = self.content.byTagsRecipeStepContent
        case .instruction:
            detailsContent = self.content.instructionStepContent
        }

        // Create a new tag step, hit cancel as you select the amount of it. Doesn't cancel, softlocks the app

        let container = UIViewController()
        let supervisor = RecipeStepDetailsSupervisor(
            step: step,
            container: container,
            content: detailsContent
        )
        self.state = .recipeStep((supervisor, container))
        self.oldTop = self.navigator.topViewController

        super.init()

        supervisor.parent = self
        self.navigator.pushViewController(container, animated: true)
        self.navigator.pushDelegate(self)
    }

    func canEnd() -> Bool {
        true
    }

    func requestEnd(onEnd: @escaping () -> Void) {
        if let oldTop {
            self.navigator.popToViewController(oldTop, animated: true) { [weak self] in
                guard let self else { return }
                self.parent?.childDidEnd(supervisor: self)
            }
        } else {
            self.navigator.popToRootViewController(animated: true) { [weak self] in
                guard let self else { return }
                self.parent?.childDidEnd(supervisor: self)
            }
        }

        onEnd()
    }

    private func endSelf() {
        self.navigator.popDelegate()

        if let oldTop {
            self.navigator.popToViewController(oldTop, animated: true) { [weak self] in
                guard let self else { return }
                self.parent?.childDidEnd(supervisor: self)
            }
        } else {
            self.navigator.popToRootViewController(animated: true) { [weak self] in
                guard let self else { return }
                self.parent?.childDidEnd(supervisor: self)
            }
        }
    }
}

extension EditRecipeStepSupervisor: ParentSupervisor {
    func childDidEnd(supervisor: Supervisor) {
        switch self.state {
        case .recipeStep((let expected, _))
            where expected === supervisor:
            self.endSelf()

        case .pickIngredient(let stepPair, let expected)
            where expected === supervisor:
            self.navigator.dismiss(animated: true)
            self.state = .recipeStep(stepPair)

        case .editMeasurement(let stepPair, let expected)
            where expected === supervisor:
            self.navigator.dismiss(animated: true)
            self.state = .recipeStep(stepPair)

        case .pickTags(let stepPair, let expected)
            where expected === supervisor:
            self.navigator.dismiss(animated: true)
            self.state = .recipeStep(stepPair)

        case .recipeStep,
                .pickIngredient,
                .editMeasurement,
                .pickTags:
            self.parent?.recover(
                fromError: .recipeStepDetailsEndFailure,
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

extension EditRecipeStepSupervisor: RecipeStepDetailsSupervisorParent {
    func didEnd() {
        self.endSelf()
    }

    func saveStep(step: RecipeDetails.Step) {
        self.parent?.saveStep(step: step)
    }

    func edit(ingredient: Ingredient) {
        guard case .recipeStep(let stepPair) = self.state else {
            return
        }

        let container = UIViewController()
        let modalNavigation = UINavigationController(rootViewController: container)

        guard let listSupervisor = ReadOnlyIngredientListSupervisor(
            container: container,
            navigationItem: container.navigationItem,
            canAddIngredient: false,
            parent: self,
            content: self.content.ingredientListContent
        ) else {
            return
        }

        self.navigator.present(modalNavigation, animated: true)
        modalNavigation.presentationController?.delegate = self

        self.state = .pickIngredient(stepPair, listSupervisor)
    }

    func edit(tags: [Tag<Ingredient>]) {
        guard case .recipeStep(let stepPair) = self.state else {
            return
        }

        let container = UIViewController()
        let modalNavigation = UINavigationController(rootViewController: container)

        guard
            let supervisor = IngredientTagSelectorSupervisor(
                container: container,
                navigationItem: container.navigationItem,
                initialTags: tags,
                parent: self,
                content: self.content.tagSelectorContent
            )
        else {
            return
        }

        self.navigator.present(modalNavigation, animated: true)
        modalNavigation.presentationController?.delegate = self

        self.state = .pickTags(stepPair, supervisor)
    }

    func edit(measurement: MeasurementType) {
        guard case .recipeStep(let stepPair) = self.state else {
            return
        }

        let container = UIViewController()
        let modalNavigation = UINavigationController(rootViewController: container)

        let supervisor = MeasurementEditSupervisor(
            container: container,
            initialMeasure: measurement,
            parent: self,
            content: self.content.measurementContent
        )

        self.navigator.present(modalNavigation, animated: true)
        modalNavigation.presentationController?.delegate = self

        self.state = .editMeasurement(stepPair, supervisor)
    }
}

extension EditRecipeStepSupervisor: ReadOnlyIngredientListSupervisorParent {
    func navigateTo(ingredient: Ingredient) {
        guard case .pickIngredient(
            let (stepSupervisor, _),
            let pickSupervisor
        ) = self.state else {
            return
        }

        stepSupervisor.updateIngredient(to: ingredient)
        self.childDidEnd(supervisor: pickSupervisor)
    }

    func navigateToAddIngredient() { /* No Add Ingredient Supported */ }
}

extension EditRecipeStepSupervisor: MeasurementEditSupervisorParent {
    func updateMeasurement(to measurementType: MeasurementType) {
        guard case .editMeasurement((let stepSupervisor, _), _) = self.state else {
            return
        }

        stepSupervisor.updateMeasurement(to: measurementType)
    }
}

extension EditRecipeStepSupervisor: TagSelectorSupervisorParent {
    func didSelect(tags: [Tag<Ingredient>]?) {
        guard case .pickTags(let stepPair, let tagSupervisor) = self.state else {
            return
        }

        guard let tags else {
            self.childDidEnd(supervisor: tagSupervisor)
            return
        }

        stepPair.0.updateTags(to: tags)
        self.childDidEnd(supervisor: tagSupervisor)
    }
}

extension EditRecipeStepSupervisor: UIAdaptivePresentationControllerDelegate {
    func presentationControllerShouldDismiss(
        _ presentationController: UIPresentationController
    ) -> Bool {
        switch self.state {
        case .recipeStep((let supervisor, _)):
            return supervisor.canEnd()

        case .pickIngredient((let stepSupervisor, _), let pickSupervisor):
            return stepSupervisor.canEnd() && pickSupervisor.canEnd()

        case .pickTags((let stepSupervisor, _), let tagSupervisor):
            return stepSupervisor.canEnd() && tagSupervisor.canEnd()

        case .editMeasurement((let stepSupervisor, _), let measurementSupervisor):
            return stepSupervisor.canEnd() && measurementSupervisor.canEnd()
        }
    }

    func presentationControllerDidAttemptToDismiss(
        _ presentationController: UIPresentationController
    ) {
        switch self.state {
        case .recipeStep((let supervisor, _)):
            supervisor.requestEnd { [weak self] in
                self?.childDidEnd(supervisor: supervisor)
            }

        case .pickIngredient(let stepPair, let pickSupervisor):
            pickSupervisor.requestEnd { [weak self] in
                self?.navigator.dismiss(animated: true) {
                    self?.state = .recipeStep(stepPair)
                    stepPair.0.requestEnd {
                        self?.childDidEnd(supervisor: stepPair.0)
                    }
                }
            }

        case .pickTags(let stepPair, let tagSupervisor):
            tagSupervisor.requestEnd { [weak self] in
                self?.navigator.dismiss(animated: true) {
                    self?.state = .recipeStep(stepPair)
                    stepPair.0.requestEnd {
                        self?.childDidEnd(supervisor: stepPair.0)
                    }
                }
            }

        case .editMeasurement(let stepPair, let measurementSupervisor):
            measurementSupervisor.requestEnd { [weak self] in
                self?.navigator.dismiss(animated: true) {
                    self?.state = .recipeStep(stepPair)
                    stepPair.0.requestEnd {
                        self?.childDidEnd(supervisor: stepPair.0)
                    }
                }
            }
        }
    }

    func presentationControllerDidDismiss(
        _ presentationController: UIPresentationController
    ) {
        switch self.state {
        case .editMeasurement(let stepPair, _),
                .pickTags(let stepPair, _),
                .pickIngredient(let stepPair, _):
            self.state = .recipeStep(stepPair)
        case .recipeStep:
            break
        }
    }
}

extension EditRecipeStepSupervisor: UINavigationControllerDelegate {
    func navigationController(
        _ navigationController: UINavigationController,
        didShow viewController: UIViewController,
        animated: Bool
    ) {
        let container: UIViewController
        switch self.state {
        case .recipeStep((_, let viewController)):
            container = viewController

        case .pickIngredient, .pickTags, .editMeasurement:
            // Presented modally, not through NavController
            return
        }

        if !navigationController
            .viewControllers
            .contains(where: { $0 === container }) {
            self.endSelf()
            navigationController.delegate?.navigationController?(
                navigationController,
                didShow: viewController,
                animated: animated
            )
        }
    }
}
