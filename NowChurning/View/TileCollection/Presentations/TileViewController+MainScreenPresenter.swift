//
//  TileViewController+MainScreenPresenter.swift
//  NowChurning
//
//  Created by Austin Dumm on 10/30/22.
//

import UIKit

extension TileViewController: MainScreenDisplayModelSink {
    func send(displayModel: MainScreenDisplayModel) {
        let tileItems = displayModel
            .items
            .enumerated()
            .map { (index, viewModelItem) in
                TileItem(
                    index: index,
                    image: Self.image(forIcon: viewModelItem.icon),
                    title: viewModelItem.text
                )
            }

        var snapshot = Snapshot()
        snapshot.appendSections([0])
        snapshot.appendItems(tileItems)
        self.dataSource.apply(
            snapshot,
            animatingDifferences: true
        )
    }

    private static func image(
        forIcon icon: ApplicationImage.Icon.MainScreen
    ) -> UIImage {
        switch icon {
        case .ingredients:
            return .Icon.ingredients
        case .recipes:
            return .Icon.dish
        }
    }
}
