//
//  IngredientListCoreDataStoreTests.swift
//  NowChurningTests
//
//  Created by Austin Dumm on 4/10/23.
//

import XCTest
import CoreData

@testable import NowChurning

final class IngredientListCoreDataStoreTests: XCTestCase {

    var dataManager: CoreDataManager!
    var context: NSManagedObjectContext! {
        self.dataManager.persistentContainer?.viewContext
    }

    var testUser: CDUser!
    let testIngredients: [Ingredient] = [
        .init(
            name: "First I",
            description: "First Ingredient",
            tags: [.init(name: "ExampleTag1")]
        ),
        .init(
            name: "Second I",
            description: "Second Ingredient",
            tags: []
        ),
        .init(
            name: "Third I",
            description: "Third Ingredient",
            tags: []
        ),
        .init(
            name: "Fourth I",
            description: "Fourth Ingredient",
            tags: []
        ),
        .init(
            name: "Fifth I",
            description: "Fifth Ingredient",
            tags: []
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

    override func setUpWithError() throws {
        self.dataManager = MemoryCoreDataManager()

        self.testUser = .init(context: self.context)
        let _ = testIngredients
            .map { ingredient in
                CDIngredient(
                    fromDomain: ingredient,
                    owner: self.testUser,
                    context: self.context
                )
            }

        try self.context.save()
    }

    override func tearDownWithError() throws {
        self.dataManager = nil
        self.testUser = nil
    }

    func testStore_WhenInit_DoesSendModel() throws {
        let mockSink = IngredientListDomainModelSinkMock()

        let expectation = XCTestExpectation()
        mockSink.sendDomainModelClosure = { model in
            XCTAssertEqual(
                self.testIngredients.sorted(),
                model.sorted()
            )
            expectation.fulfill()
        }

        let _ = IngredientListCoreDataStore(
            sink: mockSink,
            storeUser: self.testUser,
            managedObjectContext: self.context
        )

        wait(for: [expectation],
             timeout: 0.0)
    }

    func testStore_WhenNewModelSaved_DoesSendNewModel() throws {
        let mockSink = IngredientListDomainModelSinkMock()
        let store = IngredientListCoreDataStore(
            sink: mockSink,
            storeUser: self.testUser,
            managedObjectContext: self.context
        )

        let expectation = XCTestExpectation()
        mockSink.sendDomainModelClosure = { model in
            XCTAssertEqual(
                self.testIngredients.sorted(),
                model.sorted()
            )
            expectation.fulfill()
        }

        store?.send(
            action: .save(
                ingredients: self.testIngredients,
                saver: nil
            )
        )

        wait(
            for: [expectation],
            timeout: 0.0
        )
    }

    func testStore_WhenNewSinkRegistered_DoesSendModel() throws {
        let firstSink = IngredientListDomainModelSinkMock()
        let store = IngredientListCoreDataStore(
            sink: firstSink,
            storeUser: self.testUser,
            managedObjectContext: self.context
        )

        let testSink = IngredientListDomainModelSinkMock()
        let expectation = XCTestExpectation()
        testSink.sendDomainModelClosure = { model in
            XCTAssertEqual(
                self.testIngredients.sorted(),
                model.sorted()
            )
            expectation.fulfill()
        }

        store?.registerSink(asWeak: testSink)
        wait(for: [expectation],
             timeout: 0.0)
    }

    func testStore_WhenMultipleRegistered_DoesSendToAll() throws {
        let firstSink = IngredientListDomainModelSinkMock()
        let expectation = XCTestExpectation()
        expectation.expectedFulfillmentCount = 2

        let store = IngredientListCoreDataStore(
            sink: firstSink,
            storeUser: self.testUser,
            managedObjectContext: self.context
        )

        firstSink.sendDomainModelClosure = { model in
            XCTAssertEqual(
                self.testIngredients.sorted(),
                model.sorted()
            )
            expectation.fulfill()
        }

        let secondSink = IngredientListDomainModelSinkMock()

        store?.registerSink(asWeak: secondSink)

        secondSink.sendDomainModelClosure = { model in
            XCTAssertEqual(
                self.testIngredients.sorted(),
                model.sorted()
            )
            expectation.fulfill()
        }

        store?.send(
            action: .save(
                ingredients: self.testIngredients,
                saver: nil
            )
        )
    }

    func testStore_WhenWeakSinkDropped_DoesNotSendModel() throws {
        let firstSink = IngredientListDomainModelSinkMock()
        let expectation = XCTestExpectation()
        expectation.expectedFulfillmentCount = 1

        let store = IngredientListCoreDataStore(
            sink: firstSink,
            storeUser: self.testUser,
            managedObjectContext: self.context
        )

        firstSink.sendDomainModelClosure = { model in
            XCTAssertEqual(
                self.testIngredients.sorted(),
                model.sorted()
            )
            expectation.fulfill()
        }

        var secondSink = IngredientListDomainModelSinkMock()

        store?.registerSink(asWeak: secondSink)

        let badExpectation = XCTestExpectation()
        badExpectation.isInverted = true
        secondSink.sendDomainModelClosure = { _ in
            expectation.fulfill()
        }

        secondSink = .init()

        store?.send(
            action: .save(
                ingredients: self.testIngredients,
                saver: nil
            )
        )
    }

    func testStore_WhenSaveWithSaver_DoesNotSendModelToSaver() throws {
        let firstSink = IngredientListDomainModelSinkMock()
        let expectation = XCTestExpectation()
        expectation.expectedFulfillmentCount = 1

        let store = IngredientListCoreDataStore(
            sink: firstSink,
            storeUser: self.testUser,
            managedObjectContext: self.context
        )

        firstSink.sendDomainModelClosure = { model in
            XCTAssertEqual(
                self.testIngredients.sorted(),
                model.sorted()
            )
            expectation.fulfill()
        }

        let secondSink = IngredientListDomainModelSinkMock()

        store?.registerSink(asWeak: secondSink)

        let badExpectation = XCTestExpectation()
        badExpectation.isInverted = true
        secondSink.sendDomainModelClosure = { _ in
            expectation.fulfill()
        }

        store?.send(
            action: .save(
                ingredients: self.testIngredients,
                saver: secondSink
            )
        )
    }

    func testSetup_DoesInitializeDataAsExpected() throws {
        let mockSink = IngredientListDomainModelSinkMock()

        let expectation = XCTestExpectation()
        mockSink.sendDomainModelClosure = { received in
            XCTAssert(
                zip(received.sorted(), self.testIngredients.sorted())
                    .allSatisfy({ (first, second) in
                        first == second
                    })
            )
            expectation.fulfill()
        }

        let _ = IngredientListCoreDataStore(
            sink: mockSink,
            storeUser: self.testUser,
            managedObjectContext: self.context
        )

        wait(for: [expectation], timeout: 0.0)
    }

    func testSetup_DoesSaveNewData() throws {
        let newIngredients = [
            Ingredient(
                name: "New Name",
                description: "New Description",
                tags: [.init(
                    name: "NewTag"
                )]
            )
        ]

        let mockSink = IngredientListDomainModelSinkMock()
        let store = IngredientListCoreDataStore(
            sink: mockSink,
            storeUser: self.testUser,
            managedObjectContext: self.context
        )

        expectation(
            forNotification: .NSManagedObjectContextDidSave,
            object: self.context
        ) { _ in
            let savedIngredientSet = self.testUser.ingredients
            let savedCDIngredients = savedIngredientSet?
                .compactMap { element -> CDIngredient? in
                    return element as? CDIngredient
                }

            let savedIngredients = savedCDIngredients?
                .map { cdIngredient -> Ingredient in
                    let tags = cdIngredient
                        .tags?
                        .compactMap { element in
                            return element as? CDIngredientTag
                        }
                        .map { cdTag in
                            Tag<Ingredient>(
                                id: .init(rawId: cdTag.id!),
                                name: cdTag.name!
                            )
                        }

                    return Ingredient(
                        id: .init(rawId: cdIngredient.id!),
                        name: cdIngredient.name!,
                        description: cdIngredient.userDescription!,
                        tags: tags ?? []
                    )
                } ?? []

            XCTAssertEqual(
                savedIngredients.sorted(),
                newIngredients.sorted()
            )

            return true
        }

        store?.send(
            action: .save(
                ingredients: newIngredients,
                saver: nil
            )
        )

        waitForExpectations(timeout: 1.0)
    }

}
