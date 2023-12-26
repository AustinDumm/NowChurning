//
//  IngredientListApplicationTests.swift
//  NowChurningTests
//
//  Created by Austin Dumm on 10/23/22.
//

import XCTest
@testable import NowChurning

final class IngredientListApplicationTests: XCTestCase {

    let ingredients: [Ingredient] = [
        .init(name: "2second", description: "", tags: []),
        .init(name: "1bfirst", description: "", tags: []),
        .init(name: "1afirst", description: "", tags: []),
        .init(name: "4fourth", description: "", tags: []),
        .init(name: "3third", description: "", tags: []),
    ]
    var delegate: IngredientListAppNavDelegateMock!
    var storeActionSink: IngredientListStoreActionSinkMock!
    var displayModelSink: IngredientListDisplayModelSinkMock!
    var application: IngredientListApplication!

    func assertMatchingDisplayModel(
        forExpectedDomainModel: [Ingredient],
        receivedDomainModel domainModel: IngredientListDisplayModel
    ) {
        let groupedIngredients = Dictionary(
            grouping: forExpectedDomainModel,
            by: { $0.name.first! }
        )
        let sectionedModel = groupedIngredients.map { ($0.key, $0.value) }
            .sorted(by: { $0.0 < $1.0 })

        XCTAssertEqual(sectionedModel.count,
                       domainModel.inventorySections.count)

        for (domainSection, displaySection)
                in zip(sectionedModel, domainModel.inventorySections) {
            for (domainItem, displayItem)
                    in zip(domainSection.1.sorted(), displaySection.items) {
                XCTAssertEqual(
                    domainItem.name,
                    displayItem.title
                )
            }
        }
    }

    override func setUpWithError() throws {
        self.delegate = .init()
        self.storeActionSink = .init()
        self.displayModelSink = .init()

        self.application = IngredientListApplication(
            delegate: self.delegate
        )
        
        self.application.storeActionSink = self.storeActionSink
        self.application.displayModelSink = self.displayModelSink
        self.application.send(domainModel: self.ingredients)
    }

    func testApplication_WhenGivenDisplayModelSink_DoesSendDisplayModel() throws {
        guard let displayModel = displayModelSink.sendDisplayModelReceivedDisplayModel else {
            XCTFail("Failed to unwrap lastViewModel")
            return
        }

        assertMatchingDisplayModel(forExpectedDomainModel: self.ingredients,
               receivedDomainModel: displayModel)
    }

    func testApplication_WhenGivenDisplayModelSink_DoesSendSortedDisplayModel() throws {
        guard let displayModel = displayModelSink.sendDisplayModelReceivedDisplayModel else {
            XCTFail("Failed to unwrap lastViewModel")
            return
        }

        XCTAssert(displayModel.inventorySections.isSorted { $0.title < $1.title })
    }

    func testApplication_WhenDisplayModelSinkChanged_DoesSendDisplayModel() throws {
        guard let displayModel = displayModelSink.sendDisplayModelReceivedDisplayModel else {
            XCTFail("Failed to unwrap lastViewModel")
            return
        }

        assertMatchingDisplayModel(
            forExpectedDomainModel: self.ingredients,
            receivedDomainModel: displayModel
        )

        let newDisplayModelSink = IngredientListDisplayModelSinkMock()
        application.displayModelSink = newDisplayModelSink

        guard let newDisplayModel = newDisplayModelSink.sendDisplayModelReceivedDisplayModel else {
            XCTFail("Failed to unwrap lastViewModel")
            return
        }

        assertMatchingDisplayModel(forExpectedDomainModel: self.ingredients,
               receivedDomainModel: newDisplayModel)
    }

    func testApplication_WhenModelChanged_DoesSendNewDisplayModel() throws {
        guard let displayModel = displayModelSink.sendDisplayModelReceivedDisplayModel else {
            XCTFail("Failed to unwrap lastViewModel")
            return
        }

        assertMatchingDisplayModel(forExpectedDomainModel: self.ingredients,
               receivedDomainModel: displayModel)

        let newDomainModel: [Ingredient] = [
            .init(name: "New1", description: "", tags: []),
            .init(name: "New2", description: "", tags: []),
            .init(name: "New3", description: "", tags: []),
            .init(name: "New4", description: "", tags: []),
        ]
        let expectation = XCTestExpectation()
        displayModelSink.sendDisplayModelClosure = { newDisplayModel in
            self.assertMatchingDisplayModel(
                forExpectedDomainModel: newDomainModel,
                receivedDomainModel: newDisplayModel
            )
            expectation.fulfill()
        }

        application.send(domainModel: newDomainModel)

        wait(for: [expectation],
             timeout: 0.0)
    }

    func testApplication_WhenDomainModelChanged_DoesNotSendToOldDisplayModelSink() throws {
        let oldDisplayModelSink = IngredientListDisplayModelSinkMock()
        application.displayModelSink = oldDisplayModelSink

        guard let displayModel = oldDisplayModelSink.sendDisplayModelReceivedDisplayModel else {
            XCTFail("Failed to unwrap lastViewModel")
            return
        }

        assertMatchingDisplayModel(forExpectedDomainModel: self.ingredients,
               receivedDomainModel: displayModel)

        let newDisplayModelSink = IngredientListDisplayModelSinkMock()
        application.displayModelSink = newDisplayModelSink

        let newModel: [Ingredient] = [
            .init(name: "New1", description: "", tags: []),
            .init(name: "New2", description: "", tags: []),
            .init(name: "New3", description: "", tags: []),
            .init(name: "New4", description: "", tags: []),
        ]
        let expectation = XCTestExpectation()
        expectation.isInverted = true
        oldDisplayModelSink.sendDisplayModelClosure = { _ in
            expectation.fulfill()
        }

        application.send(domainModel: newModel)

        wait(for: [expectation],
             timeout: 0.0)
    }

    func testApplication_WhenItemSelected_DoesSendModelItemToDelegate() throws {
        let modelIndex = 2
        let matchingIndexPath = IndexPath(item: 0,
                                          section: 0)
        let correctIngredient = self.ingredients[modelIndex]
        self.application.send(domainModel: self.ingredients)

        let expectation = XCTestExpectation()
        self.delegate.navigateToIngredientClosure = { testIngredient in
            XCTAssertEqual(correctIngredient,
                           testIngredient)
            expectation.fulfill()
        }

        self.application.send(
            action: .selectItem(
                inSection: matchingIndexPath.section,
                atIndex: matchingIndexPath.item
            )
        )

        wait(for: [expectation],
             timeout: 0.0)
    }

    func testApplication_WhenOutOfBoundsItemSelected_DoesNotSendToDelegate() throws {
        let modelIndex = 2
        let matchingIndexPath = IndexPath(item: 0,
                                          section: 1000)
        let correctIngredient = self.ingredients[modelIndex]
        self.application.send(domainModel: self.ingredients)

        let expectation = XCTestExpectation()
        expectation.isInverted = true
        self.delegate.navigateToIngredientClosure = { testIngredient in
            XCTAssertEqual(correctIngredient,
                           testIngredient)
            expectation.fulfill()
        }

        self.application.send(
            action: .selectItem(
                inSection: matchingIndexPath.section,
                atIndex: matchingIndexPath.item
            )
        )

        wait(for: [expectation],
             timeout: 0.0)
    }

    func testApplication_WhenSentNewIngredient_DoesCallDelegate() throws {
        let expectation = XCTestExpectation()
        self.delegate.navigateToAddIngredientClosure = {
            expectation.fulfill()
        }

        self.application.send(
            action: .newIngredient
        )

        wait(for: [expectation], timeout: 0.0)
    }

    func testApplication_WhenDeleteIngredient_DoesStartEditing() throws {
        let matchingIndexPath = IndexPath(
            item: 0,
            section: 0
        )

        let expectation = XCTestExpectation()
        self.displayModelSink
            .sendEditModeDisplayModelClosure = { displayModel in
                XCTAssert(displayModel.isEditing)
                expectation.fulfill()
            }

        application.send(
            action: .deleteItem(
                inSection: matchingIndexPath.section,
                atIndex: matchingIndexPath.item
            )
        )
        wait(for: [expectation], timeout: 0.0)
    }

    func testApplication_WhenStartEditing_SendsCannotSave() throws {
        let expectation = XCTestExpectation()
        self.displayModelSink.sendEditModeDisplayModelClosure = { displayModel in
            XCTAssert(displayModel.isEditing)
            XCTAssertFalse(displayModel.canSave)

            expectation.fulfill()
        }

        self.application.send(editModeAction: .startEditing)

        let postEditExpectation = XCTestExpectation()
        self.displayModelSink.sendEditModeDisplayModelClosure = { displayModel in
            XCTAssert(displayModel.isEditing)
            XCTAssert(displayModel.canSave)

            postEditExpectation.fulfill()
        }

        self.application
            .send(action: .deleteItem(inSection: 0, atIndex: 0))

        wait(
            for: [expectation, postEditExpectation],
            timeout: 0.0
        )
    }

    func testApplication_WhenEditModeDeleting_DoesNotSendModelStoreAction() throws {
        self.application.send(editModeAction: .startEditing)

        let expectation = XCTestExpectation()
        expectation.isInverted = true
        self.storeActionSink.sendActionClosure = { _ in
            expectation.fulfill()
        }

        self.application.send(
            action: .deleteItem(
                inSection: 0,
                atIndex: 0
            )
        )
        wait(for: [expectation], timeout: 0.0)
    }

    func testApplication_WhenEditModeDeleting_DoesSendDisplayModel() throws {
        self.application.send(editModeAction: .startEditing)
        var expectedIngredients = self.ingredients
        expectedIngredients.remove(at: 2)

        let expectation = XCTestExpectation()
        self.displayModelSink.sendDisplayModelClosure = { displayModelSink in
            self.assertMatchingDisplayModel(
                forExpectedDomainModel: expectedIngredients,
                receivedDomainModel: displayModelSink
            )
            expectation.fulfill()
        }

        self.application.send(
            action: .deleteItem(
                inSection: 0,
                atIndex: 0
            )
        )
        wait(for: [expectation], timeout: 0.0)
    }

    func testApplication_WhenDelete_DoesStartEditing() throws {
        self.application.send(domainModel: self.ingredients)

        let expectation = XCTestExpectation()
        self.displayModelSink.sendEditModeDisplayModelClosure = { displayModel in
            XCTAssert(displayModel.isEditing)
            expectation.fulfill()
        }

        self.application
            .send(action: .deleteItem(inSection: 0, atIndex: 0))
    }

    func testApplication_WhenDoneEditing_DoesSendSaveStoreAction() throws {
        self.application.send(editModeAction: .startEditing)

        self.application.send(
            action: .deleteItem(
                inSection: 0,
                atIndex: 0
            )
        )

        let expectation = XCTestExpectation()
        self.storeActionSink.sendActionClosure = { action in
            switch action {
            case .save(
                ingredients: let receivedIngredients,
                saver: _
            ):
                XCTAssertEqual(
                    self.ingredients.count - 1,
                    receivedIngredients.count
                )
            }
            expectation.fulfill()
        }

        self.application.send(editModeAction: .finishEditing(.save))

        wait(for: [expectation], timeout: 0.0)
    }

    func testApplication_WhenCancelEditing_DoesNotSendSaveStoreAction() throws {
        self.application.send(editModeAction: .startEditing)

        self.application.send(
            action: .deleteItem(
                inSection: 0,
                atIndex: 0
            )
        )

        let expectation = XCTestExpectation()
        expectation.isInverted = true
        self.storeActionSink.sendActionClosure = { _ in
            expectation.fulfill()
        }

        self.application.send(editModeAction: .finishEditing(.cancel))

        wait(for: [expectation], timeout: 0.0)
    }

    func testApplication_WhenCancelEditing_DoesSendDisplayModel() throws {
        self.application.send(editModeAction: .startEditing)

        let expectation = XCTestExpectation()
        self.displayModelSink.sendDisplayModelClosure = { displayModel in
            self.assertMatchingDisplayModel(
                forExpectedDomainModel: self.ingredients,
                receivedDomainModel: displayModel
            )
            expectation.fulfill()
        }

        self.application.send(editModeAction: .finishEditing(.cancel))

        wait(for: [expectation], timeout: 0.0)
    }

    func testApplication_WhenCancelEditingWithChanges_DoesSendAlert() throws {
        self.application.send(editModeAction: .startEditing)

        self.application.send(
            action: .deleteItem(
                inSection: 0,
                atIndex: 0
            )
        )

        let expectation = XCTestExpectation()
        self.displayModelSink.sendAlertDisplayModelDidConfirmClosure = { alertModel, _ in
            switch alertModel {
            case .cancel:
                expectation.fulfill()
            case .save:
                XCTFail("Did expect cancel alert display model")
            }
        }

        self.application.send(editModeAction: .finishEditing(.cancel))

        wait(for: [expectation], timeout: 0.0)
    }
}
