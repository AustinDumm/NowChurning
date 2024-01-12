//
//  UploadProgressViewController.swift
//  NowChurning
//
//  Created by Austin Dumm on 1/11/24.
//

import UIKit

class UploadProgressViewController: UIViewController {
    
    var confirmCallback: (() -> Void)? {
        didSet {
            self.okButton.addAction(
                .init(
                    handler: { [weak self] _ in
                        self?.confirmCallback?()
                    }
                ),
                for: .touchUpInside
            )
        }
    }

    let spinner = UIActivityIndicatorView(style: .large)
    let okButton: UIButton = {
        let button = UIButton(configuration: .borderedProminent())
        button.titleLabel?.font = .preferredFont(forTextStyle: .title1)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.setTitle("uploading_ok_text".localized(), for: .normal)
        return button
    }()
    let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .title2)
        label.adjustsFontForContentSizeCategory = true
        label.adjustsFontSizeToFitWidth = true
        label.numberOfLines = 0
        label.lineBreakMode = .byClipping
        label.textAlignment = .center
        return label
    }()

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func loadView() {
        self.view = UIView()
        self.view.backgroundColor = .systemBackground
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let stack = UIStackView(arrangedSubviews: [
            self.spinner,
            self.okButton,
            self.descriptionLabel
        ])
        stack.axis = .vertical
        stack.spacing = 10.0
        stack.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            stack.widthAnchor.constraint(
                equalTo: self.view.widthAnchor,
                multiplier: 0.9
            ),
            stack.centerYAnchor.constraint(equalTo: self.view.centerYAnchor),
            stack.heightAnchor.constraint(
                lessThanOrEqualTo: self.view.heightAnchor,
                multiplier: 0.9
            ),
        ])

        self.title = "uploading_progress_title".localized()
    }

    enum State {
        case uploading
        case done
        case failed
    }
    func setState(_ state: State) {
        switch state {
        case .uploading:
            self.spinner.startAnimating()
            self.okButton.isHidden = true
            self.descriptionLabel.text = "uploading_progress_text".localized()

        case .done:
            self.spinner.stopAnimating()
            self.okButton.isHidden = false
            self.descriptionLabel.text = "uploading_complete_text".localized()

        case .failed:
            self.spinner.stopAnimating()
            self.okButton.isHidden = false
            self.descriptionLabel.text = "uploading_failed_text".localized()
        }
    }


}
