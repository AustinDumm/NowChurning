//
//  CDIngredientTag+CoreDataClass.swift
//  NowChurning
//
//  Created by Austin Dumm on 2/27/23.
//
//

import Foundation
import CoreData


public class CDIngredientTag: NSManagedObject {
    convenience init(
        fromDomain tag: Tag<Ingredient>,
        ownedBy owner: CDUser,
        context: NSManagedObjectContext
    ) {
        self.init(context: context)

        self.id = tag.id.rawId
        self.name = tag.name
        self.owner = owner
    }

    func toDomain() -> Tag<Ingredient>? {
        guard
            let id = self.id,
            let name = self.name
        else {
            return nil
        }

        return .init(
            id: .init(rawId: id),
            name: name
        )
    }
}
