//
//  NavBarManager.swift
//  NowChurning
//
//  Created by Austin Dumm on 12/22/22.
//

import UIKit

protocol NavBarManagerProvidedButtonBuilder {
    func backButton() -> UIBarButtonItem?
}

protocol NavBarManagerSystemButtonBuilder {
    func cancelButton(action: UIAction) -> UIBarButtonItem?
    func saveButton(action: UIAction) -> UIBarButtonItem?
    func editButton(action: UIAction) -> UIBarButtonItem?
    func addButton(action: UIAction) -> UIBarButtonItem?
    func doneButton(action: UIAction) -> UIBarButtonItem?
}

class NavBarManager {
    private let navigationItem: UINavigationItem
    private let providedButtonBuilder: NavBarManagerProvidedButtonBuilder
    private let systemButtonBuilder: NavBarManagerSystemButtonBuilder
    private let eventSink: NavBarEventSink

    private weak var alertViewDelegate: AlertViewDelegate?

    init(
        navigationItem: UINavigationItem,
        alertViewDelegate: AlertViewDelegate,
        providedButtonBuilder: NavBarManagerProvidedButtonBuilder,
        systemButtonBuilder: NavBarManagerSystemButtonBuilder,
        eventSink: NavBarEventSink
    ) {
        self.navigationItem = navigationItem
        self.alertViewDelegate = alertViewDelegate
        self.providedButtonBuilder = providedButtonBuilder
        self.systemButtonBuilder = systemButtonBuilder
        self.eventSink = eventSink
    }
}

extension NavBarManager: NavBarViewModelSink {
    func send(
        navBarViewModel viewModel: NavBarViewModel
    ) {
        self.onViewModelUpdate(viewModel: viewModel)
    }

    func send(
        alertViewModel: NavBarAlertViewModel
    ) {
        self.displayAlert(forViewModel: alertViewModel)
    }


    private func onViewModelUpdate(
        viewModel: NavBarViewModel
    ) {
        self.navigationItem.title = viewModel.title

        self.navigationItem.leftBarButtonItems = Self
            .barButtonItems(
                from: viewModel.leftButtons,
                onNavigationItem: self.navigationItem,
                buttonActionBuilder: { buttonIndex, button in
                    UIAction(
                        title: button.displayTitle ?? Self.defaultText(forButtonType: button.type),
                        image: Self.image(forButtonType: button.type)
                    ) { [weak self] _ in
                        self?.eventSink
                            .send(
                                navBarEvent: .tap(
                                    .left,
                                    index: buttonIndex
                                )
                            )
                    }

                },
                systemButtonBuilder: self.systemButtonBuilder,
                providedButtonBuilder: self.providedButtonBuilder
            )
        if viewModel.leftButtons.contains(where: { $0.type == .back }) {
            navigationItem.leftItemsSupplementBackButton = true
        } else {
            navigationItem.leftItemsSupplementBackButton = false
        }

        self.navigationItem.rightBarButtonItems = Self
            .barButtonItems(
                from: viewModel.rightButtons,
                onNavigationItem: self.navigationItem,
                buttonActionBuilder: { buttonIndex, button in
                    UIAction(
                        title: button.displayTitle ?? Self.defaultText(forButtonType: button.type),
                        image: Self.image(forButtonType: button.type)
                    ) { [weak self] _ in
                        self?.eventSink
                            .send(
                                navBarEvent: .tap(
                                    .right,
                                    index: buttonIndex
                                )
                            )
                    }
                },
                systemButtonBuilder: self.systemButtonBuilder,
                providedButtonBuilder: self.providedButtonBuilder
            )
    }

    private func displayAlert(
        forViewModel alertViewModel: NavBarAlertViewModel
    ) {
        let alertButton: UIBarButtonItem
        switch alertViewModel.side {
        case .left:
            guard
                let button = self
                    .navigationItem
                    .leftBarButtonItems?[safe: alertViewModel.buttonIndex]
            else {
                return
            }

            alertButton = button
        case .right:
            guard
                let button = self
                    .navigationItem
                    .rightBarButtonItems?[safe: alertViewModel.buttonIndex]
            else {
                return
            }

            alertButton = button
        }

        let display = AlertViewDisplay(
            title: alertViewModel.title,
            description: alertViewModel.message,
            buttons: alertViewModel
                .actions
                .map { action in
                    let style: UIAlertAction.Style
                    switch action.type {
                    case .cancel:
                        style = .cancel
                    case .confirm(let isDestructive):
                        style = isDestructive ? .destructive : .default
                    }

                    return .init(
                        text: action.title,
                        style: style,
                        callback: action.callback
                    )
                }
        )

        self.alertViewDelegate?.showActionCard(
            on: alertButton,
            withDisplay: display
        )
    }

    private static func barButtonItems(
        from viewModelButtons: [NavBarViewModel.Button],
        onNavigationItem navigationItem: UINavigationItem,
        buttonActionBuilder: (Int, NavBarViewModel.Button) -> UIAction,
        systemButtonBuilder: NavBarManagerSystemButtonBuilder,
        providedButtonBuilder: NavBarManagerProvidedButtonBuilder
    ) -> [UIBarButtonItem] {
        var resultItems = [UIBarButtonItem]()

        let enumeratedRemaining = viewModelButtons
            .enumerated()
            .filter({ $0.element.type != .back })
        if enumeratedRemaining.count <= 1 {
            resultItems.append(
                contentsOf: enumeratedRemaining
                    .compactMap { index, viewModelButton -> UIBarButtonItem? in
                        barButtonItem(
                            from: viewModelButton,
                            onNavigationItem: navigationItem,
                            buttonAction: buttonActionBuilder(index, viewModelButton),
                            systemButtonBuilder: systemButtonBuilder,
                            providedButtonBuilder: providedButtonBuilder
                        )
                    }
            )
        } else {
            resultItems.append(.init(
                image: .init(systemName: "ellipsis.circle"),
                menu: .init(children: enumeratedRemaining
                    .map { buttonActionBuilder($0.offset, $0.element) }
                )
            ))
        }

        return resultItems
    }

    private static func barButtonItem(
        from viewModelButton: NavBarViewModel.Button,
        onNavigationItem navigationItem: UINavigationItem,
        buttonAction: UIAction,
        systemButtonBuilder: NavBarManagerSystemButtonBuilder,
        providedButtonBuilder: NavBarManagerProvidedButtonBuilder
    ) -> UIBarButtonItem? {
        let button: UIBarButtonItem?
        switch viewModelButton.type {
        case .save:
            button = systemButtonBuilder.saveButton(
                action: buttonAction
            )
        case .cancel:
            button = systemButtonBuilder.cancelButton(
                action: buttonAction
            )
        case .back:
            return nil
        case .edit:
            button = systemButtonBuilder.editButton(
                action: buttonAction
            )
        case .add:
            button = systemButtonBuilder.addButton(
                action: buttonAction
            )
        case .done:
            button = systemButtonBuilder.doneButton(
                action: buttonAction
            )
        case .export, .exportTextOnly:
            button = .init(
                title: viewModelButton.displayTitle,
                primaryAction: buttonAction
            )
        }

        button?.isEnabled = viewModelButton.isEnabled
        return button
    }

    private static func image(
        forButtonType buttonType: NavBarViewModel.ButtonType
    ) -> UIImage? {
        switch buttonType {
        case .save:
            return nil
        case .cancel:
            return nil
        case .back:
            return nil
        case .edit:
            return .init(systemName: "pencil")
        case .add:
            return .init(systemName: "plus")
        case .export:
            return .init(systemName: "square.and.arrow.up")
        case .exportTextOnly:
            return nil
        case .done:
            return nil
        }
    }

    private static func defaultText(
        forButtonType buttonType: NavBarViewModel.ButtonType
    ) -> String {
        switch buttonType {
        case .save:
            return "default_action_name_save".localized()
        case .cancel:
            return "default_action_name_cancel".localized()
        case .back:
            return "default_action_name_back".localized()
        case .edit:
            return "default_action_name_edit".localized()
        case .add:
            return "default_action_name_add".localized()
        case .done:
            return "default_action_name_done".localized()
        case .export, .exportTextOnly:
            return "default_action_name_export".localized()
        }
    }
}
