//
//  IngredientFromListStoreTests.swift
//  NowChurningTests
//
//  Created by Austin Dumm on 12/20/22.
//

import XCTest
@testable import NowChurning

final class IngredientFromListStoreTests: XCTestCase {

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

    func testStore_WhenSentList_DoesSendModel() {
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

        let store = IngredientFromListStore(
            id: self.testIngredient.id,
            modelSink: mockSink,
            storeSink: mockStore
        )
        store.send(domainModel: self.ingredientList)

        wait(for: [expectation], timeout: 0.0)
    }

    func testStore_WhenSendSave_DoesSendSaveToListStore() {
        let newIngredient = Ingredient(
            id: self.testIngredient.id,
            name: "New name",
            description: "New description",
            tags: [.init(name: "New Tag")]
        )
        var newList = self.ingredientList

        newList![(newList?.firstIndex(where: { $0.id == self.testIngredient.id }))!] = newIngredient

        let mockSink = IngredientDomainModelSinkMock()
        let mockStore = IngredientListStoreActionSinkMock()

        let store = IngredientFromListStore(
            id: self.testIngredient.id,
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

    func testStore_WhenSentOtherIngredient_DoesNotSave() {
        let invalidIngredient = Ingredient(
            name: "New name",
            description: "New description",
            tags: [.init(name: "New Tag")]
        )

        let mockSink = IngredientDomainModelSinkMock()
        let mockStore = IngredientListStoreActionSinkMock()

        let store = IngredientFromListStore(
            id: self.testIngredient.id,
            modelSink: mockSink,
            storeSink: mockStore
        )
        store.send(domainModel: self.ingredientList)

        let badExpectation = XCTestExpectation()
        badExpectation.isInverted = true
        mockStore.sendActionClosure = { action in
            badExpectation.fulfill()
        }

        store.send(
            action: .save(
                ingredient: invalidIngredient
            )
        )

        wait(for: [badExpectation], timeout: 0.0)
    }

}
