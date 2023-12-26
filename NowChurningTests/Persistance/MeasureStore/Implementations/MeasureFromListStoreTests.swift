//
//  MeasureFromListStoreTests.swift
//  NowChurningTests
//
//  Created by Austin Dumm on 5/14/23.
//

import XCTest
@testable import NowChurning

final class MeasureFromListStoreTests: XCTestCase {

    let testMeasure = Measure(
        ingredient: .init(
            name: "Testing",
            description: "This is the test description",
            tags: []
        ),
        measure: .count(.init(value: 1.5, unit: .count), "Test count")
    )

    var measureList: [Measure]!

    override func setUp() {
        self.measureList = [
            .init(
                ingredient: .init(
                    name: "",
                    description: "",
                    tags: []
                ),
                measure: .volume(.init(value: 2.75, unit: .fluidOunces))
            ),
            testMeasure,
            .init(
                ingredient: .init(
                    name: "",
                    description: "",
                    tags: []
                ),
                measure: .volume(.init(value: 2.75, unit: .fluidOunces))
            ),
            .init(
                ingredient: .init(
                    name: "",
                    description: "",
                    tags: []
                ),
                measure: .volume(.init(value: 2.75, unit: .fluidOunces))
            ),
        ]
    }

    func testStore_WhenSentList_DoesSendModel() {
        let mockSink = MeasureDomainModelSinkMock()
        let mockStore = MeasureListStoreActionSinkMock()

        let expectation = XCTestExpectation()
        mockSink.sendDomainModelIngredientNameLookupClosure = { receivedMeasure, _ in
            XCTAssertEqual(
                self.testMeasure,
                receivedMeasure
            )
            expectation.fulfill()
        }

        let store = MeasureFromListStore(
            id: self.testMeasure.ingredient.id,
            modelSink: mockSink,
            storeSink: mockStore
        )
        store.send(domainModel: self.measureList)

        wait(for: [expectation], timeout: 0.0)
    }

    func testStore_WhenSendSave_DoesSendSaveToListStore() {
        let newMeasure = Measure(
            ingredient: .init(
                id: self.testMeasure.ingredient.id,
                name: "New name",
                description: "New description",
                tags: [.init(name: "New Tag")]
            ),
            measure: .any
        )
        var newList = self.measureList

        newList![(newList?.firstIndex(where: { $0.ingredient.id == self.testMeasure.ingredient.id }))!] = newMeasure

        let mockSink = MeasureDomainModelSinkMock()
        let mockStore = MeasureListStoreActionSinkMock()

        let store = MeasureFromListStore(
            id: self.testMeasure.ingredient.id,
            modelSink: mockSink,
            storeSink: mockStore
        )
        store.send(domainModel: self.measureList)

        let expectation = XCTestExpectation()
        mockStore.sendActionClosure = { action in
            switch action {
            case .save(let measures, let saver):
                XCTAssertIdentical(
                    store,
                    saver
                )

                XCTAssertEqual(
                    newList,
                    measures
                )
                expectation.fulfill()
            }
        }

        store.send(
            action: .save(
                measure: newMeasure
            )
        )

        wait(for: [expectation], timeout: 0.0)
    }

    func testStore_WhenSentOtherMeasure_DoesNotSave() {
        let invalidMeasure = Measure(
            ingredient: .init(
                name: "New name",
                description: "New description",
                tags: [.init(name: "New Tag")]
            ),
            measure: .any
        )

        let mockSink = MeasureDomainModelSinkMock()
        let mockStore = MeasureListStoreActionSinkMock()

        let store = MeasureFromListStore(
            id: self.testMeasure.ingredient.id,
            modelSink: mockSink,
            storeSink: mockStore
        )
        store.send(domainModel: self.measureList)

        let badExpectation = XCTestExpectation()
        badExpectation.isInverted = true
        mockStore.sendActionClosure = { action in
            badExpectation.fulfill()
        }

        store.send(
            action: .save(
                measure: invalidMeasure
            )
        )

        wait(for: [badExpectation], timeout: 0.0)
    }

    func testStore_WhenSentIngredients_SendsLookup() {
        let mockSink = MeasureDomainModelSinkMock()
        let mockStore = MeasureListStoreActionSinkMock()

        let store = MeasureFromListStore(
            id: self.testMeasure.ingredient.id,
            modelSink: mockSink,
            storeSink: mockStore
        )
        store.send(domainModel: self.measureList)

        let allIngredients = [
            self.testMeasure.ingredient,
            .init(name: "1", description: "1", tags: []),
            .init(name: "2", description: "2", tags: []),
            .init(name: "3", description: "3", tags: []),
            .init(name: "4", description: "4", tags: []),
        ]

        let expectation = XCTestExpectation()
        mockSink.sendDomainModelIngredientNameLookupClosure = { _, lookup in
            XCTAssertEqual(
                lookup,
                Dictionary(
                    allIngredients.map { ($0.name.lowercased(), $0.id) }
                ) { first, _ in first }
            )
            expectation.fulfill()
        }

        store.send(domainModel: allIngredients)

        wait(for: [expectation], timeout: 0.0)
    }

}
