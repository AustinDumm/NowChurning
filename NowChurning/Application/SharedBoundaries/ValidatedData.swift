//
//  ValidatedData.swift
//  NowChurning
//
//  Created by Austin Dumm on 5/16/23.
//

import Foundation

struct ValidationError: Equatable {
    var error: String
    var suggestion: String?
}

enum ValidatedData<Data> {
    case valid(Data)
    case invalid(Data, ValidationError)

    var data: Data {
        switch self {
        case .valid(let data),
                .invalid(let data, _):
            return data
        }
    }

    var invalidityReason: ValidationError? {
        switch self {
        case .valid:
            return nil
        case .invalid(_, let reason):
            return reason
        }
    }

    var isValid: Bool {
        switch self {
        case .valid:
            return true
        case .invalid:
            return false
        }
    }
}

extension ValidatedData: Equatable
where Data: Equatable {}
