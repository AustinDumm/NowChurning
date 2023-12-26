//
//  MainScreenApplicationTests.swift
//  NowChurningTests
//
//  Created by Austin Dumm on 10/18/22.
//

import XCTest
@testable import NowChurning

final class MainScreenApplicationTests: XCTestCase {

    let actions = MainScreenApplication.Action.allCases

    let mockDisplayModelSink = MockMainScreenDisplayModelSink()
    let mockNavDelegate = MockMainScreenAppNavDelegate()

    let testContent = MainScreenSupervisor.Content(
        headerTitle: "Test Header",
        tilesContent: .init(
            inventoryTitle: "Test Bar Title",
            myRecipesTitle: "Test Recipes Title"
        )
    )

    var application: MainScreenApplication!

    override func setUpWithError() throws {
        self.application = .init(
            actions: self.actions,
            navDelegate: self.mockNavDelegate,
            content: self.testContent.tilesContent
        )

        self.application.displayModelSink = mockDisplayModelSink
    }

    override func tearDownWithError() throws {
        mockDisplayModelSink.displayCallback = nil
        mockNavDelegate.navigateCallback = nil
    }

    func testApplication_WhenGivenDefaultActions_DoesBuildCorrectDisplayModel() throws {
        let displayModel = self.mockDisplayModelSink.lastDisplayModel!

        XCTAssertEqual(self.actions.count,
                       displayModel.items.count)

        for (action, displayModelItem) in
                zip(self.actions, displayModel.items) {
            switch action {
            case .myRecipes:
                XCTAssertEqual(.recipes,
                               displayModelItem.icon)
                XCTAssertEqual(self.testContent.tilesContent.myRecipesTitle,
                               displayModelItem.text)
            case .inventory:
                XCTAssertEqual(.ingredients,
                               displayModelItem.icon)
                XCTAssertEqual(self.testContent.tilesContent.inventoryTitle,
                               displayModelItem.text)
            }
        }
    }

    func testApplication_WhenGivenDisplayModelSink_DoesUpdateDisplayModel() throws {
        let expectation = XCTestExpectation()
        mockDisplayModelSink.displayCallback = { _ in
            expectation.fulfill()
        }

        let application = MainScreenApplication(
            navDelegate: self.mockNavDelegate, 
            content: self.testContent.tilesContent
        )
        application.displayModelSink = mockDisplayModelSink

        wait(for: [expectation],
             timeout: 0.0)
    }

    func testApplication_WhenItemTapped_DoesUpdateNavDelegate() throws {
        func testInventory() {
            let inventoryExpectation = XCTestExpectation()
            inventoryExpectation.expectedFulfillmentCount = 1
            inventoryExpectation.isInverted = false
            let myRecipesExpectation = XCTestExpectation()
            myRecipesExpectation.expectedFulfillmentCount = 1
            myRecipesExpectation.isInverted = true

            self.mockNavDelegate.navigateCallback = { item in
                switch item {
                case .inventory:
                    inventoryExpectation.fulfill()
                case .myRecipes:
                    myRecipesExpectation.fulfill()
                }
            }

            self.application.send(action: .selectItem(atIndex: 0))
            wait(for: [inventoryExpectation, myRecipesExpectation],
                 timeout: 0.0)
        }

        func testMyRecipes() {
            let inventoryExpectation = XCTestExpectation()
            inventoryExpectation.expectedFulfillmentCount = 1
            inventoryExpectation.isInverted = false
            let myRecipesExpectation = XCTestExpectation()
            myRecipesExpectation.expectedFulfillmentCount = 1
            myRecipesExpectation.isInverted = true

            self.mockNavDelegate.navigateCallback = { item in
                switch item {
                case .inventory:
                    inventoryExpectation.fulfill()
                case .myRecipes:
                    myRecipesExpectation.fulfill()
                }
            }

            self.application.send(action: .selectItem(atIndex: 0))
            wait(for: [inventoryExpectation, myRecipesExpectation],
                 timeout: 0.0)
        }

        testInventory()
        testMyRecipes()
    }

    func testApplication_WhenItemTappedOutOfBounds_DoesNotUpdateNavDelegate() throws {
        let inventoryExpectation = XCTestExpectation()
        inventoryExpectation.isInverted = true
        let myRecipesExpectation = XCTestExpectation()
        myRecipesExpectation.isInverted = true

        self.mockNavDelegate.navigateCallback = { item in
            switch item {
            case .inventory:
                inventoryExpectation.fulfill()
            case .myRecipes:
                myRecipesExpectation.fulfill()
            }
        }

        self.application.send(action: .selectItem(atIndex: 3))
    }
}
