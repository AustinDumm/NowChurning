//
//  ItemListMultiLineTextEditViewTests.swift
//  NowChurningTests
//
//  Created by Austin Dumm on 12/25/22.
//

import XCTest
@testable import NowChurning

final class ItemListMultiLineTextEditViewTests: XCTestCase {

    func testEditView_WhenInitialized_DoesShowCorrectText() throws {
        let testText = "This is the test text"
        let testPurpose = "Test Purpose"

        let configuration = ItemListMultiLineTextEditView.Configuration(
            contentPurpose: testPurpose,
            text: testText
        )

        let view = ItemListMultiLineTextEditView(
            configuration: configuration
        )

        XCTAssertEqual(
            view.textView.text,
            testText
        )

        XCTAssertEqual(
            view.textView.accessibilityLabel,
            testPurpose
        )
    }

    @MainActor func testEditView_WhenInitFromConfig_DoesShowCorrectText() throws {
        let testText = "This is the test text"
        let testPurpose = "Test Purpose"

        let configuration = ItemListMultiLineTextEditView.Configuration(
            contentPurpose: testPurpose,
            text: testText
        )

        guard let view = configuration.makeContentView() as? ItemListMultiLineTextEditView else {
            XCTFail("Expected single line edit view")
            return
        }

        XCTAssertEqual(
            testText,
            view.textView.text
        )

        XCTAssertEqual(
            view.textView.accessibilityLabel,
            testPurpose
        )
    }

    @MainActor func testEditView_WhenConfigChanged_DoesShowCorrectText() throws {
        let oldText = "This is the old text"
        let testText = "This is the test text"

        let configuration = ItemListMultiLineTextEditView.Configuration(
            contentPurpose: "",
            text: oldText
        )

        let view = ItemListMultiLineTextEditView(
            configuration: configuration
        )

        let newConfiguration = ItemListMultiLineTextEditView.Configuration(
            contentPurpose: "",
            text: testText
        )

        view.configuration = newConfiguration

        XCTAssertEqual(
            testText,
            view.textView.text
        )
    }


    func testEditView_WhenTextChanged_DoesAlertCallback() throws {
        let expectedText = "This is the expected text"
        let expectation = XCTestExpectation()

        let configuration = ItemListMultiLineTextEditView.Configuration(
            contentPurpose: "",
            text: ""
        ) { newText in
            XCTAssertEqual(
                expectedText,
                newText
            )
            expectation.fulfill()
        }

        let view = ItemListMultiLineTextEditView(
            configuration: configuration
        )

        view.textView.insertText(expectedText)

        wait(for: [expectation], timeout: 0.0)
    }

    @MainActor func testEditView_WhenInitFromConfigAndTextChanged_DoesAlertCallback() throws {
        let expectedText = "This is the expected text"
        let expectation = XCTestExpectation()

        let configuration = ItemListMultiLineTextEditView.Configuration(
            contentPurpose: "",
            text: ""
        ) { newText in
            XCTAssertEqual(
                expectedText,
                newText
            )
            expectation.fulfill()
        }

        guard let view = configuration.makeContentView() as? ItemListMultiLineTextEditView else {
            XCTFail("Expected single line text edit view")
            return
        }

        view.textView.insertText(expectedText)

        wait(for: [expectation], timeout: 0.0)
    }

    @MainActor func testEditView_WhenConfigChanged_DoesAlertOnlyNewCallback() throws {
        let oldText = "This is the old text"
        let expectedText = "This is the expected text"

        let oldExpectation = XCTestExpectation()
        oldExpectation.isInverted = true
        let oldConfiguration = ItemListMultiLineTextEditView.Configuration(
            contentPurpose: "",
            text: oldText
        ) { _ in
            oldExpectation.fulfill()
        }

        let view = ItemListMultiLineTextEditView(configuration: oldConfiguration)

        let newExpectation = XCTestExpectation()
        let newConfiguration = ItemListMultiLineTextEditView.Configuration(
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

        view.textView.insertText(expectedText)
        view.textView.delegate?.textViewDidChange?(view.textView)

        wait(for: [oldExpectation, newExpectation], timeout: 0.0)
    }

}
