//
//  RecipeDetailsDisplayBoundary.swift
//  NowChurning
//
//  Created by Austin Dumm on 3/4/23.
//

import Foundation

struct RecipeDetailsDisplayModel: Equatable {
    struct RecipeStep: Equatable {
        var isStocked: Bool
        var canPreview: Bool
        var name: String
    }

    var name: ValidatedData<String>
    var description: String

    var recipeSteps: [RecipeStep]
}

protocol RecipeDetailsDisplayModelSink: AnyObject, EditModeDisplayModelSink {
    func send(displayModel: RecipeDetailsDisplayModel)
    func highlightStep(at index: Int)
}


enum RecipeDetailsAction {
    case editName(String)
    case editDescription(String)

    case selectStep(Int)
    case deleteStep(Int)
    case moveStep(from: Int, to: Int)

    case addStep
    case openInfo(forStep: Int)
    case addToInventory(forStep: Int)
}

protocol RecipeDetailsActionSink: AnyObject, EditModeActionSink {
    func send(action: RecipeDetailsAction)
}
