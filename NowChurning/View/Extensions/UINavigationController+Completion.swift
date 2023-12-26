//
//  UINavigationController+Completion.swift
//  NowChurning
//
//  Created by Austin Dumm on 5/25/23.
//

import UIKit

extension UINavigationController {
    public func pushViewController(
        _ viewController: UIViewController,
        animated: Bool,
        completion: (() -> Void)? = nil
    ) {
        self.pushViewController(viewController, animated: animated)

        guard animated, let coordinator = self.transitionCoordinator else {
            DispatchQueue.main.async { completion?() }
            return
        }

        coordinator.animate(alongsideTransition: nil) { _ in completion?() }
    }

    public func popViewController(
        animated: Bool,
        completion: @escaping () -> Void
    ) {
        self.popViewController(animated: animated)

        guard animated, let coordinator = self.transitionCoordinator else {
            DispatchQueue.main.async { completion() }
            return
        }

        coordinator.animate(alongsideTransition: nil) { _ in completion() }
    }

    public func popToViewController(
        _ viewController: UIViewController,
        animated: Bool,
        completion: @escaping () -> Void
    ) {
        self.popToViewController(viewController, animated: animated)

        guard animated, let coordinator = self.transitionCoordinator else {
            DispatchQueue.main.async { completion() }
            return
        }

        coordinator.animate(alongsideTransition: nil) { _ in completion() }
    }

    public func popToRootViewController(
        animated: Bool,
        completion: @escaping () -> Void
    ) {
        self.popToRootViewController(animated: animated)

        guard animated, let coordinator = self.transitionCoordinator else {
            DispatchQueue.main.async { completion() }
            return
        }

        coordinator.animate(alongsideTransition: nil) { _ in completion() }
    }

    public func setViewControllers(
        _ viewControllers: [UIViewController],
        animated: Bool,
        completion: @escaping () -> Void
    ) {
        self.setViewControllers(viewControllers, animated: animated)

        guard animated, let coordinator = self.transitionCoordinator else {
            DispatchQueue.main.async { completion() }
            return
        }

        coordinator.animate(alongsideTransition: nil) { _ in completion() }
    }
}
