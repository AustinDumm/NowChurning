//
//  UIView+Inset.swift
//  NowChurning
//
//  Created by Austin Dumm on 10/19/22.
//

import UIKit

extension UIView {
    enum InsetGuideType {
        case margin
        case safeArea
        case edge
        case keyboard
    }

    var edgeLayoutGuide: UILayoutGuide {
        let layoutGuide = UILayoutGuide()
        self.addLayoutGuide(layoutGuide)
        layoutGuide.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
        layoutGuide.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        layoutGuide.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        layoutGuide.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true

        return layoutGuide
    }

    private func layoutGuide(
        forInsetType insetGuideType: InsetGuideType
    ) -> UILayoutGuide {
        switch insetGuideType {
        case .margin:
            return self.layoutMarginsGuide
        case .safeArea:
            return self.safeAreaLayoutGuide
        case .edge:
            return self.edgeLayoutGuide
        case .keyboard:
            return self.keyboardLayoutGuide
        }
    }

    func inset(
        _ view: UIView,
        layoutGuideType: InsetGuideType = .edge,
        byEdgeInsets edgeInsets: UIEdgeInsets = .zero
    ) {
        let layoutGuide = self.layoutGuide(forInsetType: layoutGuideType)

        self.addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.leftAnchor.constraint(
                equalTo: layoutGuide.leftAnchor,
                constant: edgeInsets.left
            ),
            view.topAnchor.constraint(
                equalTo: layoutGuide.topAnchor,
                constant: edgeInsets.top
            ),
            layoutGuide.rightAnchor.constraint(
                equalTo: view.rightAnchor,
                constant: edgeInsets.right
            ),
            layoutGuide.bottomAnchor.constraint(
                equalTo: view.bottomAnchor,
                constant: edgeInsets.bottom
            ),
        ])
    }

    func inset(
        _ view: UIView,
        byMargin margin: CGFloat = 0.0
    ) {
        self.inset(view,
                   byEdgeInsets: .init(top: margin,
                                       left: margin,
                                       bottom: margin,
                                       right: margin))
    }

    func centerInset(
        _ view: UIView,
        widthPercentage: CGFloat? = nil,
        heightPercentage: CGFloat? = nil
    ) {
        self.addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            self.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])

        if let widthPercentage = widthPercentage {
            self.widthAnchor.constraint(
                equalTo: view.widthAnchor,
                multiplier: widthPercentage
            ).isActive = true
        }

        if let heightPercentage = heightPercentage {
            self.heightAnchor.constraint(
                equalTo: view.heightAnchor,
                multiplier: heightPercentage
            ).isActive = true
        }
    }
}
