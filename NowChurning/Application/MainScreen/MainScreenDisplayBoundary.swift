//
//  MainScreenAppBoundary.swift
//  NowChurning
//
//  Created by Austin Dumm on 10/18/22.
//

import Foundation

protocol MainScreenDisplayModelSink: AnyObject {
    func send(displayModel: MainScreenDisplayModel)
}

struct MainScreenDisplayModel {
    struct Item {
        let icon: ApplicationImage.Icon.MainScreen
        let text: String
    }

    let items: [Item]
}

extension ApplicationImage.Icon {
    enum MainScreen {
        case ingredients
        case recipes
    }
}

protocol MainScreenActionSink: AnyObject {
    func send(action: MainScreenAction)
}

enum MainScreenAction {
    case selectItem(atIndex: Int)
}
