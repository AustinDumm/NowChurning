//
//  MeasurementValueTransformer.swift
//  NowChurning
//
//  Created by Austin Dumm on 4/30/23.
//

import Foundation

class MeasurementValueTransformer<UnitType: Unit>: ValueTransformer {
    override public class func allowsReverseTransformation() -> Bool {
        true
    }

    override func transformedValue(_ value: Any?) -> Any? {
        guard let measurement = value as? Measurement<UnitType> else {
            return nil
        }

        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(measurement)
            return data
        } catch {
            assertionFailure("Failed to transform Measure to Data")
            return nil
        }
    }

    override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let data = value as? Data else {
            return nil
        }

        let decoder = JSONDecoder()
        do {
            let measurement = try decoder.decode(Measurement<UnitType>.self, from: data)
            return measurement
        } catch {
            assertionFailure("Failed to transform from Data to Measure")
            return nil
        }
    }
}
