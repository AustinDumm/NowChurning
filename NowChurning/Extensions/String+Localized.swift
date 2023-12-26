//
//  String+Localized.swift
//  NowChurning
//
//  Created by Austin Dumm on 4/2/23.
//

import Foundation

extension String {
    func localized() -> String {
        NSLocalizedString(self, comment: "")
    }
}
