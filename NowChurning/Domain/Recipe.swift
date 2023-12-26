//
//  Recipe.swift
//  NowChurning
//
//  Created by Austin Dumm on 3/3/23.
//

import Foundation

struct Recipe: Hashable, Comparable {
    enum InvalidityReason {
        case emptyName
    }

    var id: ID<Self> = .init()
    var name: String
    var description: String

    var recipeDetails: RecipeDetails?

    var invalidityReasons: [InvalidityReason] {
        name.isEmpty ? [.emptyName] : []
    }

    var isValid: Bool {
        self.invalidityReasons.isEmpty
    }

    init(
        id: ID<Recipe> = .init(),
        name: String,
        description: String,
        recipeDetails: RecipeDetails? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.recipeDetails = recipeDetails
    }

    func hash(into hasher: inout Hasher) {
        id.hash(into: &hasher)
    }

    static func < (lhs: Recipe, rhs: Recipe) -> Bool {
        lhs.name < rhs.name
    }
}
