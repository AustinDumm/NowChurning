//
//  AppError.swift
//  NowChurning
//
//  Created by Austin Dumm on 2/23/23.
//

import UIKit

/// Errors meant to be shown to the user
enum UserError: String {
    case deviceStorageError = "user_error_storage_error"

    func alert() {
        guard
            let window = SceneDelegate.launchSupervisor?.window,
            let root = window.rootViewController
        else {
            return
        }

        let alert = UIAlertController(
            title: "user_error_header".localized(),
            message: self.rawValue.localized(),
            preferredStyle: .alert
        )
        let okAction = UIAlertAction(
            title: "user_error_confirm".localized(),
            style: .default
        )
        alert.addAction(okAction)
        root.present(
            alert,
            animated: true
        )
    }
}

enum AppError: Int {
    case unknown

    // MARK: Main Flow Supervisor
    case mainInventoryPushStateFailure
    case mainMyRecipesPushStateFailure
    case mainIngredientDetailPushStateFailure
    case mainAddIngredientPushStateFailure
    case mainRecipeDetailPushStateFailure
    case mainAddRecipePushStateFailure
    case mainEndStateFailure

    // MARK: Inventory Supervisor
    case inventorySupervisorEndStateFailure
    case inventoryIngredientDetailPushStateFailure
    case inventoryAddIngredientPushStateFailure

    // MARK: MyRecipesSupervisor
    case myRecipesSupervisorEndStateFailure
    case myRecipesDetailPushStateFailure

    // MARK: Ingredient Flow Supervisor
    case ingredientEndStateFailure
    case ingredientTagSelPushStateFailure
    case ingredientTagSelectionStateFailure

    // MARK: Measure Flow Supervisor
    case measureEndStateFailure
    case measureTagSelPushStateFailure
    case measureTagSelectionStateFailure
    case measureMeasurementEditPushStateFailure

    // MARK: Add Measure Flow Supervisor
    case addMeasureEndStateFailure
    case addMeasureExistingIngredientPushFailure
    case addMeasureNewIngredientPushFailure

    // MARK: New Ingredient Flow Supervisor
    case newIngredientEndStateFailure
    case newIngredientTagSelPushStateFailure
    case newIngredientTagSelectionStateFailure

    // MARK: Recipe Flow Supervisor
    case recipeFlowEndStateFailure

    // MARK: New Recipe Flow Supervisor
    case newRecipeEndStateFailure

    // MARK: Add Recipe Step Supervisor
    case addRecipeStepEndFailure

    // MARK: Recipe Step Details Supervisor
    case recipeStepDetailsEndFailure
    
    // MARK: Export Supervisor
    case invalidExportChildEndState

    // MARK: Microsoft Auth Error
    case failedMicrosoftAuthentication

    func showAsAlert(on viewController: UIViewController) {
        let versionString = appVersion()?.filter({ $0 != "."}) ?? ""

        let alert = UIAlertController(
            title: "Error",
            message: "An internal app error has occurred: Code \(versionString).\(self.rawValue).",
            preferredStyle: .alert
        )
        alert.addAction(
            .init(
                title: "Ok",
                style: .default
            )
        )
        viewController.present(
            alert,
            animated: true
        )
    }
}

func appVersion() -> String? {
    Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
}
