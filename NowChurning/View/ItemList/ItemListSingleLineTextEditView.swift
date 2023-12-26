//
//  ItemListSingleLineTextEditView.swift
//  NowChurning
//
//  Created by Austin Dumm on 12/22/22.
//

import UIKit

class ItemListSingleLineTextEditView: UIView, UIContentView {
    typealias TextDidUpdateCallback = (String?) -> Void
    typealias EditEventCallback = () -> Void

    struct Configuration: UIContentConfiguration {
        var contentPurpose: String
        var text: String?
        var textDidUpdate: TextDidUpdateCallback?
        var didStartEditing: EditEventCallback?
        var didEndEditing: EditEventCallback?

        func makeContentView() -> UIView & UIContentView {
            ItemListSingleLineTextEditView(configuration: self)
        }

        func updated(
            for state: UIConfigurationState
        ) -> ItemListSingleLineTextEditView.Configuration {
            self
        }
    }

    lazy private(set) var textField: UITextField = {
        let textField = UITextField()

        textField.clearButtonMode = .whileEditing
        textField.addTarget(
            self,
            action: #selector(textDidChange),
            for: .editingChanged
        )

        textField.addTarget(
            self,
            action: #selector(didStartEdit),
            for: .editingDidBegin
        )

        textField.addTarget(
            self,
            action: #selector(didEndEdit),
            for: .editingDidEnd
        )
        textField.addTarget(
            self,
            action: #selector(didEndEdit),
            for: .editingDidEndOnExit
        )

        textField.font = .preferredFont(
            forTextStyle: .body,
            compatibleWith: self.traitCollection
        )

        return textField
    }()

    var configuration: UIContentConfiguration {
        didSet {
            self.updateConfiguration(to: self.configuration)
        }
    }

    var textDidUpdate: TextDidUpdateCallback?
    var didStartEditing: EditEventCallback?
    var didEndEditing: EditEventCallback?

    override var intrinsicContentSize: CGSize {
        CGSize(width: 0, height: 44)
    }

    init(configuration: Configuration) {
        self.configuration = configuration

        super.init(frame: .zero)

        self.inset(
            self.textField,
            byEdgeInsets: UIEdgeInsets(
                top: 0,
                left: 15,
                bottom: 0,
                right: 15
            )
        )
        self.updateConfiguration(to: configuration)
    }

    required init?(coder: NSCoder) { nil }

    private func updateConfiguration(
        to configuration: UIContentConfiguration
    ) {
        guard let configuration = configuration as? Configuration else {
            return
        }

        self.textField.accessibilityLabel = configuration.contentPurpose
        self.textField.text = configuration.text
        self.textDidUpdate = configuration.textDidUpdate
        self.didStartEditing = configuration.didStartEditing
        self.didEndEditing = configuration.didEndEditing
    }

    @objc func textDidChange(for textField: UITextField) {
        self.textDidUpdate?(textField.text)
    }

    @objc func didStartEdit(for textField: UITextField) {
        self.didStartEditing?()
    }

    @objc func didEndEdit(for textField: UITextField) {
        self.didEndEditing?()
    }

}

extension UICollectionViewListCell {
    func textFieldConfiguration(
        for purpose: String
    ) -> ItemListSingleLineTextEditView.Configuration {
        ItemListSingleLineTextEditView.Configuration(
            contentPurpose: purpose
        )
    }
}
