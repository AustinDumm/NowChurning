//
//  CDIngredient+CoreDataClass.swift
//  NowChurning
//
//  Created by Austin Dumm on 2/27/23.
//
//

import Foundation
import CoreData


public class CDIngredient: NSManagedObject {
    convenience init(
        fromDomain ingredient: Ingredient,
        owner: CDUser,
        context: NSManagedObjectContext
    ) {
        self.init(context: context)

        self.id = ingredient.id.rawId
        self.name = ingredient.name
        self.userDescription = ingredient.description
        self.owner = owner

        for tag in ingredient.tags.map({
            CDIngredientTag(
                fromDomain: $0,
                ownedBy: self.owner!,
                context: context
            )
        }) {
            self.addToTags(tag)
        }
    }

    func toDomain() -> Ingredient? {
        guard
            let id = self.id,
            let name = self.name,
            let description = self.userDescription,
            let tags = self.tags?.compactMap({ element in
                (element as? CDIngredientTag)?.toDomain()
            }).sorted()
        else {
            return nil
        }

        return .init(
            id: .init(rawId: id),
            name: name,
            description: description,
            tags: tags
        )
    }

    func updateIngredient(
        name: String,
        userDescription: String,
        tags: [Tag<Ingredient>]
    ) {
        self.name = name
        self.userDescription = userDescription

        let oldTags = self
            .tags?
            .compactMap({ $0 as? CDIngredientTag }) ?? []

        for oldTag in oldTags {
            guard let newTag = tags.first(where: { newTag in
                newTag.id.rawId == oldTag.id
            }) else {
                continue
            }

            oldTag.name = newTag.name
        }

        for oldTag in oldTags
        where !tags.contains(where: { newTag in
            newTag.id.rawId == oldTag.id
        }) {
            self.removeFromTags(oldTag)
        }

        guard let managedObjectContext = self.managedObjectContext else {
            return
        }
        for newTag in tags
        where !oldTags.contains(
            where: { oldTag in
                oldTag.id == newTag.id.rawId
            }
        ) {
            let newCDTag = CDIngredientTag(
                fromDomain: newTag,
                ownedBy: self.owner!,
                context: managedObjectContext
            )

            self.addToTags(newCDTag)
        }
    }
}
