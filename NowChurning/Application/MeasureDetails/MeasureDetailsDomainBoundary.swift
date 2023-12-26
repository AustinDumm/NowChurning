//
//  MeasureDetailsDomainBoundary.swift
//  NowChurning
//
//  Created by Austin Dumm on 5/14/23.
//

import Foundation

protocol MeasureDomainModelSink: AnyObject {
    func send(
        domainModel: Measure,
        ingredientNameLookup: [String: ID<Ingredient>]
    )
}

class NoopMeasureDomainModelSink: MeasureDomainModelSink {
    func send(
        domainModel: Measure, ingredientNameLookup: [String: ID<Ingredient>]
    ) {}
}

enum MeasureStoreAction {
    case save(measure: Measure)
}

protocol MeasureStoreActionSink: AnyObject {
    func send(action: MeasureStoreAction)
}
