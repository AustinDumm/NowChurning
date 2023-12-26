//
//  MeasureListDomainBoundary.swift
//  NowChurning
//
//  Created by Austin Dumm on 5/13/23.
//

import Foundation

protocol MeasureListDomainModelSink: AnyObject {
    func send(domainModel: [Measure])
}


enum MeasureListStoreAction {
    case save(
        measures: [Measure],
        saver: MeasureListDomainModelSink?
    )
}

protocol MeasureListStoreActionSink: AnyObject {
    func send(action: MeasureListStoreAction)
    func registerSink(asWeak sink: MeasureListDomainModelSink)
}
