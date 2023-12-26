//
//  MockItemListEventSink.swift
//  NowChurningTests
//
//  Created by Austin Dumm on 12/18/22.
//

import Foundation
@testable import NowChurning

class MockItemListEventSink: ItemListEventSink {
    var sendCallback: ((ItemListEvent) -> ())?
    func send(event: ItemListEvent) {
        self.sendCallback?(event)
    }
}
