//
//  IngredientListCoreDataStore.swift
//  NowChurning
//
//  Created by Austin Dumm on 1/8/23.
//

import Foundation
import CoreData

class IngredientListCoreDataStore {
    private let storeUser: CDUser
    private var ingredientListSinks: [() -> IngredientListDomainModelSink?]
    private let objectContext: NSManagedObjectContext

    init?(
        sink: IngredientListDomainModelSink?,
        storeUser: CDUser,
        managedObjectContext: NSManagedObjectContext
    ) {
        self.ingredientListSinks = [ { sink } ]
        self.storeUser = storeUser
        self.objectContext = managedObjectContext
        self.objectContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump

        self.sendList()
    }

    func registerSink(asWeak sink: IngredientListDomainModelSink) {
        self.sendList(toSink: sink)
        self.ingredientListSinks.append({ [weak sink] in sink })
    }

    private func sendList() {
        let domainModel = Self.domainModel(
            fromCoreData: self
                .storeUser
                .ingredients?
                .compactMap { $0 as? CDIngredient } ?? []
        )

        self.ingredientListSinks
            .compactMap { $0() }
            .forEach { sink in
                sink.send(domainModel: domainModel)
            }
    }

    private func sendList(
        toSink sink: IngredientListDomainModelSink
    ) {
        let domainModel = Self.domainModel(
            fromCoreData: self
                .storeUser
                .ingredients?
                .compactMap { $0 as? CDIngredient } ?? []
        )

        sink.send(domainModel: domainModel)
    }
}

// MARK: Model Transforms
extension IngredientListCoreDataStore {
    private static func domainModel(
        fromCoreData coreDataModel: [CDIngredient]
    ) -> [Ingredient] {
        coreDataModel
            .compactMap { cdIngredient -> Ingredient? in
                guard
                    let cdId = cdIngredient.id,
                    let cdName = cdIngredient.name,
                    let cdDescription = cdIngredient.userDescription,
                    let cdTags = cdIngredient.tags
                else {
                    return nil
                }

                let tags: [Tag<Ingredient>] = cdTags
                    .compactMap { genericValue -> Tag<Ingredient>? in
                        guard
                            let cdTag = genericValue as? CDIngredientTag,
                            let id = cdTag.id,
                            let name = cdTag.name
                        else {
                            return nil
                        }

                        return .init(
                            id: .init(rawId: id),
                            name: name
                        )
                    }

                return .init(
                    id: ID(rawId: cdId),
                    name: cdName,
                    description: cdDescription,
                    tags: tags
                )
            }
    }
}

extension IngredientListCoreDataStore: IngredientListStoreActionSink {
    func send(action: IngredientListStoreAction) {
        switch action {
        case .save(
            let ingredients,
            let saver
        ):
            self.ingredientListSinks
                .compactMap { $0() }
                .filter { $0 !== saver }
                .forEach { $0.send(domainModel: ingredients) }

            self.storeUser
                .updateIngredients(from: ingredients)

            do {
                try self.objectContext.save()
            } catch let exception {
                assertionFailure(exception.localizedDescription)
                UserError.deviceStorageError.alert()
            }
        }
    }
}
