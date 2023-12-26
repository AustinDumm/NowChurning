//
//  RecipeListDisplayBoundary.swift
//  NowChurning
//
//  Created by Austin Dumm on 3/3/23.
//

import Foundation

struct RecipeListDisplayModel {
    struct Section {
        let title: String
        let items: [Item]
    }

    struct Item: Comparable {
        let id: ID<Self>
        let title: String

        init(
            id: ID<Self> = .init(),
            title: String
        ) {
            self.id = id
            self.title = title
        }

        static func < (
            lhs: RecipeListDisplayModel.Item,
            rhs: RecipeListDisplayModel.Item
        ) -> Bool {
            lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
        }
    }

    var recipeSections: [Section]
}

protocol RecipeListDisplayModelSink: AnyObject, EditModeDisplayModelSink {
    func send(displayModel: RecipeListDisplayModel)
    func scrollTo(section: Int, item: Int)
}


enum RecipeListAction {
    case selectedItem(inSection: Int, atIndex: Int)
    case deleteItem(inSection: Int, atIndex: Int)
    case newRecipe
}

protocol RecipeListActionSink: AnyObject, EditModeActionSink {
    func send(action: RecipeListAction)
}
