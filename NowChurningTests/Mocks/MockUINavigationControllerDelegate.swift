//
//  MockUINavigationControllerDelegate.swift
//  NowChurningTests
//
//  Created by Austin Dumm on 4/17/23.
//

import UIKit

class MockUINavigationControllerDelegate: NSObject, UINavigationControllerDelegate {

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
