//
//  RecipeDetails.swift
//  NowChurning
//
//  Created by Austin Dumm on 4/29/23.
//

import Foundation

struct RecipeDetails: Equatable {
    enum Step: Equatable {
        case ingredient(Measure)
        case ingredientTags([Tag<Ingredient>], MeasurementType)
        case instruction(String)
    }

    var steps: [Step]
}
