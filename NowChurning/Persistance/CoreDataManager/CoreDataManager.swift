//
//  CoreDataManager.swift
//  NowChurning
//
//  Created by Austin Dumm on 3/3/23.
//

import Foundation
import CoreData

class CoreDataManager {
    static let containerName = "NowChurning"

    lazy var persistentContainer: NSPersistentContainer? = {
        let container = NSPersistentContainer(name: Self.containerName)
        container.loadPersistentStores(completionHandler: { (_, error) in
            if let error = error as NSError? {
                assertionFailure("Unresolved error \(error), \(error.userInfo)")
                self.persistentContainer = nil
                UserError.deviceStorageError.alert()
            }
        })
        return container
    }()

    init() {
        ValueTransformer.setValueTransformer(
            MeasurementValueTransformer<Unit>(),
            forName: .init("CountMeasurementValueTransformer")
        )
        ValueTransformer.setValueTransformer(
            MeasurementValueTransformer<UnitVolume>(),
            forName: .init("VolumeMeasurementValueTransformer")
        )
    }

    func saveContext() {
        guard let context = persistentContainer?.viewContext else {
            return
        }

        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                let nserror = error as NSError
                assertionFailure("Unresolved error \(nserror), \(nserror.userInfo)")
                UserError.deviceStorageError.alert()
                return
            }
        }
    }
}
