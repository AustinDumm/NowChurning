//
//  IngredientDetailsDisplayBoundary.swift
//  NowChurning
//
//  Created by Austin Dumm on 12/16/22.
//

import Foundation

struct IngredientDetailsDisplayModel {
    var name: ValidatedData<String>
    var description: String
    var tagNames: [String]
}

protocol IngredientDetailsDisplayModelSink: AnyObject,
                                            EditModeDisplayModelSink {
    func send(ingredientDisplayModel: IngredientDetailsDisplayModel)
}


enum IngredientDetailsAction {
    /// Update data field as a direct edit from a presentation/user.
    /// Display model does not need to be sent back as the edit
    /// came from the editing presentation.
    enum Edit {
        case name(String)
        case description(String)
    }

    /// General action the user took
    enum Action {
        case addTag
        case exit
        case addToInventory

        // User has requested to change to the ingredient matching the name
        // currently entered in the "Name" field that is colliding
        case nameFooterTap
    }

    case edit(Edit)
    case action(Action)
}

protocol IngredientDetailsActionSink: AnyObject, EditModeActionSink {
    func send(ingredientAction: IngredientDetailsAction)
}
