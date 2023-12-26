//
//  EditModeHelper.swift
//  NowChurning
//
//  Created by Austin Dumm on 5/9/23.
//

import Foundation

protocol EditModeHelperDelegate: AnyObject {
    associatedtype Data: Equatable

    func sendDisplayModel(
        fromDomain: Data,
        isEditing: Bool
    )

    func onEditEnd(withDoneType: EditModeAction.DoneType)

    func isValid(model: Data) -> Bool
    func save(model: Data)
}

class EditModeHelper<Delegate: EditModeHelperDelegate> {
    typealias Data = Delegate.Data

    var isEditing: Bool

    weak var editModeDisplayModelSink: EditModeDisplayModelSink? {
        didSet {
            self.sendEditModeDisplayModel()
        }
    }
    weak var delegate: Delegate?

    private var domainModel: Data
    private var stagedModel: Data

    init(
        initialModel: Data,
        editModeDisplayModelSink: EditModeDisplayModelSink? = nil,
        delegate: Delegate? = nil
    ) {
        self.isEditing = false

        self.domainModel = initialModel
        self.stagedModel = initialModel

        self.editModeDisplayModelSink = editModeDisplayModelSink
        self.delegate = delegate
    }

    var hasChanges: Bool {
        self.domainModel != self.stagedModel
    }

    func updateActiveModel(
        shouldUpdateDisplayModel: Bool = true,
        _ action: (inout Data) -> Void
    ) {
        if self.isEditing {
            action(&self.stagedModel)
        } else {
            action(&self.domainModel)
            self.stagedModel = self.domainModel
            self.delegate?.save(model: self.domainModel)
        }

        if shouldUpdateDisplayModel {
            self.delegate?.sendDisplayModel(
                fromDomain: self.activeModel(),
                isEditing: self.isEditing
            )
        }

        self.sendEditModeDisplayModel()
    }

    func updateStoredModel(toData data: Data) {
        self.domainModel = data

        if !self.isEditing {
            self.stagedModel = self.domainModel
            self.delegate?.sendDisplayModel(
                fromDomain: self.activeModel(),
                isEditing: self.isEditing
            )
            self.sendEditModeDisplayModel()
        }
    }

    func activeModel() -> Data {
        self.isEditing ? self.stagedModel : self.domainModel
    }

    func saveEditing() {
        guard self.isEditing else { return }

        let shouldSendSave = self.hasChanges
        self.isEditing = false
        self.domainModel = self.stagedModel

        self.sendEditModeDisplayModel()

        if shouldSendSave {
            self.delegate?.save(model: self.domainModel)
        }
        self.delegate?.onEditEnd(withDoneType: .save)
    }

    func cancelEditing(
        completion: (() -> Void)? = nil
    ) {
        guard self.isEditing else { return }

        let performCancel: (Bool) -> Void = { didConfirm in
            if didConfirm {
                self.isEditing = false
                self.stagedModel = self.domainModel

                self.sendEditModeDisplayModel()
                self.delegate?
                    .sendDisplayModel(
                        fromDomain: self.activeModel(),
                        isEditing: self.isEditing
                    )

                self.delegate?
                    .onEditEnd(withDoneType: .cancel)
                completion?()
            }
        }

        if self.hasChanges {
            self.editModeDisplayModelSink?
                .send(
                    alertDisplayModel: .cancel,
                    didConfirm: performCancel
                )
        } else {
            performCancel(true)
        }
    }

    private func sendEditModeDisplayModel() {
        self.editModeDisplayModelSink?.send(
            editModeDisplayModel: .init(
                isEditing: self.isEditing,
                canSave: self.hasChanges && (self.delegate?.isValid(model: self.stagedModel) ?? true)
            )
        )
    }
}

extension EditModeHelper: EditModeActionSink {
    func send(editModeAction: EditModeAction) {
        switch editModeAction {
        case .startEditing:
            self.isEditing = true
            self.sendEditModeDisplayModel()
        case .finishEditing(.cancel):
            self.cancelEditing()
        case .finishEditing(.save):
            self.saveEditing()
        }
    }
}
