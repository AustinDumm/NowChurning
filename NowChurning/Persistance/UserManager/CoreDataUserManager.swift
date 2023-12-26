//
//  CoreDataUserManager.swift
//  NowChurning
//
//  Created by Austin Dumm on 3/3/23.
//

import Foundation
import CoreData

class CoreDataUserManager {
    private static let userObjectName = "User"

    let user: CDUser

    private let managedObjectContext: NSManagedObjectContext

    init(
        managedObjectContext: NSManagedObjectContext
    ) {
        self.managedObjectContext = managedObjectContext

        let fetch = NSFetchRequest<CDUser>(entityName: CoreDataUserManager.userObjectName)

        guard
            let results = try? self
                .managedObjectContext
                .fetch(fetch),
            let user = results.first
        else {
            self.user = .init(context: self.managedObjectContext)

            _ = IngredientTagCoreDataStore(
                tagModelSink: self,
                user: user,
                managedObjectContext: managedObjectContext
            )
            _ = RecipeListCoreDataStore(
                sink: nil,
                storeUser: user,
                objectContext: managedObjectContext
            )

            return
        }

        self.user = user
    }
}

extension CoreDataUserManager: ValidTagsDomainSink {
    func send(validTags: [Tag<Ingredient>]) {}
}

extension CoreDataUserManager: RecipeListDomainModelSink {
    func send(domainModel: [Recipe]) {}
}
