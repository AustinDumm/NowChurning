//
//  CDRecipe+CoreDataClass.swift
//  NowChurning
//
//  Created by Austin Dumm on 3/7/23.
//
//

import Foundation
import CoreData

@objc(CDRecipe)
public class CDRecipe: NSManagedObject {
    convenience init(
        fromDomain recipe: Recipe,
        owner: CDUser,
        context: NSManagedObjectContext
    ) {
        self.init(
            context: context
        )

        self.id = recipe.id.rawId
        self.name = recipe.name
        self.userDescription = recipe.description

        self.recipeSteps = .init(
            array: recipe
                .recipeDetails?
                .steps
                .map({ step in
                    switch step {
                    case .ingredient(let measure):
                        return CDRecipeStepIngredient(
                            fromDomain: measure,
                            owner: owner,
                            context: context
                        )
                    case .ingredientTags(let tags, let measurement):
                        return CDRecipeStepIngredientTag(
                            fromDomainTags: tags,
                            andMeasurement: measurement,
                            forUser: owner,
                            context: context
                        )
                    case .instruction(let instruction):
                        return CDRecipeStepInstruction(
                            fromInstruction: instruction,
                            context: context
                        )
                    }
                }) ?? []
        )

        self.owner = owner
    }

    func toDomain() -> Recipe? {
        guard
            let id = self.id,
            let name = self.name,
            let description = self.userDescription
        else {
            return nil
        }

        let steps = self.recipeSteps?
            .compactMap({ element in
                (element as? CDRecipeStep)?.toDomain()
            })

        return Recipe(
            id: .init(rawId: id),
            name: name,
            description: description,
            recipeDetails: steps
                .flatMap { $0.isEmpty ? nil : .init(steps: $0) }
        )
    }

    func updateRecipeDetails(
        name: String,
        userDescription: String,
        recipeDetails: RecipeDetails?
    ) {
        guard
            let owner = self.owner,
            let context = self.managedObjectContext
        else {
            return
        }

        self.name = name
        self.userDescription = userDescription

        while (self.recipeSteps?.count ?? 0) > 0 {
            self.removeFromRecipeSteps(at: 0)
        }

        for step in recipeDetails?.steps ?? [] {
            switch step {
            case .ingredient(let measure):
                let ingredientStep = CDRecipeStepIngredient(
                    fromDomain: measure,
                    owner: owner,
                    context: context
                )

                self.addToRecipeSteps(ingredientStep)
                break

            case .ingredientTags(let tags, let amount):
                let tagStep = CDRecipeStepIngredientTag(
                    fromDomainTags: tags,
                    andMeasurement: amount,
                    forUser: owner,
                    context: context
                )

                self.addToRecipeSteps(tagStep)

            case .instruction(let instruction):
                let instructionStep = CDRecipeStepInstruction(
                    fromInstruction: instruction,
                    context: context
                )

                self.addToRecipeSteps(instructionStep)
            }
        }
    }
}
