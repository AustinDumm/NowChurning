//
//  AlertViewDelegate.swift
//  NowChurning
//
//  Created by Austin Dumm on 12/25/22.
//

import UIKit

struct AlertViewDisplay {
    struct Button {
        let text: String
        let style: UIAlertAction.Style
        let callback: () -> Void
    }

    let title: String?
    let description: String?
    let buttons: [Button]
}
protocol AlertViewDelegate: AnyObject {
    var alertPresenter: UIViewController { get }

    func showActionCard(
        on barButton: UIBarButtonItem,
        withDisplay display: AlertViewDisplay
    )
}

extension AlertViewDelegate {
    func showActionCard(
        on barButton: UIBarButtonItem,
        withDisplay display: AlertViewDisplay
    ) {
        let alert = UIAlertController
            .confirmActionSheet(
                on: barButton,
                display: display,
                isDestructive: true
            )

        self.alertPresenter
            .present(
                alert,
                animated: true
            )
    }

}

class AlertDelegateWrapper: AlertViewDelegate {
    var alertPresenter: UIViewController

    init(alertPresenter: UIViewController) {
        self.alertPresenter = alertPresenter
    }
}
