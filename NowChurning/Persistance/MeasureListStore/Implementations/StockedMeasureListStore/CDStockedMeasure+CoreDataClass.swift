//
//  CDStockedMeasure+CoreDataClass.swift
//  NowChurning
//
//  Created by Austin Dumm on 5/13/23.
//
//

import Foundation
import CoreData


public class CDStockedMeasure: NSManagedObject {
    convenience init(
        fromDomainModel domainModel: Measure,
        coreIngredient: CDIngredient? = nil,
        forUser user: CDUser,
        context: NSManagedObjectContext
    ) {
        self.init(context: context)

        if let coreIngredient {
            self.ingredient = coreIngredient
        } else {
            let doesIngredientExist = user
                .ingredients?
                .compactMap { $0 as? CDIngredient }
                .contains { $0.id == domainModel.ingredient.id.rawId } ?? false

            if !doesIngredientExist {
                let newIngredient = CDIngredient(
                    fromDomain: domainModel.ingredient,
                    owner: user,
                    context: context
                )
                self.ingredient = newIngredient
            }
        }

        self.updateMeasure(fromDomainModel: domainModel)
    }

    func updateMeasure(
        fromDomainModel domainModel: Measure
    ) {
        switch domainModel.measure {
        case .volume(let volumeMeasurement):
            self.volumeMeasurement = volumeMeasurement
            self.countMeasurement = nil
        case .count(let countMeasurement, let description):
            self.volumeMeasurement = nil
            self.countMeasurement = countMeasurement
            self.countDescription = description
        case .any:
            self.volumeMeasurement = nil
            self.countMeasurement = nil
        }

        let ingredient = domainModel.ingredient
        self.ingredient?.updateIngredient(
            name: ingredient.name,
            userDescription: ingredient.description,
            tags: ingredient.tags
        )
    }

    func toDomain() -> Measure? {
        guard let ingredient = self.ingredient?.toDomain() else {
            return nil
        }

        let measureType: MeasurementType
        if let volumeMeasurement {
            measureType = .volume(volumeMeasurement)
        } else if let countMeasurement {
            measureType = .count(
                countMeasurement,
                self.countDescription
            )
        } else {
            measureType = .any
        }

        return .init(
            ingredient: ingredient,
            measure: measureType
        )
    }
}
