//
//  CDRecipeStepIngredientTag+CoreDataClass.swift
//  NowChurning
//
//  Created by Austin Dumm on 6/28/23.
//
//

import Foundation
import CoreData


public class CDRecipeStepIngredientTag: CDRecipeStep {
    convenience init(
        fromDomainTags tags: [Tag<Ingredient>],
        andMeasurement measurement: MeasurementType,
        forUser user: CDUser,
        context: NSManagedObjectContext
    ) {
        self.init(context: context)

        self.ingredientTags = NSSet(array: tags
            .map { tag in
                CDIngredientTag(
                    fromDomain: tag,
                    ownedBy: user,
                    context: context
                )
            })

        switch measurement {
        case .volume(let measurement):
            self.volumeMeasurement = measurement
            self.countMeasurement = nil
            self.countDescription = nil
        case .count(let measurement, let description):
            self.volumeMeasurement = nil
            self.countMeasurement = measurement
            self.countDescription = description
        case .any:
            self.volumeMeasurement = nil
            self.countMeasurement = nil
            self.countDescription = nil
        }
    }

    override func toDomain() -> RecipeDetails.Step? {
        guard
            let tags = self
                .ingredientTags?
                .compactMap(
                    { ($0 as? CDIngredientTag)?.toDomain() }
                )
        else {
            return nil
        }

        let measurementType: MeasurementType
        if let volumeMeasurement {
            measurementType = .volume(volumeMeasurement)
        } else if let countMeasurement {
            measurementType = .count(
                countMeasurement,
                self.countDescription ?? ""
            )
        } else {
            measurementType = .any
        }

        return .ingredientTags(
            tags,
            measurementType
        )
    }
}
