//
//  ItemListSingleLineTextEditViewTests.swift
//  NowChurningTests
//
//  Created by Austin Dumm on 12/25/22.
//

import XCTest
@testable import NowChurning

final class ItemListSingleLineTextEditViewTests: XCTestCase {

    func testEditView_WhenInitialized_DoesShowCorrectText() throws {
        let testText = "This is the test text"
        let testPurpose = "Test Purpose"

        let configuration = ItemListSingleLineTextEditView.Configuration(
            contentPurpose: testPurpose,
            text: testText
        )

        let view = ItemListSingleLineTextEditView(
            configuration: configuration
        )

        XCTAssertEqual(
            view.textField.text,
            testText
        )

        XCTAssertEqual(
            view.textField.accessibilityLabel,
            testPurpose
        )
    }

    @MainActor func testEditView_WhenInitFromConfig_DoesShowCorrectText() throws {
        let testText = "This is the test text"
        let testPurpose = "Test Purpose"

        let configuration = ItemListSingleLineTextEditView.Configuration(
            contentPurpose: testPurpose,
            text: testText
        )

        guard let view = configuration.makeContentView() as? ItemListSingleLineTextEditView else {
            XCTFail("Expected single line edit view")
            return
        }

        XCTAssertEqual(
            testText,
            view.textField.text
        )

        XCTAssertEqual(
            view.textField.accessibilityLabel,
            testPurpose
        )
    }

    @MainActor func testEditView_WhenConfigChanged_DoesShowCorrectText() throws {
        let oldText = "This is the old text"
        let testText = "This is the test text"

        let configuration = ItemListSingleLineTextEditView.Configuration(
            contentPurpose: "",
            text: oldText
        )

        let view = ItemListSingleLineTextEditView(
            configuration: configuration
        )

        let newConfiguration = ItemListSingleLineTextEditView.Configuration(
            contentPurpose: "",
            text: testText
        )

        view.configuration = newConfiguration

        XCTAssertEqual(
            testText,
            view.textField.text
        )
    }


    func testEditView_WhenTextChanged_DoesAlertCallback() throws {
        let expectedText = "This is the expected text"
        let expectation = XCTestExpectation()

        let configuration = ItemListSingleLineTextEditView.Configuration(
            contentPurpose: "",
            text: ""
        ) { newText in
            XCTAssertEqual(
                expectedText,
                newText
            )
            expectation.fulfill()
        }

        let view = ItemListSingleLineTextEditView(
            configuration: configuration
        )

        view.textField.insertText(expectedText)

        wait(for: [expectation], timeout: 0.0)
    }

    @MainActor func testEditView_WhenInitFromConfigAndTextChanged_DoesAlertCallback() throws {
        let expectedText = "This is the expected text"
        let expectation = XCTestExpectation()

        let configuration = ItemListSingleLineTextEditView.Configuration(
            contentPurpose: "",
            text: ""
        ) { newText in
            XCTAssertEqual(
                expectedText,
                newText
            )
            expectation.fulfill()
        }

        guard let view = configuration.makeContentView() as? ItemListSingleLineTextEditView else {
            XCTFail("Expected single line text edit view")
            return
        }

        view.textField.insertText(expectedText)

        wait(for: [expectation], timeout: 0.0)
    }

    @MainActor func testEditView_WhenConfigChanged_DoesAlertOnlyNewCallback() throws {
        let oldText = "This is the old text"
        let expectedText = "This is the expected text"

        let oldExpectation = XCTestExpectation()
        oldExpectation.isInverted = true
        let oldConfiguration = ItemListSingleLineTextEditView.Configuration(
            contentPurpose: "",
            text: oldText
        ) { _ in
            oldExpectation.fulfill()
        }

        let view = ItemListSingleLineTextEditView(configuration: oldConfiguration)

        let newExpectation = XCTestExpectation()
        let newConfiguration = ItemListSingleLineTextEditView.Configuration(
            contentPurpose: "",
            text: ""
        ) { receivedText in
                XCTAssertEqual(
                    expectedText,
                    receivedText
                )
                newExpectation.fulfill()
            }

        view.configuration = newConfiguration

        view.textField.insertText(expectedText)

        wait(for: [oldExpectation, newExpectation], timeout: 0.0)
    }
    
}
