//
//  ExportSupervisor.swift
//  NowChurning
//
//  Created by Austin Dumm on 1/10/24.
//

import UIKit

class ExportSupervisor: NSObject, Supervisor {
    weak var parent: ParentSupervisor?

    private enum State {
        case authentication(MicrosoftAuthSupervisor)
        case upload
    }

    private var state: State

    private let navigation: SegmentedNavigationController
    private let recipesToExport: [Recipe]

    init(
        recipesToExport: [Recipe],
        navigation: SegmentedNavigationController,
        parent: ParentSupervisor? = nil
    ) {
        self.recipesToExport = recipesToExport
        self.navigation = navigation
        self.parent = parent

        let container = UIViewController()
        let authentication = MicrosoftAuthSupervisor(container: container)
        self.state = .authentication(authentication)

        super.init()

        authentication.parent = self
        self.navigation.pushViewController(
            container,
            startingNewSegmentWithDelegate: self,
            animated: true,
            completion: {
                authentication.start()
            }
        )
    }
}

extension ExportSupervisor: ParentSupervisor {
    func childDidEnd(
        supervisor: Supervisor
    ) {
        switch self.state {
        case .authentication(let child)
            where child === supervisor:
            self.navigation.dismiss(animated: true)
            self.parent?.childDidEnd(supervisor: self)

        default:
            self.parent?.recover(fromError: .invalidExportChildEndState, on: self)
        }
    }

    func recover(
        fromError error: AppError,
        on child: Supervisor?
    ) {
        self.navigation.dismiss(animated: true)
        self.parent?.recover(fromError: error, on: child)
    }
}

extension ExportSupervisor: MicrosoftAuthSupervisorParent {
    func didAuthenticate(
        token: String,
        identifier: String?
    ) {
        let tempViewController = UIViewController()
        tempViewController.title = "Did Authenticate!"
        tempViewController.navigationItem.leftBarButtonItem = .init(systemItem: .cancel)
        tempViewController.navigationItem.rightBarButtonItem = .init(systemItem: .done)
        tempViewController.view.backgroundColor = .systemPink

        self.navigation.setViewControllers(
            [tempViewController],
            animated: true
        )

        self.state = .upload
    }
}

extension ExportSupervisor: SegmentedNavigationControllerDelegate {
    func didDisconnectDelegate(
        fromNavigationController: SegmentedNavigationController
    ) {
        self.parent?.childDidEnd(supervisor: self)
    }
}
