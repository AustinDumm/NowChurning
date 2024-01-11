//
//  AuthenticationPlaceholderViewController.swift
//  NowChurning
//
//  Created by Austin Dumm on 1/10/24.
//

import UIKit

class AuthenticationPlaceholderViewController: UIViewController {

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = .systemBackground
        let activity = UIActivityIndicatorView(style: .large)
        activity.startAnimating()
        self.view.inset(activity)
    }
}
