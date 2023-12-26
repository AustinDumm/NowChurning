//
//  SelectionListViewBoundary.swift
//  NowChurning
//
//  Created by Austin Dumm on 2/20/23.
//

import Foundation

struct SelectionListViewModel {
    struct Item: Hashable {
        let title: String
        let isSelected: Bool
    }

    let items: [Item]
}

protocol SelectionListViewModelSink: AnyObject {
    func send(viewModel: SelectionListViewModel)
}


enum SelectionListEvent {
    case changeSelection(indices: [Int])
}

protocol SelectionListEventSink: AnyObject {
    func send(event: SelectionListEvent)
}
