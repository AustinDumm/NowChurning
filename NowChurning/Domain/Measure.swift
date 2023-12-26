//
//  Measure.swift
//  NowChurning
//
//  Created by Austin Dumm on 4/30/23.
//

import Foundation

extension Unit {
    static var count = Unit(symbol: "")
}

enum MeasurementType: Equatable {
    enum InvalidityReason {
        case negativeVolume
        case negativeCount
    }

    case volume(Measurement<UnitVolume>)
    case count(Measurement<Unit>, String?)
    case any

    var invalidityReasons: [InvalidityReason] {
        switch self {
        case .volume(let measure):
            return measure.value < 0.0 ? [.negativeVolume] : []
        case .count(let measure, _):
            return measure.value < 0.0 ? [.negativeCount] : []
        case .any:
            return []
        }
    }

    var isValid: Bool {
        self.invalidityReasons.isEmpty
    }

    func map<O>(_ transform: (Self) -> O) -> O {
        transform(self)
    }
}

struct Measure: Equatable, Comparable {
    enum InvalidityReason: Equatable {
        case invalidMeasure(MeasurementType.InvalidityReason)
        case invalidIngredient(Ingredient.InvalidityReason)
    }

    var ingredient: Ingredient
    var measure: MeasurementType

    var invalidityReasons: [InvalidityReason] {
        self.ingredient.invalidityReasons.map { .invalidIngredient($0)} +
        self.measure.invalidityReasons.map { .invalidMeasure($0) }
    }

    var isValid: Bool {
        self.invalidityReasons.isEmpty
    }

    static func < (lhs: Measure, rhs: Measure) -> Bool {
        lhs.ingredient < rhs.ingredient
    }
}
