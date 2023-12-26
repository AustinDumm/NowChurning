//
//  MeasureListItemListPresentation.swift
//  NowChurning
//
//  Created by Austin Dumm on 5/13/23.
//

import Foundation

class MeasureListItemListPresentation {
    struct Content {
        let title: String
        let alertContent: AlertContent
        let listInstruction: String
        let editListDescription: String
        let addToInventoryDescription: String
    }

    weak var viewModelSink: ItemListViewModelSink? {
        didSet {
            self.updateViewModel()
        }
    }
    weak var navBarViewModelSink: NavBarViewModelSink? {
        didSet {
            self.updateNavBarViewModel()
        }
    }

    private let actionSink: MeasureListActionSink
    private let content: Content

    private var displayModel: MeasureListDisplayModel?
    private var editDisplayModel: EditModeDisplayModel?

    init(
        actionSink: MeasureListActionSink,
        content: Content
    ) {
        self.actionSink = actionSink
        self.content = content
    }

    private func updateViewModel() {
        guard
            let displayModel
        else {
            return
        }

        self.viewModelSink?
            .send(
                viewModel: Self.viewModel(
                    fromDisplayModel: displayModel,
                    isEditing: self.editDisplayModel?.isEditing ?? false,
                    content: self.content
                )
            )
    }

    private func updateNavBarViewModel() {
        guard
            let editDisplayModel = self.editDisplayModel
        else {
            return
        }

        let isViewModelEmtpy = self.displayModel?.sections.isEmpty ?? true
        self.navBarViewModelSink?
            .send(
                navBarViewModel: Self.navBarViewModel(
                    fromEditModeDisplayModel: editDisplayModel,
                    hasElements: !isViewModelEmtpy,
                    content: self.content
                )
            )
    }
}

// MARK: Model Transforms
extension MeasureListItemListPresentation {
    private static func viewModel(
        fromDisplayModel displayModel: MeasureListDisplayModel,
        isEditing: Bool,
        content: Content
    ) -> ItemListViewModel {
        .init(
            sections:
                [.init(title: "", items: [
                    .init(
                        type: .message(content.listInstruction),
                        context: []
                    )
                ])] +
                displayModel
                        .sections
                        .map { section(
                            fromDisplayModel: $0,
                            isEditing: isEditing
                        ) },
            isEditing: isEditing
        )
    }

    private static func section(
        fromDisplayModel displayModel: MeasureListDisplayModel.Section,
        isEditing: Bool
    ) -> ItemListViewModel.Section {
        .init(
            title: displayModel.title,
            items: displayModel
                .items
                .map { Self.item(
                    fromDisplayModel: $0,
                    isEditing: isEditing
                ) }
        )
    }

    private static func item(
        fromDisplayModel displayModel: MeasureListDisplayModel.Item,
        isEditing: Bool
    ) -> ItemListViewModel.Item {
        return .init(
            id: displayModel.id.rawId.uuidString,
            type: .text(displayModel.title),
            context: isEditing ? [.delete] : [.delete, .navigate]
        )
    }

    private static func navBarViewModel(
        fromEditModeDisplayModel displayModel: EditModeDisplayModel,
        hasElements: Bool,
        content: Content
    ) -> NavBarViewModel {
        .init(
            title: content.title,
            leftButtons: Self.leftNavButtons(
                fromEditModeDisplayModel: displayModel
            ),
            rightButtons: Self.rightNavButtons(
                fromEditModeDisplayModel: displayModel,
                hasElements: hasElements,
                content: content
            )
        )
    }

    private static func leftNavButtons(
        fromEditModeDisplayModel displayModel: EditModeDisplayModel
    ) -> [NavBarViewModel.Button] {
        if displayModel.isEditing {
            return [.init(type: .cancel, isEnabled: true)]
        } else {
            return [.init(type: .back, isEnabled: true)]
        }
    }

    private static func rightNavButtons(
        fromEditModeDisplayModel displayModel: EditModeDisplayModel,
        hasElements: Bool,
        content: Content
    ) -> [NavBarViewModel.Button] {
        if displayModel.isEditing {
            return [.init(type: .save, isEnabled: displayModel.canSave)]
        } else if hasElements {
            return [
                .init(
                    type: .add,
                    displayTitle: content.addToInventoryDescription,
                    isEnabled: true
                ),
                .init(
                    type: .edit,
                    displayTitle: content.editListDescription,
                    isEnabled: true
                )
            ]
        } else {
            return [.init(type: .add, isEnabled: true)]
        }
    }
}

extension MeasureListItemListPresentation: MeasureListDisplayModelSink {
    func send(displayModel: MeasureListDisplayModel) {
        self.displayModel = displayModel
        self.updateViewModel()
        self.updateNavBarViewModel()
    }

    func send(editModeDisplayModel: EditModeDisplayModel) {
        self.editDisplayModel = editModeDisplayModel
        self.updateViewModel()
        self.updateNavBarViewModel()
    }

    func send(
        alertDisplayModel: EditModeAction.DoneType,
        didConfirm: @escaping (Bool) -> Void
    ) {
        switch alertDisplayModel {
        case .save:
            return
        case .cancel:
            self.navBarViewModelSink?
                .send(
                    alertViewModel: .init(
                        title: nil,
                        message: self.content.alertContent.descriptionText,
                        side: .left,
                        buttonIndex: 0,
                        actions: [
                            .init(
                                title: self
                                    .content
                                    .alertContent
                                    .cancelText,
                                type: .cancel,
                                callback: { didConfirm(false) }
                            ),
                            .init(
                                title: self
                                    .content
                                    .alertContent
                                    .confirmText,
                                type: .confirm(isDestructive: true),
                                callback: { didConfirm(true) }
                            ),
                        ]
                    )
                )
        }
    }

    func scrollTo(section: Int, item: Int) {
        self.viewModelSink?.scrollTo(.init(item: item, section: section))
    }
}

extension MeasureListItemListPresentation: ItemListEventSink {
    func send(event: ItemListEvent) {
        switch event {
        case .select(itemAt: let indexPath):
            let isEditing = self.editDisplayModel?.isEditing ?? false
            guard !isEditing else { break }

            self.actionSink
                .send(action: .selectMeasure(
                    atIndex: indexPath.item,
                    inSection: indexPath.section - 1
                ))
        case .delete(itemAt: let indexPath):
            self.actionSink
                .send(action: .deleteMeasure(
                    atIndex: indexPath.item,
                    inSection: indexPath.section - 1
                ))
        case .edit, .selectFooter, .move, .openInfo, .resolveAlert:
            break
        }
    }
}

extension MeasureListItemListPresentation: NavBarEventSink {
    func send(navBarEvent: NavBarEvent) {
        if self.editDisplayModel?.isEditing ?? false {
            self.editModeNavBarEvent(navBarEvent)
        } else {
            self.viewModeNavBarEvent(navBarEvent)
        }
    }

    func editModeNavBarEvent(_ navBarEvent: NavBarEvent) {
        switch navBarEvent {
        case .tap(.left, 0):
            self.actionSink
                .send(editModeAction: .finishEditing(.cancel))
        case .tap(.right, 0):
            self.actionSink
                .send(editModeAction: .finishEditing(.save))
        default:
            break
        }
    }

    func viewModeNavBarEvent(_ navBarEvent: NavBarEvent) {
        switch navBarEvent {
        case .tap(.right, 0):
            self.actionSink
                .send(action: .newMeasure)
        case .tap(.right, 1):
            self.actionSink
                .send(editModeAction: .startEditing)
        default:
            break
        }
    }
}
