//
//  NewMeasureFromListStore.swift
//  NowChurning
//
//  Created by Austin Dumm on 5/14/23.
//

import Foundation

class NewMeasureFromListStore {
    private let modelSink: MeasureDomainModelSink?
    private let storeSink: MeasureListStoreActionSink

    private let initialMeasure: Measure

    private var measureList: [Measure]?
    private var allIngredients = [Ingredient]()

    init(
        initialMeasure: Measure = .init(
            ingredient: .init(
                name: "",
                description: "",
                tags: []
            ),
            measure: .any
        ),
        modelSink: MeasureDomainModelSink?,
        storeSink: MeasureListStoreActionSink
    ) {
        self.initialMeasure = initialMeasure

        self.modelSink = modelSink
        self.storeSink = storeSink

        self.updateModelSink()
    }

    private func updateModelSink() {
        self.modelSink?.send(
            domainModel: self.initialMeasure,
            ingredientNameLookup: Dictionary(
                self.allIngredients.map { ($0.name.lowercased(), $0.id) }
            ) { first, _ in first }
        )
    }
}

extension NewMeasureFromListStore: MeasureListDomainModelSink {
    func send(
        domainModel: [Measure]
    ) {
        self.measureList = domainModel
    }
}

extension NewMeasureFromListStore: IngredientListDomainModelSink {
    func send(domainModel: [Ingredient]) {
        self.allIngredients = domainModel
        self.updateModelSink()
    }
}

extension NewMeasureFromListStore: MeasureStoreActionSink {
    func send(action: MeasureStoreAction) {
        switch action {
        case .save(let measure):
            guard
                var measureList = self.measureList
            else {
                return
            }

            if let replaceIndex = measureList.firstIndex(
                where: { $0.ingredient.id == measure.ingredient.id }
            ) {
                measureList[replaceIndex] = measure
            } else {
                measureList.append(measure)
            }

            self.measureList = measureList
            self.storeSink
                .send(
                    action: .save(
                        measures: measureList,
                        saver: self
                    )
                )
        }
    }
}
