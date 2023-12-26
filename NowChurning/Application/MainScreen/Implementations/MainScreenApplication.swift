//
//  MainScreenApplication.swift
//  NowChurning
//
//  Created by Austin Dumm on 10/18/22.
//

import Foundation

protocol MainScreenAppNavDelegate: AnyObject {
    func navigateTo(action: MainScreenApplication.Action)
}

class MainScreenApplication {
    struct Content {
        let inventoryTitle: String
        let myRecipesTitle: String
    }

    enum Action: CaseIterable {
        case inventory
        case myRecipes
    }

    // MARK: Display Dependencies
    weak var displayModelSink: MainScreenDisplayModelSink? {
        didSet {
            self.onDisplayModelSinkUpdate()
        }
    }

    // MARK: Local Models
    private let actions: [Action]
    private let content: Content
    weak var navDelegate: MainScreenAppNavDelegate?

    init(
        actions: [Action] = Action.allCases,
        navDelegate: MainScreenAppNavDelegate? = nil,
        content: Content
    ) {
        self.actions = actions
        self.content = content
        self.navDelegate = navDelegate

        self.sendDisplayModel()
    }

    // MARK: DidSet Event Handlers
    private func onDisplayModelSinkUpdate() {
        self.sendDisplayModel()
    }

    // MARK: Senders
    private func sendDisplayModel() {
        guard let displayModelSink = displayModelSink else { return }
        let displayModel = Self.buildDisplayModel(
            fromActions: self.actions,
            content: self.content
        )
        displayModelSink.send(displayModel: displayModel)
    }
}

// MARK: Model Transforms
extension MainScreenApplication {
    private static func buildDisplayModel(
        fromActions actions: [Action],
        content: Content
    ) -> MainScreenDisplayModel {
        let items = actions.map { action in
            switch action {
            case .myRecipes:
                return MainScreenDisplayModel.Item(
                    icon: .recipes,
                    text: content.myRecipesTitle
                )
            case .inventory:
                return MainScreenDisplayModel.Item(
                    icon: .ingredients,
                    text: content.inventoryTitle
                )
            }
        }

        return .init(items: items)
    }
}

extension MainScreenApplication: MainScreenActionSink {
    func send(action: MainScreenAction) {
        switch action {
        case .selectItem(atIndex: let index):
            self.selectItem(atIndex: index)
        }
    }

    private func selectItem(atIndex index: Int) {
        guard let action = self.actions[safe: index] else { return }

        self.navDelegate?.navigateTo(action: action)
    }
}
