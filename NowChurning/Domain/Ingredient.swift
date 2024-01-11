//
//  Ingredient.swift
//  NowChurning
//
//  Created by Austin Dumm on 10/22/22.
//

import Foundation

struct Ingredient: Identifiable, Equatable, Comparable {
    typealias ID = NowChurning.ID<Ingredient>
    enum InvalidityReason {
        case emptyName
    }

    var id: ID
    var name: String
    var description: String
    var tags: [Tag<Ingredient>]

    var invalidityReasons: [InvalidityReason] {
        self.name.isEmpty ? [.emptyName] : []
    }

    var isValid: Bool {
        self.invalidityReasons.isEmpty
    }

    init(
        id: ID = ID(),
        name: String,
        description: String,
        tags: [Tag<Ingredient>]
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.tags = tags
    }

    static func < (lhs: Ingredient, rhs: Ingredient) -> Bool {
        lhs.name < rhs.name
    }
}
