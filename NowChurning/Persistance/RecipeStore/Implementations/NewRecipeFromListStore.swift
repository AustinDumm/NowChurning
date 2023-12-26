//
//  NewRecipeFromListStore.swift
//  NowChurning
//
//  Created by Austin Dumm on 3/9/23.
//

import Foundation

class NewRecipeFromListStore {
    private let modelSink: RecipeDetailsDomainModelSink
    private let storeSink: RecipeListStoreActionSink

    private var recipeList: [Recipe]?
    private let initialRecipe: Recipe

    private let user: CDUser

    init(
        user: CDUser,
        initialRecipe: Recipe = .init(
            name: "",
            description: ""
        ),
        modelSink: RecipeDetailsDomainModelSink,
        storeSink: RecipeListStoreActionSink
    ) {
        self.user = user
        self.initialRecipe = initialRecipe

        self.modelSink = modelSink
        self.storeSink = storeSink

        self.sendRecipeModel()
    }

    private func sendRecipeModel() {
        self.modelSink.send(
            domainModel: .init(
                recipe: initialRecipe,
                stockedIngredientIds: user.stockedIngredientIds()
            )
        )
    }
}

extension NewRecipeFromListStore: RecipeDetailsStoreActionSink {
    func send(action: RecipeDetailsStoreAction) {
        switch action {
        case .save(let recipe):
            self.handleSave(newRecipe: recipe)
        case .refresh:
            self.sendRecipeModel()
        }
    }

    private func handleSave(newRecipe: Recipe) {
        guard var recipeList = self.recipeList else {
            return
        }

        if let replaceIndex = recipeList.firstIndex(
            where: { $0.id == newRecipe.id }
        ) {
            recipeList[replaceIndex] = newRecipe
        } else {
            recipeList.append(newRecipe)
        }

        self.recipeList = recipeList
        self.storeSink
            .send(
                storeAction: .save(
                    recipes: recipeList,
                    saver: self
                )
            )
    }
}

extension NewRecipeFromListStore: RecipeListDomainModelSink {
    func send(domainModel: [Recipe]) {
        self.recipeList = domainModel
    }
}
