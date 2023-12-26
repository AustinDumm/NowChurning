//
//  RecipeListDomainBoundary.swift
//  NowChurning
//
//  Created by Austin Dumm on 3/3/23.
//

import Foundation

protocol RecipeListDomainModelSink: AnyObject {
    func send(domainModel: [Recipe])
}


enum RecipeListStoreAction {
    case save(
        recipes: [Recipe],
        saver: RecipeListDomainModelSink?
    )
    case refresh
}

protocol RecipeListStoreActionSink: AnyObject {
    func send(storeAction: RecipeListStoreAction)
}
