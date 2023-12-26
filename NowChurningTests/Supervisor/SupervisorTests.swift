//
//  SupervisorTests.swift
//  NowChurningTests
//
//  Created by Austin Dumm on 4/17/23.
//

import XCTest
import Factory

@testable import NowChurning

class SupervisorTests: XCTestCase {

    override func setUpWithError() throws {
        Container.shared.manager.reset(scope: .cached)
        Container.shared.coreDataManager.register {
            MemoryCoreDataManager()
        }
    }

}
