//
//  ItemListViewController.swift
//  NowChurning
//
//  Created by Austin Dumm on 10/23/22.
//

import UIKit

class ItemListViewController: UIViewController {
    typealias Cell = UICollectionViewListCell
    typealias Layout = UICollectionViewCompositionalLayout
    typealias ItemViewModel = ItemListViewModel.Item
    typealias DataSource = UICollectionViewDiffableDataSource<String, ItemViewModel.ID>
    typealias Registration = UICollectionView.CellRegistration<Cell, ItemViewModel.ID>
    typealias HeaderRegistration = UICollectionView.SupplementaryRegistration<Cell>
    typealias FooterRegistration = UICollectionView.SupplementaryRegistration<Cell>
    typealias Snapshot = NSDiffableDataSourceSnapshot<String, ItemViewModel.ID>

    private lazy var collectionHandlers: ListCollectionHandler = {
        self.listCollection(eventSink: self.eventSink)
    }()

    var collectionViewLayout: UICollectionViewLayout {
        self.collectionHandlers.layout
    }

    var collectionView: UICollectionView {
        self.collectionViewController
            .collectionView
    }

    var collectionViewController: UICollectionViewController {
        self.collectionHandlers.collectionViewController
    }

    var dataSource: DataSource {
        self.collectionHandlers.dataSource
    }

    private let eventSink: ItemListEventSink?
    private var itemLookup = [ItemViewModel.ID: ItemViewModel]()
    private var footerLookup = [String: ItemListViewModel.ErrorMessage?]()
    private var sectionBeingEdited: String?

    private var initialSelection: IndexPath?
    private var isUpdating: Bool = false

    init(
        eventSink: ItemListEventSink?,
        initialSelection: IndexPath? = nil
    ) {
        self.eventSink = eventSink
        self.initialSelection = initialSelection

        super.init(
            nibName: nil,
            bundle: nil
        )
    }

    required init?(coder: NSCoder) { nil }

    deinit {
        NotificationCenter
            .default
            .removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.insetChild(self.collectionViewController)
        self.collectionView.allowsSelection = true
        self.collectionView.allowsMultipleSelection = true
        self.collectionViewController
            .collectionView
            .delegate = self
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.selectInitialSelection()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        for selected in self.collectionView.indexPathsForSelectedItems ?? [] {
            self.collectionView.deselectItem(at: selected, animated: false)
        }
    }

    private func reloadSection(_ section: String) {
        var snapshot = self.dataSource.snapshot()

        if snapshot.sectionIdentifiers.contains(section) {
            snapshot.reloadSections([section])

            Task { @MainActor in
                self.dataSource.apply(snapshot)
            }
        }
    }

    @objc private func tapFooter(_ tapGesture: UITapGestureRecognizer) {
        guard let footerView = tapGesture.view as? Cell else {
            return
        }

        let section = footerView.tag
        self.eventSink?
            .send(event: .selectFooter(forSection: section))
    }
}

// MARK: Init Helpers
extension ItemListViewController {
    private struct ListCollectionHandler {
        let layout: Layout
        let dataSource: DataSource
        let collectionViewController: UICollectionViewController
    }

    private func listCollection(
        eventSink: ItemListEventSink?
    ) -> ListCollectionHandler {
        let collectionViewController = UICollectionViewController(
            collectionViewLayout: UICollectionViewLayout()
        )
        let textRegistration = self.registration(eventSink: eventSink)
        let messageRegistration = self.registration(eventSink: eventSink)
        let singlelineEditRegistration = self.registration(eventSink: eventSink)
        let multilineEditRegistration = self.registration(eventSink: eventSink)
        let dataSource = self.dataSource(
            collectionView: collectionViewController.collectionView,
            textRegistration: textRegistration,
            messageRegistration: messageRegistration,
            singlelineEditRegistration: singlelineEditRegistration,
            multilineEditRegistration: multilineEditRegistration
        )

        let configuration = self.configuration(
            dataSource: dataSource,
            eventSink: eventSink
        )
        let layout = UICollectionViewCompositionalLayout.list(
            using: configuration
        )
        collectionViewController
            .collectionView
            .setCollectionViewLayout(
                layout,
                animated: false
            )

        collectionViewController
            .collectionView
            .dataSource = dataSource

        return .init(
            layout: layout,
            dataSource: dataSource,
            collectionViewController: collectionViewController
        )
    }

    private func configuration(
        dataSource: DataSource,
        eventSink: ItemListEventSink?
    ) -> UICollectionLayoutListConfiguration {
        var configuration = UICollectionLayoutListConfiguration(appearance: .grouped)
        configuration.backgroundColor = .App.viewBackground
        configuration.headerMode = .supplementary
        configuration.footerMode = .supplementary
        configuration.trailingSwipeActionsConfigurationProvider
        = { [weak self, weak dataSource] indexPath in
            self?.trailingSwipeProvider(
                for: indexPath,
                dataSource: dataSource,
                eventSink: eventSink
            )
        }

        return configuration
    }

    private func trailingSwipeProvider(
        for indexPath: IndexPath,
        dataSource: DataSource?,
        eventSink: ItemListEventSink?
    ) -> UISwipeActionsConfiguration? {
        guard
            let dataSource = dataSource,
            let eventSink = eventSink,
            let viewModelId = dataSource.itemIdentifier(for: indexPath),
            let viewModel = self.itemLookup[viewModelId]
        else {
            return nil
        }

        guard viewModel.context.contains(.delete) else { return nil }

        return .init(actions: [
            .deleteAction(
                title: "Delete",
                handler: { _, _, completion in
                    var snapshot = self.dataSource.snapshot()

                    if let sectionId = snapshot.sectionIdentifiers[safe: indexPath.section],
                       let itemId = snapshot.itemIdentifiers(inSection: sectionId)[safe: indexPath.item] {
                        snapshot.deleteItems([itemId])
                        self.dataSource.apply(snapshot)
                    }

                    eventSink.send(
                        event: .delete(
                            itemAt: indexPath
                        )
                    )

                    completion(true)
                }
            )
        ])
    }

    private func registration(
        eventSink: ItemListEventSink?
    ) -> Registration {
        Registration { [weak self] cell, indexPath, itemId in
            guard
                let self,
                let itemViewModel = self.itemLookup[itemId]
            else {
                return
            }

            let configuration = self
                .cellConfiguration(
                    cell,
                    at: indexPath,
                    inSection: self.dataSource.sectionIdentifier(for: indexPath.section),
                    fromViewModel: itemViewModel,
                    eventSink: eventSink
                )

            cell.contentConfiguration = configuration
            cell.accessories = self
                .cellAccessories(
                    indexPath: indexPath,
                    fromViewModel: itemViewModel
                )
            cell.indentationLevel = itemViewModel.indentation
        }
    }

    private func dataSource(
        collectionView: UICollectionView,
        textRegistration: Registration,
        messageRegistration: Registration,
        singlelineEditRegistration: Registration,
        multilineEditRegistration: Registration
    ) -> DataSource {
        let dataSource = DataSource(
            collectionView: collectionView
        ) { [weak self] collectionView, indexPath, item in
            guard let self else { return nil }

            switch self.itemLookup[item]?.type {
            case .text, .attributedText, .none:
                return collectionView.dequeueConfiguredReusableCell(
                    using: textRegistration,
                    for: indexPath,
                    item: item
                )

            case .message:
                return collectionView.dequeueConfiguredReusableCell(
                    using: messageRegistration,
                    for: indexPath,
                    item: item
                )

            case .editSingleline:
                return collectionView.dequeueConfiguredReusableCell(
                    using: singlelineEditRegistration,
                    for: indexPath,
                    item: item
                )

            case .editMultiline:
                return collectionView.dequeueConfiguredReusableCell(
                    using: multilineEditRegistration,
                    for: indexPath,
                    item: item
                )
            }

        }

        let headerRegistration = self.headerRegistration(
            dataSource: dataSource
        )
        let footerRegistration = self.footerRegistration(
            dataSource: dataSource
        )
        dataSource.supplementaryViewProvider = { collectionView, elementKind, indexPath in
            switch elementKind {
            case UICollectionView.elementKindSectionHeader:
                return collectionView.dequeueConfiguredReusableSupplementary(
                    using: headerRegistration,
                    for: indexPath
                )
            case UICollectionView.elementKindSectionFooter:
                return collectionView.dequeueConfiguredReusableSupplementary(
                    using: footerRegistration,
                    for: indexPath
                )
            default:
                return nil
            }
        }

        dataSource
            .reorderingHandlers
            .canReorderItem = { [weak self] id in
                self?.canReorder(id) ?? false
            }

        dataSource
            .reorderingHandlers
            .didReorder = { [weak self] transaction in
                self?.didReorder(transaction: transaction)
            }

        return dataSource
    }

    private func canReorder(_ itemId: ItemViewModel.ID) -> Bool {
        self.itemLookup[itemId]?.context.contains(
            where: { context in
                switch context {
                case .reorder:
                    return true
                default:
                    return false
                }
            }
        ) ?? false
    }

    private func didReorder(
        transaction: NSDiffableDataSourceTransaction<String, ItemViewModel.ID>
    ) {
        for section in transaction.sectionTransactions {
            for move in section.difference.inferringMoves().removals {
                guard
                    case .remove(
                        offset: let from,
                        element: _,
                        associatedWith: let to
                    ) = move,
                    let to,
                    let sectionIndex = self.dataSource.snapshot().indexOfSection(section.sectionIdentifier)
                else { continue }

                self.eventSink?
                    .send(event: .move(
                        from: .init(item: from, section: sectionIndex),
                        to: .init(item: to, section: sectionIndex)
                    ))
            }
        }
    }

    private func headerRegistration(
        dataSource: DataSource
    ) -> HeaderRegistration {
        HeaderRegistration(
            elementKind: UICollectionView.elementKindSectionHeader
        ) { [weak dataSource] supplementaryView, _, indexPath in
            guard let dataSource = dataSource else { return }

            let sectionIdentifiers = dataSource
                .snapshot()
                .sectionIdentifiers

            guard let sectionString = sectionIdentifiers[safe: indexPath.section] else {
                return
            }

            var headerConfiguration = supplementaryView.defaultContentConfiguration()

            headerConfiguration.text = sectionString

            supplementaryView.contentConfiguration = headerConfiguration
        }
    }

    private func footerRegistration(
        dataSource: DataSource
    ) -> FooterRegistration {
        FooterRegistration(
            elementKind: UICollectionView.elementKindSectionFooter
        ) { [weak self, weak dataSource] supplementaryView, _, indexPath in
            guard
                let self,
                let dataSource = dataSource
            else { return }

            let sectionIdentifiers = dataSource
                .snapshot()
                .sectionIdentifiers

            guard let sectionString = sectionIdentifiers[safe: indexPath.section] else {
                return
            }

            var footerConfiguration = supplementaryView.defaultContentConfiguration()

            footerConfiguration.attributedText = self.footerLookup[sectionString]?.map { errorMessage in
                    .init(
                        string: errorMessage.message,
                        purpose: .error(suggestion: errorMessage.suggestion)
                    )
            }

            if (self.footerLookup[sectionString] ?? nil) != nil {
                let footerTap = UITapGestureRecognizer(
                    target: self,
                    action: #selector(tapFooter)
                )
                supplementaryView.tag = indexPath.section
                supplementaryView.addGestureRecognizer(footerTap)
            }

            supplementaryView.contentConfiguration = footerConfiguration
        }
    }

    private func textConfiguration(
        forCell cell: UICollectionViewListCell,
        content text: (String)
    ) -> UIContentConfiguration {
        var configuration = cell.defaultContentConfiguration()
        configuration.text = text

        return configuration
    }

    private func messageConfiguration(
        forCell cell: UICollectionViewListCell,
        content text: String
    ) -> UIContentConfiguration {
        var configuration = cell.defaultContentConfiguration()
        configuration.text = text

        var properties = configuration.textProperties
        properties.alignment = .center
        properties.font = .preferredFont(forTextStyle: .footnote)
        properties.color = .systemGray
        configuration.textProperties = properties

        return configuration
    }

    private func attributedTextConfiguration(
        forCell cell: UICollectionViewListCell,
        content text: NSAttributedString
    ) -> UIContentConfiguration {
        var configuration = cell.defaultContentConfiguration()
        configuration.attributedText = text

        return configuration
    }

    // swiftlint:disable:next function_parameter_count
    private func singlelineEditableConfiguration(
        forCell cell: UICollectionViewListCell,
        purpose: String,
        text: String,
        eventSink: ItemListEventSink?,
        indexPath: IndexPath,
        section: String?
    ) -> UIContentConfiguration {
        var configuration = cell.textFieldConfiguration(
            for: purpose
        )
        configuration.text = text
        configuration.textDidUpdate = { newText in
            guard
                let eventSink = eventSink,
                let newText = newText
            else {
                return
            }

            eventSink.send(
                event: .edit(
                    string: newText,
                    forItemAt: indexPath
                )
            )
        }
        configuration.didStartEditing = { [weak self] in
            self?.sectionBeingEdited = section
            Task {
                eventSink?.send(
                    event: .edit(
                        string: text,
                        forItemAt: indexPath
                    )
                )
            }
        }
        configuration.didEndEditing = { [weak self] in
            self?.sectionBeingEdited = nil
            if let section { self?.reloadSection(section) }
        }

        return configuration
    }

    // swiftlint:disable:next function_parameter_count
    private func multilineEditableConfiguration(
        forCell cell: UICollectionViewListCell,
        purpose: String,
        text: String,
        eventSink: ItemListEventSink?,
        indexPath: IndexPath,
        section: String?
    ) -> UIContentConfiguration {
        var configuration = cell.textViewConfiguration(
            for: purpose
        )
        configuration.text = text
        configuration.textDidUpdate = { newText in
            guard
                let eventSink = eventSink,
                let newText = newText
            else {
                return
            }

            eventSink.send(
                event: .edit(
                    string: newText,
                    forItemAt: indexPath
                )
            )
        }
        configuration.didStartEditing = { [weak self] in
            self?.sectionBeingEdited = section
        }
        configuration.didEndEditing = { [weak self] in
            self?.sectionBeingEdited = nil
            if let section { self?.reloadSection(section) }
        }

        return configuration
    }

    private func cellConfiguration(
        _ cell: UICollectionViewListCell,
        at indexPath: IndexPath,
        inSection section: String?,
        fromViewModel viewModel: ItemViewModel,
        eventSink: ItemListEventSink?
    ) -> UIContentConfiguration {
        switch viewModel.type {
        case .text(let text):
            return textConfiguration(forCell: cell, content: text)

        case .message(let text):
            return messageConfiguration(forCell: cell, content: text)
            
        case .attributedText(let text):
            return attributedTextConfiguration(forCell: cell, content: text)

        case .editSingleline(let text, let purpose):
            return singlelineEditableConfiguration(
                forCell: cell,
                purpose: purpose,
                text: text,
                eventSink: eventSink,
                indexPath: indexPath,
                section: section
            )

        case .editMultiline(let text, let purpose):
            return multilineEditableConfiguration(
                forCell: cell,
                purpose: purpose,
                text: text,
                eventSink: eventSink,
                indexPath: indexPath,
                section: section
            )
        }
    }

    private func cellAccessories(
        indexPath: IndexPath,
        fromViewModel viewModel: ItemViewModel
    ) -> [UICellAccessory] {
        cellAccessories(indexPath: indexPath, fromTextItem: viewModel)
    }

    private func cellAccessories(
        indexPath: IndexPath,
        fromTextItem textItem: ItemListViewModel.Item
    ) -> [UICellAccessory] {
        textItem
            .context
            .compactMap {
                self.cellAccessory(
                    indexPath: indexPath,
                    fromItemAccessory: $0
                )
            }
    }

    private func cellAccessory(
        indexPath: IndexPath,
        fromItemAccessory itemAccessory: ItemListViewModel.Context
    ) -> UICellAccessory? {
        switch itemAccessory {
        case .navigate:
            return .disclosureIndicator()
        case .delete:
            return .delete()
        case .add:
            return .insert(displayed: .always)
        case .invalid(let reason):
            return .detail(
                options: .init(tintColor: .red)) {
                    let alertController = UIAlertController(
                        title: reason,
                        message: nil,
                        preferredStyle: .alert
                    )
                    alertController.addAction(
                        .init(title: "OK", style: .cancel)
                    )
                    self.present(alertController, animated: true)
                }
        case .reorder:
            return .reorder()
        case .info:
            return .detail { [weak self] in
                self?.eventSink?.send(event: .openInfo(itemAt: indexPath))
            }
        case .alert(let data):
            return alertAccessory(data: data, for: indexPath)
        case .multiselect:
            return .multiselect(displayed: .always)
        }
    }

    private func alertAccessory(
        data: ItemListViewModel.AlertData,
        for indexPath: IndexPath
    ) -> UICellAccessory? {
        let alertButton = UIButton(
            frame: .init(x: 0, y: 0, width: 50, height: 50),
            primaryAction: .init(
                image: .init(systemName: "exclamationmark.circle")?.withRenderingMode(.alwaysTemplate),
                handler: { _ in }
            ))
        alertButton.menu = .init(
            title: data.message,
            children: [
                UIAction(
                    title: data.actionDescription,
                    image: self.image(forButtonType: data.icon),
                    handler: { [weak self] _ in
                        self?.eventSink?.send(event: .resolveAlert(itemAt: indexPath))
                    })
            ]
        )
        alertButton.showsMenuAsPrimaryAction = true
        let configuration = UICellAccessory.CustomViewConfiguration(
            customView: alertButton,
            placement: .trailing(),
            isHidden: false,
            reservedLayoutWidth: .standard,
            tintColor: .red,
            maintainsFixedSize: true
        )
        return .customView(configuration: configuration)
    }

    private func image(
        forButtonType buttonType: NavBarViewModel.ButtonType?
    ) -> UIImage? {
        switch buttonType {
        case .save:
            return nil
        case .cancel:
            return nil
        case .back:
            return nil
        case .edit:
            return .init(systemName: "pencil")
        case .add:
            return .init(systemName: "plus")
        case .done:
            return nil
        case .export, .exportTextOnly:
            fatalError("Not yet implemented")
        case .none:
            return nil
        }
    }
}

extension ItemListViewController: UICollectionViewDelegate {
    private func itemViewModel(at indexPath: IndexPath) -> ItemViewModel? {
        let snapshot = self.dataSource.snapshot()
        guard
            let sectionIdentifier
                = snapshot.sectionIdentifiers[safe: indexPath.section],
            let itemViewModelId
                = snapshot.itemIdentifiers(inSection: sectionIdentifier)[safe: indexPath.item]
        else {
            return nil
        }

        return self.itemLookup[itemViewModelId]
    }

    func collectionView(
        _ collectionView: UICollectionView,
        shouldSelectItemAt indexPath: IndexPath
    ) -> Bool {
        guard let itemViewModel = itemViewModel(at: indexPath) else {
            return false
        }

        return itemViewModel.context.contains(.multiselect)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        canPerformPrimaryActionForItemAt indexPath: IndexPath
    ) -> Bool {
        guard let itemViewModel = self.itemViewModel(at: indexPath) else {
            return false
        }

        return itemViewModel.context.contains { context in
            context == .navigate ||
            context == .add
        }
    }

    func collectionView(
        _ collectionView: UICollectionView,
        performPrimaryActionForItemAt indexPath: IndexPath
    ) {
        let snapshot = self.dataSource.snapshot()
        guard
            let sectionIdentifier
                = snapshot.sectionIdentifiers[safe: indexPath.section],
            snapshot.numberOfItems(inSection: sectionIdentifier)
                > indexPath.item
        else {
            return
        }

        self.eventSink?.send(
            event: .select(itemAt: indexPath)
        )
    }

    func collectionView(
        _ collectionView: UICollectionView,
        targetIndexPathForMoveOfItemFromOriginalIndexPath originalIndexPath: IndexPath,
        atCurrentIndexPath currentIndexPath: IndexPath,
        toProposedIndexPath proposedIndexPath: IndexPath
    ) -> IndexPath {
        guard
            let id = self.dataSource.itemIdentifier(for: currentIndexPath),
            let item = self.itemLookup[id],
            let validReorder = item.context.compactMap({ context in
                switch context {
                case .reorder(let validReorder):
                    return validReorder
                default:
                    return nil
                }
            }).first
        else {
            return proposedIndexPath
        }

        if validReorder.isValid(indexPath: proposedIndexPath) {
            return proposedIndexPath
        } else {
            return currentIndexPath
        }
    }

    private func selectInitialSelection() {
        guard
            let initialSelection,
            let cell = self.collectionView.cellForItem(at: initialSelection)
        else { return }

        switch cell.contentView {
        case let cellView as ItemListSingleLineTextEditView:
            cellView.textField.becomeFirstResponder()
        case let cellView as ItemListMultiLineTextEditView:
            cellView.textView.becomeFirstResponder()
        default:
            break
        }

        self.initialSelection = nil
    }
}

extension ItemListViewController: ItemListViewModelSink {
    func send(viewModel: ItemListViewModel) {
        for selection in self.collectionView.indexPathsForSelectedItems ?? [] {
            self.collectionView.deselectItem(at: selection, animated: true)
        }

        let itemPairs = viewModel
            .sections
            .flatMap { $0.items }
            .map { ($0.id, $0) }
        let itemsToReconfigure = itemPairs
            .filter { (id, item) in
                self.itemLookup[id].map { $0 != item } ?? false
            }
            .map { $0.0 }

        let newItemLookup = Dictionary(itemPairs) { first, _ in first }
        self.itemLookup = newItemLookup

        let sectionPairs = viewModel
            .sections
            .map { ($0.title, $0.footerErrorMessage) }
        let sectionsToReconfigure = sectionPairs
            .filter {
                self.footerLookup[$0.0] == nil ||
                self.footerLookup[$0.0] != $0.1
            }
            .filter { $0.0 != self.sectionBeingEdited }
            .map { $0.0 }

        self.footerLookup = Dictionary(sectionPairs) { first, _ in first }

        var snapshot = Snapshot()

        snapshot.appendSections(viewModel.sections.map { $0.title })
        snapshot.reloadSections(sectionsToReconfigure)

        for section in viewModel.sections {
            snapshot.appendItems(
                section.items.map { $0.id },
                toSection: section.title
            )
        }
        snapshot.reconfigureItems(itemsToReconfigure)

        Task { @MainActor in
            self.dataSource.apply(snapshot)
        }

        self.collectionViewController
            .collectionView
            .isEditing = viewModel.isEditing
    }

    func scrollTo(_ indexPath: IndexPath) {
        let snapshot = self.dataSource.snapshot()
        guard
            let sectionId = snapshot.sectionIdentifiers[safe: indexPath.section],
            snapshot.itemIdentifiers(inSection: sectionId).indices.contains(indexPath.item)
        else {
            return
        }

        self.collectionView.selectItem(
            at: indexPath,
            animated: true,
            scrollPosition: .centeredVertically
        )
    }
}
