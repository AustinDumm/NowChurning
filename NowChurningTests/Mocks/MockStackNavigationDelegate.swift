//
//  MockStackNavigationDelegate.swift
//  NowChurningTests
//
//  Created by Austin Dumm on 4/17/23.
//

import UIKit
@testable import NowChurning

class MockStackNavigationDelegate: NSObject, StackNavigationDelegate {
    var didDisconnectDelegateFromNavigationControllerClosure: ((StackNavigation) -> Void)?
    func didDisconnectDelegate(
        fromNavigationController navigationController: StackNavigation
    ) {
        self.didDisconnectDelegateFromNavigationControllerClosure?(navigationController)
    }

    var navigationControllerDidShowAnimatedClosure: ((UINavigationController, UIViewController, Bool) -> Void)?
    func navigationController(
        _ navigationController: UINavigationController,
        didShow viewController: UIViewController,
        animated: Bool
    ) {
        self.navigationControllerDidShowAnimatedClosure?(
            navigationController,
            viewController,
            animated
        )
    }
}
