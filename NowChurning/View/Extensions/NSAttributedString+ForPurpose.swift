//
//  NSAttributedString+ForPurpose.swift
//  NowChurning
//
//  Created by Austin Dumm on 5/25/23.
//

import UIKit

extension NSAttributedString {
    enum Purpose {
        case error(suggestion: String?)
        case unstocked
    }

    convenience init(
        string: String,
        purpose: Purpose
    ) {
        switch purpose {
        case .error(let suggestion):
            if let suggestion {
                let error = NSAttributedString(
                    string: string,
                    attributes: [.foregroundColor: UIColor.red]
                )
                let suggestion = NSAttributedString(
                    string: suggestion,
                    attributes: [.foregroundColor: UIColor.link]
                )
                let result = NSMutableAttributedString(attributedString: error)

                if !suggestion.string.isEmpty {
                    result.append(NSAttributedString(string: " "))
                    result.append(suggestion)
                }

                self.init(attributedString: result)
            } else {
                self.init(
                    string: string,
                    attributes: [.foregroundColor: UIColor.red]
                )
            }
        case .unstocked:
            self.init(
                string: string,
                attributes: [.foregroundColor: UIColor.red]
            )
        }
    }
}
