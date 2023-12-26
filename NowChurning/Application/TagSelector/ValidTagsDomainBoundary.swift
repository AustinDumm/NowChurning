//
//  ValidTagsDomainBoundary.swift
//  NowChurning
//
//  Created by Austin Dumm on 2/18/23.
//

import Foundation

protocol ValidTagsDomainSink {
    associatedtype TagBase

    func send(validTags: [Tag<TagBase>])
}
