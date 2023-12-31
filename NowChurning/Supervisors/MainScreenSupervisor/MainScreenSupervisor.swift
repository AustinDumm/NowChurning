//
//  MainScreenSupervisor.swift
//  NowChurning
//
//  Created by Austin Dumm on 2/16/23.
//

import UIKit
import CoreData
import Factory

class MainScreenSupervisor: Supervisor {
    struct Content {
        let headerTitle: String
        let tilesContent: MainScreenApplication.Content
    }

    private let navigator: SegmentedNavigationController
    @Injected(\.managedObjectContext)
        private var managedObjectContext: NSManagedObjectContext
    weak var navigationHandler: MainScreenAppNavDelegate? {
        didSet {
            self.application.navDelegate = self.navigationHandler
        }
    }

    private let application: MainScreenApplication
    private let view: TileViewController

    private var ingredientListSupervisor: IngredientListSupervisor?

    init(
        navigator: SegmentedNavigationController,
        navigationHandler: MainScreenAppNavDelegate? = nil,
        content: Content
    ) {
        self.navigator = navigator

        self.application = .init(
            actions: MainScreenApplication.Action.allCases,
            content: content.tilesContent
        )

        self.view = .init(actionSink: self.application)
        self.view.title = content.headerTitle
        self.view.navigationItem.largeTitleDisplayMode = .always

        self.application.displayModelSink = self.view

        self.navigator.pushViewController(
            self.view,
            animated: false
        )
    }

    func canEnd() -> Bool {
        false
    }

    func requestEnd(
        onEnd _: @escaping () -> Void
    ) {
        assertionFailure("MainScreen should never be requested to end.")
    }
}
