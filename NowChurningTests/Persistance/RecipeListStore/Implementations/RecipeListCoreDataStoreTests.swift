//
//  RecipeListCoreDataStoreTests.swift
//  NowChurningTests
//
//  Created by Austin Dumm on 4/10/23.
//

import XCTest
import CoreData

@testable import NowChurning

final class RecipeListCoreDataStoreTests: XCTestCase {

    var dataManager: CoreDataManager!
    var context: NSManagedObjectContext! {
        self.dataManager.persistentContainer?.viewContext
    }

    var testUser: CDUser!
    let testRecipes: [Recipe] = [
        .init(
            name: "First D",
            description: "First Recipe",
            recipeDetails: .init(
                steps: [
                    .ingredient(
                        .init(
                            ingredient: .init(
                                name: "First",
                                description: "Desc",
                                tags: []
                            ),
                            measure: .any
                        )
                    ),
                    .ingredient(
                        .init(
                            ingredient: .init(
                                name: "Second",
                                description: "Desc",
                                tags: []
                            ),
                            measure: .count(.init(
                                value: 3.0,
                                unit: .init(symbol: "")
                            ), "Test Count Description")
                        )
                    ),
                    .ingredient(
                        .init(
                            ingredient: .init(
                                name: "Third",
                                description: "Desc",
                                tags: []
                            ),
                            measure: .volume(.init(
                                value: 5.25,
                                unit: .fluidOunces)
                            )
                        )
                    ),
                ]
            )
        ),
        .init(
            name: "Second D",
            description: "Second Recipe"
        ),
        .init(
            name: "Third D",
            description: "Third Recipe"
        ),
        .init(
            name: "Fourth D",
            description: "Fourth Recipe"
        ),
        .init(
            name: "Fifth D",
            description: "Fifth Recipe"
        ),
        .init(
            name: "Sixth D",
            description: "Sixth Recipe"
        ),
        .init(
            name: "Seventh D",
            description: "Seventh Recipe"
        ),
    ]
    override func setUpWithError() throws {
        self.dataManager = MemoryCoreDataManager()

        self.testUser = .init(context: self.context)
        let _ = testRecipes
            .map { recipe in
                CDRecipe(
                    fromDomain: recipe,
                    owner: self.testUser,
                    context: self.context
                )
            }

        try! self.context.save()
    }

    override func tearDownWithError() throws {
        self.dataManager = nil
        self.testUser = nil
    }

    func testStore_WhenInit_DoesSendModel() throws {
        let mockSink = RecipeListDomainModelSinkMock()

        let expectation = XCTestExpectation()
        mockSink.sendDomainModelClosure = { model in
            XCTAssertEqual(
                model.sorted(),
                self.testRecipes.sorted()
            )
            expectation.fulfill()
        }

        let _ = RecipeListCoreDataStore(
            sink: mockSink,
            storeUser: self.testUser,
            objectContext: self.context
        )

        wait(for: [expectation],
             timeout: 0.0)
    }

    func testStore_WhenNewModelSaved_DoesSendNewModel() throws {
        let mockSink = RecipeListDomainModelSinkMock()
        let store = RecipeListCoreDataStore(
            sink: mockSink,
            storeUser: self.testUser,
            objectContext: self.context
        )

        let expectation = XCTestExpectation()
        mockSink.sendDomainModelClosure = { model in
            XCTAssertEqual(
                self.testRecipes.sorted(),
                model.sorted()
            )
            expectation.fulfill()
        }

        store?.send(
            storeAction: .save(
                recipes: self.testRecipes,
                saver: nil
            )
        )

        wait(
            for: [expectation],
            timeout: 0.0
        )
    }

    func testStore_WhenNewSinkRegistered_DoesSendModel() throws {
        let firstSink = RecipeListDomainModelSinkMock()
        let store = RecipeListCoreDataStore(
            sink: firstSink,
            storeUser: self.testUser,
            objectContext: self.context
        )

        let testSink = RecipeListDomainModelSinkMock()
        let expectation = XCTestExpectation()
        testSink.sendDomainModelClosure = { model in
            for (recieved, expected) in zip(model.sorted(), self.testRecipes.sorted()) {
                XCTAssertEqual(
                    recieved,
                    expected
                )
            }
            expectation.fulfill()
        }

        store?.registerWeak(sink: testSink)
        wait(for: [expectation],
             timeout: 0.0)
    }

    func testStore_WhenMultipleRegistered_DoesSendToAll() throws {
        let firstSink = RecipeListDomainModelSinkMock()
        let expectation = XCTestExpectation()
        expectation.expectedFulfillmentCount = 2

        let store = RecipeListCoreDataStore(
            sink: firstSink,
            storeUser: self.testUser,
            objectContext: self.context
        )

        firstSink.sendDomainModelClosure = { model in
            XCTAssertEqual(
                self.testRecipes.sorted(),
                model.sorted()
            )
            expectation.fulfill()
        }

        let secondSink = RecipeListDomainModelSinkMock()

        store?.registerWeak(sink: secondSink)

        secondSink.sendDomainModelClosure = { model in
            XCTAssertEqual(
                self.testRecipes.sorted(),
                model.sorted()
            )
            expectation.fulfill()
        }

        store?.send(
            storeAction: .save(
                recipes: self.testRecipes,
                saver: nil
            )
        )

        wait(for: [expectation], timeout: 0.0)
    }

    func testStore_WhenWeakSinkDropped_DoesNotSendModel() throws {
        let firstSink = RecipeListDomainModelSinkMock()
        let expectation = XCTestExpectation()
        expectation.expectedFulfillmentCount = 1

        let store = RecipeListCoreDataStore(
            sink: firstSink,
            storeUser: self.testUser,
            objectContext: self.context
        )

        firstSink.sendDomainModelClosure = { model in
            XCTAssertEqual(
                self.testRecipes.sorted(),
                model.sorted()
            )
            expectation.fulfill()
        }

        var secondSink = RecipeListDomainModelSinkMock()

        store?.registerWeak(sink: secondSink)

        let badExpectation = XCTestExpectation()
        badExpectation.isInverted = true
        secondSink.sendDomainModelClosure = { _ in
            expectation.fulfill()
        }

        secondSink = .init()

        store?.send(
            storeAction: .save(
                recipes: self.testRecipes,
                saver: nil
            )
        )

        wait(for: [expectation, badExpectation], timeout: 0.0)
    }

    func testStore_WhenSaveWithSaver_DoesNotSendModelToSaver() throws {
        let firstSink = RecipeListDomainModelSinkMock()
        let expectation = XCTestExpectation()
        expectation.expectedFulfillmentCount = 1

        let store = RecipeListCoreDataStore(
            sink: firstSink,
            storeUser: self.testUser,
            objectContext: self.context
        )

        firstSink.sendDomainModelClosure = { model in
            XCTAssertEqual(
                self.testRecipes.sorted(),
                model.sorted()
            )
            expectation.fulfill()
        }

        let secondSink = RecipeListDomainModelSinkMock()

        store?.registerWeak(sink: secondSink)

        let badExpectation = XCTestExpectation()
        badExpectation.isInverted = true
        secondSink.sendDomainModelClosure = { _ in
            expectation.fulfill()
        }

        store?.send(
            storeAction: .save(
                recipes: self.testRecipes,
                saver: secondSink
            )
        )
    }

    func testSetup_DoesInitializeDataAsExpected() throws {
        let mockSink = RecipeListDomainModelSinkMock()

        let expectation = XCTestExpectation()
        mockSink.sendDomainModelClosure = { received in
            XCTAssert(
                zip(received.sorted(), self.testRecipes.sorted())
                    .allSatisfy({ (first, second) in
                        first == second
                    })
            )
            expectation.fulfill()
        }

        let _ = RecipeListCoreDataStore(
            sink: mockSink,
            storeUser: self.testUser,
            objectContext: self.context
        )

        wait(for: [expectation], timeout: 0.0)
    }

    func assertExpected(
        recipesForUser testUser: CDUser,
        expectedRecipes: [Recipe]
    ) {
        let savedRecipeSet = testUser.recipes
        let savedCDRecipes = savedRecipeSet?
            .compactMap { element -> CDRecipe? in
                return element as? CDRecipe
            }

        let savedRecipes = savedCDRecipes?
            .map { cdRecipe -> Recipe in
                return Recipe(
                    id: .init(rawId: cdRecipe.id!),
                    name: cdRecipe.name!,
                    description: cdRecipe.userDescription!,
                    recipeDetails: cdRecipe
                        .recipeSteps
                        .flatMap { $0.count == 0 ? nil : $0 }
                        .map { steps in
                            .init(
                                steps: steps.compactMap({ ($0 as? CDRecipeStep)?.toDomain() })
                            )
                        }

                )
            } ?? []

        XCTAssertEqual(
            savedRecipes.sorted(),
            expectedRecipes.sorted()
        )
    }

    func testSetup_DoesSaveNewData() throws {
        let newRecipes = [
            Recipe(
                name: "New Name",
                description: "New Description"
            )
        ]

        let mockSink = RecipeListDomainModelSinkMock()
        let store = RecipeListCoreDataStore(
            sink: mockSink,
            storeUser: self.testUser,
            objectContext: self.context
        )

        expectation(
            forNotification: .NSManagedObjectContextDidSave,
            object: self.context
        ) { _ in
            self.assertExpected(
                recipesForUser: self.testUser,
                expectedRecipes: newRecipes
            )

            return true
        }

        store?.send(
            storeAction: .save(
                recipes: newRecipes,
                saver: nil
            )
        )

        waitForExpectations(timeout: 1.0)
    }

}
