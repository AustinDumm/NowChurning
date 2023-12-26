//
//  MeasurementEditFormListPresentation.swift
//  NowChurning
//
//  Created by Austin Dumm on 5/29/23.
//

import Foundation

class MeasurementEditFormListPresentation {
    struct Content {
        var itemTitles: ItemTitles
        var screenTitle: String

        var unspecifiedOptionText: String
        var volumeOptionText: String
        var countOptionText: String

        var cancelAlert: AlertContent
    }

    struct ItemTitles {
        let typeTitle: String
        let valueTitle: String
        let unitTitle: String
        let descriptionTitle: String
    }

    weak var viewModelSink: FormListViewModelSink? {
        didSet {
            self.sendViewModel()
        }
    }
    weak var navBarViewModelSink: NavBarViewModelSink? {
        didSet {
            self.sendNavBarViewModel()
        }
    }

    private let actionSink: MeasurementEditActionSink
    private let content: Content

    private var displayModel: MeasurementEditDisplayModel?

    init(
        actionSink: MeasurementEditActionSink,
        content: Content
    ) {
        self.actionSink = actionSink
        self.content = content
    }

    private func sendViewModel() {
        guard let displayModel else { return }

        self.viewModelSink?.send(
            viewModel: Self.viewModel(
                fromDisplayModel: displayModel,
                content: self.content
            )
        )
    }

    private func sendNavBarViewModel() {
        self.navBarViewModelSink?
            .send(
                navBarViewModel: .init(
                    title: self.content.screenTitle,
                    leftButtons: [.init(type: .cancel, isEnabled: true)],
                    rightButtons: [.init(type: .done, isEnabled: true)]
                )
            )
    }
}

// MARK: Model Transforms
extension MeasurementEditFormListPresentation {
    private static func viewModel(
        fromDisplayModel displayModel: MeasurementEditDisplayModel,
        content: Content
    ) -> FormListViewModel {
        .init(sections: [
            .init(
                title: "",
                items: self.viewModelItems(
                    fromDisplayModel: displayModel,
                    content: content
                )
            )
        ])
    }

    private static func viewModelItems(
        fromDisplayModel displayModel: MeasurementEditDisplayModel,
        content: Content
    ) -> [FormListViewModel.Item] {
        switch displayModel.displayType {
        case .unspecified:
            return self.unspecifiedViewModel(
                options: displayModel.validTypes,
                content: content
            )
        case .volume(let data):
            return self.volumeViewModel(
                data: data,
                options: displayModel.validTypes,
                content: content
            )
        case .count(let amount, let description):
            return self.countViewModel(
                amount: amount,
                description: description,
                options: displayModel.validTypes,
                content: content
            )
        }
    }

    private static func unspecifiedViewModel(
        options: [String],
        content: Content
    ) -> [FormListViewModel.Item] {
        [
            .init(
                id: "unspecified-type",
                type: .labeledSelection(
                    label: content.itemTitles.typeTitle,
                    options: options,
                    selection: 0
                ))
        ]
    }

    private static func volumeViewModel(
        data: MeasurementEditDisplayModel.VolumeTypeData,
        options: [String],
        content: Content
    ) -> [FormListViewModel.Item] {
        [
            .init(
                id: "volume-type",
                type: .labeledSelection(
                    label: content.itemTitles.typeTitle,
                    options: options,
                    selection: 1
                )),
            .init(
                id: "volume-unit",
                type: .labeledSelection(
                    label: content.itemTitles.unitTitle,
                    options: data.validUnits,
                    selection: data.selectedUnitIndex
                )),
            .init(
                id: "volume-scalar",
                type: .labeledNumber(
                    label: content.itemTitles.valueTitle,
                    content: data.scalar
                )),
        ]
    }

    private static func countViewModel(
        amount: Double,
        description: String,
        options: [String],
        content: Content
    ) -> [FormListViewModel.Item] {
        [
            .init(
                id: "count-type",
                type: .labeledSelection(
                    label: content.itemTitles.typeTitle,
                    options: options,
                    selection: 2
                )),
            .init(
                id: "count-number",
                type: .labeledNumber(
                    label: content.itemTitles.valueTitle,
                    content: amount
                )),
            .init(
                id: "count-description",
                type: .labeledField(
                    label: content.itemTitles.descriptionTitle,
                    content: description
                ))
        ]
    }
}

extension MeasurementEditFormListPresentation: MeasurementEditDisplayModelSink {
    func send(displayModel: MeasurementEditDisplayModel) {
        self.displayModel = displayModel
        self.sendViewModel()
    }

    func send(editModeDisplayModel: EditModeDisplayModel) {
        self.sendNavBarViewModel()
    }

    func startEdit(
        for editableValue: MeasurementEditDisplayModel.EditableValue
    ) {
        switch editableValue {
        case .measurementType:
            self.viewModelSink?
                .startEdit(at: .init(item: 0, section: 0))
        case .unit:
            switch self.displayModel?.displayType {
            case .volume:
                self.viewModelSink?
                    .startEdit(at: .init(item: 1, section: 0))
            case .count, .unspecified, .none:
                break
            }
        case .scalar:
            switch self.displayModel?.displayType {
            case .volume:
                self.viewModelSink?
                    .startEdit(at: .init(item: 2, section: 0))
            case .count:
                self.viewModelSink?
                    .startEdit(at: .init(item: 1, section: 0))
            case .unspecified, .none:
                break
            }
        }
    }

    func send(
        alertDisplayModel: EditModeAction.DoneType,
        didConfirm: @escaping (Bool) -> Void
    ) {
        switch alertDisplayModel {
        case .save:
            break
        case .cancel:
            let content = self.content.cancelAlert
            self.navBarViewModelSink?
                .send(alertViewModel: .init(
                    title: nil,
                    message: content.descriptionText,
                    side: .left,
                    buttonIndex: 0,
                    actions: [
                        .init(
                            title: content.cancelText,
                            type: .cancel,
                            callback: { didConfirm(false) }
                        ),
                        .init(
                            title: content.confirmText,
                            type: .confirm(isDestructive: true),
                            callback: { didConfirm(true) }
                        ),
                    ]
                ))
        }
    }
}

extension MeasurementEditFormListPresentation: FormListEventSink {
    func send(event: FormListEvent) {
        switch self.displayModel?.displayType {
        case .unspecified:
            self.handleEventUnspecified(event: event)
        case .volume(let data):
            self.handleEventVolume(
                volumeData: data,
                event: event
            )
        case .count(let amount, let description):
            self.handleEventCount(
                amount: amount,
                description: description,
                event: event
            )
        case .none:
            break
        }
    }

    private func handleEventUnspecified(
        event: FormListEvent
    ) {
        switch event {
        case .updateSelection(
            item: 0,
            section: 0,
            let selection
        ):
            self.actionSink
                .send(action: .changeType(atIndex: selection))
        default:
            break
        }
    }

    private func handleEventVolume(
        volumeData: MeasurementEditDisplayModel.VolumeTypeData,
        event: FormListEvent
    ) {
        switch event {
        case .updateSelection(
            item: 0,
            section: 0,
            let selection
        ):
            self.actionSink
                .send(action: .changeType(atIndex: selection))
        case .updateSelection(
            item: 1,
            section: 0,
            let selection
        ):
            self.actionSink
                .send(action: .changeVolumeUnit(atIndex: selection))
        case .updateNumber(
            item: 2,
            section: 0,
            let number
        ):
            self.actionSink
                .send(action: .changeAmount(number))
        default:
            break
        }
    }

    private func handleEventCount(
        amount: Double,
        description: String,
        event: FormListEvent
    ) {
        switch event {
        case .updateSelection(
            item: 0,
            section: 0,
            let selection
        ):
            self.actionSink
                .send(action: .changeType(atIndex: selection))
        case .updateNumber(
            item: 1,
            section: 0,
            let number
        ):
            self.actionSink
                .send(action: .changeAmount(number))
        case .updateFieldText(
            item: 2,
            section: 0,
            let content
        ):
            self.actionSink
                .send(action: .changeDescription(content))
        default:
            break
        }
    }
}

extension MeasurementEditFormListPresentation: NavBarEventSink {
    func send(navBarEvent: NavBarEvent) {
        switch navBarEvent {
        case .tap(.left, index: 0):
            self.actionSink.send(editModeAction: .finishEditing(.cancel))
        case .tap(.right, index: 0):
            self.actionSink.send(editModeAction: .finishEditing(.save))
        default:
            break
        }
    }
}
