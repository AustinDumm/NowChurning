//
//  RecipeFromListStoreTests.swift
//  NowChurningTests
//
//  Created by Austin Dumm on 3/4/23.
//

import XCTest
@testable import NowChurning

final class RecipeFromListStoreTests: XCTestCase {
    
    let testRecipe = Recipe(
        name: "Test Recipe Name",
        description: "Test Recipe Description"
    )
    var recipeList: [Recipe]!

    var manager: CoreDataManager!
    var testUser: CDUser {
        .init(context: manager.persistentContainer!.viewContext)
    }

    var store: RecipeFromListStore!
    var modelSink: RecipeDetailsDomainModelSinkMock!
    var storeActionSink: RecipeListStoreActionSinkMock!
    
    override func setUpWithError() throws {
        self.manager = MemoryCoreDataManager()
        recipeList = [
            .init(name: "", description: ""),
            .init(name: "", description: ""),
            self.testRecipe,
            .init(name: "", description: ""),
        ]
        
        self.modelSink = .init()
        self.storeActionSink = .init()
        self.store = .init(
            user: self.testUser,
            modelSink: self.modelSink,
            storeSink: self.storeActionSink,
            id: self.testRecipe.id
        )
    }
    
    func testStore_WhenGivenList_DoesSendRecipe() throws {
        let expectation = XCTestExpectation()
        self.modelSink.sendDomainModelClosure = { model in
            XCTAssertEqual(
                model.recipe,
                self.testRecipe
            )
            expectation.fulfill()
        }
        
        self.store.send(domainModel: self.recipeList)
        wait(for: [expectation], timeout: 0.0)
    }
    
    func testStore_WhenGivenNoMatchList_SendsNothing() throws {
        let expectation = XCTestExpectation()
        expectation.isInverted = true
        self.modelSink.sendDomainModelClosure = { model in
            expectation.fulfill()
        }
        
        self.store.send(domainModel: [
            .init(name: "", description: ""),
            .init(name: "", description: ""),
            .init(name: "", description: ""),
            .init(name: "", description: ""),
        ])
        wait(for: [expectation], timeout: 0.0)
    }
    
    func testStore_WhenSendSaveIngredient_DoesSendNewIngredientList() throws {
        var recipeList: [Recipe] = [
            .init(id: testRecipe.id, name: "", description: ""),
            .init(name: "", description: ""),
            .init(name: "", description: ""),
            .init(name: "", description: ""),
        ]
        self.store.send(domainModel: recipeList)
        recipeList[0] = testRecipe

        let expectation = XCTestExpectation()
        self.storeActionSink.sendStoreActionClosure = { action in
            switch action {
            case .save(
                recipes: let recipes,
                saver: _
            ):
                XCTAssertEqual(
                    recipes,
                    recipeList
                )
                expectation.fulfill()
            default:
                XCTFail("Expected .save. Found: \(action)")
            }
        }

        self.store
            .send(action: .save(recipe: testRecipe))
        wait(for: [expectation], timeout: 0.0)
    }

}
