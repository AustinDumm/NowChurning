//
//  MeasureFromListStore.swift
//  NowChurning
//
//  Created by Austin Dumm on 5/14/23.
//

import Foundation

class MeasureFromListStore {
    private let modelSink: MeasureDomainModelSink
    private let storeSink: MeasureListStoreActionSink

    private var measureList: [Measure]?
    private var allIngredients = [Ingredient]()
    private let id: ID<Ingredient>

    init(
        id: ID<Ingredient>,
        modelSink: MeasureDomainModelSink,
        storeSink: MeasureListStoreActionSink
    ) {
        self.id = id
        self.modelSink = modelSink
        self.storeSink = storeSink
    }

    private func updateModelSink() {
        guard
            let measure = self.measureList?.first(where: {
                $0.ingredient.id == self.id
            })
        else {
            return
        }

        self.modelSink.send(
            domainModel: measure,
            ingredientNameLookup: Dictionary(self
                .allIngredients
                .map { ($0.name.lowercased(), $0.id) }
            ) { first, _ in first }
        )
    }
}

extension MeasureFromListStore: MeasureListDomainModelSink {
    func send(
        domainModel: [Measure]
    ) {
        self.measureList = domainModel

        self.updateModelSink()
    }
}

extension MeasureFromListStore: IngredientListDomainModelSink {
    func send(domainModel: [Ingredient]) {
        self.allIngredients = domainModel

        self.updateModelSink()
    }
}

extension MeasureFromListStore: MeasureStoreActionSink {
    func send(action: MeasureStoreAction) {
        switch action {
        case .save(let measure):
            guard var measureList = self.measureList,
                  let replaceIndex
                    = measureList.firstIndex(where: { $0.ingredient.id == measure.ingredient.id }) else {
                return
            }

            measureList[replaceIndex] = measure
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
