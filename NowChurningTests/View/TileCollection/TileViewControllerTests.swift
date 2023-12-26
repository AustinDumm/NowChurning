//
//  TileViewControllerTests.swift
//  NowChurningTests
//
//  Created by Austin Dumm on 12/18/22.
//

import XCTest
@testable import NowChurning

final class TileViewControllerTests: XCTestCase {

    func displayModel() -> MainScreenDisplayModel {
        .init(items: [
            .init(icon: .ingredients, text: "First"),
            .init(icon: .recipes, text: "Second"),
            .init(icon: .recipes, text: "Third"),
        ])
    }

    func testTileController_WhenGivenDisplayModel_DisplaysCorrectCount() throws {
        let vc = TileViewController(actionSink: nil)
        vc.loadView()
        vc.viewDidLoad()

        let displayModel = self.displayModel()
        vc.send(displayModel: displayModel)

        let snapshot = vc.dataSource.snapshot()

        XCTAssertEqual(
            1,
            snapshot.numberOfSections
        )

        XCTAssertEqual(
            displayModel.items.count,
            snapshot.numberOfItems(inSection: 0)
        )
    }

    func testTileController_WhenItemTapped_DoesSendCorrectAction() throws {
        let mockActionSink = MockMainScreenActionSink()

        let vc = TileViewController(actionSink: mockActionSink)
        vc.loadView()
        vc.viewDidLoad()

        vc.send(displayModel: displayModel())

        let tappedIndex = IndexPath(
            item: 1,
            section: 0
        )
        let expectation = XCTestExpectation()
        mockActionSink.sendCallback = { action in
            switch action {
            case .selectItem(atIndex: let index):
                XCTAssertEqual(
                    tappedIndex.item,
                    index
                )
                expectation.fulfill()
            }
        }

        vc.collectionView(
            vc.collectionView,
            didSelectItemAt: tappedIndex
        )
        wait(for: [expectation], timeout: 0.0)
    }

    func testTileController_WhenOutOfBoundsItemTapped_DoesNotSendAction() throws {
        let mockActionSink = MockMainScreenActionSink()

        let vc = TileViewController(actionSink: mockActionSink)
        vc.loadView()
        vc.viewDidLoad()

        vc.send(displayModel: displayModel())

        let expectation = XCTestExpectation()
        expectation.isInverted = true
        mockActionSink.sendCallback = { action in
            switch action {
            case .selectItem(atIndex: _):
                expectation.fulfill()
            }
        }

        vc.collectionView(
            vc.collectionView,
            didSelectItemAt: IndexPath(
                item: 10000000,
                section: 0
            )
        )

        vc.collectionView(
            vc.collectionView,
            didSelectItemAt: IndexPath(
                item: 1,
                section: 100000
            )
        )

        vc.collectionView(
            vc.collectionView,
            didSelectItemAt: IndexPath(
                item: 10000000,
                section: 10000000
            )
        )
        
        wait(for: [expectation], timeout: 0.0)
    }

}
