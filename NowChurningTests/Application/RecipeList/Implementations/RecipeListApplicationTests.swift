//
//  RecipeListApplicationTests.swift
//  NowChurningTests
//
//  Created by Austin Dumm on 3/3/23.
//

import XCTest
@testable import NowChurning

final class RecipeListApplicationTests: XCTestCase {

    var application: RecipeListApplication!
    var delegate: RecipeListApplicationDelegateMock!
    var displayModelSink: RecipeListDisplayModelSinkMock!
    var storeSink: RecipeListStoreActionSinkMock!

    var testRecipes: [Recipe] = [
        .init(name: "Boulevardier", description: "Boulevardier Description"),
        .init(name: "Bee's Knees", description: "Bee's Knees Description"),
        .init(name: "Old Fashioned", description: "Old Fashioned Description"),
        .init(name: "Martini", description: "Martini Description"),
        .init(name: "Aviation", description: "Aviation Description"),
    ]

    override func setUpWithError() throws {
        self.delegate = .init()
        self.application = .init(delegate: self.delegate)
        self.displayModelSink = .init()
        self.storeSink = .init()

        self.application.displayModelSink = self.displayModelSink
        self.application.storeActionSink = self.storeSink
    }

    func assert(
        isExpectedDisplayModel displayModel: RecipeListDisplayModel,
        forDomainModel domainModel: [Recipe]
    ) {
        XCTAssertEqual(
            displayModel
                .recipeSections
                .map { $0.items.count }
                .reduce(0, +),
            domainModel.count
        )

        XCTAssert(
            displayModel
                .recipeSections
                .isSorted(by: { lhs, rhs in
                    lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
                })
        )

        XCTAssert(
            displayModel
                .recipeSections
                .allSatisfy { section in
                    section
                        .items
                        .isSorted { lhs, rhs in
                            lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
                        }
                }
        )

        for recipe in domainModel {
            let name = recipe.name.capitalized
            let firstLetter = name.first!

            guard let section = displayModel.recipeSections.first(where: { section in
                section.title.lowercased() == String(firstLetter).lowercased()
            }) else {
                XCTFail("Could not find section for letter: \(firstLetter)")
                return
            }

            XCTAssert(
                section
                    .items
                    .contains(where: { item in
                        item.title == name
                    })
            )
        }
    }

    func testApplication_WhenDisplayModelSinkSet_SendsDisplayModel() throws {
        self.application.send(domainModel: self.testRecipes)
        let expectation = XCTestExpectation()
        expectation.expectedFulfillmentCount = 2
        let newDisplayModelSink = RecipeListDisplayModelSinkMock()
        newDisplayModelSink
            .sendDisplayModelClosure = { displayModel in
                self.assert(
                    isExpectedDisplayModel: displayModel,
                    forDomainModel: self.testRecipes
                )
                expectation.fulfill()
            }
        newDisplayModelSink
            .sendEditModeDisplayModelClosure = { editModel in
                XCTAssertFalse(editModel.isEditing)
                expectation.fulfill()
            }

        self.application.displayModelSink = newDisplayModelSink
        wait(
            for: [expectation],
            timeout: 0.0
        )
    }

    func testApplication_WhenRecvDomainModel_SendsDisplayModel() throws {
        let expectation = XCTestExpectation()
        self.displayModelSink
            .sendDisplayModelClosure = { displayModel in
                self.assert(
                    isExpectedDisplayModel: displayModel,
                    forDomainModel: self.testRecipes
                )
                expectation.fulfill()
            }

        self.application.send(domainModel: self.testRecipes)
        wait(
            for: [expectation],
            timeout: 0.0
        )
    }

    func testApplication_WhenNavigateAction_DoesAlertDelegate() throws {
        let testIndex = 1
        let expectedRecipe = self.testRecipes[testIndex]
        let recipeSection = 1
        let recipeItem = 0

        let expectation = XCTestExpectation()
        self.application.send(domainModel: self.testRecipes)
        self.delegate.navigateToDetailsForRecipeClosure = { recipe in
            XCTAssertEqual(
                recipe,
                expectedRecipe
            )
            expectation.fulfill()
        }

        self.application
            .send(
                action: .selectedItem(
                    inSection: recipeSection,
                    atIndex: recipeItem
                )
            )
        wait(for: [expectation], timeout: 0.0)
    }

    func testApplication_WhenStartEditing_DoesSendDisplayModels() throws {
        self.application
            .send(domainModel: self.testRecipes)

        let expectation = XCTestExpectation()
        self.displayModelSink.sendEditModeDisplayModelClosure = { model in
            XCTAssert(model.isEditing)
            XCTAssertFalse(model.canSave)
            expectation.fulfill()
        }

        self.application
            .send(editModeAction: .startEditing)
        wait(for: [expectation], timeout: 0.0)
    }

    func testApplication_WhenCancelEditingNoChanges_ImmediatelyCancels() throws {
        self.application
            .send(domainModel: self.testRecipes)
        self.application
            .send(editModeAction: .startEditing)

        let expectation = XCTestExpectation()
        self.displayModelSink.sendEditModeDisplayModelClosure = { model in
            XCTAssertFalse(model.isEditing)
            expectation.fulfill()
        }

        self.application
            .send(editModeAction: .finishEditing(.cancel))
        wait(for: [expectation], timeout: 0.0)
    }

    func testApplication_WhenEditMade_SendsEditDisplayModel() throws {
        self.application
            .send(domainModel: self.testRecipes)
        self.application
            .send(editModeAction: .startEditing)

        let expectation = XCTestExpectation()
        self.displayModelSink.sendEditModeDisplayModelClosure = { model in
            XCTAssert(model.isEditing)
            XCTAssert(model.canSave)
            expectation.fulfill()
        }

        self.application
            .send(action: .deleteItem(inSection: 1, atIndex: 0))
        wait(for: [expectation], timeout: 0.0)
    }

    func testApplication_WhenEditMade_SendsUpdatedDisplayModel() throws {
        let deletedRecipe = self.testRecipes[1]
        let sectionDeleted = 1
        let indexDeleted = 0

        self.application
            .send(domainModel: self.testRecipes)
        self.application
            .send(editModeAction: .startEditing)

        let expectation = XCTestExpectation()
        self.displayModelSink.sendDisplayModelClosure = { displayModel in
            XCTAssert(
                !displayModel
                    .recipeSections
                    .contains(where: { section in
                        section
                            .items
                            .contains(where: { foundItem in
                                foundItem.id.rawId == deletedRecipe.id
                                    .rawId
                            })
                    })
            )

            expectation.fulfill()
        }

        self.application
            .send(
                action: .deleteItem(
                    inSection: sectionDeleted,
                    atIndex: indexDeleted
                )
            )
        wait(for: [expectation], timeout: 0.0)
    }

    func testApplication_WhenCancelEditingWithChanges_SendsAlert() throws {
        self.application
            .send(domainModel: self.testRecipes)
        self.application
            .send(editModeAction: .startEditing)

        self.application
            .send(action: .deleteItem(inSection: 1, atIndex: 0))

        let badExpectation = XCTestExpectation()
        badExpectation.isInverted = true
        self.displayModelSink.sendEditModeDisplayModelClosure = { model in
            badExpectation.fulfill()
        }
        let expectation = XCTestExpectation()
        self.displayModelSink.sendAlertDisplayModelDidConfirmClosure = { _, _ in
            expectation.fulfill()
        }

        self.application
            .send(editModeAction: .finishEditing(.cancel))
        wait(for: [badExpectation, expectation], timeout: 0.0)
    }

    func testApplication_WhenCancelAndConfirm_SendsCanceled() throws {
        self.application
            .send(domainModel: self.testRecipes)
        self.application
            .send(editModeAction: .startEditing)
        self.application
            .send(action: .deleteItem(inSection: 0, atIndex: 1))

        let expectation = XCTestExpectation()
        self.displayModelSink
            .sendDisplayModelClosure = { displayModel in
                self.assert(
                    isExpectedDisplayModel: displayModel,
                    forDomainModel: self.testRecipes
                )
                expectation.fulfill()
            }
        self.displayModelSink
            .sendAlertDisplayModelDidConfirmClosure = { _, closure in
                closure(true)
            }

        self.application
            .send(editModeAction: .finishEditing(.cancel))
        wait(for: [expectation], timeout: 0.0)
    }

    func testApplication_WhenSaveNoChanges_SendsNoSave() throws {
        self.application
            .send(domainModel: self.testRecipes)
        self.application
            .send(editModeAction: .startEditing)

        let expectation = XCTestExpectation()
        self.displayModelSink.sendEditModeDisplayModelClosure = { model in
            XCTAssertFalse(model.isEditing)
            expectation.fulfill()
        }

        let badExpectation = XCTestExpectation()
        badExpectation.isInverted = true
        self.storeSink.sendStoreActionClosure = { _ in
            badExpectation.fulfill()
        }

        self.application
            .send(editModeAction: .finishEditing(.save))
        wait(for: [expectation, badExpectation], timeout: 0.0)
    }

    func testApplication_WhenSaveWithChanges_SendsSave() throws {
        self.application
            .send(domainModel: self.testRecipes)
        self.application
            .send(editModeAction: .startEditing)

        let testIndex = 1
        self.application
            .send(action: .deleteItem(inSection: 1, atIndex: 0))

        let expectation = XCTestExpectation()
        expectation.expectedFulfillmentCount = 2
        self.displayModelSink.sendEditModeDisplayModelClosure = { model in
            XCTAssertFalse(model.isEditing)
            expectation.fulfill()
        }

        self.storeSink.sendStoreActionClosure = { action in
            var expected = self.testRecipes
            expected.remove(at: testIndex)
            switch action {
            case .save(recipes: let receieved, saver: _):
                XCTAssertEqual(
                    receieved,
                    expected
                )
            default:
                XCTFail("Expected .save. Found: \(action)")
            }

            expectation.fulfill()
        }

        self.application
            .send(editModeAction: .finishEditing(.save))
        wait(for: [expectation], timeout: 0.0)
    }

    func testApplication_WhenNewRecipe_SendsNavigationCall() throws {
        let expectation = XCTestExpectation()
        self.delegate.navigateToAddRecipeClosure = {
            expectation.fulfill()
        }

        self.application
            .send(action: .newRecipe)

        wait(for: [expectation], timeout: 0.0)
    }

}
