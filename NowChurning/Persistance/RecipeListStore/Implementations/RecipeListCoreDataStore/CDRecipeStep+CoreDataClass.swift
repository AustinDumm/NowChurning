//
//  CDRecipeStep+CoreDataClass.swift
//  NowChurning
//
//  Created by Austin Dumm on 4/29/23.
//
//

import Foundation
import CoreData


public class CDRecipeStep: NSManagedObject {
    func toDomain() -> RecipeDetails.Step? {
        assertionFailure("Abstract CDRecipeStep should never be directly used")
        return nil
    }
}
