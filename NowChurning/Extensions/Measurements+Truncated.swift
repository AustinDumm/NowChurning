//
//  Measurements+Truncate.swift
//  NowChurning
//
//  Created by Austin Dumm on 6/12/23.
//

import Foundation

extension Measurement {
    func truncated(toSignificantDigits digits: Int) -> Self {
        let divisor = pow(10.0, Double(digits))
        let trunactedValue = (self.value * divisor).rounded() / divisor

        return .init(value: trunactedValue, unit: self.unit)
    }
}
