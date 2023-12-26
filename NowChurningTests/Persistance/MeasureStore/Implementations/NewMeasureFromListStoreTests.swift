//
//  NewMeasureFromListStoreTests.swift
//  NowChurningTests
//
//  Created by Austin Dumm on 5/14/23.
//

import XCTest
@testable import NowChurning

final class NewMeasureFromListStoreTests: XCTestCase {

    let testMeasure = Measure(
        ingredient: .init(
            name: "Testing",
            description: "This is the test description",
            tags: []
        ),
        measure: .any
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

    func testStore_WhenSentInit_DoesSendInitModel() {
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

        let _ = NewMeasureFromListStore(
            initialMeasure: self.testMeasure,
            modelSink: mockSink,
            storeSink: mockStore
        )

        wait(for: [expectation], timeout: 0.0)
    }

    func testStore_WhenSentList_DoesNotSendModel() {
        let mockSink = MeasureDomainModelSinkMock()
        let mockStore = MeasureListStoreActionSinkMock()

        let store = NewMeasureFromListStore(
            modelSink: mockSink,
            storeSink: mockStore
        )

        let expectation = XCTestExpectation()
        expectation.isInverted = true
        mockSink.sendDomainModelIngredientNameLookupClosure = { receivedMeasure, _ in
            expectation.fulfill()
        }

        store.send(domainModel: self.measureList)

        wait(for: [expectation], timeout: 0.0)
    }

    func testStore_WhenSendSave_DoesSendSaveToListStore() {
        let newMeasure = Measure(
            ingredient: .init(
                name: "New name",
                description: "New description",
                tags: [.init(name: "New Tag")]
            ),
            measure: .count(.init(value: 1.0, unit: .count), "Test Count")
        )

        var newList = self.measureList
        newList?.append(newMeasure)

        let mockSink = MeasureDomainModelSinkMock()
        let mockStore = MeasureListStoreActionSinkMock()

        let store = NewMeasureFromListStore(
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

    func testStore_WhenSentIngredients_SendsLookup() {
        let mockSink = MeasureDomainModelSinkMock()
        let mockStore = MeasureListStoreActionSinkMock()

        let store = NewMeasureFromListStore(
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
