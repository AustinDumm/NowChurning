//
//  NumberFormatter+Measurements.swift
//  NowChurning
//
//  Created by Austin Dumm on 5/28/23.
//

import Foundation

extension NumberFormatter {
    static let countFormatter: NumberFormatter = {
        let formatter = NumberFormatter()

        formatter.isLenient = true
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        formatter.locale = .current

        return formatter
    }()

    static let volumeFormatter: NumberFormatter = {
        let formatter = NumberFormatter()

        formatter.isLenient = true
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        formatter.locale = .current

        return formatter
    }()
}
