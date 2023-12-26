//
//  IngredientListDomainBoundary.swift
//  NowChurning
//
//  Created by Austin Dumm on 10/22/22.
//

import Foundation

protocol IngredientListDomainModelSink: AnyObject {
    func send(domainModel: [Ingredient])
}


enum IngredientListStoreAction {
    case save(
        ingredients: [Ingredient],
        saver: IngredientListDomainModelSink?
    )
}

protocol IngredientListStoreActionSink: AnyObject {
    func send(action: IngredientListStoreAction)
    func registerSink(asWeak sink: IngredientListDomainModelSink)
}
