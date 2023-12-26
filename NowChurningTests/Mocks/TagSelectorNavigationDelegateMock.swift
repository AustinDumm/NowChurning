//
//  TagSelectorNavigationDelegateMock.swift
//  NowChurningTests
//
//  Created by Austin Dumm on 2/20/23.
//

import Foundation
@testable import NowChurning

class TagSelectorNavigationDelegateMock<TagBase>: TagSelectorDelegate {
    var didSelectClosure: (([Tag<TagBase>]) -> Void)?
    func didSelect(tags: [Tag<TagBase>]) {
        self.didSelectClosure?(tags)
    }

    var cancelTagClosure: (() -> Void)?
    func cancelTagSelection() {
        self.cancelTagClosure?()
    }
}
