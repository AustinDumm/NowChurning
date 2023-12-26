//
//  IngredientTagCoreDataStore.swift
//  NowChurning
//
//  Created by Austin Dumm on 2/23/23.
//

import Foundation
import CoreData

class DefaultIngredientTagContainer {
    static let dairy: Tag<Ingredient> = .init(name: "Dairy")
    static let sweetener: Tag<Ingredient> = .init(name: "Sweetener")
    static let liquor: Tag<Ingredient> = .init(name: "Liquor")
    static let liqueur: Tag<Ingredient> = .init(name: "Liqueur")
    static let extract: Tag<Ingredient> = .init(name: "Extract")
    static let floral: Tag<Ingredient> = .init(name: "Floral")
    static let bitter: Tag<Ingredient> = .init(name: "Bitter")
    static let exotic: Tag<Ingredient> = .init(name: "Exotic")
    static let fruit: Tag<Ingredient> = .init(name: "Fruit")
    static let citrusJuice: Tag<Ingredient> = .init(name: "Citrus Juice")
    static let candy: Tag<Ingredient> = .init(name: "Candy")
    static let mixin: Tag<Ingredient> = .init(name: "Mixin")
    static let chocolate: Tag<Ingredient> = .init(name: "Chocolate")
    static let caramel: Tag<Ingredient> = .init(name: "Caramel")
    static let flavoring: Tag<Ingredient> = .init(name: "Flavoring")

    static let initialTags = [
        dairy, sweetener, liquor, liqueur, extract,
        floral, bitter, exotic, fruit, citrusJuice,
        candy, mixin, chocolate, caramel, flavoring,
    ]
}
private let ingredientTagEntityName = "IngredientTag"

class IngredientTagCoreDataStore<Sink: ValidTagsDomainSink>
where Sink.TagBase == Ingredient {

    private let tagModelSink: Sink
    private let managedObjectContext: NSManagedObjectContext

    private let user: CDUser
    private var cdIngredientTags: [CDIngredientTag] {
        get {
            self.user
                .validIngredientTags?
                .compactMap { $0 as? CDIngredientTag} ?? []
        }
        set {
            self.user
                .validIngredientTags = NSSet(array: newValue)
        }
    }

    init?(
        tagModelSink: Sink,
        user: CDUser,
        managedObjectContext: NSManagedObjectContext
    ) {
        self.user = user
        self.tagModelSink = tagModelSink
        self.managedObjectContext = managedObjectContext
        self.managedObjectContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump

        if self.cdIngredientTags.isEmpty {
            self.cdIngredientTags = Self.coreDataModel(
                fromDomain: DefaultIngredientTagContainer.initialTags,
                owner: self.user,
                managedObjectContext: self.managedObjectContext
            )
            do {
                try self.managedObjectContext.save()
            } catch {
                return nil
            }
        }

        self.tagModelSink
            .send(
                validTags: Self.domainModel(
                    fromCoreData: self.cdIngredientTags
                )
            )
    }

    // MARK: Model Transforms
    private static func coreDataModel(
        fromDomain domainModel: [Tag<Ingredient>],
        owner: CDUser,
        managedObjectContext: NSManagedObjectContext
    ) -> [CDIngredientTag] {
        domainModel
            .map { domainItem in
                let cdModel = CDIngredientTag(
                    context: managedObjectContext
                )

                cdModel.owner = owner
                cdModel.id = domainItem.id.rawId
                cdModel.name = domainItem.name

                return cdModel
            }
    }

    private static func domainModel(
        fromCoreData cdModel: [CDIngredientTag]
    ) -> [Tag<Ingredient>] {
        cdModel
            .map { cdTag in
                .init(
                    id: .init(rawId: cdTag.id!),
                    name: cdTag.name!
                )
            }
    }
}
