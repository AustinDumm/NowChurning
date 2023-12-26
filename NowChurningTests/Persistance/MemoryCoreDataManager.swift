//
//  MemoryCoreDataManager.swift
//  NowChurningTests
//
//  Created by Austin Dumm on 4/10/23.
//

import Foundation
import CoreData

@testable import NowChurning

class MemoryCoreDataManager: CoreDataManager {
    override init() {
        super.init()

        let description = NSPersistentStoreDescription()
        description.type = NSSQLiteStoreType
        description.url = URL(filePath: "/dev/null")

        let container = NSPersistentContainer(name: Self.containerName)
        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores(completionHandler: { _, error in
            if let error {
                assertionFailure("Unexpected CoreData memory store error: \(error). \(error.localizedDescription)")
                UserError.deviceStorageError.alert()
            }
        })
        self.persistentContainer = container
    }
}
