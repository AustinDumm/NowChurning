//
//  ItemListMultiLineTextEditView.swift
//  NowChurning
//
//  Created by Austin Dumm on 12/22/22.
//

import UIKit

class ItemListMultiLineTextEditView: UIView, UIContentView {
    typealias TextDidUpdateCallback = (String?) -> Void
    typealias EditEventCallback = () -> Void

    struct Configuration: UIContentConfiguration {
        var contentPurpose: String
        var text: String?
        var textDidUpdate: TextDidUpdateCallback?
        var didStartEditing: EditEventCallback?
        var didEndEditing: EditEventCallback?

        func makeContentView() -> UIView & UIContentView {
            ItemListMultiLineTextEditView(configuration: self)
        }

        func updated(
            for state: UIConfigurationState
        ) -> ItemListMultiLineTextEditView.Configuration {
            self
        }

    }

    lazy private(set) var textView: UITextView = {
        let textView = UITextView()

        textView.delegate = self
        textView.backgroundColor = .clear
        textView.isScrollEnabled = false
        textView.inputAccessoryView = UIToolbar.doneToolbar { [weak textView] in
            textView?.resignFirstResponder()
        }

        textView.font = .preferredFont(
            forTextStyle: .body,
            compatibleWith: self.traitCollection
        )

        return textView
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
            self.textView,
            byEdgeInsets: UIEdgeInsets(
                top: 5,
                left: 15,
                bottom: 5,
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

        self.textView.text = configuration.text
        self.textView.accessibilityLabel = configuration.contentPurpose
        self.textDidUpdate = configuration.textDidUpdate
        self.didStartEditing = configuration.didStartEditing
        self.didEndEditing = configuration.didEndEditing
    }
}

extension ItemListMultiLineTextEditView: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        UIView.performWithoutAnimation {
            self.invalidateIntrinsicContentSize()
        }
        self.textDidUpdate?(textView.text)
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        self.didStartEditing?()
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        self.didEndEditing?()
    }
}

extension UICollectionViewListCell {
    func textViewConfiguration(
        for purpose: String
    ) -> ItemListMultiLineTextEditView.Configuration {
        ItemListMultiLineTextEditView.Configuration(
            contentPurpose: purpose
        )
    }
}
