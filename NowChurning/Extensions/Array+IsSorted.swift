//
//  Array+IsSorted.swift
//  NowChurning
//
//  Created by Austin Dumm on 10/23/22.
//

import Foundation

extension Array
where Array.Element: Comparable {
    func isSorted() -> Bool {
        self.isSorted(by: <)
    }
}

extension Array {
    func isSorted(by predicate: (Array.Element, Array.Element) -> Bool) -> Bool {
        let test = zip(self.dropLast(1), self.dropFirst(1))
        return test
            .allSatisfy(predicate)
    }
}
