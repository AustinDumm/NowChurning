//
//  RecipeListCoreDataStore.swift
//  NowChurning
//
//  Created by Austin Dumm on 3/7/23.
//

import Foundation
import CoreData

class RecipeListCoreDataStore {
    private let storeUser: CDUser
    private let objectContext: NSManagedObjectContext

    private var observers: [() -> RecipeListDomainModelSink?]

    init?(
        sink: RecipeListDomainModelSink?,
        storeUser: CDUser,
        objectContext: NSManagedObjectContext
    ) {
        self.storeUser = storeUser
        self.objectContext = objectContext
        self.objectContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump

        if (self.storeUser.recipes?.count ?? 0) == 0 {
            self.storeUser
                .updateRecipes(from: Self.defaults)

            do {
                try self.objectContext.save()
            } catch {
                return nil
            }
        }

        self.observers = [ { sink } ]
        self.sendList()
    }

    func registerWeak(sink: RecipeListDomainModelSink) {
        self.sendList(toSink: sink)
        self.observers
            .append({ [weak sink] in sink })
    }

    private func sendList() {
        let domainModel = Self.domainModel(
            fromCoreData: self
                .storeUser
                .recipes?
                .compactMap { $0 as? CDRecipe } ?? []
        )

        self.observers
            .compactMap { $0() }
            .forEach {
                $0.send(domainModel: domainModel)
            }
    }

    private func sendList(
        toSink sink: RecipeListDomainModelSink
    ) {
        let domainModel = Self.domainModel(
            fromCoreData: self
                .storeUser
                .recipes?
                .compactMap { $0 as? CDRecipe } ?? []
        )

        sink.send(domainModel: domainModel)
    }
}

extension RecipeListCoreDataStore: RecipeListStoreActionSink {
    func send(storeAction: RecipeListStoreAction) {
        switch storeAction {
        case .save(
            recipes: let recipes,
            saver: let saver
        ):
            self.observers
                .compactMap { $0() }
                .filter { $0 !== saver }
                .forEach { $0.send(domainModel: recipes) }

            self.storeUser
                .updateRecipes(from: recipes)

            do {
                try self.objectContext.save()
            } catch let exception {
                assertionFailure(exception.localizedDescription)

                UserError.deviceStorageError.alert()
            }
        case .refresh:
            self.sendList()
        }
    }
}

// MARK: Model Transforms
extension RecipeListCoreDataStore {
    private static func domainModel(
        fromCoreData coreDataModel: [CDRecipe]
    ) -> [Recipe] {
        return coreDataModel
            .compactMap { cdRecipe -> Recipe? in
                cdRecipe.toDomain()
            }
    }
}
