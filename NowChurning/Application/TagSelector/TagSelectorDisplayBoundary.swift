//
//  TagSelectorDisplayBoundary.swift
//  NowChurning
//
//  Created by Austin Dumm on 2/18/23.
//

import Foundation

struct TagSelectorDisplayModel<TagBase> {
    struct TagSelection: Equatable {
        var tag: Tag<TagBase>
        var isSelected: Bool
    }

    var tagSelections: [TagSelection]
}

protocol TagSelectorDisplayModelSink: AnyObject {
    associatedtype TagBase

    func send(displayModel: TagSelectorDisplayModel<TagBase>)
}


enum TagSelectorAction {
    case cancel
    case select(tagIndices: [Int])
}

protocol TagSelectorActionSink: AnyObject {
    func send(action: TagSelectorAction)
}
