//
//  MeasurementFormatter+Measurements.swift
//  NowChurning
//
//  Created by Austin Dumm on 5/28/23.
//

import Foundation

extension MeasurementFormatter {
    static let countFormatter: MeasurementFormatter = {
        let formatter = MeasurementFormatter()

        formatter.unitStyle = .long
        formatter.unitOptions = .providedUnit
        formatter.numberFormatter = .countFormatter

        return formatter
    }()

    static let volumeFormatter: MeasurementFormatter = {
        let formatter = MeasurementFormatter()

        formatter.unitStyle = .long
        formatter.unitOptions = .providedUnit
        formatter.numberFormatter = .volumeFormatter

        return formatter
    }()
}
