//
//  MeasureListApplicationTests.swift
//  NowChurningTests
//
//  Created by Austin Dumm on 5/13/23.
//

import XCTest
@testable import NowChurning

final class MeasureListApplicationTests: XCTestCase {

    var application: MeasureListApplication!

    var displayModelSink: MeasureListDisplayModelSinkMock!
    var storeActionSink: MeasureListStoreActionSinkMock!
    var delegate: MeasureListApplicationDelegateMock!

    var testMeasures: [Measure] = [
        .init(
            ingredient: .init(
                name: "First",
                description: "First Ingredient",
                tags: [.init(name: "Tag")]
            ),
            measure: .any
        ),
        .init(
            ingredient: .init(
                name: "Second",
                description: "Second Ingredient",
                tags: []
            ),
            measure: .count(.init(value: 1.5, unit: .count), "Test Count")
        ),
        .init(
            ingredient: .init(
                name: "Third",
                description: "Third Ingredient",
                tags: [.init(name: "Tag"), .init(name: "Another")]
            ),
            measure: .volume(.init(value: 2.75, unit: .fluidOunces))
        ),
        .init(
            ingredient: .init(
                name: "Aaa",
                description: "Aaa Ingredient",
                tags: []
            ),
            measure: .volume(.init(value: 2.75, unit: .fluidOunces))
        ),
        .init(
            ingredient: .init(
                name: "Aab",
                description: "Aab Ingredient",
                tags: []
            ),
            measure: .volume(.init(value: 2.75, unit: .fluidOunces))
        ),
    ]

    override func setUpWithError() throws {
        self.displayModelSink = .init()
        self.storeActionSink = .init()
        self.delegate = .init()

        self.application = .init()
        self.application.displayModelSink = self.displayModelSink
        self.application.storeActionSink = self.storeActionSink
        self.application.delegate = self.delegate
    }

    func assert(
        isExpectedDisplayModel displayModel: MeasureListDisplayModel,
        forDomainModel domainModel: [Measure]
    ) {
        XCTAssertEqual(
            displayModel
                .sections
                .map { $0.items.count }
                .reduce(0, +),
            domainModel.count
        )

        XCTAssert(
            displayModel
                .sections
                .map { $0.title }
                .isSorted { lhs, rhs in
                    lhs.localizedCaseInsensitiveCompare(rhs) == .orderedAscending
                }
        )

        XCTAssert(
            displayModel
                .sections
                .allSatisfy {
                    $0.items
                        .map { $0.title }
                        .isSorted { lhs, rhs in
                            lhs.localizedCaseInsensitiveCompare(rhs) == .orderedAscending
                        }
                }
        )

        for measure in domainModel {
            let ingredient = measure.ingredient
            let sectionLetter = ingredient.name.first!.uppercased()
            let itemName = ingredient.name.capitalized

            guard
                let section = displayModel.sections.first(where: { section in
                    section.title == sectionLetter
                })
            else {
                XCTFail("Could not find matching section for ingredient: \(itemName)")
                return
            }

            XCTAssert(
                section
                    .items
                    .contains(where: { item in
                        item.title == itemName
                    })
            )
        }
    }

    func testApplication_WhenDisplayModelSinkSet_SendsDisplayModel() throws {
        self.application.send(domainModel: self.testMeasures)
        let expectation = XCTestExpectation()
        expectation.expectedFulfillmentCount = 2
        let newDisplayModelSink = MeasureListDisplayModelSinkMock()
        newDisplayModelSink
            .sendDisplayModelClosure = { displayModel in
                self.assert(
                    isExpectedDisplayModel: displayModel,
                    forDomainModel: self.testMeasures
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
                    forDomainModel: self.testMeasures
                )
                expectation.fulfill()
            }

        self.application.send(domainModel: self.testMeasures)
        wait(
            for: [expectation],
            timeout: 0.0
        )
    }

    func testApplication_WhenNavigateAction_DoesAlertDelegate() throws {
        let testIndex = 3
        let expectedMeasure = self.testMeasures[testIndex]
        let measureSection = 0
        let measureItem = 0

        let expectation = XCTestExpectation()
        self.application.send(domainModel: self.testMeasures)
        self.delegate.navigateToDetailsForMeasureClosure = { measure in
            XCTAssertEqual(
                measure,
                expectedMeasure
            )
            expectation.fulfill()
        }

        self.application
            .send(
                action: .selectMeasure(
                    atIndex: measureItem,
                    inSection: measureSection
                )
            )
        wait(for: [expectation], timeout: 0.0)
    }

    func testApplication_WhenStartEditing_DoesSendDisplayModels() throws {
        self.application
            .send(domainModel: self.testMeasures)

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
            .send(domainModel: self.testMeasures)
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
            .send(domainModel: self.testMeasures)
        self.application
            .send(editModeAction: .startEditing)

        let expectation = XCTestExpectation()
        self.displayModelSink.sendEditModeDisplayModelClosure = { model in
            XCTAssert(model.isEditing)
            XCTAssert(model.canSave)
            expectation.fulfill()
        }

        self.application
            .send(action: .deleteMeasure(atIndex: 1, inSection: 0))
        wait(for: [expectation], timeout: 0.0)
    }

    func testApplication_WhenEditMade_SendsUpdatedDisplayModel() throws {
        let deletedMeasure = self.testMeasures[4]
        let sectionDeleted = 0
        let indexDeleted = 1

        self.application
            .send(domainModel: self.testMeasures)
        self.application
            .send(editModeAction: .startEditing)

        let expectation = XCTestExpectation()
        self.displayModelSink.sendDisplayModelClosure = { displayModel in
            XCTAssert(
                !displayModel
                    .sections
                    .contains(where: { section in
                        section
                            .items
                            .contains(where: { foundItem in
                                foundItem.id.rawId == deletedMeasure.ingredient.id.rawId
                            })
                    })
            )

            expectation.fulfill()
        }

        self.application
            .send(
                action: .deleteMeasure(
                    atIndex: indexDeleted,
                    inSection: sectionDeleted
                )
            )
        wait(for: [expectation], timeout: 0.0)
    }

    func testApplication_WhenCancelEditingWithChanges_SendsAlert() throws {
        self.application
            .send(domainModel: self.testMeasures)
        self.application
            .send(editModeAction: .startEditing)

        self.application
            .send(action: .deleteMeasure(atIndex: 1, inSection: 0))

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
            .send(domainModel: self.testMeasures)
        self.application
            .send(editModeAction: .startEditing)
        self.application
            .send(action: .deleteMeasure(atIndex: 1, inSection: 0))

        let expectation = XCTestExpectation()
        self.displayModelSink
            .sendDisplayModelClosure = { displayModel in
                self.assert(
                    isExpectedDisplayModel: displayModel,
                    forDomainModel: self.testMeasures
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
            .send(domainModel: self.testMeasures)
        self.application
            .send(editModeAction: .startEditing)

        let expectation = XCTestExpectation()
        self.displayModelSink.sendEditModeDisplayModelClosure = { model in
            XCTAssertFalse(model.isEditing)
            expectation.fulfill()
        }

        let badExpectation = XCTestExpectation()
        badExpectation.isInverted = true
        self.storeActionSink.sendActionClosure = { _ in
            badExpectation.fulfill()
        }

        self.application
            .send(editModeAction: .finishEditing(.save))
        wait(for: [expectation, badExpectation], timeout: 0.0)
    }

    func testApplication_WhenSaveWithChanges_SendsSave() throws {
        self.application
            .send(domainModel: self.testMeasures)
        self.application
            .send(editModeAction: .startEditing)

        let testIndex = 4
        self.application
            .send(action: .deleteMeasure(atIndex: 1, inSection: 0))

        let expectation = XCTestExpectation()
        expectation.expectedFulfillmentCount = 2
        self.displayModelSink.sendEditModeDisplayModelClosure = { model in
            XCTAssertFalse(model.isEditing)
            expectation.fulfill()
        }

        self.storeActionSink.sendActionClosure = { action in
            var expected = self.testMeasures
            expected.remove(at: testIndex)
            switch action {
            case .save(
                measures: let receieved,
                saver: _
            ):
                XCTAssertEqual(
                    receieved,
                    expected
                )
            }

            expectation.fulfill()
        }

        self.application
            .send(editModeAction: .finishEditing(.save))
        wait(for: [expectation], timeout: 0.0)
    }

    func testApplication_WhenNewMeasure_SendsNavigationCall() throws {
        let expectation = XCTestExpectation()
        self.delegate.navigateToAddMeasureClosure = {
            expectation.fulfill()
        }

        self.application
            .send(action: .newMeasure)

        wait(for: [expectation], timeout: 0.0)
    }

    func testApplication_WhenDeleteMeasure_SendsStartEdit() throws {
        self.application
            .send(domainModel: self.testMeasures)
        let expectation = XCTestExpectation()
        self.displayModelSink.sendEditModeDisplayModelClosure = { displayModel in
            XCTAssert(displayModel.isEditing)
            expectation.fulfill()
        }

        self.application
            .send(action: .deleteMeasure(atIndex: 0, inSection: 0))
        wait(for: [expectation], timeout: 0.0)
    }

}
