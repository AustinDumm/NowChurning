//
//  TagSelectorSelectionListPresentation.swift
//  NowChurning
//
//  Created by Austin Dumm on 2/20/23.
//

import Foundation

struct TagSelectorContent {
    let barTitle: String
}

class TagSelectorSelectionListPresentation<TagBase> {
    weak var viewModelSink: SelectionListViewModelSink? {
        didSet {
            self.updateViewModel()
        }
    }

    weak var navBarManager: NavBarViewModelSink? {
        didSet {
            self.updateNavBar()
        }
    }

    private let application: TagSelectorActionSink
    private let content: TagSelectorContent

    private var displayInverseSortLookup: [Int: Int]?
    private var displayModel: TagSelectorDisplayModel<TagBase>? {
        didSet {
            self.updateViewModel()
        }
    }
    private var currentSelectionIndices: [Int] = []

    init(
        application: TagSelectorActionSink,
        content: TagSelectorContent
    ) {
        self.application = application
        self.content = content
    }

    private func updateViewModel() {
        guard let displayModel = self.displayModel else {
            return
        }

        self.currentSelectionIndices = displayModel
            .tagSelections
            .enumerated()
            .compactMap { index, selection in
                if selection.isSelected {
                    return index
                } else {
                    return nil
                }
            }
            .compactMap {
                self.displayInverseSortLookup?[$0] ?? $0
            }

        let viewModel = SelectionListViewModel(
            items: displayModel
                .tagSelections
                .map { .init(
                    title: "#\($0.tag.name)",
                    isSelected: $0.isSelected
                )}
        )

        self.viewModelSink?.send(viewModel: viewModel)
    }

    private func updateNavBar() {
        self.navBarManager?
            .send(navBarViewModel: .init(
                title: self.content.barTitle,
                leftButtons: [.init(type: .cancel, isEnabled: true)],
                rightButtons: [.init(type: .done, isEnabled: true)]
            )
        )
    }
}

extension TagSelectorSelectionListPresentation: SelectionListEventSink {
    func send(event: SelectionListEvent) {
        switch event {
        case .changeSelection(let indices):
            let inverseSortedIndices = indices
                .compactMap { self.displayInverseSortLookup?[$0] }

            self.currentSelectionIndices = inverseSortedIndices
        }
    }
}

extension TagSelectorSelectionListPresentation: TagSelectorDisplayModelSink {
    func send(displayModel: TagSelectorDisplayModel<TagBase>) {
        let enumeratedItems = displayModel.tagSelections.enumerated()
        let sortedEnumerated = enumeratedItems
            .sorted { lhs, rhs in
                lhs.element.tag.name
                    .localizedCaseInsensitiveCompare(
                        rhs.element.tag.name
                    ) == .orderedAscending
            }
        let lookupPairs = sortedEnumerated
            .enumerated()
            .map { index, sortedPair in
                (index, sortedPair.offset)
            }
        self.displayInverseSortLookup = .init(
            lookupPairs,
            uniquingKeysWith: { first, _ in first }
        )

        self.displayModel = .init(
            tagSelections: sortedEnumerated.map { $0.element }
        )
    }
}

extension TagSelectorSelectionListPresentation: NavBarEventSink {
    func send(navBarEvent: NavBarEvent) {
        switch navBarEvent {
        case .tap(.left, 0):
            self.application
                .send(action: .cancel)
        case .tap(.right, 0):
            self.application
                .send(action: .select(
                    tagIndices: self.currentSelectionIndices
                ))
        default:
            break
        }
    }
}
