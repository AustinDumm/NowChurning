//
//  MockMainScreenAppNavDelegate.swift
//  NowChurningTests
//
//  Created by Austin Dumm on 10/18/22.
//

import Foundation
@testable import NowChurning

class MockMainScreenAppNavDelegate: MainScreenAppNavDelegate {
    var navigateCallback: ((MainScreenApplication.Action) -> ())?
    func navigateTo(action: MainScreenApplication.Action) {
        self.navigateCallback?(action)
    }
}
