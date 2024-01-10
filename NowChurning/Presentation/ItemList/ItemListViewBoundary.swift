//
//  ItemListPresentation.swift
//  NowChurning
//
//  Created by Austin Dumm on 12/17/22.
//

import Foundation

struct ItemListViewModel: Hashable {
    struct ErrorMessage: Hashable {
        var message: String
        var suggestion: String?
    }

    struct Section: Hashable {
        var title: String
        var items: [Item]
        var footerErrorMessage: ErrorMessage?
    }

    struct Item: Hashable, Identifiable {
        var id: String
        var type: ItemType
        var indentation: Int
        var context: [Context]

        init(
            id: String? = nil,
            type: ItemListViewModel.ItemType,
            indentation: Int = 0,
            context: [ItemListViewModel.Context]
        ) {
            if let id {
                self.id = id
            } else {
                switch type {
                case .text(let id),
                        .message(let id),
                        .editSingleline(_, let id),
                        .editMultiline(_, let id):
                    self.id = id
                case .attributedText(let string):
                    self.id = string.string
                }
            }
            self.type = type
            self.indentation = indentation
            self.context = context
        }
    }

    enum ItemType: Hashable {
        case text(String)
        case message(String)
        case attributedText(NSAttributedString)
        case editSingleline(String, purpose: String)
        case editMultiline(String, purpose: String)
    }

    struct ValidReorders: Hashable {
        enum Value<T: Hashable>: Hashable {
            case any
            case set(T)
        }

        let sections: Value<[Int: Value<Set<Int>>]>

        func isValid(indexPath: IndexPath) -> Bool {
            switch self.sections {
            case .any:
                return true
            case .set(let lookup):
                switch lookup[indexPath.section] {
                case .any:
                    return true
                case .none:
                    return false
                case .set(let validItems):
                    return validItems.contains(indexPath.item)
                }
            }
        }
    }

    struct AlertData: Hashable, Equatable {
        var message: String
        var actionDescription: String
        var icon: NavBarViewModel.ButtonType?
    }

    enum Context: Hashable, Equatable {
        case navigate
        case delete
        case add
        case info
        case multiselect
        case invalid(reason: String)
        case alert(AlertData)
        case reorder(ValidReorders)
    }

    var sections: [Section]
    let isEditing: Bool
}

protocol ItemListViewModelSink: AnyObject {
    func send(viewModel: ItemListViewModel)
    func scrollTo(_ indexPath: IndexPath)
}


enum ItemListEvent {
    case select(itemAt: IndexPath)
    case selectFooter(forSection: Int)

    case delete(itemAt: IndexPath)
    case edit(
        string: String,
        forItemAt: IndexPath
    )
    case openInfo(itemAt: IndexPath)
    case resolveAlert(itemAt: IndexPath)
    case move(from: IndexPath, to: IndexPath)
}

class WeakItemListEventAdapter: ItemListEventSink, NavBarEventSink {
    weak var eventSink: (ItemListEventSink & NavBarEventSink)?

    init(eventSink: (ItemListEventSink & NavBarEventSink)? = nil) {
        self.eventSink = eventSink
    }

    func send(event: ItemListEvent) {
        self.eventSink?.send(event: event)
    }

    func send(navBarEvent: NavBarEvent) {
        self.eventSink?.send(navBarEvent: navBarEvent)
    }
}
protocol ItemListEventSink: AnyObject {
    func send(event: ItemListEvent)
}
