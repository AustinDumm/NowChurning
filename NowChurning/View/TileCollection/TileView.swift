//
//  TileView.swift
//  NowChurning
//
//  Created by Austin Dumm on 10/19/22.
//

import UIKit

struct TileViewConfiguration: UIContentConfiguration {
    let image: UIImage
    let title: String
    let color: UIColor

    init(image: UIImage,
         title: String,
         backgroundColor: UIColor) {
        self.image = image
        self.title = title
        self.color = backgroundColor
    }

    func makeContentView() -> UIView & UIContentView {
        TileView(configuration: self)
    }

    func updated(for state: UIConfigurationState) -> TileViewConfiguration {
        self
    }
}

class TileView: UIView, UIContentView {
    var configuration: UIContentConfiguration

    private let stackView: UIStackView = {
        let stack = UIStackView()

        stack.axis = .vertical
        stack.spacing = 5.0

        return stack
    }()

    private let tileBackgroundContainer: UIView = {
        let view = UIView()

        view.backgroundColor = .clear

        return view
    }()

    private let tileBackgroundView: UIView = {
        let view = UIView()

        view.layer.cornerRadius = 10.0
        view.widthAnchor.constraint(equalTo: view.heightAnchor).isActive = true

        return view
    }()

    let tileImageView: UIImageView = {
        let imageView = UIImageView()

        imageView.contentMode = .scaleAspectFill
        imageView.layer.minificationFilter = .trilinear
        imageView.widthAnchor.constraint(equalToConstant: 125.0).isActive = true

        return imageView
    }()

    let tileTitleLabel: UILabel = {
        let label = UILabel()

        label.font = .preferredFont(forTextStyle: .headline)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0

        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        label.textAlignment = .center

        label.setContentHuggingPriority(.init(1),
                                        for: .horizontal)
        label.setContentHuggingPriority(.required,
                                        for: .vertical)

        return label
    }()


    init(configuration: UIContentConfiguration) {
        self.configuration = configuration

        super.init(frame: .zero)

        self.setupSubviews()
        self.configure(self.configuration)
    }

    required init?(coder: NSCoder) { nil }

    func setupSubviews() {
        self.centerInset(stackView,
                         heightPercentage: 1.0)
        self.stackView.widthAnchor.constraint(
            lessThanOrEqualTo: self.widthAnchor,
            multiplier: 0.9
        ).isActive = true
        self.stackView.addArrangedSubview(self.tileBackgroundContainer)
        self.stackView.addArrangedSubview(self.tileTitleLabel)

        self.tileBackgroundContainer.centerInset(
            self.tileBackgroundView,
            heightPercentage: 1.0
        )
        self.tileBackgroundView.inset(
            self.tileImageView,
            byMargin: 5.0
        )
    }

    private func configure(_ configuration: UIContentConfiguration) {
        guard let configuration = configuration as? TileViewConfiguration else {
            return
        }

        self.tileImageView.image = configuration.image
        self.tileTitleLabel.text = configuration.title
        self.tileBackgroundView.backgroundColor = configuration.color
    }
}
