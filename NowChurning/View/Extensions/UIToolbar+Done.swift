//
//  UIToolbar+Done.swift
//  NowChurning
//
//  Created by Austin Dumm on 6/14/23.
//

import UIKit

extension UIToolbar {
    static func doneToolbar(action: @escaping () -> Void) -> UIToolbar {
        let toolbar = UIToolbar()

        toolbar.items = [
            .flexibleSpace(),
            .init(
                systemItem: .done,
                primaryAction: .init(handler: { _ in
                    action()
                })
            )
        ]

        toolbar.sizeToFit()
        return toolbar
    }
}
