//
//  RecipeFromListStore.swift
//  NowChurning
//
//  Created by Austin Dumm on 3/4/23.
//

import Foundation

class RecipeFromListStore {
    private let modelSink: RecipeDetailsDomainModelSink
    private let storeSink: RecipeListStoreActionSink

    private var recipeList: [Recipe]?
    private let id: ID<Recipe>

    private let user: CDUser

    init(
        user: CDUser,
        modelSink: RecipeDetailsDomainModelSink,
        storeSink: RecipeListStoreActionSink,
        id: ID<Recipe>
    ) {
        self.user = user
        self.modelSink = modelSink
        self.storeSink = storeSink
        self.id = id
    }
}

extension RecipeFromListStore: RecipeListDomainModelSink {
    func send(
        domainModel: [Recipe]
    ) {
        self.recipeList = domainModel

        self.sendRecipeModel()
    }

    private func sendRecipeModel() {
        guard
            let recipeList,
            let matchingRecipe = recipeList.first(where: { recipe in
                recipe.id == self.id
            })
        else {
            return
        }

        self.modelSink
            .send(
                domainModel: .init(
                    recipe: matchingRecipe,
                    stockedIngredientIds: user.stockedIngredientIds()
                )
            )
    }
}

extension RecipeFromListStore: RecipeDetailsStoreActionSink {
    func send(action: RecipeDetailsStoreAction) {
        switch action {
        case .save(recipe: let updatedRecipe):
            guard
                var recipeList = self.recipeList,
                let replaceIndex = recipeList
                    .firstIndex(where: { $0.id == updatedRecipe.id})
            else {
                return
            }

            recipeList[replaceIndex] = updatedRecipe
            self.recipeList = recipeList
            self.storeSink
                .send(
                    storeAction: .save(
                        recipes: recipeList,
                        saver: self
                    )
                )
        case .refresh:
            self.sendRecipeModel()
        }
    }
}
