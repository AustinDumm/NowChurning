//
//  FormListViewController.swift
//  NowChurning
//
//  Created by Austin Dumm on 6/4/23.
//

import UIKit

class FormListViewController: UIViewController {
    private typealias Cell = UICollectionViewListCell
    private typealias SectionModel = String
    private typealias CellModel = FormListViewModel.Item.ID
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

    private lazy var fieldRegistration: Registration = {
        .init { [weak self] cell, indexPath, itemIdentifier in
            guard
                let self,
                case let .labeledField(
                    label,
                    content
                ) = self.itemLookup[itemIdentifier]?.type
            else {
                return

            }

            var configuration = cell.editableFieldConfiguration()
            configuration.label = label
            configuration.text = content
            configuration.textDidUpdate = { [weak self] newText in
                guard let newText else { return }

                self?.eventSink?.send(event: .updateFieldText(
                    item: indexPath.item,
                    section: indexPath.section,
                    content: newText
                ))
            }

            cell.contentConfiguration = configuration
        }
    }()

    private lazy var numberRegistration: Registration = {
        .init { [weak self] cell, indexPath, itemIdentifier in
            guard
                let self,
                case let .labeledNumber(
                    label,
                    content
                ) = self.itemLookup[itemIdentifier]?.type
            else {
                return

            }

            var configuration = cell.numberFieldConfiguration()

            configuration.title = label
            configuration.value = content
            configuration.valueDidUpdate = { [weak self] value in
                self?.eventSink?.send(event: .updateNumber(
                    item: indexPath.item,
                    section: indexPath.section,
                    number: value ?? 0.0
                ))
            }
            configuration.didStartEdit = { [weak self] in
                self?.currentEditPath = indexPath
            }
            configuration.didEndEdit = { [weak self] in
                self?.currentEditPath = nil
            }

            cell.contentConfiguration = configuration
        }
    }()

    private lazy var selectionRegistration: Registration = {
        .init { [weak self] cell, indexPath, itemIdentifier in
            guard
                let self,
                case let .labeledSelection(
                    label,
                    options,
                    selection
                ) = self.itemLookup[itemIdentifier]?.type
            else {
                return
            }

            var configuration = UIListContentConfiguration.valueCell()

            configuration.text = label
            configuration.secondaryText = options[safe: selection] ?? ""

            cell.contentConfiguration = configuration
            cell.accessories = [.popUpMenu(
                .init(
                    options: .singleSelection,
                    children: options.enumerated().map { (index, option) in
                        UIAction(
                            title: option,
                            state: (index == selection) ? .on : .off,
                            handler: { [weak self] _ in
                                self?.eventSink?.send(event: .updateSelection(
                                    item: indexPath.item,
                                    section: indexPath.section,
                                    selection: index
                                ))
                            }
                        )
                    }
                ),
                displayed: .always
            )]
        }
    }()

    private lazy var dataSource: DataSource = {
        .init(
            collectionView: self.collectionView
        ) { [weak self] collectionView, indexPath, itemIdentifier in
            guard let self else { return nil }

            switch self.itemLookup[itemIdentifier]?.type {
            case .labeledField, .none:
                return collectionView.dequeueConfiguredReusableCell(
                    using: self.fieldRegistration,
                    for: indexPath,
                    item: itemIdentifier
                )
            case .labeledNumber:
                return collectionView.dequeueConfiguredReusableCell(
                    using: self.numberRegistration,
                    for: indexPath,
                    item: itemIdentifier
                )
            case .labeledSelection:
                return collectionView.dequeueConfiguredReusableCell(
                    using: self.selectionRegistration,
                    for: indexPath,
                    item: itemIdentifier
                )
            }
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

    private var viewModel: FormListViewModel? {
        didSet {
            self.updateView()
        }
    }
    private var itemLookup = [String: FormListViewModel.Item]()

    private let eventSink: FormListEventSink?
    private var currentEditPath: IndexPath?

    init(eventSink: FormListEventSink? = nil) {
        self.eventSink = eventSink

        super.init(nibName: nil, bundle: nil)

        // Used to build lazy registration before its use in dequeuing cells
        _ = self.selectionRegistration
        _ = self.numberRegistration
        _ = self.fieldRegistration
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
        self.itemLookup = .init(
            viewModel
                .sections
                .flatMap { $0.items }
                .map { ($0.id, $0) }
        ) { first, _ in first }

        var snapshot = Snapshot()

        snapshot.appendSections(viewModel.sections.map { $0.title })
        for (sectionIndex, section) in viewModel.sections.enumerated() {
            let ids = section.items.map { $0.id }

            snapshot.appendItems(
                ids,
                toSection: section.title
            )

            snapshot.reconfigureItems(
                section.items.enumerated().filter { (itemIndex, item) in
                    self.itemLookup[item.id] != nil &&
                    self.currentEditPath != IndexPath(item: itemIndex, section: sectionIndex)
                }.map { $0.element.id }
            )
        }

        self.dataSource.apply(
            snapshot,
            animatingDifferences: true
        )
    }
}

extension FormListViewController: UICollectionViewDelegate {}

extension FormListViewController: FormListViewModelSink {
    func send(viewModel: FormListViewModel) {
        self.viewModel = viewModel
        self.updateView()
    }

    func startEdit(at indexPath: IndexPath) {
        let cell = self.collectionView.cellForItem(at: indexPath)?.contentView as? FormListNumberView
        cell?.textField.becomeFirstResponder()
    }
}
