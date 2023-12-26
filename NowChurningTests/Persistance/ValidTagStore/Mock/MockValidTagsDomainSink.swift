//
//  MockValidTagsDomainSink.swift
//  NowChurningTests
//
//  Created by Austin Dumm on 4/11/23.
//

import Foundation
@testable import NowChurning

class MockValidTagsDomainSink<TagBase>: ValidTagsDomainSink {
    var sendValidTagsClosure: (([Tag<TagBase>]) -> Void)?
    func send(validTags: [Tag<TagBase>]) {
        self.sendValidTagsClosure?(validTags)
    }
}
