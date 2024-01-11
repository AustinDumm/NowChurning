//
//  Tag.swift
//  NowChurning
//
//  Created by Austin Dumm on 12/16/22.
//

import Foundation

struct Tag<Base>: Identifiable, Equatable, Hashable, Comparable {
    typealias ID = NowChurning.ID<Tag>
    let id: ID
    let name: String

    init(
        id: ID = ID(),
        name: String
    ) {
        self.id = id
        self.name = name
    }

    func hash(into hasher: inout Hasher) {
        self.id.hash(into: &hasher)
    }

    static func < (lhs: Tag<Base>, rhs: Tag<Base>) -> Bool {
        lhs.name < rhs.name
    }
}
