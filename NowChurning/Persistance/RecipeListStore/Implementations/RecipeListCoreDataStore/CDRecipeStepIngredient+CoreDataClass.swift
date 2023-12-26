//
//  CDRecipeStepIngredient+CoreDataClass.swift
//  NowChurning
//
//  Created by Austin Dumm on 4/29/23.
//
//

import Foundation
import CoreData


public class CDRecipeStepIngredient: CDRecipeStep {
    convenience init(
        fromDomain measure: Measure,
        owner: CDUser,
        context: NSManagedObjectContext
    ) {
        self.init(context: context)

        if let ingredient = owner
            .cdIngredient(forId: measure.ingredient.id) {
            self.ingredient = ingredient
        } else {
            self.ingredient = CDIngredient(
                fromDomain: measure.ingredient,
                owner: owner,
                context: context
            )
        }

        switch measure.measure {
        case .volume(let volumeMeasurement):
            self.volumeMeasurement = volumeMeasurement
            self.countMeasurement = nil
            self.countDescription = nil
        case .count(let countMeasurement, let description):
            self.volumeMeasurement = nil
            self.countMeasurement = countMeasurement
            self.countDescription = description
        case .any:
            self.volumeMeasurement = nil
            self.countMeasurement = nil
            self.countDescription = nil
        }
    }

    override func toDomain() -> RecipeDetails.Step? {
        guard
            let ingredient = self.ingredient?.toDomain()
        else {
            return nil
        }

        let measureType: MeasurementType
        if let volume = self.volumeMeasurement {
            measureType = .volume(volume)
        } else if let countMeasurement = self.countMeasurement {
            measureType = .count(countMeasurement, countDescription)
        } else {
            measureType = .any
        }

        return .ingredient(
            .init(ingredient: ingredient, measure: measureType)
        )
    }
}
