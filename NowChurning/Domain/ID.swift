//
//  ID.swift
//  NowChurning
//
//  Created by Austin Dumm on 10/22/22.
//

import Foundation

struct ID<T>: Equatable, Hashable {
    let rawId: UUID

    init(rawId: UUID = .init()) {
        self.rawId = rawId
    }

    func convert<Out>() -> ID<Out> {
        .init(rawId: self.rawId)
    }
}
