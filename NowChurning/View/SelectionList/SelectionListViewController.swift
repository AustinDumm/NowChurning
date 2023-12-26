//
//  SelectionListViewController.swift
//  NowChurning
//
//  Created by Austin Dumm on 2/20/23.
//

import UIKit

class SelectionListViewController: UIViewController {
    private typealias Cell = UICollectionViewListCell
    private typealias SectionModel = String
    private typealias CellModel = SelectionListViewModel.Item
    private typealias Registration = UICollectionView.CellRegistration<Cell, CellModel>
    private typealias DataSource = UICollectionViewDiffableDataSource<SectionModel, CellModel>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<SectionModel, CellModel>

    private lazy var configuration: UICollectionLayoutListConfiguration = {
        var configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)

        configuration.backgroundColor = .App.viewBackground

        return configuration
    }()

    private lazy var layout: UICollectionViewLayout = {
        UICollectionViewCompositionalLayout.list(using: self.configuration)
    }()

    private let registration: Registration = {
        .init { cell, _, itemIdentifier in
            var configuration = cell.defaultContentConfiguration()
            configuration.text = itemIdentifier.title

            cell.contentConfiguration = configuration
            cell.accessories = [.multiselect(
                displayed: .always
            )]
        }
    }()

    private lazy var dataSource: DataSource = {
        .init(
            collectionView: self.collectionView
        ) { [weak self] collectionView, indexPath, itemIdentifier in
            guard let self else { return nil }

            return collectionView.dequeueConfiguredReusableCell(
                using: self.registration,
                for: indexPath,
                item: itemIdentifier
            )
        }
    }()

    private lazy var collectionView: UICollectionView = {
        let view = UICollectionView(
            frame: .zero,
            collectionViewLayout: self.layout
        )

        view.allowsMultipleSelection = true

        return view
    }()

    private var viewModel: SelectionListViewModel? {
        didSet {
            self.updateView()
        }
    }

    private let eventSink: SelectionListEventSink?

    init(eventSink: SelectionListEventSink? = nil) {
        self.eventSink = eventSink

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { nil }

    override func loadView() {
        self.view = self.collectionView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.collectionView.dataSource = self.dataSource
        self.collectionView.delegate = self
    }

    private func updateView() {
        guard let viewModel = self.viewModel else {
            return
        }

        var snapshot = Snapshot()

        snapshot.appendSections([""])
        snapshot.appendItems(viewModel.items)

        self.dataSource.apply(
            snapshot,
            animatingDifferences: true
        ) { [weak self] in
            guard let self = self else { return }

            for (index, elt) in viewModel.items.enumerated()
            where elt.isSelected {
                self.collectionView
                    .selectItem(
                        at: .init(row: index, section: 0),
                        animated: false,
                        scrollPosition: .centeredVertically
                    )
            }
        }
    }
}

extension SelectionListViewController: UICollectionViewDelegate {
    func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        guard
            let selectedIndexPaths = collectionView.indexPathsForSelectedItems
        else {
            return
        }

        self.eventSink?
            .send(
                event: .changeSelection(
                    indices: selectedIndexPaths.map { $0.item }
                )
            )
    }

    func collectionView(
        _ collectionView: UICollectionView,
        didDeselectItemAt indexPath: IndexPath
    ) {
        guard
            let selectedIndexPaths = collectionView.indexPathsForSelectedItems
        else {
            return
        }

        self.eventSink?
            .send(
                event: .changeSelection(
                    indices: selectedIndexPaths.map { $0.item }
                )
            )
    }
}

extension SelectionListViewController: SelectionListViewModelSink {
    func send(viewModel: SelectionListViewModel) {
        self.viewModel = viewModel
    }
}
