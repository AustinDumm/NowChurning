//
//  Array+SafeIndex.swift
//  NowChurning
//
//  Created by Austin Dumm on 12/18/22.
//

import Foundation

extension Array {
    subscript(safe index: Int) -> Element? {
        get {
            guard self.indices.contains(index) else {
                return nil
            }

            return self[index]
        }
        set(newValue) {
            guard
                self.indices.contains(index),
                let newValue
            else {
                return
            }

            self[index] = newValue
        }
    }
}
