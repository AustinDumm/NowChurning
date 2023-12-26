//
//  CALayer+UIColor.swift
//  NowChurning
//
//  Created by Austin Dumm on 10/19/22.
//

import UIKit

extension CALayer {
    var borderUIColor: UIColor? {
        get {
            guard let borderColor = self.borderColor else {
                return nil
            }
            return UIColor(cgColor: borderColor)
        }
        set(newColor) {
            self.borderColor = newColor?.cgColor
        }
    }
}
