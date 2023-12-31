//
//  SegmentedNavigationController.swift
//  NowChurning
//
//  Created by Austin Dumm on 12/26/23.
//

import UIKit

protocol SegmentedNavigationControllerDelegate: UINavigationControllerDelegate {
    func didDisconnectDelegate(
        fromNavigationController: SegmentedNavigationController
    )
}

/// Stack-based navigation controller allowing for a management of segments of
/// the stack by different delegates. The segments form a stack each owning a
/// non-overlapping portion of the navigation's view stack. Each segment has a
/// delegate and the top segment's delegate will receive all ``UINavigationControllerDelegate`` messages.
///
/// Removing all view controllers in a segment (through any of the associated
/// ``UINavigationControllerDelegate`` functions) will automatically pop the segment's
/// associated delegate. When this happens, the popped delegate will be alerted
/// via ``SegmentedNavigationControllerDelegate``.didDisconnectDelegate.
///
/// This segmenting and automatic redirecting of delegate events based on the
/// top segment is useful in isolating reusable sets of functionality within an
/// app. With ``UINavigationController``, if an object manages multiple views
/// with the navigation stack and changes the controller's delegate object, it
/// must be sure to reset the delegate to its previous value once it is finished.
///
/// With the segmented solution, an object (e.g. a Supervisor) can start a new 
/// segment with itself as segment delegate when it pushes its first view onto the
/// navigation stack. If a new segment gets pushed from one of its children, this
/// Supervisor will no longer receive delegate messages until its child is done,
/// ensuring that this object will not impact the functionality of any children.
/// Similarly, when this Supervisor's final view is popped, it will automatically be
/// removed as delegate and whatever object was delegate when this Supervisor was
/// instantiated will once again receive delegate messages. This removes any need 
/// for the Supervisor to be aware of the state of the segmented navigation stack
/// when it was initialized.
///
/// E.g. Below shows a navigation stack with three segments, each with their own
/// delegate:
/// ```
///                         / -- End Segment 3   \
///                         | [ViewController 6] |
/// [SegmentDelegate 3] ->  \ -- Start Segment 3 |
///                                              |
///                         / -- End Segment 2   |
///                         | [ViewController 5] |
///                         | [ViewController 4] |
///                         | [ViewController 3] |
/// [SegmentDelegate 2] ->  \ -- Start Segment 2 |
///                                              |
///                         / -- End Segment 1   |
///                         | [ViewController 2] |
///                         | [ViewController 1] |
/// [SegmentDelegate 1] ->  \ -- Start Segment 1 / <- UINavigationController Stack
/// ```
///
/// If `popViewController` is called on the navigation stack shown
/// above, ViewController 6 will be popped, SegmentDelegate 3 will
/// have its `didDisconnectDelegate` function called, and Segment 2
/// will now be the topmost segment. This means SegmentDelegate 2
/// will start recieving ``UINavigationControllerDelegate``
/// function calls and the stack will look as below:
/// ```
///                         / -- End Segment 2   \
///                         | [ViewController 5] |
///                         | [ViewController 4] |
///                         | [ViewController 3] |
/// [SegmentDelegate 2] ->  \ -- Start Segment 2 |
///                                              |
///                         / -- End Segment 1   |
///                         | [ViewController 2] |
///                         | [ViewController 1] |
/// [SegmentDelegate 1] ->  \ -- Start Segment 1 / <- UINavigationController Stack
/// ```
///
/// Pushing a view controller without any segment information extends the current
/// segment to include the new view controller as shown below with a new
/// ViewController 6 on the top of segment 2:
/// ```
///                         / -- End Segment 2   \
///                         | [ViewController 6] |
///                         | [ViewController 5] |
///                         | [ViewController 4] |
///                         | [ViewController 3] |
/// [SegmentDelegate 2] ->  \ -- Start Segment 2 |
///                                              |
///                         / -- End Segment 1   |
///                         | [ViewController 2] |
///                         | [ViewController 1] |
/// [SegmentDelegate 1] ->  \ -- Start Segment 1 / <- UINavigationController Stack
/// ```
///
/// Pushing a view controller with a nil new segment delegate starts a new segment
/// without a delegate. This is good for ensuring a previous segment no longer gets
/// messages as long as this new segement exists, however the new segment does not
/// need any actual ``UINavigationControllerDelegate`` calls.
///
/// ```
///                          / -- End Segment 3   \
///                          | [ViewController 7] |
/// [SegmentDelegate nil] -> \ -- Start Segment 3 |
///                                               |
///                          / -- End Segment 2   |
///                          | [ViewController 6] |
///                          | [ViewController 5] |
///                          | [ViewController 4] |
///                          | [ViewController 3] |
/// [SegmentDelegate 2] ->   \ -- Start Segment 2 |
///                                               |
///                          / -- End Segment 1   |
///                          | [ViewController 2] |
///                          | [ViewController 1] |
/// [SegmentDelegate 1] ->   \ -- Start Segment 1 / <- UINavigationController Stack
/// ```
///
class SegmentedNavigationController: UINavigationController {
    private struct WeakDelegate {
        // Nullable in the case of the root segment which starts below the
        // first view controller and handles the case where Segmented is treated
        // exactly as a UINavigationController (i.e., no segment starts).
        var attachedStackIndex: Int?

        // Should be a SegmentedNavigationControllerDelegate if this
        // was set in the start of a new segment. However, changing
        // the delegate via the inherited `delegate` member leaves
        // room to maybe use a base UINavigationControllerDelegate
        // as a segment's delegate instead.
        weak var delegate: UINavigationControllerDelegate?
    }

    /// Alias to the top segment's segment delegate. This is not the preferred
    /// way to interact with a segment delegate but is left for compatibility
    /// in cases where UINavigationController is expected instead of Segmented.
    override var delegate: UINavigationControllerDelegate? {
        get {
            self.topSegmentDelegate
        }
        // swiftlint:disable:next line_length
        @available(*, deprecated, message: "Setting StackNavigation delegate should be set via the pushDelegate to associate the delegate with the current top view controller and maintain delegate consistency through navigation changes.")
        set {
            self.delegateStack[
                self.delegateStack.count - 1
            ].delegate = newValue
        }
    }

    private var delegateStack = [WeakDelegate]()
    var topSegmentDelegate: UINavigationControllerDelegate? {
        get {
            self.delegateStack.last?.delegate
        }
        set {
            self.delegateStack[self.delegateStack.count - 1].delegate = newValue
        }
    }

    /// Creates a new SegmentedNavigationController with an empty navigation stack
    ///
    /// Initializes the root segment to be below the first view controller to handle
    /// cases where delegate is set or edited before the first view controller push.
    init() {
        super.init(nibName: nil, bundle: nil)

        self.emptyRootSegmentInit()
    }

    /// Creates a new SegmentedNavigationController with a single root view controller
    ///
    /// Initializes the root segment to be starting on the first view controller
    /// with a nil delegate.
    override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)

        self.sharedInit()
        self.delegateStack.append(.init(
            attachedStackIndex: 0,
            delegate: nil
        ))
    }

    /// Creates a new SegmentedNavigationController with a single root view controller
    ///
    /// Initializes the root segment to be starting on the first view controller
    /// with the provided delegate.
    init(
        rootViewController: UIViewController,
        rootSegmentDelegate: SegmentedNavigationControllerDelegate
    ) {
        super.init(rootViewController: rootViewController)

        self.sharedInit()
        self.delegateStack.append(.init(
            attachedStackIndex: 0,
            delegate: rootSegmentDelegate
        ))
    }

    /// Creates a new SegmentedNavigationController with an empty navigation stack
    ///
    /// Initializes the root segment to be below the first view controller to handle
    /// cases where delegate is set or edited before the first view controller push.
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        self.emptyRootSegmentInit()
    }

    private func emptyRootSegmentInit() {
        self.sharedInit()
        self.delegateStack.append(.init())
    }

    private func sharedInit() {
        super.delegate = self
    }

    /// Begins a new segment rooted on the current top view controller
    ///
    /// This changes the top view controller's segment from whatever was the top
    /// segment when it was pushed to be a new segment rooted on itself. This does
    /// not take into account any delay for current animations. Ensure the navigation
    /// stack is not animating a transition while calling this function. To create
    /// a new segment alongside a push, use at 
    /// ``pushViewController(_:startingNewSegmentWithDelegate:animated:completion:)``
    ///
    /// Allows a nil delegate to handle cases where the previous segment should stop
    /// receiving delegation messages but this segment does not need to be alerted
    /// on any delegate events.
    ///
    /// For example, starting with:
    /// ```
    ///                         / -- End Segment 2   \
    ///                         | [ViewController 5] |
    ///                         | [ViewController 4] |
    ///                         | [ViewController 3] |
    /// [SegmentDelegate 2] ->  \ -- Start Segment 2 |
    ///                                              |
    ///                         / -- End Segment 1   |
    ///                         | [ViewController 2] |
    ///                         | [ViewController 1] |
    /// [SegmentDelegate 1] ->  \ -- Start Segment 1 / <- UINavigationController Stack
    /// ```
    /// Calling: startSegment(withDelegate: ...) results in:
    /// ```
    ///                         / -- End Segment 3   \
    ///                         | [ViewController 5] |
    /// [SegmentDelegate 3] ->  \ -- End Segment 3   |
    ///                                              |
    ///                         / -- End Segment 2   |
    ///                         | [ViewController 4] |
    ///                         | [ViewController 3] |
    /// [SegmentDelegate 2] ->  \ -- Start Segment 2 |
    ///                                              |
    ///                         / -- End Segment 1   |
    ///                         | [ViewController 2] |
    ///                         | [ViewController 1] |
    /// [SegmentDelegate 1] ->  \ -- Start Segment 1 / <- UINavigationController Stack
    /// ```
    ///
    /// - Parameter delegate: The delegate to use for this new segment
    func startSegment(withDelegate delegate: SegmentedNavigationControllerDelegate?) {
        guard !self.viewControllers.isEmpty else {
            // Empty view stack means that the root segment is below the navigation
            // stack. Just update that root segment.
            self.delegateStack[0].delegate = delegate
            return
        }

        let associatedViewIndex = self.viewControllers.count - 1
        self.delegateStack.append(
            .init(
                attachedStackIndex: associatedViewIndex,
                delegate: delegate
            )
        )
    }

    /// Pushes a new view controller as the root of a new segment.
    ///
    /// For example starting with:
    /// ```
    ///                         / -- End Segment 2   \
    ///                         | [ViewController 5] |
    ///                         | [ViewController 4] |
    ///                         | [ViewController 3] |
    /// [SegmentDelegate 2] ->  \ -- Start Segment 2 |
    ///                                              |
    ///                         / -- End Segment 1   |
    ///                         | [ViewController 2] |
    ///                         | [ViewController 1] |
    /// [SegmentDelegate 1] ->  \ -- Start Segment 1 / <- UINavigationController Stack
    /// ```
    /// Calling ``pushViewController(_:startingNewSegmentWithDelegate:animated:completion:)`` results in:
    /// ```
    ///                         / -- End Segment 3   \
    ///                         | [ViewController 6] |
    /// [SegmentDelegate 3] ->  \ -- Start Segment 3 |
    ///                                              |
    ///                         / -- End Segment 2   |
    ///                         | [ViewController 5] |
    ///                         | [ViewController 4] |
    ///                         | [ViewController 3] |
    /// [SegmentDelegate 2] ->  \ -- Start Segment 2 |
    ///                                              |
    ///                         / -- End Segment 1   |
    ///                         | [ViewController 2] |
    ///                         | [ViewController 1] |
    /// [SegmentDelegate 1] ->  \ -- Start Segment 1 / <- UINavigationController Stack
    /// ```
    ///
    /// - Parameters:
    ///   - viewController: The view controller to push onto the stack. Meets 
    ///   the same requirements as
    ///   ``UINavigationController``.`pushViewController`
    ///   - segmentDelegate: The object that should receive delegate messages for 
    ///   this new segment. Can be nil to handle cases where the previous segment
    ///   should no longer receive messages but this segment does not need delegate
    ///   messages.
    ///   - animated: Same as the inherited 
    ///   ``UINavigationController``.`pushViewController` animated flag
    ///   - completion: A completion block which is called when the transition is 
    ///   finished. If animated is true, will be called on the end of the animation,
    ///   otherwise is called immediately on transition. Both cases cause this
    ///   completion to be called after the new segment is initialized.
    func pushViewController(
        _ viewController: UIViewController,
        startingNewSegmentWithDelegate segmentDelegate: SegmentedNavigationControllerDelegate?,
        animated: Bool,
        completion: (() -> Void)? = nil
    ) {
        super.pushViewController(
            viewController,
            animated: animated
        ) {
            if let delegate = segmentDelegate {
                self.startSegment(withDelegate: delegate)
            }

            completion?()
        }
    }

    /// Adds a new view controller at a specified index with the new view controller
    /// being the root of a new segment starting at the index and going up the stack
    /// until the next existing segment root. Insertion will not be animated as it
    /// is expected the insertion is not happening at the top of the navigation
    /// stack. If it is happening on the top of the navigation stack, use
    /// ``pushViewController(_:startingNewSegmentWithDelegate:animated:completion:)``.
    ///
    /// For example, starting with:
    /// ```
    ///                         / -- End Segment 2   \
    ///                         | [ViewController 7] |
    ///                         | [ViewController 6] |
    ///                         | [ViewController 5] |
    /// [SegmentDelegate 2] ->  \ -- Start Segment 2 |
    ///                                              |
    ///                         / -- End Segment 1   |
    ///                         | [ViewController 4] |
    ///                         | [ViewController 3] |
    ///                         | [ViewController 2] |
    ///                         | [ViewController 1] |
    /// [SegmentDelegate 1] ->  \ -- Start Segment 1 / <- UINavigationController Stack
    /// ```
    /// Calling `insertViewController(..., atStackIndex: 2, segmentDelegate: ...)` results in:
    /// ```
    ///                          / -- End Segment 2     \
    ///                          | [ViewController 7]   |
    ///                          | [ViewController 6]   |
    ///                          | [ViewController 5]   |
    /// [SegmentDelegate 2] ---> \ -- Start Segment 2   |
    ///                                                 |
    ///                          / -- End Segment NEW   |
    ///                          | [ViewController 4]   |
    ///                          | [ViewController 3]   |
    ///                          | [ViewController NEW] |
    /// [SegmentDelegate NEW] -> \ -- End Segment NEW   |
    ///                                                 |
    ///                          / -- End Segment 1     |
    ///                          | [ViewController 2]   |
    ///                          | [ViewController 1]   |
    /// [SegmentDelegate 1] ---> \ -- Start Segment 1   / <- UINavigationController Stack
    /// ```
    ///
    /// - Parameters:
    ///   - viewController: The view controller to insert
    ///   - stackIndex: The navigation stack index at which to insert the view 
    ///   controller
    ///   - segmentDelegate: The delegate for the new segment starting at 
    ///   viewController. Can be nil to handle cases where the new segment does not
    ///   need to receive delegate messages but the segment below in the stack
    ///   should not until this new segment is removed.
    func insertViewController(
        _ viewController: UIViewController,
        atStackIndex stackIndex: Int,
        startingNewSegmentWithDelegate segmentDelegate: SegmentedNavigationControllerDelegate?
    ) {
        var viewControllers = self.viewControllers
        viewControllers.insert(viewController, at: stackIndex)
        self.setViewControllers(
            viewControllers,
            animated: false
        ) {
            self.insertSegmentDelegate(
                segmentDelegate,
                segmentRootViewController: viewController,
                atNavigationStackIndex: stackIndex
            )
        }
    }

    /// Inserts a new view controller at the specified index while adjusting the
    /// segment start indicies for all segments above the insertion index. The 
    /// inserted view controller will be part of the nearest segment whose root is
    /// below the insert index. Insertion will not be animated as it
    /// is expected the insertion is not happening at the top of the navigation
    /// stack. If it is happening on the top of the navigation stack, use
    /// ``pushViewController(_:startingNewSegmentWithDelegate:animated:completion:)``.
    ///
    /// For example, starting with:
    /// ```
    ///                         / -- End Segment 2   \
    ///                         | [ViewController 7] |
    ///                         | [ViewController 6] |
    ///                         | [ViewController 5] |
    /// [SegmentDelegate 2] ->  \ -- Start Segment 2 |
    ///                                              |
    ///                         / -- End Segment 1   |
    ///                         | [ViewController 4] |
    ///                         | [ViewController 3] |
    ///                         | [ViewController 2] |
    ///                         | [ViewController 1] |
    /// [SegmentDelegate 1] ->  \ -- Start Segment 1 / <- UINavigationController Stack
    /// ```
    /// Calling `insertViewController(..., atStackIndex: 2)` results in:
    /// ```
    ///                          / -- End Segment 2     \
    ///                          | [ViewController 7]   |
    ///                          | [ViewController 6]   |
    ///                          | [ViewController 5]   |
    /// [SegmentDelegate 2] ---> \ -- Start Segment 2   |
    ///                                                 |
    ///                          / -- End Segment 1     |
    ///                          | [ViewController 4]   |
    ///                          | [ViewController 3]   |
    ///                          | [ViewController NEW] |
    ///                          | [ViewController 2]   |
    ///                          | [ViewController 1]   |
    /// [SegmentDelegate 1] ---> \ -- Start Segment 1   / <- UINavigationController Stack
    /// ```
    ///
    ///
    /// - Parameters:
    ///   - viewController: The view controller to insert
    ///   - stackIndex: The index in the navigation stack to insert the new view
    ///   controller.
    func insertViewController(
        _ viewController: UIViewController,
        atStackIndex stackIndex: Int
    ) {
        var viewControllers = self.viewControllers
        viewControllers.insert(viewController, at: stackIndex)
        self.setViewControllers(
            viewControllers,
            animated: false
        ) {
            for var segmentDelegate in self.delegateStack where
            (segmentDelegate.attachedStackIndex.map { $0 >= stackIndex } ?? false) {
                segmentDelegate.attachedStackIndex = segmentDelegate.attachedStackIndex.map { $0 + 1 }
            }
        }
    }

    private func insertSegmentDelegate(
        _ delegate: SegmentedNavigationControllerDelegate?,
        segmentRootViewController: UIViewController,
        atNavigationStackIndex stackIndex: Int
    ) {
        let insertItem = WeakDelegate(
            attachedStackIndex: stackIndex,
            delegate: delegate
        )

        if let insertIndex = self.delegateStack.firstIndex(where: { existingDelegate in
            existingDelegate
                .attachedStackIndex
                .map { $0 > stackIndex } ?? false
        }) {
            // Need to scoot each stack delegate above this one up one index
            // to handle the new view controller being inserted at stackIndex
            for var existingDelegate in self.delegateStack[insertIndex...] {
                existingDelegate.attachedStackIndex = existingDelegate
                    .attachedStackIndex
                    .map { $0 + 1 }
            }

            self.delegateStack.insert(
                insertItem,
                at: insertIndex
            )
        } else {
            self.delegateStack.append(insertItem)
        }
    }
}

extension SegmentedNavigationController: UINavigationControllerDelegate {
    func navigationController(
        _ navigationController: UINavigationController,
        willShow viewController: UIViewController,
        animated: Bool
    ) {
        self.topSegmentDelegate?.navigationController?(
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
        self.topSegmentDelegate?.navigationController?(
            navigationController,
            didShow: viewController,
            animated: animated
        )

        if let activeDelegate = self.delegateStack.last,
           self.viewControllers.count <= activeDelegate.attachedStackIndex ?? -1 {
            // View stack no longer contains the root view controller for the current
            // top segment.
            // The active segment delegate should no longer be connected to this navigation controller
            _ = self.delegateStack.popLast()

            if let segmentedDelegate = activeDelegate.delegate as? SegmentedNavigationControllerDelegate {
                segmentedDelegate.didDisconnectDelegate(
                    fromNavigationController: self
                )
            }

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
        self.topSegmentDelegate?.navigationControllerSupportedInterfaceOrientations?(
            navigationController
        ) ?? .all
    }

    func navigationControllerPreferredInterfaceOrientationForPresentation(
        _ navigationController: UINavigationController
    ) -> UIInterfaceOrientation {
        self.topSegmentDelegate?
            .navigationControllerPreferredInterfaceOrientationForPresentation?(
                navigationController
            ) ?? .unknown
    }


    func navigationController(
        _ navigationController: UINavigationController,
        interactionControllerFor animationController: UIViewControllerAnimatedTransitioning
    ) -> UIViewControllerInteractiveTransitioning? {
        self.topSegmentDelegate?.navigationController?(
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
        self.topSegmentDelegate?.navigationController?(
            navigationController,
            animationControllerFor: operation,
            from: fromVC,
            to: toVC
        )
    }
}
