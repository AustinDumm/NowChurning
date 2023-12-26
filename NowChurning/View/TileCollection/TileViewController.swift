//
//  TileViewController.swift
//  NowChurning
//
//  Created by Austin Dumm on 10/18/22.
//

import UIKit

class TileViewController: UIViewController {
    typealias SectionType = Int
    typealias ItemType = TileItem
    typealias Cell = UICollectionViewCell
    typealias DataSource = UICollectionViewDiffableDataSource<SectionType, ItemType>
    typealias CellRegistration = UICollectionView.CellRegistration<Cell, ItemType>
    typealias Snapshot = NSDiffableDataSourceSnapshot<SectionType, ItemType>

    struct TileItem: Hashable {
        let index: Int
        let image: UIImage
        let title: String
    }

    private(set) var cellRegistration: CellRegistration
    private(set) var dataSource: DataSource

    let layout: UICollectionViewLayout = {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(0.5),
            heightDimension: .estimated(100.0)
        )

        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = .init(
            top: 0.0,
            leading: 7.5,
            bottom: 0.0,
            trailing: 7.5
        )

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(100.0)
        )
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: groupSize,
            subitems: Array(repeating: item, count: 2)
        )

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = .init(
            top: 30.0,
            leading: 0.0,
            bottom: 15.0,
            trailing: 0.0
        )

        let layout = UICollectionViewCompositionalLayout(
            section: section
        )

        return layout
    }()
    let collectionView: UICollectionView

    private let actionSink: MainScreenActionSink?

    init(actionSink: MainScreenActionSink?) {
        self.actionSink = actionSink

        let collectionView: UICollectionView = .init(
            frame: .zero,
            collectionViewLayout: self.layout
        )
        self.collectionView = collectionView

        let registration = CellRegistration { cell, indexPath, tileItem in
            cell.contentConfiguration = TileViewConfiguration(
                image: tileItem.image,
                title: tileItem.title,
                backgroundColor: ([
                    UIColor.MainScreen.inventoryTileBackground,
                    UIColor.MainScreen.recipeTileBackground
                ])[indexPath.row]
            )
        }
        self.cellRegistration = registration

        let dataSource = DataSource(
            collectionView: collectionView
        ) { collectionView, indexPath, itemIdentifier in
            collectionView.dequeueConfiguredReusableCell(
                using: registration,
                for: indexPath,
                item: itemIdentifier
            )
        }
        self.dataSource = dataSource

        super.init(nibName: nil, bundle: nil)

        self.navigationItem.largeTitleDisplayMode = .always
        self.collectionView.dataSource = self.dataSource
    }

    required init?(coder: NSCoder) { nil }

    override func loadView() {
        self.view = UIView()
        self.view.backgroundColor = .App.viewBackground

        self.view.inset(self.collectionView,
                        layoutGuideType: .safeArea,
                        byEdgeInsets: .init(top: 20.0,
                                            left: 10.0,
                                            bottom: 10.0,
                                            right: 10.0))

        self.collectionView.backgroundColor = .MainScreen.collectionBackground
        self.collectionView.layer.borderWidth = 1.5
        self.collectionView.layer.borderUIColor = .MainScreen.collectionBorder
        self.collectionView.layer.cornerRadius = 15.0
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.collectionView.delegate = self
    }
}

extension TileViewController: UICollectionViewDelegate {
    func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        let snapshot = self.dataSource.snapshot()

        guard snapshot.numberOfSections > indexPath.section,
              snapshot.numberOfItems(inSection: snapshot.sectionIdentifiers[indexPath.section]) > indexPath.item else {
            return
        }

        self.actionSink?.send(
            action: .selectItem(
                atIndex: indexPath.row
            )
        )
    }
}
