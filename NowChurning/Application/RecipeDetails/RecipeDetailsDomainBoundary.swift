//
//  RecipeDetailsDomainBoundary.swift
//  NowChurning
//
//  Created by Austin Dumm on 3/4/23.
//

import Foundation

struct RecipeDetailsModel: Equatable {
    var recipe: Recipe
    var stockedIngredientIds: [ID<Ingredient>: Ingredient]
}

protocol RecipeDetailsDomainModelSink: AnyObject {
    func send(domainModel: RecipeDetailsModel)
}


enum RecipeDetailsStoreAction {
    case save(recipe: Recipe)
    case refresh
}

protocol RecipeDetailsStoreActionSink: AnyObject {
    func send(action: RecipeDetailsStoreAction)
}
