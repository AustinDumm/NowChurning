//
//  EditModeDisplayBoundary.swift
//  NowChurning
//
//  Created by Austin Dumm on 1/7/23.
//

import Foundation

struct EditModeDisplayModel {
    let isEditing: Bool
    let canSave: Bool
}

protocol EditModeDisplayModelSink: AnyObject {
    func send(editModeDisplayModel: EditModeDisplayModel)

    func send(
        alertDisplayModel: EditModeAction.DoneType,
        didConfirm: @escaping (Bool) -> Void
    )
}


enum EditModeAction {
    enum DoneType {
        case save
        case cancel
    }
    case startEditing
    case finishEditing(DoneType)
}

protocol EditModeActionSink: AnyObject {
    func send(editModeAction: EditModeAction)
}
