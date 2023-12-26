//
//  MeasureDetailsDisplayBoundary.swift
//  NowChurning
//
//  Created by Austin Dumm on 5/14/23.
//

import Foundation

struct MeasureDetailsDisplayModel {
    var name: ValidatedData<String>
    var description: String
    var tagNames: [String]
    var measurementDescription: String?
}

protocol MeasureDetailsDisplayModelSink: AnyObject,
                                            EditModeDisplayModelSink {
    func send(measureDisplayModel: MeasureDetailsDisplayModel)
}


enum MeasureDetailsAction {
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
        case editMeasurement
        case exit

        // User has requested to change to the ingredient matching the name
        // currently entered in the "Name" field that is colliding
        case nameFooterTap
    }

    case edit(Edit)
    case action(Action)
}

protocol MeasureDetailsActionSink: AnyObject, EditModeActionSink {
    func send(measureAction: MeasureDetailsAction)
}
