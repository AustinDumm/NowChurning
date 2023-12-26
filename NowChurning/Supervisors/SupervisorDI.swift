//
//  SupervisorDI.swift
//  NowChurning
//
//  Created by Austin Dumm on 4/12/23.
//

import Foundation
import CoreData
import Factory

extension Container {
    var coreDataManager: Factory<CoreDataManager> {
        self {
            .init()
        }
        .cached
    }

    var managedObjectContext: Factory<NSManagedObjectContext> {
        self {
            self.coreDataManager()
                .persistentContainer!
                .viewContext
        }
        .cached
    }

    var coreDataUserManager: Factory<CoreDataUserManager> {
        self {
            .init(managedObjectContext: self.managedObjectContext())
        }
        .cached
    }
}
