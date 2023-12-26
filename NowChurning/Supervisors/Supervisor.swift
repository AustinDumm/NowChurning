//
//  Supervisor.swift
//  NowChurning
//
//  Created by Austin Dumm on 2/15/23.
//

import Foundation

protocol Supervisor: AnyObject {
    /// Returns true if and only if this Supervisor can be ended
    /// immediately without any async or long-running work needed.
    /// If an async or long task is needed before this Supervisor
    /// can be ended, returns false. No work related to preparing for
    /// end should be done in this function.
    ///
    /// - Returns: If this Supervisor can be immediately ended.
    func canEnd() -> Bool

    /// Asks the child Supervisor to end by pulling everything it owns
    /// off screen. Once this child Supervisor has completed cleanup
    /// work and is ready to leave the screen, should the onEnd callback
    /// when the end is done.
    func requestEnd(
        onEnd: @escaping () -> Void
    )
}

extension Supervisor {
    func canEnd() -> Bool { true }
    func requestEnd(onEnd: @escaping () -> Void) { onEnd() }
}

protocol ParentSupervisor: Supervisor {
    func childDidEnd(supervisor: Supervisor)
    func recover(
        fromError error: AppError,
        on child: Supervisor?
    )
}
