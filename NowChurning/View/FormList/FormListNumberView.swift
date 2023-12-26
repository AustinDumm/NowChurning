//
//  FormListNumberView.swift
//  NowChurning
//
//  Created by Austin Dumm on 6/4/23.
//

import UIKit

class FormListNumberView: UIView, UIContentView {
    typealias ValueDidUpdateCallback = (Double?) -> Void
    typealias DidStartEditCallback = () -> Void
    typealias DidEndEditCallback = () -> Void

    struct Configuration: UIContentConfiguration {
        var title: String?
        var value: Double?
        var valueDidUpdate: ValueDidUpdateCallback?
        var didStartEdit: DidStartEditCallback?
        var didEndEdit: DidEndEditCallback?

        func makeContentView() -> UIView & UIContentView {
            FormListNumberView(configuration: self)
        }

        func updated(
            for state: UIConfigurationState
        ) -> FormListNumberView.Configuration {
            self
        }
    }

    private static let formatter: NumberFormatter = {
        let formatter = NumberFormatter()

        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 10

        return formatter
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()

        label.font = .preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true

        return label
    }()

    lazy private(set) var textField: UITextField = {
        let textField = UITextField()

        textField.leftViewMode = .always
        textField.leftView = self.titleLabel
        textField.font = .preferredFont(forTextStyle: .body)
        textField.adjustsFontForContentSizeCategory = true
        textField.textAlignment = .right
        textField.keyboardType = .decimalPad
        textField.clearButtonMode = .whileEditing
        textField.enablesReturnKeyAutomatically = true
        textField.returnKeyType = .done
        textField.inputAccessoryView = UIToolbar.doneToolbar { [weak textField] in
            textField?.resignFirstResponder()
        }

        textField.addTarget(
            self,
            action: #selector(didEdit),
            for: .editingChanged
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

    var valueDidUpdate: ValueDidUpdateCallback?
    var didStartEdit: DidStartEditCallback?
    var didEndEdit: DidEndEditCallback?

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
                left: 20,
                bottom: 0,
                right: 15
            )
        )
        self.updateConfiguration(to: configuration)
        self.textField.delegate = self
    }

    required init?(coder: NSCoder) { nil }

    private func updateConfiguration(
        to configuration: UIContentConfiguration
    ) {
        guard let configuration = configuration as? Configuration else {
            return
        }

        self.titleLabel.text = configuration.title

        self.textField.leftView = self.titleLabel
        self.textField.accessibilityLabel = "\(configuration.title ?? "") \(configuration.value ?? 0.0)"
        self.textField.text = configuration.value?.formatted()

        self.valueDidUpdate = configuration.valueDidUpdate
        self.didStartEdit = configuration.didStartEdit
        self.didEndEdit = configuration.didEndEdit
    }

    @objc func didEdit(for textField: UITextField) {
        guard
            let text = textField.text?.replacingOccurrences(of: Self.formatter.groupingSeparator, with: "")
        else {
            return
        }

        if text.isEmpty {
            self.valueDidUpdate?(0.0)
            return
        }

        guard
            let value = Self.formatter.number(from: text)
        else {
            return
        }

        self.valueDidUpdate?(value.doubleValue)
    }
}

extension FormListNumberView: UITextFieldDelegate {
    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        guard let currentText = textField.text else {
            return false
        }

        let currentSeparatorCount = currentText
            .filter { String($0) == Self.formatter.groupingSeparator }
            .count

        let start = currentText.index(currentText.startIndex, offsetBy: range.location)
        let end = currentText.index(start, offsetBy: range.length)
        let replaced = currentText.replacingCharacters(in: start..<end, with: string)
        let filtered = replaced.filter { String($0) != Self.formatter.groupingSeparator }

        if filtered.isEmpty {
            return true
        }

        guard var number = Self.formatter.number(from: filtered) else {
            return false
        }

        if number.doubleValue < 0.0 {
            number = number.doubleValue.magnitude as NSNumber
        }

        var formattedNumber = Self.formatter.string(from: number)

        let newSeparatorCount = formattedNumber?
            .filter { String($0) == Self.formatter.groupingSeparator }
            .count ?? currentSeparatorCount
        let addedSeparators = newSeparatorCount - currentSeparatorCount

        if let decimalStart = filtered.firstIndex(where: { String($0) == Self.formatter.decimalSeparator}) {
            let fractionalDigits = filtered[decimalStart...]
            if fractionalDigits == Self.formatter.decimalSeparator ||
                Self.formatter.number(from: String(fractionalDigits))?.doubleValue.isZero ?? false {
                formattedNumber = formattedNumber.map { $0 + String(fractionalDigits) }
            }
        }

        textField.text = formattedNumber

        if let startSelection = textField.position(
            from: textField.beginningOfDocument,
            offset: range.location + addedSeparators + 1
        ),
           let endSelection = textField.position(
            from: startSelection,
            offset: range.length
           ) {
            textField.selectedTextRange = textField.textRange(from: startSelection, to: endSelection)
        }
        textField.sendActions(for: .editingChanged)

        return false
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        if let numberValue = Double(textField.text ?? ""), numberValue.isZero {
            textField.text = ""
        }

        self.didStartEdit?()
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        self.didEndEdit?()
    }
}

extension UICollectionViewListCell {
    func numberFieldConfiguration() -> FormListNumberView.Configuration {
        FormListNumberView.Configuration()
    }
}
