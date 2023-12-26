//
//  UIContextualAction+CellDelete.swift
//  NowChurning
//
//  Created by Austin Dumm on 1/5/23.
//

import UIKit

extension UIContextualAction {
    static func deleteAction(
        title: String,
        handler: @escaping Handler
    ) -> UIContextualAction {
        let action = UIContextualAction(
            style: .destructive,
            title: title,
            handler: handler
        )

        action.image = UIImage(systemName: "trash")

        return action
    }
}
