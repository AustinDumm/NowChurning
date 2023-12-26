//
//  RecipeStepDetailsSupervisor.swift
//  NowChurning
//
//  Created by Austin Dumm on 7/9/23.
//

import UIKit

protocol RecipeStepDetailsSupervisorParent: ParentSupervisor, RecipeStepEditApplicationDelegate {
    func saveStep(step: RecipeDetails.Step)
}

class RecipeStepDetailsSupervisor: Supervisor {
    struct Content {
        var application: RecipeStepEditApplication.Content
        var presentation: RecipeStepEditItemListPresentation.Content
    }
    weak var parent: RecipeStepDetailsSupervisorParent? {
        didSet {
            self.application.delegate = self.parent
        }
    }

    private let application: RecipeStepEditApplication
    private let presentation: RecipeStepEditItemListPresentation

    private let itemList: ItemListViewController
    private let navBar: NavBarManager

    private let content: Content

    init(
        step: RecipeDetails.Step,
        container: UIViewController,
        parent: RecipeStepDetailsSupervisorParent? = nil,
        content: Content
    ) {
        self.parent = parent
        self.content = content

        self.application = .init(content: content.application)

        self.presentation = .init(
            actionSink: self.application,
            content: content.presentation
        )
        self.application.displaySink = self.presentation

        self.itemList = .init(eventSink: self.presentation)
        self.presentation.itemListSink = self.itemList

        self.navBar = .init(
            navigationItem: container.navigationItem,
            alertViewDelegate: container,
            providedButtonBuilder: ProvidedBarButtonBuilder(backButton: container.navigationItem.backBarButtonItem),
            systemButtonBuilder: NavBarSystemButtonBuilder(),
            eventSink: self.presentation
        )
        self.presentation.navBarSink = self.navBar

        container.insetChild(self.itemList)
        self.application.delegate = self.parent
        self.application.storeSink = self

        self.application.send(step: step)
    }

    func updateIngredient(to ingredient: Ingredient) {
        self.application.send(ingredient: ingredient)
    }

    func updateTags(to tags: [Tag<Ingredient>]) {
        self.application.send(tags: tags)
    }

    func updateMeasurement(to measurement: MeasurementType) {
        self.application.send(measurement: measurement)
    }
}

extension RecipeStepDetailsSupervisor: RecipeStepEditStoreActionSink {
    func send(action: RecipeStepEditStoreAction) {
        switch action {
        case .saveStep(let step):
            self.parent?.saveStep(step: step)
        }
    }
}
