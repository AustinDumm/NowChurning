//
//  IngredientListApplication.swift
//  NowChurning
//
//  Created by Austin Dumm on 10/22/22.
//

import Foundation

protocol IngredientListAppNavDelegate: AnyObject {
    func navigateTo(
        ingredient: Ingredient
    )

    func navigateToAddIngredient()
}

class IngredientListApplication {
    // MARK: Out Dependencies
    weak var displayModelSink: IngredientListDisplayModelSink? {
        didSet {
            self.editModeHelper.editModeDisplayModelSink = displayModelSink
            self.onDisplayModelSinkUpdate()
        }
    }

    weak var storeActionSink: IngredientListStoreActionSink?
    weak var delegate: IngredientListAppNavDelegate?

    let editModeHelper: EditModeHelper<IngredientListApplication>

    var hasChanges: Bool {
        self.editModeHelper.hasChanges
    }

    init(delegate: IngredientListAppNavDelegate? = nil) {
        self.delegate = delegate
        self.editModeHelper = .init(initialModel: [])

        self.editModeHelper.delegate = self
    }

    // MARK: DidSet Event Handlers
    private func onDisplayModelSinkUpdate() {
        self.sendDisplayModel(model: self.editModeHelper.activeModel())
    }

    // MARK: Senders
    private func sendDisplayModel(
        model: [Ingredient]
    ) {
        self.displayModelSink?
            .send(displayModel: Self.displayModel(
                fromDomainModel: model
            ))
    }
}

extension IngredientListApplication: EditModeHelperDelegate {
    func sendDisplayModel(
        fromDomain data: [Ingredient],
        isEditing _: Bool
    ) {
        self.sendDisplayModel(model: data)
    }

    func onEditEnd(withDoneType: EditModeAction.DoneType) {}

    func isValid(model _: [Ingredient]) -> Bool {
        true
    }

    func save(model: [Ingredient]) {
        self.storeActionSink?.send(
            action: .save(
                ingredients: model,
                saver: self
            )
        )
    }
}

// MARK: Model Transforms
extension IngredientListApplication {
    private static func displayModel(
        fromDomainModel model: [Ingredient]
    ) -> IngredientListDisplayModel {
        let groupedModel = groupModel(model)

        return .init(
            inventorySections: groupedModel
                .map {
                    .init(title: $0,
                          items: $1.map { item in
                            .init(
                                id: item.id.convert(),
                                title: item.name
                            )
                        }
                    )
                }
        )
    }

    private static func groupModel(
        _ model: [Ingredient]
    ) -> [(String, [Ingredient])] {
        let groupedDict = Dictionary(
            grouping: model) { ingredient in
                String(ingredient.name.first!)
            }

        return groupedDict
            .map { firstCharacter, ingredients in
                (firstCharacter, ingredients.sorted())
            }
            .sorted { $0.0 < $1.0 }
    }
}

extension IngredientListApplication: IngredientListActionSink {
    func send(action: IngredientListAction) {
        switch action {
        case .selectItem(
            inSection: let section,
            atIndex: let index
        ):
            self.selectItem(
                inSection: section,
                atIndex: index
            )
        case .deleteItem(
            inSection: let section,
            atIndex: let index
        ):
            self.editModeHelper.isEditing = true
            self.deleteItem(
                inSection: section,
                atIndex: index
            )
        case .newIngredient:
            self.delegate?.navigateToAddIngredient()
        }
    }

    func send(editModeAction: EditModeAction) {
        self.editModeHelper.send(editModeAction: editModeAction)
    }

    private func selectItem(
        inSection section: Int,
        atIndex index: Int
    ) {
        guard
            let ingredient = self.ingredient(
                fromGroupedSection: section,
                atIndex: index
            )
        else {
            return
        }

        self.delegate?.navigateTo(
            ingredient: ingredient
        )
    }

    private func deleteItem(
        inSection section: Int,
        atIndex index: Int
    ) {
        guard
            let ingredientToDelete = self.ingredient(
                fromGroupedSection: section,
                atIndex: index
            )
        else {
            return
        }

        self.editModeHelper
            .updateActiveModel { model in
                self.deleteItem(
                    ingredientToDelete: ingredientToDelete,
                    fromModel: &model
                )
            }
    }

    private func deleteItem(
        ingredientToDelete: Ingredient,
        fromModel model: inout [Ingredient]
    ) {
        guard
            let indexToDelete = model.firstIndex(of: ingredientToDelete)
        else {
            return
        }

        model.remove(at: indexToDelete)
    }

    private func ingredient(
        fromGroupedSection section: Int,
        atIndex index: Int
    ) -> Ingredient? {
        let groupedModel = Self.groupModel(self.editModeHelper.activeModel())
        let section = groupedModel[safe: section]

        return section?.1[safe: index]
    }
}

extension IngredientListApplication: IngredientListDomainModelSink {
    func send(domainModel model: [Ingredient]) {
        self.editModeHelper
            .updateStoredModel(toData: model)
    }
}
