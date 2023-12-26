//
//  TagSelectorApplication.swift
//  NowChurning
//
//  Created by Austin Dumm on 2/18/23.
//

import Foundation

protocol TagSelectorDelegate: AnyObject {
    associatedtype TagBase

    func didSelect(tags: [Tag<TagBase>])
    func cancelTagSelection()
}

class TagSelectorApplication<
    Sink: TagSelectorDisplayModelSink,
    Delegate: TagSelectorDelegate
> where Sink.TagBase == Delegate.TagBase {
    private typealias TagType = Tag<TagBase>

    weak var displayModelSink: Sink? {
        didSet {
            self.tagsDidUpdate()
        }
    }

    weak var delegate: Delegate?

    private var tagSelections: [Tag<TagBase>]
    private var validTags: [TagType]? {
        didSet {
            self.tagsDidUpdate()
        }
    }

    init(
        initialSelection: [Tag<TagBase>],
        navDelegate: Delegate? = nil
    ) {
        self.tagSelections = initialSelection
        self.delegate = navDelegate
    }

    private func tagsDidUpdate() {
        guard let validTags = self.validTags else { return }

        let displayModelSelections = validTags
            .map { TagSelectorDisplayModel.TagSelection(
                tag: $0,
                isSelected: self.tagSelections.contains($0)
            )}

        self.displayModelSink?.send(
            displayModel: .init(
                tagSelections: displayModelSelections
            )
        )
    }
}

extension TagSelectorApplication: TagSelectorActionSink {
    func send(action: TagSelectorAction) {
        switch action {
        case .cancel:
            self.delegate?.cancelTagSelection()
        case .select(let tagIndices):
            let selectedTags = tagIndices
                .map { self.validTags?[safe: $0] }

            guard selectedTags.allSatisfy({ $0 != nil }) else {
                break
            }

            self.delegate?
                .didSelect(tags: selectedTags.compactMap { $0 })
        }
    }
}

extension TagSelectorApplication: ValidTagsDomainSink {
    func send(validTags: [Tag<Sink.TagBase>]) {
        self.validTags = validTags
    }
}
