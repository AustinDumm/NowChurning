//
//  MeasurementEditDisplayBoundary.swift
//  NowChurning
//
//  Created by Austin Dumm on 5/28/23.
//

import Foundation

struct MeasurementEditDisplayModel {
    enum DisplayType {
        case unspecified
        case volume(VolumeTypeData)
        case count(Double, String)
    }

    struct VolumeTypeData {
        let scalar: Double
        let selectedUnitIndex: Int
        let validUnits: [String]
    }

    enum EditableValue {
        case measurementType
        case unit
        case scalar
    }

    var validTypes: [String]
    var displayType: DisplayType
}

protocol MeasurementEditDisplayModelSink: AnyObject, EditModeDisplayModelSink {
    func send(displayModel: MeasurementEditDisplayModel)
    func startEdit(for editableValue: MeasurementEditDisplayModel.EditableValue)
}


enum MeasurementEditAction {
    case changeType(atIndex: Int)
    case changeVolumeUnit(atIndex: Int)
    case changeAmount(Double)
    case changeDescription(String)
}

protocol MeasurementEditActionSink: AnyObject, EditModeActionSink {
    func send(action: MeasurementEditAction)
}
