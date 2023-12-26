//
//  LaunchSupervisor.swift
//  NowChurning
//
//  Created by Austin Dumm on 2/16/23.
//

import UIKit
import CoreData
import Factory

class LaunchSupervisor: Supervisor {
    let window: UIWindow

    @Injected(\.coreDataManager)
        private var coreDataManager: CoreDataManager

    private let flowSupervisor: MainFlowSupervisor!

    init?(
        window: UIWindowScene
    ) {
        self.window = .init(windowScene: window)

        self.flowSupervisor = .init(
            window: self.window,
            content: AppContent.englishContent
        )
    }

    func canEnd() -> Bool {
        false
    }

    func requestEnd(
        onEnd _: @escaping () -> Void
    ) {
        assertionFailure("LaunchSupervisor should never be requested to end.")
    }

    func handleDidEnterBackground() {
        self.coreDataManager.saveContext()
    }
}
