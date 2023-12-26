//
//  IngredientDetailsApplication.swift
//  NowChurning
//
//  Created by Austin Dumm on 12/16/22.
//

import Foundation

protocol IngredientDetailsApplicationDelegate: AnyObject {
    func requestEditTags(forIngredient: Ingredient)
    func addToInventory(ingredient: Ingredient)
    func navigate(forEditDoneType: EditModeAction.DoneType)
    func exit()
}

class IngredientDetailsApplication {
    struct Content {
        var invalidityText: (Ingredient.InvalidityReason) -> String
        var existingNameInvalidDescription: String
        var existingNameInvalidSuggestion: String
    }

    // MARK: Display Dependencies
    weak var displayModelSink: IngredientDetailsDisplayModelSink? {
        didSet {
            self.onSetIngredientDisplayModelSink()
            self.editModeHelper
                .editModeDisplayModelSink = displayModelSink
        }
    }


    // MARK: Persistance Dependencies
    weak var domainModelStore: IngredientStoreActionSink?


    // MARK: Local Models
    private let editModeHelper: EditModeHelper<IngredientDetailsApplication>
    private var hasEditedSet = Set<PartialKeyPath<Ingredient>>()
    private let canResolveNameError: Bool
    private let content: Content

    weak var delegate: IngredientDetailsApplicationDelegate?

    var hasChanges: Bool {
        self.editModeHelper.hasChanges
    }

    init(
        content: Content,
        canResolveNameError: Bool = true,
        delegate: IngredientDetailsApplicationDelegate? = nil
    ) {
        self.content = content
        self.canResolveNameError = canResolveNameError
        self.editModeHelper = .init(initialModel: .init(
            ingredient: .init(
                name: "",
                description: "",
                tags: []
            ),
            usedNames: [:]
        ))
        self.editModeHelper.delegate = self
        self.delegate = delegate
    }

    func setTags(_ tags: [Tag<Ingredient>]) {
        self.hasEditedSet.insert(\.tags)
        self.editModeHelper
            .updateActiveModel { model in
                model.ingredient.tags = tags
            }
    }

    // MARK: DidSet Event Handlers
    private func onSetIngredientDisplayModelSink() {
        self.sendIngredientDisplayModel(
            model: self.editModeHelper.activeModel()
        )
    }

    // MARK: Senders
    private func sendIngredientDisplayModel(model: IngredientDetailsStoredModel) {
        self.displayModelSink?
            .send(ingredientDisplayModel: Self.displayModel(
                fromDomainModel: model,
                hasEditedSet: self.hasEditedSet,
                canResolveNameError: self.canResolveNameError,
                content: self.content
            ))
    }
}

// MARK: Model Transforms
extension IngredientDetailsApplication {
    private static func displayModel(
        fromDomainModel domainModel: IngredientDetailsStoredModel,
        hasEditedSet: Set<PartialKeyPath<Ingredient>>,
        canResolveNameError: Bool,
        content: Content
    ) -> IngredientDetailsDisplayModel {
        let ingredient = domainModel.ingredient
        let invalidityReasons = ingredient.invalidityReasons

        let name: ValidatedData<String>
        if invalidityReasons.contains(.emptyName) && hasEditedSet.contains(\.name) {
            name = .invalid(
                ingredient.name,
                .init(error: content.invalidityText(.emptyName))
            )
        } else if domainModel.usedNames[ingredient.name] != ingredient.id && hasEditedSet.contains(\.name) {
            name = .invalid(
                ingredient.name,
                .init(
                    error: content.existingNameInvalidDescription,
                    suggestion: canResolveNameError ? content.existingNameInvalidSuggestion : ""
                )
            )
        } else {
            name = .valid(ingredient.name)
        }

        return IngredientDetailsDisplayModel(
            name: name,
            description: ingredient.description,
            tagNames: ingredient.tags.map { $0.name }
        )
    }
}

extension IngredientDetailsApplication: EditModeHelperDelegate {
    func sendDisplayModel(
        fromDomain model: IngredientDetailsStoredModel,
        isEditing: Bool
    ) {
        let displayModel = Self.displayModel(
            fromDomainModel: model,
            hasEditedSet: self.hasEditedSet,
            canResolveNameError: self.canResolveNameError,
            content: self.content
        )

        self.displayModelSink?
            .send(
                ingredientDisplayModel: displayModel
            )
    }

    func onEditEnd(withDoneType doneType: EditModeAction.DoneType) {
        self.delegate?
            .navigate(forEditDoneType: doneType)
    }

    func isValid(model: IngredientDetailsStoredModel) -> Bool {
        model.ingredient.isValid &&
        self.isNameUnique(model: model)
    }

    private func isNameUnique(model: IngredientDetailsStoredModel) -> Bool {
        model.usedNames[model.ingredient.name].map { $0 == model.ingredient.id } ?? true
    }

    func save(model: IngredientDetailsStoredModel) {
        self.domainModelStore?
            .send(
                action: .save(ingredient: model.ingredient)
            )
    }
}

extension IngredientDetailsApplication: IngredientDomainModelSink {
    func send(domainModel: IngredientDetailsStoredModel) {
        self.editModeHelper
            .updateStoredModel(toData: domainModel)
    }
}

extension IngredientDetailsApplication: IngredientDetailsActionSink {
    func send(
        editModeAction action: EditModeAction
    ) {
        if case .startEditing = action {
            self.hasEditedSet = []
        }

        self.editModeHelper
            .send(editModeAction: action)
    }

    func send(
        ingredientAction action: IngredientDetailsAction
    ) {
        switch action {
        case .edit(let edit):
            self.editModeHelper
                .updateActiveModel { model in
                    switch edit {
                    case .name(let name):
                        self.hasEditedSet.insert(\.name)
                        model.ingredient.name = name
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                    case .description(let description):
                        self.hasEditedSet.insert(\.description)
                        model.ingredient.description = description
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                }
        case .action(let action):
            switch action {
            case .addTag:
                self.delegate?.requestEditTags(
                    forIngredient: self.editModeHelper.activeModel().ingredient
                )
            case .addToInventory:
                self.delegate?.addToInventory(ingredient: self.editModeHelper.activeModel().ingredient)
            case .exit:
                self.delegate?.exit()
            case .nameFooterTap:
                break
            }
        }
    }

    func cancelEditing(
        confirmAction: @escaping () -> Void
    ) {
        self.editModeHelper.cancelEditing()
    }
}
