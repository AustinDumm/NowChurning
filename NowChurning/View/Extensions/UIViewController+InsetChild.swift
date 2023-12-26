//
//  UIViewController+InsetChild.swift
//  NowChurning
//
//  Created by Austin Dumm on 3/11/23.
//

import UIKit

extension UIViewController {
    func insetChild(
        _ child: UIViewController,
        insetGuideType: UIView.InsetGuideType = .edge,
        byEdgeInsets edgeInsets: UIEdgeInsets = .zero
    ) {
        self.addChild(child)
        self.view.inset(
            child.view,
            layoutGuideType: insetGuideType,
            byEdgeInsets: edgeInsets
        )
        child.didMove(toParent: self)
    }

    func insetChild(
        _ child: UIViewController,
        byMargin margin: CGFloat = 0.0
    ) {
        self.insetChild(
            child,
            byEdgeInsets: .init(
                top: margin,
                left: margin,
                bottom: margin,
                right: margin
            )
        )
    }

    func centerInsetChild(
        _ child: UIViewController,
        widthPercentage: CGFloat? = nil,
        heightPercentage: CGFloat? = nil
    ) {
        self.addChild(child)
        self.view
            .centerInset(
                child.view,
                widthPercentage: widthPercentage,
                heightPercentage: heightPercentage
            )
        child.didMove(toParent: self)
    }
}
