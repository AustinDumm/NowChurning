//
//  MeasureListDisplayBoundary.swift
//  NowChurning
//
//  Created by Austin Dumm on 5/13/23.
//

import Foundation

struct MeasureListDisplayModel {
    struct Section {
        let title: String
        let items: [Item]
    }

    struct Item {
        let title: String
        let id: ID<Item>
    }

    let sections: [Section]
}

protocol MeasureListDisplayModelSink: AnyObject, EditModeDisplayModelSink {
    func send(displayModel: MeasureListDisplayModel)
    func scrollTo(section: Int, item: Int)
}


enum MeasureListAction {
    case selectMeasure(atIndex: Int, inSection: Int)
    case deleteMeasure(atIndex: Int, inSection: Int)
    case newMeasure
}

protocol MeasureListActionSink: AnyObject, EditModeActionSink {
    func send(action: MeasureListAction)
}
