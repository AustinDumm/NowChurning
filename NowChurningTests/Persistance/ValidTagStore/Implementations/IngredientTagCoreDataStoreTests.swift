//
//  IngredientTagCoreDataStoreTests.swift
//  NowChurningTests
//
//  Created by Austin Dumm on 4/10/23.
//

import XCTest
import CoreData

@testable import NowChurning

final class IngredientTagCoreDataStoreTests: XCTestCase {

    var dataManager: CoreDataManager!
    var context: NSManagedObjectContext! {
        self.dataManager.persistentContainer?.viewContext
    }

    var testUser: CDUser!
    let testTags: [Tag<Ingredient>] = [
        .init(name: "First"),
        .init(name: "Second"),
        .init(name: "Third"),
        .init(name: "Fourth"),
        .init(name: "Fifth"),
    ]

    override func setUpWithError() throws {
        self.dataManager = MemoryCoreDataManager()
        self.testUser = .init(context: self.context)
        for testTag in testTags {
            _ = CDIngredientTag(
                fromDomain: testTag,
                ownedBy: self.testUser,
                context: self.context
            )
        }

        try self.context.save()
    }

    override func tearDownWithError() throws {
        self.dataManager = nil
    }

    func testTagStore_ProvidesCorrectTags() throws {
        let sink: MockValidTagsDomainSink<Ingredient> = .init()

        let expectation = XCTestExpectation()
        sink.sendValidTagsClosure = { receivedTags in
            XCTAssertEqual(
                receivedTags.sorted(),
                self.testTags.sorted()
            )
            expectation.fulfill()
        }

        let _ = IngredientTagCoreDataStore(
            tagModelSink: sink,
            user: self.testUser,
            managedObjectContext: self.context
        )

        wait(for: [expectation], timeout: 0.0)
    }

    func testTagStore_InitializesToDefaultTags() throws {
        let sink: MockValidTagsDomainSink<Ingredient> = .init()
        let emptyUser = CDUser(context: self.context)

        let expectation = XCTestExpectation()
        sink.sendValidTagsClosure = { receivedTags in
            XCTAssertEqual(
                receivedTags.sorted(),
                DefaultIngredientTagContainer.initialTags.sorted()
            )
            expectation.fulfill()
        }

        let _ = IngredientTagCoreDataStore(
            tagModelSink: sink,
            user: emptyUser,
            managedObjectContext: self.context
        )

        wait(for: [expectation], timeout: 0.0)
    }

}
