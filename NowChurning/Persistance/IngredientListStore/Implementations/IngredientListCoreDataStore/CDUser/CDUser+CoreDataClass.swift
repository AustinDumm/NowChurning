//
//  CDUser+CoreDataClass.swift
//  NowChurning
//
//  Created by Austin Dumm on 2/27/23.
//
//

import Foundation
import CoreData


public class CDUser: NSManagedObject {
    func hasUnstockedIngredients() -> Bool {
        let ingredients = self
            .ingredients?
            .compactMap { $0 as? CDIngredient }
            .filter { $0.stock == nil } ?? []

        return ingredients.count > 0
    }

    func stockedMeasure(
        forIngredientId ingredientId: ID<Ingredient>
    ) -> Measure? {
        guard
            let stockedMeasures = self
                .stockedMeasures?
                .compactMap({ $0 as? CDStockedMeasure }),
            let matchingMeasure = stockedMeasures.first(where: { measure in
                measure.ingredient?.id == ingredientId.rawId
            })
        else {
            return nil
        }

        return matchingMeasure.toDomain()
    }

    func cdIngredient(forId ingredientId: ID<Ingredient>) -> CDIngredient? {
        guard
            let ingredients = self
                .ingredients?
                .compactMap({ $0 as? CDIngredient }),
            let matchingIngredient = ingredients.first(where: { ingredient in
                ingredient.id == ingredientId.rawId
            })
        else {
            return nil
        }

        return matchingIngredient
    }

    func ingredient(forId ingredientId: ID<Ingredient>) -> Ingredient? {
        cdIngredient(forId: ingredientId)?.toDomain()
    }

    func stockedIngredientIds() -> [ID<Ingredient>: Ingredient] {
        guard let stockedIngredients = self.stockedMeasures?
            .compactMap({ cdMeasure -> Ingredient? in
                (cdMeasure as? CDStockedMeasure)?
                    .ingredient?.toDomain()
            })
        else {
            return [:]
        }

        let dictionary = Dictionary(
            stockedIngredients
                .map { ($0.id, $0 ) }
        ) { first, _ in
            first
        }

        return dictionary
//
//        let ids = self.stockedMeasures?
//            .compactMap { item -> ID<Ingredient>? in
//                let measure = (item as? CDStockedMeasure)
//
//                return measure?.ingredient?.id.map { .init(rawId: $0) }
//            } ?? []
//
//        return Set(ids)
    }

    func updateIngredients(from newIngredients: [Ingredient]) {
        guard
            let managedObjectContext = self.managedObjectContext
        else {
            return
        }

        let oldIngredients = self
            .ingredients?
            .compactMap { $0 as? CDIngredient } ?? []

        for oldIngredient in oldIngredients {
            guard let newIngredient = newIngredients
                .first(where: { newIngredient in
                    newIngredient.id.rawId == oldIngredient.id
                }) else {
                continue
            }

            oldIngredient.updateIngredient(
                name: newIngredient.name,
                userDescription: newIngredient.description,
                tags: newIngredient.tags)
        }

        for oldIngredient in oldIngredients
        where !newIngredients.contains(where: { newIngredient in
            oldIngredient.id == newIngredient.id.rawId
        }) {
            self.removeFromIngredients(oldIngredient)
            managedObjectContext.delete(oldIngredient)
        }

        for newIngredient in newIngredients
        where !oldIngredients.contains(where: { oldIngredient in
            oldIngredient.id == newIngredient.id.rawId
        }) {
            let newCDIngredient = CDIngredient(
                fromDomain: newIngredient,
                owner: self,
                context: managedObjectContext
            )

            self.addToIngredients(newCDIngredient)
        }
    }

    func updateRecipes(
        from newRecipes: [Recipe]
    ) {
        guard
            let managedObjectContext = self.managedObjectContext
        else {
            return
        }

        let oldRecipes = self
            .recipes?
            .compactMap { $0 as? CDRecipe } ?? []

        for oldRecipe in oldRecipes {
            guard let newRecipe = newRecipes
                .first(where: { newRecipe in
                    newRecipe.id.rawId == oldRecipe.id
                }) else {
                continue
            }

            oldRecipe.updateRecipeDetails(
                name: newRecipe.name,
                userDescription: newRecipe.description,
                recipeDetails: newRecipe.recipeDetails
            )
        }

        for oldRecipe in oldRecipes
        where !newRecipes.contains(where: { newRecipe in
            oldRecipe.id == newRecipe.id.rawId
        }) {
            self.removeFromRecipes(oldRecipe)
            managedObjectContext.delete(oldRecipe)
        }

        for newRecipe in newRecipes
        where !oldRecipes.contains(where: { oldRecipe in
            oldRecipe.id == newRecipe.id.rawId
        }) {
            let newCDRecipe = CDRecipe(
                fromDomain: newRecipe,
                owner: self,
                context: managedObjectContext
            )

            self.addToRecipes(newCDRecipe)
        }
    }

    private func removeOldMeasures(
        newMeasures: [Measure],
        oldMeasures: [CDStockedMeasure]
    ) {
        for oldMeasure in oldMeasures
        where !newMeasures.contains(where: { newMeasure in
            newMeasure.ingredient.id.rawId == oldMeasure.ingredient?.id
        }) {
            // oldMeasure is not in newMeasures
            oldMeasure.ingredient?.stock = nil
            self.removeFromStockedMeasures(oldMeasure)
        }
    }

    private func insertNewMeasures(
        newMeasures: [Measure],
        oldMeasures: [CDStockedMeasure],
        context: NSManagedObjectContext
    ) {
        for newMeasure in newMeasures
        where !oldMeasures.contains(where: { oldMeasure in
            newMeasure.ingredient.id.rawId == oldMeasure.ingredient?.id
        }) {
            // newMeasure is not in oldMeasures
            let ingredient = newMeasure.ingredient

            let coreIngredient: CDIngredient
            if let storedIngredient = self.ingredients?.first(where: { element in
                (element as? CDIngredient)?.id == ingredient.id
                    .rawId
            }),
               let coreStored = storedIngredient as? CDIngredient {
                coreIngredient = coreStored
            } else {
                coreIngredient = .init(
                    fromDomain: ingredient,
                    owner: self,
                    context: context
                )

                self.addToIngredients(coreIngredient)
            }

            self.addToStockedMeasures(
                .init(
                    fromDomainModel: newMeasure,
                    coreIngredient: coreIngredient,
                    forUser: self,
                    context: context
                )
            )
        }
    }

    fileprivate func updateExistingMeasures(
        newMeasures: [Measure],
        oldMeasures: [CDStockedMeasure]
    ) {
        for oldMeasure in oldMeasures {
            guard
                let newMeasure = newMeasures.first(where: { newMeasure in
                    newMeasure.ingredient.id.rawId == oldMeasure.ingredient?.id
                }) else {
                continue
            }

            // newMeasure does exist in oldMeasures
            oldMeasure.updateMeasure(fromDomainModel: newMeasure)
        }
    }

    func updateStockedMeasures(
        from newMeasures: [Measure]
    ) {
        guard
            let context = self.managedObjectContext
        else {
            return
        }

        let oldMeasures = self
            .stockedMeasures?
            .compactMap { $0 as? CDStockedMeasure } ?? []

        removeOldMeasures(
            newMeasures: newMeasures,
            oldMeasures: oldMeasures
        )

        insertNewMeasures(
            newMeasures: newMeasures,
            oldMeasures: oldMeasures,
            context: context
        )

        updateExistingMeasures(
            newMeasures: newMeasures,
            oldMeasures: oldMeasures
        )
    }
}
