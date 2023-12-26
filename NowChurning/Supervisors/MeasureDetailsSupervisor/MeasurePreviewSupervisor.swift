//
//  MeasurePreviewSupervisor.swift
//  NowChurning
//
//  Created by Austin Dumm on 6/25/23.
//

import UIKit

protocol MeasurePreviewSupervisorParent: ParentSupervisor {
    func switchToEditing(ingredient: Ingredient)
}

class MeasurePreviewSupervisor: Supervisor {
    struct Content {
        let applicationContent: MeasureDetailsApplication.Content
        let presentationContent: MeasureDetailsItemListPresentation.Content
        let screenTitle: String
        let editSwitchAlert: AlertContent
    }

    weak var parent: MeasurePreviewSupervisorParent?

    private let application: MeasureDetailsApplication
    private let presentation: MeasureDetailsItemListPresentation
    private let view: ItemListViewController
    private let store: MeasureFromListStore

    private let ingredient: Ingredient

    private var navBarManager: NavBarManager?

    private let content: Content

    init(
        ingredient: Ingredient,
        container: UIViewController,
        navigationItem: UINavigationItem,
        listStore: StockedMeasureListCoreDataStore,
        parent: MeasurePreviewSupervisorParent? = nil,
        content: Content
    ) {
        self.content = content
        self.parent = parent
        self.ingredient = ingredient

        self.application = .init(content: content.applicationContent)

        self.presentation = .init(
            actionSink: self.application,
            contentContainer: content.presentationContent
        )
        self.application.displayModelSink = self.presentation

        self.view = .init(eventSink: self.presentation)
        self.presentation.viewModelSink = self.view
        container.insetChild(self.view)

        self.store = .init(
            id: ingredient.id,
            modelSink: self.application,
            storeSink: listStore
        )
        listStore.registerSink(asWeak: self.store)

        self.navBarManager = .init(
            navigationItem: navigationItem,
            alertViewDelegate: container,
            providedButtonBuilder: ProvidedBarButtonBuilder(backButton: navigationItem.backBarButtonItem),
            systemButtonBuilder: NavBarSystemButtonBuilder(),
            eventSink: WeakNavBarEventSink(eventSink: self)
        )
        self.application.delegate = self
        self.navBarManager?.send(
            navBarViewModel: .init(
                title: self.content.screenTitle,
                leftButtons: [.init(type: .done, isEnabled: true)],
                rightButtons: [.init(type: .edit, isEnabled: true)]
            )
        )
    }

    func canEnd() -> Bool {
        true
    }

    func requestEnd(onEnd: @escaping () -> Void) {
        onEnd()
    }
}

extension MeasurePreviewSupervisor: MeasureDetailsApplicationDelegate {
    // Preview is Read-Only. No need to handle editing events
    func requestEditTags(forMeasure: Measure) {}
    func requestMeasurementEdit(forMeasure: Measure) {}
    func navigate(forEditDoneType: EditModeAction.DoneType) {}
    func switchEditing(toMeasureForIngredientId: ID<Ingredient>) {}
    func didSaveMeasure(withIngredientId id: ID<Ingredient>) {}
    func exit() {
        self.parent?.childDidEnd(supervisor: self)
    }
}

extension MeasurePreviewSupervisor: NavBarEventSink {
    func send(navBarEvent: NavBarEvent) {
        switch navBarEvent {
        case .tap(.left, 0):
            self.handleDone()
        case .tap(.right, 0):
            self.switchToEdit()
        default:
            break
        }
    }

    private func handleDone() {
        self.parent?.childDidEnd(supervisor: self)
    }

    private func switchToEdit() {
        let content = self.content.editSwitchAlert
        self.navBarManager?.send(
            alertViewModel: .init(
                title: nil,
                message: content.descriptionText,
                side: .right,
                buttonIndex: 0,
                actions: [
                    .init(
                        title: content.cancelText,
                        type: .cancel,
                        callback: {}
                    ),
                    .init(
                        title: content.confirmText,
                        type: .confirm(isDestructive: false),
                        callback: { [weak self] in
                            guard let self else {
                                return
                            }

                            self.parent?
                                .switchToEditing(ingredient: ingredient)
                        }
                    )
                ]
            )
        )
    }
}
