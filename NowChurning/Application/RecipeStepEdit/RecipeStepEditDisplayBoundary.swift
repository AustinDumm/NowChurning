//
//  RecipeStepEditDisplayBoundary.swift
//  NowChurning
//
//  Created by Austin Dumm on 7/8/23.
//

import Foundation

struct RecipeStepEditDisplayModel {
    var stepTypeName: String
    var stepName: String
    var isStepNameEditable: Bool
    var measurementDescription: String?
}

protocol RecipeStepEditDisplayModelSink: AnyObject {
    func send(displayModel: RecipeStepEditDisplayModel)
    func showCancelAlert(onCancel: @escaping () -> Void)
}


enum RecipeStepEditAction {
    case editMainStepData
    case mainStepTextEdit(String)

    case editMeasurement

    case cancelEdit
    case finishEdit
}

protocol RecipeStepEditActionSink: AnyObject {
    func send(action: RecipeStepEditAction)
}
