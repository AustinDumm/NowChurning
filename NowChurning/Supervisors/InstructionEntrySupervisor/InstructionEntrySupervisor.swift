//
//  InstructionEntrySupervisor.swift
//  NowChurning
//
//  Created by Austin Dumm on 7/13/23.
//

import UIKit

protocol InstructionEntrySupervisorParent: ParentSupervisor {
    func save(instruction: String)
}

class InstructionEntrySupervisor: Supervisor {
    struct Content {
        var instructionTitle: String
        var screenTitle: String
        var cancelEditAlert: AlertContent
    }

    weak var parent: InstructionEntrySupervisorParent?

    private let itemList: ItemListViewController
    private let navBarManager: NavBarManager
    private let content: Content

    private let weakSink: WeakItemListEventAdapter

    private let initialInstruction: String
    private var currentInstruction: String

    init(
        initialInstruction: String = "",
        parent: InstructionEntrySupervisorParent? = nil,
        container: UIViewController,
        content: Content
    ) {
        self.initialInstruction = initialInstruction
        self.currentInstruction = initialInstruction
        self.parent = parent
        self.content = content

        self.weakSink = .init()
        self.itemList = .init(eventSink: self.weakSink)
        self.navBarManager = .init(
            navigationItem: container.navigationItem,
            alertViewDelegate: container,
            providedButtonBuilder: ProvidedBarButtonBuilder(backButton: container.navigationItem.backBarButtonItem),
            systemButtonBuilder: NavBarSystemButtonBuilder(),
            eventSink: self.weakSink
        )

        self.weakSink.eventSink = self
        container.insetChild(self.itemList)

        self.navBarManager.send(
            navBarViewModel: .init(
                title: self.content.screenTitle,
                leftButtons: [.init(type: .cancel, isEnabled: true)],
                rightButtons: [.init(type: .done, isEnabled: true)]
            )
        )
        self.itemList.send(
            viewModel: .init(
                sections: [
                    .init(
                        title: self.content.instructionTitle,
                        items: [
                            .init(
                                type: .editMultiline(
                                    initialInstruction,
                                    purpose: self.content.instructionTitle
                                ),
                                context: []
                            )
                        ]
                    )
                ],
                isEditing: true
            )
        )
    }

    func canEnd() -> Bool {
        self.initialInstruction == self.currentInstruction
    }

    func requestEnd(onEnd: @escaping () -> Void) {
        self.handleCancel(completion: onEnd)
    }
}

extension InstructionEntrySupervisor: ItemListEventSink, NavBarEventSink {
    func send(event: ItemListEvent) {
        switch event {
        case .edit(
            string: let newInstruction,
            forItemAt: .init(item: 0, section: 0)
        ):
            self.currentInstruction = newInstruction
        default:
            break
        }
    }

    func send(navBarEvent: NavBarEvent) {
        switch navBarEvent {
        case .tap(.left, index: 0):
            self.handleCancel()
        case .tap(.right, index: 0):
            self.parent?.save(instruction: self.currentInstruction)
            self.parent?.childDidEnd(supervisor: self)
        default:
            break
        }
    }

    private func handleCancel() {
        self.handleCancel { [weak self] in
            guard let self else { return }
            self.parent?.childDidEnd(supervisor: self)
        }
    }

    private func handleCancel(completion: @escaping () -> Void) {
        guard self.initialInstruction != self.currentInstruction else {
            completion()
            return
        }

        let content = self.content.cancelEditAlert
        self.navBarManager.send(
            alertViewModel: .init(
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
                        callback: completion
                    )
                ]
            )
        )
    }
}
