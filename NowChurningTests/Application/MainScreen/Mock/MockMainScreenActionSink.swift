//
//  MockMainScreenActionSink.swift
//  NowChurningTests
//
//  Created by Austin Dumm on 12/18/22.
//

import Foundation
@testable import NowChurning

class MockMainScreenActionSink: MainScreenActionSink {
    var sendCallback: ((MainScreenAction) -> ())?
    func send(action: MainScreenAction) {
        self.sendCallback?(action)
    }
}
