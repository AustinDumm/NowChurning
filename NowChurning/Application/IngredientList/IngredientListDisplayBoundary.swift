//
//  IngredientListDisplayBoundary.swift
//  NowChurning
//
//  Created by Austin Dumm on 10/22/22.
//

import Foundation

struct IngredientListDisplayModel {
    struct Section {
        var title: String
        var items: [Item]
    }

    struct Item: Comparable {
        var id: ID<Self>
        var title: String

        init(
            id: ID<Self> = .init(),
            title: String
        ) {
            self.id = id
            self.title = title
        }

        static func < (
            lhs: IngredientListDisplayModel.Item,
            rhs: IngredientListDisplayModel.Item
        ) -> Bool {
            lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
        }
    }

    var inventorySections: [Section]
}

protocol IngredientListDisplayModelSink: AnyObject, EditModeDisplayModelSink {
    func send(displayModel: IngredientListDisplayModel)
}


enum IngredientListAction {
    case selectItem(inSection: Int, atIndex: Int)
    case deleteItem(inSection: Int, atIndex: Int)
    case newIngredient
}

protocol IngredientListActionSink: AnyObject, EditModeActionSink {
    func send(action: IngredientListAction)
}
