//
//  NewNIngredientFromListStoreTests.swift
//  NowChurningTests
//
//  Created by Austin Dumm on 12/20/22.
//

import XCTest
@testable import NowChurning

final class NewIngredientFromListStoreTests: XCTestCase {

    let testIngredient = Ingredient(
        name: "Testing",
        description: "This is the test description",
        tags: []
    )

    var ingredientList: [Ingredient]!

    override func setUp() {
        self.ingredientList = [
            .init(
                name: "",
                description: "",
                tags: []
            ),
            .init(
                name: "",
                description: "",
                tags: []
            ),
            testIngredient,
            .init(
                name: "",
                description: "",
                tags: []
            ),
        ]
    }

    func testStore_WhenSentInit_DoesSendInitModel() {
        let mockSink = IngredientDomainModelSinkMock()
        let mockStore = IngredientListStoreActionSinkMock()

        let expectation = XCTestExpectation()
        mockSink.sendDomainModelClosure = { receivedIngredient in
            XCTAssertEqual(
                self.testIngredient,
                receivedIngredient.ingredient
            )
            expectation.fulfill()
        }

        let _ = NewIngredientFromListStore(
            initialIngredient: self.testIngredient,
            modelSink: mockSink,
            storeSink: mockStore
        )

        wait(for: [expectation], timeout: 0.0)
    }

    func testStore_WhenSendSave_DoesSendSaveToListStore() {
        let newIngredient = Ingredient(
            name: "New name",
            description: "New description",
            tags: [.init(name: "New Tag")]
        )

        var newList = self.ingredientList
        newList?.append(newIngredient)

        let mockSink = IngredientDomainModelSinkMock()
        let mockStore = IngredientListStoreActionSinkMock()

        let store = NewIngredientFromListStore(
            modelSink: mockSink,
            storeSink: mockStore
        )
        store.send(domainModel: self.ingredientList)

        let expectation = XCTestExpectation()
        mockStore.sendActionClosure = { action in
            switch action {
            case .save(let ingredients, let saver):
                XCTAssertIdentical(
                    store,
                    saver
                )

                XCTAssertEqual(
                    newList,
                    ingredients
                )
                expectation.fulfill()
            }
        }

        store.send(
            action: .save(
                ingredient: newIngredient
            )
        )

        wait(for: [expectation], timeout: 0.0)
    }

}
