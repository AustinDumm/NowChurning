//
//  RecipeDetailsApplication.swift
//  NowChurning
//
//  Created by Austin Dumm on 3/4/23.
//

import Foundation

protocol RecipeDetailsApplicationDelegate: AnyObject {
    func didFinishEdit(by finishType: EditModeAction.DoneType)
    func didSave(recipe: Recipe)
    func preview(step: RecipeDetails.Step)
    func editStep(forRecipe: Recipe, atIndex: Int)
    func addStep()
    func switchToAdd(ingredient: Ingredient)
}

class RecipeDetailsApplication {
    struct Content {
        var invalidityText: (Recipe.InvalidityReason) -> String
        var byTagPrefix: String
        var byTagEmpty: String
    }

    weak var displayModelSink: RecipeDetailsDisplayModelSink? {
        didSet {
            self.updateDisplayModelSink(
                model: self.editModeHelper.activeModel()
            )
            self.editModeHelper.editModeDisplayModelSink = displayModelSink
        }
    }
    weak var storeActionSink: RecipeDetailsStoreActionSink?

    weak var delegate: RecipeDetailsApplicationDelegate?

    private let content: Content

    var hasChanges: Bool {
        self.editModeHelper.hasChanges
    }

    private let editModeHelper: EditModeHelper<RecipeDetailsApplication>
    private var hasEditedSet = Set<PartialKeyPath<Recipe>>()

    init(content: Content) {
        self.content = content
        self.editModeHelper = .init(
            initialModel: .init(
                recipe: .init(name: "", description: ""),
                stockedIngredientIds: [:]
            )
        )
        self.editModeHelper.delegate = self
    }

    func attemptCancelExit() {
        self.confirmEditCancel(confirmAction: {
            self.delegate?.didFinishEdit(by: .cancel)
        })
    }

    func appendStep(_ step: RecipeDetails.Step) {
        self.editModeHelper.updateActiveModel { model in
            if model.recipe.recipeDetails == nil {
                model.recipe.recipeDetails = .init(steps: [step])
            } else {
                model.recipe.recipeDetails?.steps.append(step)
            }
        }
    }

    func replaceStep(at index: Int, with step: RecipeDetails.Step) {
        self.editModeHelper.updateActiveModel { model in
            model.recipe.recipeDetails?.steps[safe: index] = step
        }
    }

    private func updateDisplayModelSink(model: RecipeDetailsModel) {
        self.displayModelSink?
            .send(
                displayModel: Self.displayModel(
                    fromDomainModel: model,
                    hasEditedSet: self.hasEditedSet,
                    content: self.content
                )
            )
    }
}

extension RecipeDetailsApplication: RecipeDetailsActionSink {
    func send(action: RecipeDetailsAction) {
        switch action {
        case .editName(let newName):
            self.hasEditedSet.insert(\.name)
            self.editModeHelper
                .updateActiveModel { model in
                    model.recipe.name = newName
                }
        case .editDescription(let newDescription):
            self.hasEditedSet.insert(\.description)
            self.editModeHelper
                .updateActiveModel { model in
                    model.recipe.description = newDescription
                }

        case .selectStep(let selection):
            self.handleStepSelection(atIndex: selection)
        case .deleteStep(let index):
            self.handleStepDeletion(atIndex: index)
        case .moveStep(let from, let to):
            self.handleStepMove(from: from, to: to)

        case .addStep:
            self.delegate?.addStep()
        case .openInfo(forStep: let index):
            self.delegate?.editStep(
                forRecipe: self.editModeHelper.activeModel().recipe,
                atIndex: index
            )
        case .addToInventory(forStep: let step):
            self.handleAddToInventory(forStep: step)
        }
    }

    private func handleStepSelection(atIndex selection: Int) {
        guard
            !self.editModeHelper.isEditing,
            let recipe = self.editModeHelper.activeModel().recipe.recipeDetails
        else {
            return
        }

        if let step = recipe.steps[safe: selection] {
            self.delegate?.preview(step: step)
        }
    }

    private func handleStepDeletion(atIndex index: Int) {
        guard
            var newRecipe = self.editModeHelper.activeModel().recipe.recipeDetails,
            newRecipe.steps.indices.contains(index)
        else {
            return
        }

        newRecipe.steps.remove(at: index)

        if !self.editModeHelper.isEditing {
            self.editModeHelper.send(editModeAction: .startEditing)
        }

        self.editModeHelper.updateActiveModel { model in
            model.recipe.recipeDetails = newRecipe
        }
    }

    private func handleStepMove(from: Int, to: Int) {
        guard
            self.editModeHelper.isEditing,
            var newRecipe = self.editModeHelper.activeModel().recipe.recipeDetails,
            newRecipe.steps.indices.contains(from),
            newRecipe.steps.indices.contains(to)
        else {
            return
        }

        let step = newRecipe.steps.remove(at: from)
        newRecipe.steps.insert(step, at: to)

        self.editModeHelper.updateActiveModel { model in
            model.recipe.recipeDetails = newRecipe
        }
    }

    private func handleAddToInventory(forStep step: Int) {
        guard
            let step = self.editModeHelper.activeModel().recipe.recipeDetails?.steps[safe: step]
        else {
            return
        }

        switch step {
        case .ingredient(let measure)
            where self.isUnstocked(ingredient: measure.ingredient):
            self.delegate?.switchToAdd(ingredient: measure.ingredient)

        case .ingredientTags(let tags, _)
            where self.isUnstocked(tags: tags):
            self.delegate?.switchToAdd(ingredient: .init(
                name: "",
                description: "",
                tags: tags
            ))

        case .ingredient, .ingredientTags, .instruction:
            break
        }
    }

    private func isUnstocked(ingredient: Ingredient) -> Bool {
        !self.editModeHelper.activeModel().stockedIngredientIds.keys.contains(ingredient.id)
    }

    private func isUnstocked(tags: [Tag<Ingredient>]) -> Bool {
        !self.editModeHelper.activeModel().stockedIngredientIds.values.contains(where: { ingredient in
            Set(ingredient.tags).isSuperset(of: tags)
        })
    }

    func send(editModeAction: EditModeAction) {
        if case .startEditing = editModeAction {
            self.hasEditedSet = []
        }

        self.editModeHelper
            .send(editModeAction: editModeAction)
    }

    func confirmEditCancel(
        confirmAction: @escaping () -> Void
    ) {
        self.editModeHelper
            .cancelEditing()
    }
}

extension RecipeDetailsApplication: RecipeDetailsDomainModelSink {
    func send(domainModel: RecipeDetailsModel) {
        self.editModeHelper
            .updateStoredModel(toData: domainModel)
    }
}

// MARK: Model Transforms
extension RecipeDetailsApplication {
    private static func displayModel(
        fromDomainModel domainModel: RecipeDetailsModel,
        hasEditedSet: Set<PartialKeyPath<Recipe>>,
        content: Content
    ) -> RecipeDetailsDisplayModel {
        let recipe = domainModel.recipe
        let invalidityReasons = recipe.invalidityReasons

        let name: ValidatedData<String>
        if invalidityReasons.contains(.emptyName) && hasEditedSet.contains(\.name) {
            name = .invalid(
                recipe.name,
                .init(error: content.invalidityText(.emptyName))
            )
        } else {
            name = .valid(recipe.name)
        }

        return .init(
            name: name,
            description: recipe.description,
            recipeSteps: recipe
                .recipeDetails?
                .steps
                .map { Self.recipeText(
                    fromDomainModel: $0,
                    stockedIngredients: domainModel.stockedIngredientIds,
                    content: content
                ) } ?? []
        )
    }

    private static func recipeText(
        fromDomainModel domainModel: RecipeDetails.Step,
        stockedIngredients: [ID<Ingredient>: Ingredient],
        content: Content
    ) -> RecipeDetailsDisplayModel.RecipeStep {
        switch domainModel {
        case .ingredient(let measure):
            return .init(
                isStocked: stockedIngredients
                    .keys
                    .contains(measure.ingredient.id),
                canPreview: true,
                name: Self.measureText(fromDomainModel: measure)
            )
        case .ingredientTags(let tags, let amount):
            return .init(
                isStocked: Self.isByTagStocked(
                    tags: tags,
                    stockedIngredients: stockedIngredients
                ),
                canPreview: true,
                name: Self.tagText(
                    fromTags: tags,
                    measurement: amount,
                    content: content
                )
            )
        case .instruction(let instruction):
            return .init(
                isStocked: true,
                canPreview: false,
                name: instruction
            )
        }
    }

    private static func measureText(
        fromDomainModel domainModel: Measure
    ) -> String {
        self.formatStep(
            stepText: domainModel.ingredient.name,
            measurement: domainModel.measure
        )
    }

    private static func tagText(
        fromTags tags: [Tag<Ingredient>],
        measurement: MeasurementType,
        content: Content
    ) -> String {
        if tags.isEmpty {
            return self.formatStep(
                stepText: content.byTagEmpty,
                measurement: measurement
            )
        } else {
            return self.formatStep(
                stepText:
                    content.byTagPrefix + " " +
                    tags.map { "#\($0.name)" }.joined(separator: ", "),
                measurement: measurement
            )
        }
    }

    private static func isByTagStocked(
        tags: [Tag<Ingredient>],
        stockedIngredients: [ID<Ingredient>: Ingredient]
    ) -> Bool {
        stockedIngredients.values.contains { ingredient in
            Set(ingredient.tags).isSuperset(of: tags)
        }
    }

    private static func formatStep(
        stepText: String,
        measurement: MeasurementType
    ) -> String {
        switch measurement {
        case .any:
            return stepText
        case .count(let measurement, let description):
            return [
                NumberFormatter
                    .countFormatter
                    .string(from: measurement.value as NSNumber) ?? String(measurement.value),
                description,
                "-",
                stepText,
            ].compactMap { $0 }.joined(separator: " ")
        case .volume(let measurement):
            let volumeText = MeasurementFormatter
                .volumeFormatter
                .string(from: measurement)
            return "\(volumeText) - \(stepText)"
        }
    }
}

extension RecipeDetailsApplication: EditModeHelperDelegate {
    func sendDisplayModel(
        fromDomain recipe: RecipeDetailsModel,
        isEditing: Bool
    ) {
        self.updateDisplayModelSink(model: recipe)
    }

    func onEditEnd(withDoneType doneType: EditModeAction.DoneType) {
        if doneType == .save {
            self.delegate?.didSave(recipe: self.editModeHelper.activeModel().recipe)
        }

        self.delegate?.didFinishEdit(by: doneType)
    }

    func isValid(model: RecipeDetailsModel) -> Bool {
        model.recipe.isValid
    }

    func save(model: RecipeDetailsModel) {
        self.storeActionSink?
            .send(
                action: .save(
                    recipe: model.recipe
                )
            )
    }
}
