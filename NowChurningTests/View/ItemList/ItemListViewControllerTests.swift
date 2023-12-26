//
//  ItemListViewControllerTests.swift
//  NowChurningTests
//
//  Created by Austin Dumm on 12/18/22.
//

import XCTest
@testable import NowChurning

final class ItemListViewControllerTests: XCTestCase {

    func viewModel(testCount: Int) -> ItemListViewModel {
        ItemListViewModel(
            sections: (0..<testCount)
                .map { index in .init(
                    title: String(index),
                    items: (0..<index)
                        .map { index in
                                .init(
                                    id: String(index),
                                    type: .text(String(index)),
                                    context: []
                                )
                        }
                )},
            isEditing: false
        )

    }

    func testList_WhenGivenEditingViewModel_DisplaysEditingTable() {
        let vc = ItemListViewController(eventSink: nil)
        vc.loadView()
        vc.viewDidLoad()

        let testCount = 4
        let viewModel = self.viewModel(testCount: testCount)

        let editViewModel = ItemListViewModel(
            sections: viewModel.sections,
            isEditing: true
        )

        vc.send(viewModel: editViewModel)

        let expectation = XCTestExpectation()
        DispatchQueue.main.async {
            XCTAssert(vc.collectionView.isEditing)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 0.5)
    }

    func testList_WhenItemActionPerformed_SendsEventToPresenter() {
        let mockSink = MockItemListEventSink()
        let vc = ItemListViewController(eventSink: mockSink)
        vc.loadView()
        vc.viewDidLoad()

        vc.send(viewModel: self.viewModel(testCount: 4))

        let expectedIndexPath = IndexPath(
            item: 2,
            section: 3
        )

        let expectation = XCTestExpectation()
        mockSink.sendCallback = { event in
            switch event {
            case .select(itemAt: let receivedIndexPath):
                XCTAssertEqual(
                    expectedIndexPath,
                    receivedIndexPath
                )
                expectation.fulfill()
            case .edit,
                    .delete,
                    .selectFooter,
                    .move,
                    .openInfo,
                    .resolveAlert:
                XCTFail("Received edit action when expecting a select action")
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            vc.collectionView(
                vc.collectionView,
                performPrimaryActionForItemAt: expectedIndexPath
            )
        }

        wait(for: [expectation],
             timeout: 0.5)
    }

    func testList_WhenOutOfBoundsItemSelected_SendsNothing() {
        let mockSink = MockItemListEventSink()
        let vc = ItemListViewController(eventSink: mockSink)
        vc.loadView()
        vc.viewDidLoad()

        let expectation = XCTestExpectation()
        expectation.isInverted = true
        mockSink.sendCallback = { event in
            switch event {
            case .select(itemAt: _):
                expectation.fulfill()
            case .edit, .delete, .selectFooter, .move, .openInfo, .resolveAlert:
                XCTFail("Received edit action when expecting a select action")
            }
        }

        vc.collectionView(
            vc.collectionView,
            performPrimaryActionForItemAt: IndexPath(
                item: 0,
                section: 3000
            )
        )
        vc.collectionView(
            vc.collectionView,
            performPrimaryActionForItemAt: IndexPath(
                item: 2000,
                section: 0
            )
        )
        vc.collectionView(
            vc.collectionView,
            performPrimaryActionForItemAt: IndexPath(
                item: 2000,
                section: 3000
            )
        )

        wait(for: [expectation],
             timeout: 0.0)
    }
}
