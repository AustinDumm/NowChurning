//
//  NavBarViewBoundary.swift
//  NowChurning
//
//  Created by Austin Dumm on 12/29/22.
//

import Foundation

struct NavBarViewModel {
    enum Side {
        case left
        case right
    }

    struct Button: Equatable {
        let type: ButtonType
        let displayTitle: String?
        let isEnabled: Bool

        init(
            type: NavBarViewModel.ButtonType,
            displayTitle: String? = nil,
            isEnabled: Bool
        ) {
            self.type = type
            self.displayTitle = displayTitle
            self.isEnabled = isEnabled
        }
    }

    enum ButtonType: Equatable {
        case save
        case cancel
        case back
        case edit
        case add
        case done
        case export
        case exportTextOnly
    }

    var title: String
    var leftButtons: [Button]
    var rightButtons: [Button]
}

struct NavBarAlertViewModel {
    struct Action {
        let title: String
        let type: ActionType
        let callback: () -> Void
    }

    enum ActionType {
        case cancel
        case confirm(isDestructive: Bool)
    }

    let title: String?
    let message: String
    let side: NavBarViewModel.Side
    let buttonIndex: Int
    let actions: [Action]
}

protocol NavBarViewModelSink: AnyObject {
    func send(navBarViewModel: NavBarViewModel)
    func send(alertViewModel: NavBarAlertViewModel)
}


enum NavBarEvent {
    case tap(NavBarViewModel.Side, index: Int)
}

class WeakNavBarEventSink: NavBarEventSink {
    private weak var eventSink: NavBarEventSink?

    init(eventSink: NavBarEventSink) {
        self.eventSink = eventSink
    }

    func send(navBarEvent: NavBarEvent) {
        self.eventSink?.send(navBarEvent: navBarEvent)
    }
}

protocol NavBarEventSink: AnyObject {
    func send(navBarEvent: NavBarEvent)
}
