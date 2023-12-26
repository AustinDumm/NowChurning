//
//  TagSelectorApplicationTests.swift
//  NowChurningTests
//
//  Created by Austin Dumm on 2/20/23.
//

import XCTest
@testable import NowChurning

final class TagSelectorApplicationTests: XCTestCase {
    typealias TagType = Tag<TagBase>
    typealias TagBase = Int
    typealias DisplayModelSink = TagSelectorDisplayModelSinkMock<TagBase>
    typealias NavDelegate = TagSelectorNavigationDelegateMock<TagBase>

    var application: TagSelectorApplication<
        DisplayModelSink,
        NavDelegate
    >!
    var mockDisplayModelSink: DisplayModelSink!
    var mockNavDelegate: NavDelegate!

    var testTags: [TagType] = [
        .init(name: "0"),
        .init(name: "1"),
        .init(name: "2"),
        .init(name: "3"),
        .init(name: "4"),
        .init(name: "5"),
    ]

    var expectedSelections: [TagSelectorDisplayModel<TagBase>.TagSelection] {
        testTags
            .map { .init(tag: $0, isSelected: false) }
    }

    override func setUpWithError() throws {
        self.mockDisplayModelSink = .init()
        self.mockNavDelegate = .init()

        self.application = .init(
            initialSelection: [],
            navDelegate: mockNavDelegate
        )
        self.application.displayModelSink = self.mockDisplayModelSink
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testApplication_WhenValidTagsSent_DoesSendDisplayModel() throws {
        let expectation = XCTestExpectation()
        self.mockDisplayModelSink.sendClosure = { displayModel in
            XCTAssertEqual(
                self.expectedSelections,
                displayModel.tagSelections
            )
            expectation.fulfill()
        }

        self.application.send(validTags: self.testTags)
        wait(for: [expectation], timeout: 0.0)
    }

    func testApplication_WhenDisplayModelSinkSet_DoesSendDisplayModel() throws {
        self.application.send(validTags: self.testTags)

        let newSink = DisplayModelSink()
        let expectation = XCTestExpectation()
        newSink.sendClosure = { displayModel in
            XCTAssertEqual(
                self.expectedSelections,
                displayModel.tagSelections
            )
            expectation.fulfill()
        }

        self.application.displayModelSink = newSink
        wait(for: [expectation], timeout: 0.0)
    }

    func testApplication_WhenTagSelected_DoesSendToDelegate() throws {
        self.application.send(validTags: self.testTags)

        let tagIndices = [2, 4]
        let selectedTags = tagIndices.map { self.testTags[$0] }
        let expectation = XCTestExpectation()
        self.mockNavDelegate.didSelectClosure = { tag in
            XCTAssertEqual(
                selectedTags,
                tag
            )
            expectation.fulfill()
        }

        self.application.send(action: .select(tagIndices: tagIndices))
        wait(for: [expectation], timeout: 0.0)
    }

    func testApplication_WhenCancelled_DoesSendToDelegate() throws {
        let expectation = XCTestExpectation()
        self.mockNavDelegate.cancelTagClosure = {
            expectation.fulfill()
        }

        self.application.send(action: .cancel)
        wait(for: [expectation], timeout: 0.0)
    }

}
