//
//  IngredientStepEditDomainBoundary.swift
//  NowChurning
//
//  Created by Austin Dumm on 7/8/23.
//

import Foundation

protocol RecipeStepEditDomainModelSink: AnyObject {
    func send(step: RecipeDetails.Step)

    func send(ingredient: Ingredient)
    func send(tags: [Tag<Ingredient>])
    func send(measurement: MeasurementType)
}


enum RecipeStepEditStoreAction {
    case saveStep(RecipeDetails.Step)
}

protocol RecipeStepEditStoreActionSink: AnyObject {
    func send(action: RecipeStepEditStoreAction)
}
