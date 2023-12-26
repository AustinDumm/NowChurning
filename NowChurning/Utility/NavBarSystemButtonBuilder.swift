//
//  NavBarSystemButtonBuilder.swift
//  NowChurning
//
//  Created by Austin Dumm on 2/16/23.
//

import UIKit

class NavBarSystemButtonBuilder: NavBarManagerSystemButtonBuilder {
    func cancelButton(
        action: UIAction
    ) -> UIBarButtonItem? {
        .init(
            systemItem: .cancel,
            primaryAction: action
        )
    }

    func saveButton(
        action: UIAction
    ) -> UIBarButtonItem? {
        .init(
            systemItem: .save,
            primaryAction: action
        )
    }

    func editButton(
        action: UIAction
    ) -> UIBarButtonItem? {
        .init(
            systemItem: .edit,
            primaryAction: action
        )
    }

    func addButton(
        action: UIAction
    ) -> UIBarButtonItem? {
        .init(
            systemItem: .add,
            primaryAction: action
        )
    }

    func doneButton(
        action: UIAction
    ) -> UIBarButtonItem? {
        .init(
            systemItem: .done,
            primaryAction: action
        )
    }
}
