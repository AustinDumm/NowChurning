//
//  StackNavigation.swift
//  NowChurning
//
//  Created by Austin Dumm on 12/26/23.
//

import UIKit

protocol StackNavigationDelegate: UINavigationControllerDelegate {
    func didDisconnectDelegate(
        fromNavigationController: StackNavigation
    )
}

class StackNavigation: UINavigationController {
    private struct WeakDelegate {
        weak var attachedViewController: UIViewController?
        var attachedStackIndex: Int
        weak var delegate: StackNavigationDelegate?
    }


    override var delegate: UINavigationControllerDelegate? {
        get {
            super.delegate
        }
        // swiftlint:disable:next line_length
        @available(*, deprecated, renamed: "pushDelegate(_:)", message: "Setting StackNavigation delegate should be set via the pushDelegate to associate the delegate with the current top view controller and maintain delegate consistency through navigation changes.")
        set {
            super.delegate = newValue
        }
    }

    private var delegateStack = [WeakDelegate]()
    var topDelegate: StackNavigationDelegate? {
        delegateStack.last?.delegate
    }

    init() {
        super.init(nibName: nil, bundle: nil)

        self.sharedInit()
    }

    override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)

        self.sharedInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        self.sharedInit()
    }

    private func sharedInit() {
        super.delegate = self
    }

    func pushDelegate(_ delegate: StackNavigationDelegate) {
        let associatedViewIndex = self.viewControllers.count - 1
        self.delegateStack.append(
            .init(
                attachedViewController: self.topViewController,
                attachedStackIndex: associatedViewIndex,
                delegate: delegate
            )
        )
    }

    func pushViewController(
        _ viewController: UIViewController,
        withAssociatedNavigationDelegate associatedNavigationDelegate: StackNavigationDelegate? = nil,
        animated: Bool,
        completion: (() -> Void)? = nil
    ) {
        super.pushViewController(
            viewController,
            animated: animated
        ) {
            if let delegate = associatedNavigationDelegate {
                self.pushDelegate(delegate)
            }

            completion?()
        }
    }

    func insertViewController(
        _ viewController: UIViewController,
        atStackIndex stackIndex: Int,
        withAssociatedNavigationDelegate associatedNavigationDelegate: StackNavigationDelegate? = nil
    ) {
#if !DEBUG
        // Only protect against this out of bounds on release builds
        // On debug builds, let the out of bounds crash
        guard self.viewControllers.indices.contains(stackIndex) else {
            return
        }
#endif

        var viewControllers = self.viewControllers
        viewControllers.insert(viewController, at: stackIndex)
        self.viewControllers = viewControllers

        if let delegate = associatedNavigationDelegate {
            self.insertStackedDelegate(
                delegate,
                associatedViewController: viewController,
                atStackIndex: stackIndex
            )
        }
    }

    private func insertStackedDelegate(
        _ delegate: StackNavigationDelegate,
        associatedViewController: UIViewController,
        atStackIndex stackIndex: Int
    ) {
        let insertItem = WeakDelegate(
            attachedViewController: associatedViewController,
            attachedStackIndex: stackIndex,
            delegate: delegate
        )

        if let insertIndex = self.delegateStack.firstIndex(where: { existingDelegate in
            existingDelegate.attachedStackIndex > stackIndex
        }) {
            self.delegateStack.insert(
                insertItem,
                at: insertIndex
            )
        } else {
            self.delegateStack.append(insertItem)
        }
    }
}

extension StackNavigation: UINavigationControllerDelegate {
    func navigationController(
        _ navigationController: UINavigationController,
        willShow viewController: UIViewController,
        animated: Bool
    ) {
        self.topDelegate?.navigationController?(
            navigationController,
            willShow: viewController,
            animated: animated
        )
    }

    func navigationController(
        _ navigationController: UINavigationController,
        didShow viewController: UIViewController,
        animated: Bool
    ) {
        self.topDelegate?.navigationController?(
            navigationController,
            didShow: viewController,
            animated: animated
        )

        if let activeDelegate = self.delegateStack.last,
           let expectedViewController = activeDelegate.attachedViewController,
           expectedViewController !== navigationController.viewControllers[safe: activeDelegate.attachedStackIndex] || activeDelegate.delegate
         == nil {
            // View stack has popped off the view at the delegate's attached index or
            // the view at the attached index is no longer the attached view.
            // The active delegate should no longer be connected to this navigation controller
            self.popDelegate()
            activeDelegate.delegate?.didDisconnectDelegate(
                fromNavigationController: self
            )

            // Reforward and recalculate didShow with new top delegate
            self.navigationController(
                navigationController,
                didShow: viewController,
                animated: animated
            )
        }
    }


    func navigationControllerSupportedInterfaceOrientations(
        _ navigationController: UINavigationController
    ) -> UIInterfaceOrientationMask {
        self.topDelegate?.navigationControllerSupportedInterfaceOrientations?(
            navigationController
        ) ?? .all
    }

    func navigationControllerPreferredInterfaceOrientationForPresentation(
        _ navigationController: UINavigationController
    ) -> UIInterfaceOrientation {
        self.topDelegate?
            .navigationControllerPreferredInterfaceOrientationForPresentation?(
                navigationController
            ) ?? .unknown
    }


    func navigationController(
        _ navigationController: UINavigationController,
        interactionControllerFor animationController: UIViewControllerAnimatedTransitioning
    ) -> UIViewControllerInteractiveTransitioning? {
        self.topDelegate?.navigationController?(
            navigationController,
            interactionControllerFor: animationController
        )
    }


    func navigationController(
        _ navigationController: UINavigationController,
        animationControllerFor operation: UINavigationController.Operation,
        from fromVC: UIViewController,
        to toVC: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        self.topDelegate?.navigationController?(
            navigationController,
            animationControllerFor: operation,
            from: fromVC,
            to: toVC
        )
    }
}
