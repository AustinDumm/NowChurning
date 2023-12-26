//
//  EditableFieldTextView.swift
//  NowChurning
//
//  Created by Austin Dumm on 7/18/23.
//

import UIKit

class EditableFieldTextView: UIView, UIContentView {
    typealias TextDidUpdateCallback = (String?) -> Void

    struct Configuration: UIContentConfiguration {
        var label: String?
        var text: String?
        var textDidUpdate: TextDidUpdateCallback?

        func makeContentView() -> UIView & UIContentView {
            EditableFieldTextView(configuration: self)
        }

        func updated(
            for state: UIConfigurationState
        ) -> EditableFieldTextView.Configuration {
            self
        }
    }

    let label: UILabel = {
        let label = UILabel()

        label.font = .preferredFont(forTextStyle: .body)
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.adjustsFontForContentSizeCategory = true

        return label
    }()

    let field: UITextField = {
        let field = UITextField()

        field.font = .preferredFont(forTextStyle: .body)
        field.textAlignment = .right
        field.adjustsFontForContentSizeCategory = true

        return field
    }()

    var configuration: UIContentConfiguration

    init(configuration: Configuration) {
        self.configuration = configuration

        let stack = UIStackView(arrangedSubviews: [
            self.label,
            self.field
        ])
        stack.axis = .horizontal
        stack.spacing = 10.0

        self.label.text = configuration.label
        self.field.text = configuration.text

        super.init(frame: .zero)

        self.inset(stack, byEdgeInsets: .init(
            top: 12.0,
            left: 20.0,
            bottom: 12.0,
            right: 12.0
        ))

        self.field.addTarget(
            self,
            action: #selector(didEditField(_:)),
            for: .editingChanged)
    }

    required init?(coder: NSCoder) { nil }

    @objc private func didEditField(_ textField: UITextField) {
        (self.configuration as? Configuration)?
            .textDidUpdate?(textField.text)
    }
}

extension UICollectionViewListCell {
    func editableFieldConfiguration() -> EditableFieldTextView.Configuration {
        EditableFieldTextView.Configuration()
    }
}
