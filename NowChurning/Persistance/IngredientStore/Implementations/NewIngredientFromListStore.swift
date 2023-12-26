//
//  NewIngredientFromListStore.swift
//  NowChurning
//
//  Created by Austin Dumm on 12/28/22.
//

import Foundation

class NewIngredientFromListStore {
    private let modelSink: IngredientDomainModelSink?
    private let storeSink: IngredientListStoreActionSink

    private let initialIngredient: Ingredient

    private var ingredientList: [Ingredient]?

    init(
        initialIngredient: Ingredient = .init(
            name: "",
            description: "",
            tags: []
        ),
        modelSink: IngredientDomainModelSink?,
        storeSink: IngredientListStoreActionSink
    ) {
        self.initialIngredient = initialIngredient

        self.modelSink = modelSink
        self.storeSink = storeSink

        self.modelSink?.send(
            domainModel: .init(
                ingredient: self.initialIngredient,
                usedNames: [:]
            )
        )
    }
}

extension NewIngredientFromListStore: IngredientListDomainModelSink {
    func send(
        domainModel: [Ingredient]
    ) {
        self.ingredientList = domainModel
        self.modelSink?.send(
            domainModel: .init(
                ingredient: self.initialIngredient,
                usedNames: Dictionary(
                    domainModel.map { ($0.name, $0.id) }
                ) { first, _ in first }
            )
        )
    }
}

extension NewIngredientFromListStore: IngredientStoreActionSink {
    func send(action: IngredientStoreAction) {
        switch action {
        case .save(let ingredient):
            guard
                var ingredientList = self.ingredientList
            else {
                return
            }

            if let replaceIndex = ingredientList.firstIndex(
                where: { $0.id == ingredient.id }
            ) {
                ingredientList[replaceIndex] = ingredient
            } else {
                ingredientList.append(ingredient)
            }

            self.ingredientList = ingredientList
            self.storeSink
                .send(
                    action: .save(
                        ingredients: ingredientList,
                        saver: self
                    )
                )
        }
    }
}
