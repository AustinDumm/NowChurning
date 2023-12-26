//
//  ProvidedBarButtonBuilder.swift
//  NowChurning
//
//  Created by Austin Dumm on 2/16/23.
//

import UIKit

class ProvidedBarButtonBuilder: NavBarManagerProvidedButtonBuilder {
    private let providedBackButton: UIBarButtonItem?

    init(
        backButton: UIBarButtonItem? = nil
    ) {
        self.providedBackButton = backButton
    }

    func backButton() -> UIBarButtonItem? {
        self.providedBackButton
    }
}
