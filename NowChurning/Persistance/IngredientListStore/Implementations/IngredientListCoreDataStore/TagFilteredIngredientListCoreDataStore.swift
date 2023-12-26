//
//  TagFilteredIngredientListCoreDataStore.swift
//  NowChurning
//
//  Created by Austin Dumm on 6/29/23.
//

import Foundation
import CoreData

class TagFilteredIngredientListCoreDataStore {
    private class InternalSink: IngredientListDomainModelSink {
        private let sendAction: ([Ingredient]) -> Void

        init(
            sendAction: @escaping ([Ingredient]) -> Void
        ) {
            self.sendAction = sendAction
        }

        func send(domainModel: [Ingredient]) {
            self.sendAction(domainModel)
        }
    }

    let listStore: IngredientListCoreDataStore
    private let internalSink: InternalSink

    init?(
        tags: [Tag<Ingredient>],
        sink: IngredientListDomainModelSink,
        storeUser: CDUser,
        managedObjectContext: NSManagedObjectContext
    ) {
        self.internalSink = .init(sendAction: { ingredients in
            let filtered = ingredients
                .filter { ingredient in
                    tags.allSatisfy { tag in
                        ingredient.tags.contains(tag)
                    }
                }
            sink.send(domainModel: filtered)
        })

        guard let listStore = IngredientListCoreDataStore(
            sink: self.internalSink,
            storeUser: storeUser,
            managedObjectContext: managedObjectContext
        ) else {
            return nil
        }

        self.listStore = listStore
    }
}

// I'm unsure how this filtered store should save things when they are
// sent in given that what is sent out is filtered. Leaving this empty
// until it is actually used or needed and answering that question later.
extension TagFilteredIngredientListCoreDataStore: IngredientListStoreActionSink {
    func send(action: IngredientListStoreAction) {}
    func registerSink(asWeak sink: IngredientListDomainModelSink) {}
}
