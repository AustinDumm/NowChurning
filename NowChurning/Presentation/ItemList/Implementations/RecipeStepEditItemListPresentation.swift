//
//  RecipeStepEditItemListPresentation.swift
//  NowChurning
//
//  Created by Austin Dumm on 7/8/23.
//

import Foundation

class RecipeStepEditItemListPresentation {
    struct Content {
        struct SectionTitles {
            let measurementSection: String
        }

        let sectionTitles: SectionTitles
        let screenTitle: String
        let cancelAlert: AlertContent
    }
    weak var navBarSink: NavBarViewModelSink? {
        didSet {
            self.updateNavBarViewModel()
        }
    }
    weak var itemListSink: ItemListViewModelSink? {
        didSet {
            self.updateItemListViewModel()
        }
    }

    private let actionSink: RecipeStepEditActionSink
    private let content: Content

    private var displayModel: RecipeStepEditDisplayModel?

    init(
        actionSink: RecipeStepEditActionSink,
        content: Content
    ) {
        self.actionSink = actionSink
        self.content = content
    }

    private func updateItemListViewModel() {
        guard let displayModel else { return }

        self.itemListSink?.send(
            viewModel: self.itemListViewModel(
                fromDisplayModel: displayModel
            )
        )
    }

    private func updateNavBarViewModel() {
        self.navBarSink?.send(
            navBarViewModel: .init(
                title: self.content.screenTitle,
                leftButtons: [.init(type: .cancel, isEnabled: true)],
                rightButtons: [.init(type: .done, isEnabled: true)]
            )
        )
    }
}

// MARK: Model Transforms
extension RecipeStepEditItemListPresentation {
    private func itemListViewModel(
        fromDisplayModel displayModel: RecipeStepEditDisplayModel
    ) -> ItemListViewModel {
        .init(
            sections: [
                .init(
                    title: displayModel.stepTypeName,
                    items: [self.stepNameItem(
                        fromDisplayModel: displayModel
                    )]
                ),
                displayModel.measurementDescription.map { description in
                    .init(
                        title: self.content.sectionTitles.measurementSection,
                        items: [
                            .init(
                                type: .text(description),
                                context: [.navigate]
                            )
                        ]
                    )
                },
            ].compactMap { $0 },
            isEditing: false
        )
    }

    private func stepNameItem(
        fromDisplayModel displayModel: RecipeStepEditDisplayModel
    ) -> ItemListViewModel.Item {
        if displayModel.isStepNameEditable {
            return .init(
                type: .editMultiline(
                    displayModel.stepName,
                    purpose: displayModel.stepTypeName),
                context: []
            )
        } else {
            return .init(
                type: .text(displayModel.stepName),
                context: [.navigate]
            )
        }
    }
}

extension RecipeStepEditItemListPresentation: RecipeStepEditDisplayModelSink {
    func send(displayModel: RecipeStepEditDisplayModel) {
        self.displayModel = displayModel
        self.updateItemListViewModel()
    }

    func showCancelAlert(onCancel: @escaping () -> Void) {
        let content = self.content.cancelAlert
        self.navBarSink?.send(alertViewModel: .init(
            title: nil,
            message: content.descriptionText,
            side: .left,
            buttonIndex: 0,
            actions: [
                .init(
                    title: content.cancelText,
                    type: .cancel,
                    callback: {}
                ),
                .init(
                    title: content.confirmText,
                    type: .confirm(isDestructive: true),
                    callback: onCancel
                )
            ]
        ))
    }
}

extension RecipeStepEditItemListPresentation: NavBarEventSink {
    func send(navBarEvent: NavBarEvent) {
        switch navBarEvent {
        case .tap(.left, 0):
            self.actionSink.send(action: .cancelEdit)
        case .tap(.right, 0):
            self.actionSink.send(action: .finishEdit)
        default:
            return
        }
    }
}

extension RecipeStepEditItemListPresentation: ItemListEventSink {
    func send(event: ItemListEvent) {
        switch event {
        case .select(itemAt: .init(row: 0, section: 0)):
            self.actionSink.send(action: .editMainStepData)

        case .select(itemAt: .init(row: 0, section: 1)):
            self.actionSink.send(action: .editMeasurement)

        case .edit(
            string: let newString,
            forItemAt: .init(row: 0, section: 0)
        ) where self.displayModel?.isStepNameEditable ?? false:
            self.actionSink.send(action: .mainStepTextEdit(newString))

        default:
            break
        }
    }
}
