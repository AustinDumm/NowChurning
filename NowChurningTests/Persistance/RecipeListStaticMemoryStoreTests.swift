//
//  RecipeListStaticMemoryStoreTests.swift
//  NowChurningTests
//
//  Created by Austin Dumm on 4/10/23.
//

import XCTest

@testable import NowChurning

final class RecipeListStaticMemoryStoreTests: XCTestCase {

    let testRecipes: [Recipe] = RecipeListStaticMemoryStore.dummyModel

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testStore_WhenInit_DoesSendModel() throws {
        let mockSink = RecipeListDomainModelSinkMock()

        let expectation = XCTestExpectation()
        mockSink.sendDomainModelClosure = { model in
            XCTAssertEqual(
                self.testRecipes.sorted(),
                model.sorted()
            )
            expectation.fulfill()
        }

        let _ = RecipeListStaticMemoryStore(
            domainModelSink: mockSink
        )

        wait(for: [expectation],
             timeout: 0.0)
    }

    func testStore_WhenNewModelSaved_DoesSendNewModel() throws {
        let mockSink = RecipeListDomainModelSinkMock()
        let store = RecipeListStaticMemoryStore(
            domainModelSink: mockSink
        )

        let expectation = XCTestExpectation()
        mockSink.sendDomainModelClosure = { model in
            XCTAssertEqual(
                self.testRecipes.sorted(),
                model.sorted()
            )
            expectation.fulfill()
        }

        store.send(
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
        let store = RecipeListStaticMemoryStore(
            domainModelSink: firstSink
        )

        let testSink = RecipeListDomainModelSinkMock()
        let expectation = XCTestExpectation()
        testSink.sendDomainModelClosure = { model in
            XCTAssertEqual(
                self.testRecipes.sorted(),
                model.sorted()
            )
            expectation.fulfill()
        }

        store.registerWeak(sink: testSink)
        wait(for: [expectation],
             timeout: 0.0)
    }

    func testStore_WhenMultipleRegistered_DoesSendToAll() throws {
        let firstSink = RecipeListDomainModelSinkMock()
        let expectation = XCTestExpectation()
        expectation.expectedFulfillmentCount = 2

        let store = RecipeListStaticMemoryStore(
            domainModelSink: firstSink
        )

        firstSink.sendDomainModelClosure = { model in
            XCTAssertEqual(
                self.testRecipes.sorted(),
                model.sorted()
            )
            expectation.fulfill()
        }

        let secondSink = RecipeListDomainModelSinkMock()

        store.registerWeak(sink: secondSink)

        secondSink.sendDomainModelClosure = { model in
            XCTAssertEqual(
                self.testRecipes.sorted(),
                model.sorted()
            )
            expectation.fulfill()
        }

        store.send(
            storeAction: .save(
                recipes: self.testRecipes,
                saver: nil
            )
        )
    }

    func testStore_WhenWeakSinkDropped_DoesNotSendModel() throws {
        let firstSink = RecipeListDomainModelSinkMock()
        let expectation = XCTestExpectation()
        expectation.expectedFulfillmentCount = 1

        let store = RecipeListStaticMemoryStore(
            domainModelSink: firstSink
        )

        firstSink.sendDomainModelClosure = { model in
            XCTAssertEqual(
                self.testRecipes.sorted(),
                model.sorted()
            )
            expectation.fulfill()
        }

        var secondSink = RecipeListDomainModelSinkMock()

        store.registerWeak(sink: secondSink)

        let badExpectation = XCTestExpectation()
        badExpectation.isInverted = true
        secondSink.sendDomainModelClosure = { _ in
            expectation.fulfill()
        }

        secondSink = .init()

        store.send(
            storeAction: .save(
                recipes: self.testRecipes,
                saver: nil
            )
        )
    }

    func testStore_WhenSaveWithSaver_DoesNotSendModelToSaver() throws {
        let firstSink = RecipeListDomainModelSinkMock()
        let expectation = XCTestExpectation()
        expectation.expectedFulfillmentCount = 1

        let store = RecipeListStaticMemoryStore(
            domainModelSink: firstSink
        )

        firstSink.sendDomainModelClosure = { model in
            XCTAssertEqual(
                self.testRecipes.sorted(),
                model.sorted()
            )
            expectation.fulfill()
        }

        let secondSink = RecipeListDomainModelSinkMock()

        store.registerWeak(sink: secondSink)

        let badExpectation = XCTestExpectation()
        badExpectation.isInverted = true
        secondSink.sendDomainModelClosure = { _ in
            expectation.fulfill()
        }

        store.send(
            storeAction: .save(
                recipes: self.testRecipes,
                saver: secondSink
            )
        )
    }

}
