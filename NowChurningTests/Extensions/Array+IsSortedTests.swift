//
//  Array+IsSortedTests.swift
//  NowChurningTests
//
//  Created by Austin Dumm on 12/18/22.
//

import XCTest
@testable import NowChurning

final class ArrayIsSortedTests: XCTestCase {

    func testIsSorted_WhenGivenEmptyComparable_DoesReturnTrue() {
        let emptyArray: [Int] = []

        XCTAssert(emptyArray.isSorted())
    }

    func testIsSorted_WhenGivenEmptyNonComparable_DoesReturnTrue() {
        struct Dummy {}

        let emptyDummy: [Dummy] = []

        XCTAssert(emptyDummy.isSorted(by: { _, _ in true }))
        XCTAssert(emptyDummy.isSorted(by: { _, _ in false }))
    }

    func testIsSorted_WhenGivenSortedComparable_DoesReturnTrue() {
        XCTAssert([1, 3, 4, 6, 8].isSorted())
    }

    func testIsSorted_WhenGivenUnsortedComparable_DoesReturnFalse() {
        XCTAssertFalse([2, 6, 32, 9, 3, 5].isSorted())
        XCTAssertFalse([2, 6, 6, 6, 6, 7].isSorted())
    }

    func testIsSorted_WhenGivenSortedByCompareClosure_DoesReturnTrue() {
        XCTAssert([10, 9, 8, 7, 6].isSorted(by: >))
        XCTAssert([6, 7, 8, 9, 9, 9, 10].isSorted(by: <=))
    }

    func testIsSorted_WhenGivenUnsortedByCompareClosure_DoesReturnFalse() {
        XCTAssertFalse([10, 9, 100, 7, 6].isSorted(by: >))
        XCTAssertFalse([6, 7, 8, 9, 9, 8, 10].isSorted(by: <=))
    }

}
