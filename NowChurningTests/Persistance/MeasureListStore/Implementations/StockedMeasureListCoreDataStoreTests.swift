//
//  StockedMeasureListCoreDataStoreTests.swift
//  NowChurningTests
//
//  Created by Austin Dumm on 5/13/23.
//

import XCTest
import CoreData

@testable import NowChurning

final class StockedMeasureListCoreDataStoreTests: XCTestCase {

    var store: StockedMeasureListCoreDataStore!

    var domainModelSink: MeasureListDomainModelSinkMock!
    var coreDataManager: MemoryCoreDataManager!

    var testUser: CDUser!

    var context: NSManagedObjectContext! {
        self.coreDataManager
            .persistentContainer?
            .viewContext
    }

    var testMeasures: [Measure] = [
        .init(
            ingredient: .init(
                name: "First",
                description: "First Description",
                tags: []
            ),
            measure: .any
        ),
        .init(
            ingredient: .init(
                name: "Second",
                description: "Second Description",
                tags: [.init(name: "Tag1")]
            ),
            measure: .volume(.init(value: 2.832, unit: .fluidOunces))
        ),
        .init(
            ingredient: .init(
                name: "Third",
                description: "Third Description",
                tags: [.init(name: "Tag2"), .init(name: "Tag3")]
            ),
            measure: .count(.init(value: 1.0, unit: .count), "Test Count")
        ),
        .init(
            ingredient: .init(
                name: "Fourth",
                description: "Fourth Description",
                tags: [.init(name: "Tag4")]
            ),
            measure: .any
        ),
    ]

    override func setUpWithError() throws {
        self.coreDataManager = .init()
        self.domainModelSink = .init()
        self.testUser = .init(context: self.context)

        self.store = .init(
            domainModelSink: self.domainModelSink,
            user: self.testUser,
            context: self.context
        )

        self.testMeasures
            .forEach { measure in
                self.testUser.addToStockedMeasures(
                    CDStockedMeasure(
                        fromDomainModel: measure,
                        forUser: self.testUser,
                        context: self.context
                    )
                )
            }

        try self.context.save()
    }

    override func tearDownWithError() throws {
        self.coreDataManager = nil
        self.testUser = nil
    }

    func assert(
        receivedModel: [Measure],
        matchesExpectedModel expectedModel: [Measure]
    ) {
        for (received, expected)
                in zip(receivedModel.sorted(), expectedModel.sorted()) {
            var received = received
            var expected = expected

            received.ingredient.tags.sort()
            expected.ingredient.tags.sort()

            XCTAssertEqual(
                received,
                expected
            )
        }
    }

    func testStore_WhenInit_DoesSendModel() throws {
        let expectation = XCTestExpectation()
        self.domainModelSink.sendDomainModelClosure = { model in
            self.assert(
                receivedModel: model,
                matchesExpectedModel: self.testMeasures
            )
            expectation.fulfill()
        }

        let _ = StockedMeasureListCoreDataStore(
            domainModelSink: self.domainModelSink,
            user: self.testUser,
            context: self.context
        )

        wait(for: [expectation],
             timeout: 0.0)
    }

    func testStore_WhenNewModelSaved_DoesSendNewModel() throws {
        let expectation = XCTestExpectation()
        self.domainModelSink.sendDomainModelClosure = { model in
            self.assert(
                receivedModel: model,
                matchesExpectedModel: self.testMeasures
            )
            expectation.fulfill()
        }

        self.store?.send(
            action: .save(
                measures: self.testMeasures,
                saver: nil
            )
        )

        wait(
            for: [expectation],
            timeout: 0.0
        )
    }

    func testStore_WhenNewSinkRegistered_DoesSendModel() throws {
        let firstSink = MeasureListDomainModelSinkMock()
        let store = StockedMeasureListCoreDataStore(
            domainModelSink: firstSink,
            user: self.testUser,
            context: self.context
        )

        let testSink = MeasureListDomainModelSinkMock()
        let expectation = XCTestExpectation()
        testSink.sendDomainModelClosure = { model in
            self.assert(
                receivedModel: model,
                matchesExpectedModel: self.testMeasures
            )
            expectation.fulfill()
        }

        store?.registerSink(asWeak: testSink)
        wait(for: [expectation],
             timeout: 0.0)
    }

    func testStore_WhenMultipleRegistered_DoesSendToAll() throws {
        let expectation = XCTestExpectation()
        expectation.expectedFulfillmentCount = 2
        self.domainModelSink.sendDomainModelClosure = { model in
            self.assert(
                receivedModel: model,
                matchesExpectedModel: self.testMeasures
            )
            expectation.fulfill()
        }

        let secondSink = MeasureListDomainModelSinkMock()

        store?.registerSink(asWeak: secondSink)

        secondSink.sendDomainModelClosure = { model in
            self.assert(
                receivedModel: model,
                matchesExpectedModel: self.testMeasures
            )
            expectation.fulfill()
        }

        store?.send(
            action: .save(
                measures: self.testMeasures,
                saver: nil
            )
        )

        wait(for: [expectation], timeout: 0.0)
    }

    func testStore_WhenWeakSinkDropped_DoesNotSendModel() throws {
        let expectation = XCTestExpectation()
        expectation.expectedFulfillmentCount = 1

        self.domainModelSink.sendDomainModelClosure = { model in
            self.assert(
                receivedModel: model,
                matchesExpectedModel: self.testMeasures
            )
            expectation.fulfill()
        }

        var secondSink = MeasureListDomainModelSinkMock()

        store?.registerSink(asWeak: secondSink)

        let badExpectation = XCTestExpectation()
        badExpectation.isInverted = true
        secondSink.sendDomainModelClosure = { _ in
            expectation.fulfill()
        }

        secondSink = .init()

        store?.send(
            action: .save(
                measures: self.testMeasures,
                saver: nil
            )
        )

        wait(for: [expectation, badExpectation], timeout: 0.0)
    }

    func testStore_WhenSaveWithSaver_DoesNotSendModelToSaver() throws {
        let firstSink = MeasureListDomainModelSinkMock()
        let expectation = XCTestExpectation()
        expectation.expectedFulfillmentCount = 1

        firstSink.sendDomainModelClosure = { model in
            self.assert(
                receivedModel: model,
                matchesExpectedModel: self.testMeasures
            )
            expectation.fulfill()
        }

        let secondSink = MeasureListDomainModelSinkMock()

        store?.registerSink(asWeak: secondSink)

        let badExpectation = XCTestExpectation()
        badExpectation.isInverted = true
        secondSink.sendDomainModelClosure = { _ in
            expectation.fulfill()
        }

        store?.send(
            action: .save(
                measures: self.testMeasures,
                saver: secondSink
            )
        )
    }

    func testSetup_DoesInitializeDataAsExpected() throws {
        let mockSink = MeasureListDomainModelSinkMock()

        let expectation = XCTestExpectation()
        mockSink.sendDomainModelClosure = { received in
            self.assert(
                receivedModel: received,
                matchesExpectedModel: self.testMeasures
            )
            expectation.fulfill()
        }

        let _ = StockedMeasureListCoreDataStore(
            domainModelSink: mockSink,
            user: self.testUser,
            context: self.context
        )

        wait(for: [expectation], timeout: 0.0)
    }

    func assertExpected(
        measuresForUser testUser: CDUser,
        expectedMeasure: [Measure]
    ) {
        let savedMeasureSet = testUser.stockedMeasures
        let savedCDStockedMeasure = savedMeasureSet?
            .compactMap { element -> CDStockedMeasure? in
                return element as? CDStockedMeasure
            }

        let savedMeasure = savedCDStockedMeasure?
            .compactMap { cdMeasure -> Measure? in
                return cdMeasure.toDomain()
            } ?? []

        self.assert(
            receivedModel: savedMeasure,
            matchesExpectedModel: expectedMeasure
        )
    }

    func testSetup_DoesSaveNewData() throws {
        let newMeasures = [
            Measure(
                ingredient: .init(
                    name: "New",
                    description: "New",
                    tags: []
                ),
                measure: .any
            )
        ]

        let mockSink = MeasureListDomainModelSinkMock()
        let store = StockedMeasureListCoreDataStore(
            domainModelSink: mockSink,
            user: self.testUser,
            context: self.context
        )

        expectation(
            forNotification: .NSManagedObjectContextDidSave,
            object: self.context
        ) { _ in
            self.assertExpected(
                measuresForUser: self.testUser,
                expectedMeasure: newMeasures
            )

            return true
        }

        store?.send(
            action: .save(
                measures: newMeasures,
                saver: nil
            )
        )

        waitForExpectations(timeout: 1.0)
    }
}
