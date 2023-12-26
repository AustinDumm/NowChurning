//
//  RecipeListStaticMemoryStore.swift
//  NowChurning
//
//  Created by Austin Dumm on 3/3/23.
//

import Foundation

class RecipeListStaticMemoryStore {
    static let dummyModel: [Recipe] = [].shuffled()

    private var observers: [() -> RecipeListDomainModelSink?] = []
    let domainModelSink: RecipeListDomainModelSink

    private var recipes: [Recipe]

    init(
        domainModelSink: RecipeListDomainModelSink
    ) {
        self.domainModelSink = domainModelSink
        self.observers.append({ domainModelSink })

        self.recipes = Self.dummyModel

        self.sendDomainModel()
    }

    func registerWeak(sink: RecipeListDomainModelSink) {
        sink.send(domainModel: self.recipes)
        self.observers.append({ [weak sink] in sink })
    }

    private func sendDomainModel() {
        for observer in self.observers {
            guard let sink = observer() else { continue }

            sink.send(domainModel: self.recipes)
        }
    }
}

extension RecipeListStaticMemoryStore: RecipeListStoreActionSink {
    func send(storeAction: RecipeListStoreAction) {
        switch storeAction {
        case .save(
            recipes: let recipes,
            saver: let saver
        ):
            self.recipes = recipes
            self.observers
                .compactMap { $0() }
                .filter { $0 !== saver }
                .forEach { $0.send(domainModel: recipes) }

        case .refresh:
            self.sendDomainModel()
        }
    }
}
