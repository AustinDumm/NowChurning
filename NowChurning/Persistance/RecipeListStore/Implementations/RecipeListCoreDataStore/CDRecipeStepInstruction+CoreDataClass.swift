//
//  CDRecipeStepInstruction+CoreDataClass.swift
//  NowChurning
//
//  Created by Austin Dumm on 7/13/23.
//
//

import Foundation
import CoreData


public class CDRecipeStepInstruction: CDRecipeStep {
    convenience init(
        fromInstruction instruction: String,
        context: NSManagedObjectContext
    ) {
        self.init(context: context)

        self.instructionText = instruction
    }

    override func toDomain() -> RecipeDetails.Step? {
        self.instructionText.map { .instruction($0) }
    }
}
