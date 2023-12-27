//
//  StackNavigation.swift
//  NowChurning
//
//  Created by Austin Dumm on 12/26/23.
//

import UIKit

class StackNavigation: UINavigationController {
    private struct WeakDelegate {
        weak var delegate: UINavigationControllerDelegate?
    }

    private var delegateStack = [WeakDelegate]()

    func pushDelegate(_ delegate: UINavigationControllerDelegate) {
        self.delegateStack.append(.init(delegate: delegate))
        self.delegate = delegate
    }

    func popDelegate() {
        _ = self.delegateStack.popLast()
        self.delegate = self.delegateStack.last?.delegate
    }
}
