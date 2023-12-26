//
//  FormListViewBoundary.swift
//  NowChurning
//
//  Created by Austin Dumm on 5/29/23.
//

import Foundation

struct FormListViewModel {
    struct Section {
        var title: String
        var items: [Item]
    }

    struct Item: Hashable, Identifiable {
        var id: String
        var type: ItemType
    }

    enum ItemType: Hashable {
        case labeledField(label: String, content: String)
        case labeledNumber(label: String, content: Double)
        case labeledSelection(label: String, options: [String], selection: Int)
    }

    var sections: [Section]
}

protocol FormListViewModelSink: AnyObject {
    func send(viewModel: FormListViewModel)
    func startEdit(at indexPath: IndexPath)
}


enum FormListEvent {
    case updateFieldText(
        item: Int,
        section: Int,
        content: String
    )

    case updateNumber(
        item: Int,
        section: Int,
        number: Double
    )

    case updateSelection(
        item: Int,
        section: Int,
        selection: Int
    )
}

protocol FormListEventSink: AnyObject {
    func send(event: FormListEvent)
}
