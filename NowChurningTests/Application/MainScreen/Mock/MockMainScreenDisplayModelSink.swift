//
//  MockMainScreenDisplayModelSink.swift
//  NowChurningTests
//
//  Created by Austin Dumm on 10/18/22.
//

import Foundation
@testable import NowChurning

class MockMainScreenDisplayModelSink: MainScreenDisplayModelSink {
    var lastDisplayModel: MainScreenDisplayModel?
    var displayCallback: ((MainScreenDisplayModel) -> ())?
    func send(displayModel: MainScreenDisplayModel) {
        self.lastDisplayModel = displayModel
        self.displayCallback?(displayModel)
    }
}
