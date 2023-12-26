//
//  TagSelectorDisplayModelSinkMock.swift
//  NowChurningTests
//
//  Created by Austin Dumm on 2/20/23.
//

import Foundation
@testable import NowChurning

class TagSelectorDisplayModelSinkMock<TagBase>: TagSelectorDisplayModelSink {
    var sendClosure: ((TagSelectorDisplayModel<TagBase>) -> Void)?
    func send(displayModel: TagSelectorDisplayModel<TagBase>) {
        self.sendClosure?(displayModel)
    }
}
