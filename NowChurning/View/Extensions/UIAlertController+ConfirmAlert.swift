//
//  UIAlertController+ConfirmAlert.swift
//  NowChurning
//
//  Created by Austin Dumm on 12/25/22.
//

import UIKit

extension UIAlertController {
    static func confirmActionSheet(
        on barButton: UIBarButtonItem,
        display: AlertViewDisplay,
        isDestructive: Bool
    ) -> UIAlertController {
        let controller = UIAlertController(
            title: display.title,
            message: display.description,
            preferredStyle: .actionSheet
        )

        let actions = display
            .buttons
            .map { button in
                UIAlertAction(
                    title: button.text,
                    style: button.style,
                    handler: { _ in button.callback() }
                )
            }

        for action in actions {
            controller.addAction(action)
        }

        if let popoverController = controller.popoverPresentationController {
            popoverController.barButtonItem = barButton
        }

        return controller
    }
}
