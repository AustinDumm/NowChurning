//
//  UIColor+AppColors.swift
//  NowChurning
//
//  Created by Austin Dumm on 10/19/22.
//

import UIKit

extension UIColor {
    enum Accent {
        static let inventory = UIColor(named: "ac_inventory")!
        static let recipes = UIColor(named: "ac_recipes")!
    }

    enum App {
        static let viewBackground = UIColor(named: "ap_viewBackground")!
    }

    enum MainScreen {
        static let inventoryTileBackground = UIColor(named: "ms_inventoryTileBackground")!
        static let recipeTileBackground = UIColor(named: "ms_recipeTileBackground")!
        static let collectionBackground = UIColor(named: "ms_collectionBackground")!
        static let collectionBorder = UIColor(named: "ms_collectionBorder")!
    }
}
