//
//  IngredientFromListStore.swift
//  NowChurning
//
//  Created by Austin Dumm on 12/19/22.
//

import Foundation

class IngredientFromListStore {
    private let modelSink: IngredientDomainModelSink
    private let storeSink: IngredientListStoreActionSink

    private var ingredientList: [Ingredient]?
    private let id: ID<Ingredient>

    init(
        id: ID<Ingredient>,
        modelSink: IngredientDomainModelSink,
        storeSink: IngredientListStoreActionSink
    ) {
        self.id = id
        self.modelSink = modelSink
        self.storeSink = storeSink
    }
}

extension IngredientFromListStore: IngredientListDomainModelSink {
    func send(
        domainModel: [Ingredient]
    ) {
        guard
            let ingredient = domainModel.first(where: { $0.id == self.id})
        else {
            return
        }

        let namesLookup = Dictionary(
            domainModel.map { ($0.name, $0.id) }
        ) { first, _ in first }

        self.ingredientList = domainModel
        self.modelSink.send(
            domainModel: .init(
                ingredient: ingredient,
                usedNames: namesLookup
            )
        )
    }
}

extension IngredientFromListStore: IngredientStoreActionSink {
    func send(action: IngredientStoreAction) {
        switch action {
        case .save(let ingredient):
            guard var ingredientList = self.ingredientList,
                  let replaceIndex
                    = ingredientList.firstIndex(where: { $0.id == ingredient.id }) else {
                return
            }

            ingredientList[replaceIndex] = ingredient
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
