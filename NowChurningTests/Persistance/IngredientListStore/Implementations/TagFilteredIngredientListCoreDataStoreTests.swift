//
//  TagFilteredIngredientListCoreDataStoreTests.swift
//  NowChurningTests
//
//  Created by Austin Dumm on 6/29/23.
//

import XCTest
import CoreData
@testable import NowChurning

final class TagFilteredIngredientListCoreDataStoreTests: XCTestCase {

    var coreDataManager: CoreDataManager!
    var context: NSManagedObjectContext! {
        self.coreDataManager.persistentContainer?.viewContext
    }

    var testUser: CDUser!
    let firstTag: Tag<Ingredient> = .init(name: "First")
    let secondTag: Tag<Ingredient> = .init(name: "Second")
    lazy var testIngredients: [Ingredient] = [
        .init(
            name: "First I",
            description: "First Ingredient",
            tags: [firstTag, secondTag]
        ),
        .init(
            name: "Second I",
            description: "Second Ingredient",
            tags: [firstTag]
        ),
        .init(
            name: "Third I",
            description: "Third Ingredient",
            tags: [secondTag]
        ),
        .init(
            name: "Fourth I",
            description: "Fourth Ingredient",
            tags: []
        ),
        .init(
            name: "Fifth I",
            description: "Fifth Ingredient",
            tags: [firstTag, secondTag]
        ),
        .init(
            name: "Sixth I",
            description: "Sixth Ingredient",
            tags: []
        ),
        .init(
            name: "Seventh I",
            description: "Seventh Ingredient",
            tags: []
        ),
    ]
    var expectedIngredients: [Ingredient] {
        self.testIngredients
            .filter { ingredient in
                [self.firstTag, self.secondTag].allSatisfy { tag in
                    ingredient.tags.contains(tag)
                }
            }
    }

    var store: TagFilteredIngredientListCoreDataStore!
    var sink: IngredientListDomainModelSinkMock!

    override func setUpWithError() throws {
        self.coreDataManager = MemoryCoreDataManager()
        self.testUser = .init(context: self.context)
        let _ = testIngredients.map { ingredient in
            CDIngredient(
                fromDomain: ingredient,
                owner: self.testUser,
                context: self.context
            )
        }

        self.sink = .init()
    }

    override func tearDownWithError() throws {
        self.coreDataManager = nil
        self.testUser = nil
    }

    func testWhenInitialized_SendsFilteredModel() throws {
        let expectation = XCTestExpectation()
        self.sink.sendDomainModelClosure = { model in
            let model = model
                .map { ingredient in
                    var ingredient = ingredient
                    ingredient.tags.sort()
                    return ingredient
                }

            XCTAssertEqual(
                model.sorted(),
                self.expectedIngredients.sorted()
            )
            expectation.fulfill()
        }

        let store = TagFilteredIngredientListCoreDataStore(
            tags: [self.firstTag, self.secondTag],
            sink: self.sink,
            storeUser: self.testUser,
            managedObjectContext: self.context
        )
        wait(for: [expectation], timeout: 0.0)
    }

}
