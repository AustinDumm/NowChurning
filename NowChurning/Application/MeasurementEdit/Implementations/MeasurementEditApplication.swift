//
//  MeasurementEditApplication.swift
//  NowChurning
//
//  Created by Austin Dumm on 5/28/23.
//

import Foundation

protocol MeasurementEditDelegate: AnyObject {
    func didEnter(measurement: MeasurementType)
    func didCancel()
}

class MeasurementEditApplication {
    struct Content {
        var anyMeasurementDescription: String
        var volumeMeasurementDescription: String
        var countMeasurementDescription: String

        var validVolumeUnits: [UnitVolume]
    }

    weak var displayModelSink: MeasurementEditDisplayModelSink? {
        didSet {
            self.sendDisplayModel()
        }
    }

    weak var delegate: MeasurementEditDelegate?

    private let content: Content

    private let initialMeasure: MeasurementType?
    private var measure: MeasurementType

    init(
        initialMeasure: MeasurementType?,
        content: Content
    ) {
        self.initialMeasure = initialMeasure
        self.measure = initialMeasure ?? .any
        self.content = content
    }

    func hasChanges() -> Bool {
        self.initialMeasure == nil || self.initialMeasure != self.measure
    }

    func attemptCancel(_ completion: (() -> Void)? = nil) {
        guard hasChanges() else {
            completion?()
            return
        }

        self.displayModelSink?.send(
            alertDisplayModel: .cancel
        ) { didConfirm in
            if didConfirm {
                completion?()
            }
        }
    }

    private func sendDisplayModel() {
        self.displayModelSink?
            .send(displayModel: Self.displayModel(
                from: self.measure,
                content: self.content
            ))
    }
}

extension MeasurementEditApplication: MeasurementEditActionSink {
    func send(action: MeasurementEditAction) {
        switch action {
        case .changeType(atIndex: let index):
            self.changeType(toIndex: index)
        case .changeVolumeUnit(atIndex: let index):
            self.changeVolumeUnit(toIndex: index)
        case .changeAmount(let amount):
            self.changeAmount(toAmount: amount)
        case .changeDescription(let description):
            self.changeDescription(to: description)
        }
    }

    func send(editModeAction action: EditModeAction) {
        switch action {
        case .startEditing:
            break
        case .finishEditing(.cancel):
            self.delegate?.didCancel()
        case .finishEditing(.save):
            self.delegate?.didEnter(measurement: self.measure)
        }
    }

    private func changeType(toIndex index: Int) {
        let editScalar: Bool
        switch index {
        case 0:
            self.measure = .any
            editScalar = false
        case 1:
            self.measure = .volume(.init(value: 0.0, unit: .fluidOunces))
            editScalar = false
        case 2:
            self.measure = .count(
                .init(value: 0.0, unit: .count),
                ""
            )
            editScalar = true
        default:
            return
        }

        self.sendDisplayModel()
        if editScalar {
            self.displayModelSink?.startEdit(for: .scalar)
        }
    }

    private func changeVolumeUnit(toIndex index: Int) {
        guard
            let newMeasure = self.content.validVolumeUnits[safe: index],
            case let .volume(oldMeasurement) = self.measure
        else {
            return
        }

        self.measure = .volume(
            oldMeasurement
                .converted(to: newMeasure)
                .truncated(toSignificantDigits: 2)
        )
        self.sendDisplayModel()
        self.displayModelSink?.startEdit(for: .scalar)
    }

    private func changeAmount(toAmount amount: Double) {
        switch self.measure {
        case .volume(var measurement):
            measurement.value = amount
            self.measure = .volume(measurement)
        case .count(var measurement, let description):
            measurement.value = amount
            self.measure = .count(measurement, description)
        case .any:
            break
        }

        self.sendDisplayModel()
    }

    private func changeDescription(to description: String) {
        switch self.measure {
        case .count(let measurement, _):
            self.measure = .count(measurement, description)
        case .volume, .any:
            break
        }

        self.sendDisplayModel()
    }
}

// MARK: Model Transforms
extension MeasurementEditApplication {
    private static func displayModel(
        from measurement: MeasurementType,
        content: Content
    ) -> MeasurementEditDisplayModel {
        .init(
            validTypes: [
                content.anyMeasurementDescription,
                content.volumeMeasurementDescription,
                content.countMeasurementDescription
            ],
            displayType: self.displayType(
                from: measurement,
                content: content
            )
        )
    }

    private static func displayType(
        from measurement: MeasurementType,
        content: Content
    ) -> MeasurementEditDisplayModel.DisplayType {
        switch measurement {
        case .volume(let measurement):
            print(measurement.unit)
            let selectedUnitIndex = content.validVolumeUnits.firstIndex(
                where: { validUnit in validUnit.symbol == measurement.unit.symbol }
            ) ?? 0

            return .volume(
                .init(
                    scalar: measurement.value,
                    selectedUnitIndex: selectedUnitIndex,
                    validUnits: content
                        .validVolumeUnits
                        .map { $0.symbol }
                ))
        case .count(let measurement, let description):
            return .count(measurement.value, description ?? "")
        case .any:
            return .unspecified
        }
    }
}
