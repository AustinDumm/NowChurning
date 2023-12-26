//
//  StockedMeasureListCoreDataStore.swift
//  NowChurning
//
//  Created by Austin Dumm on 5/13/23.
//

import Foundation
import CoreData
import Factory

class StockedMeasureListCoreDataStore {
    private var domainModelSinks: [() -> MeasureListDomainModelSink?]
    private let user: CDUser
    private let context: NSManagedObjectContext

    private var model: [Measure]

    init?(
        domainModelSink: MeasureListDomainModelSink?,
        user: CDUser,
        context: NSManagedObjectContext
    ) {
        self.domainModelSinks = [ { domainModelSink } ]
        self.user = user
        self.context = context

        guard
            let model = user
                .stockedMeasures?
                .compactMap({ ($0 as? CDStockedMeasure)?.toDomain() })
        else {
            return nil
        }

        self.model = model
        self.sendUpdatedModel(to: domainModelSink)
    }

    func registerSink(asWeak sink: MeasureListDomainModelSink) {
        self.sendUpdatedModel(to: sink)
        self.domainModelSinks
            .append({ [weak sink] in sink })
    }

    private func sendUpdatedModel(to sink: MeasureListDomainModelSink?) {
        sink?.send(domainModel: self.model)
    }

    private func sendUpdatedModel(
        excepting: MeasureListDomainModelSink? = nil
    ) {
        domainModelSinks
            .compactMap { $0() }
            .filter { $0 !== excepting }
            .forEach { $0.send(domainModel: self.model) }
    }
}

extension StockedMeasureListCoreDataStore: MeasureListStoreActionSink {
    func send(action: MeasureListStoreAction) {
        switch action {
        case .save(let measures, let saver):
            self.model = measures
            self.sendUpdatedModel(excepting: saver)
            self.saveToCoreData()
        }
    }

    private func saveToCoreData() {
        self.user.updateStockedMeasures(from: self.model)
        do {
            try self.context.save()
        } catch {
            assertionFailure("Failed to save to CoreData due to error. \(error.localizedDescription)")
        }
    }
}
