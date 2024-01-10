//
//  ExportSupervisor.swift
//  NowChurning
//
//  Created by Austin Dumm on 1/10/24.
//

import UIKit

class ExportSupervisor: NSObject, Supervisor {
    weak var parent: ParentSupervisor?

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

        super.init()

        let tempViewController = UIViewController()
        tempViewController.view.backgroundColor = .cyan
        tempViewController.title = "Temporary"
        tempViewController.navigationItem.leftBarButtonItem = .init(systemItem: .cancel)
        tempViewController.navigationItem.rightBarButtonItem = .init(systemItem: .done)

        self.navigation.pushViewController(
            tempViewController,
            startingNewSegmentWithDelegate: self,
            animated: true
        )
    }
}

extension ExportSupervisor: SegmentedNavigationControllerDelegate {
    func didDisconnectDelegate(
        fromNavigationController: SegmentedNavigationController
    ) {
        self.parent?.childDidEnd(supervisor: self)
    }
}
