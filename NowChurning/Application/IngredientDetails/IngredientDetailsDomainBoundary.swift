//
//  IngredientDetailsDomainBoundary.swift
//  NowChurning
//
//  Created by Austin Dumm on 12/16/22.
//

import Foundation

struct IngredientDetailsStoredModel: Equatable {
    var ingredient: Ingredient
    var usedNames: [String: ID<Ingredient>]
}

protocol IngredientDomainModelSink: AnyObject {
    func send(domainModel: IngredientDetailsStoredModel)
}

enum IngredientStoreAction {
    case save(ingredient: Ingredient)
}

protocol IngredientStoreActionSink: AnyObject {
    func send(action: IngredientStoreAction)
}
