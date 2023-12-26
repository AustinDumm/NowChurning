//
//  AppContent.swift
//  NowChurning
//
//  Created by Austin Dumm on 12/18/22.
//

import Foundation

// swiftlint:disable:next type_body_length
struct AppContent {
    static let englishContent = MainFlowSupervisor.Content(
        mainScreenContent: .init(
            headerTitle: "app_title".localized(),
            tilesContent: .init(
                inventoryTitle: "ingredients_area_title".localized(),
                myRecipesTitle: "recipes_area_title".localized()
            )
        ),
        inventoryContent: .init(
            barListContent: .init(
                listTitle: "ingredients_area_title".localized(),
                alertContent: Self.editCancel,
                emptyListMessage: "inventory_instruction".localized()
            ),
            measureListContent: .init(
                presentationContent: .init(
                    title: "ingredients_area_title".localized(),
                    alertContent: Self.editCancel,
                    listInstruction: "inventory_instruction".localized(),
                    editListDescription: "inventory_edit_list_action".localized(),
                    addToInventoryDescription: "inventory_add_item_action".localized()
                )
            ),
            editDetailsContent: .init(
                detailsContent: .init(
                    applicationContent: .init(
                        invalidityText: { reason in
                            switch reason {
                            case .invalidIngredient(.emptyName):
                                return "ingredient_invalid_empty_name".localized()
                            case .invalidMeasure:
                                return ""
                            }
                        },
                        existingNameInvalidDescription: "ingredient_name_already_exists".localized(),
                        existingNameInvalidSuggestion: "ingredient_name_already_exists_suggestion".localized()
                    ),
                    presentationContent: .init(
                        sectionTitles: Self.measureDetailsTitles,
                        headerTitle: "editing_state_text".localized(),
                        alertContainer: Self.editCancel,
                        ingredientDetailsContent: .init(
                            sectionTitles: Self.ingredientDetailsTitles,
                            headerTitle: "editing_state_text".localized(),
                            editDescription: "edit_ingredient_action".localized(),
                            alertContainer: Self.editCancel
                        ),
                        unspecifiedMeasurementText: "measure_any_measurement_description".localized()
                    )
                ),
                tagSelectorContent: Self.ingredientTagSelector,
                measurementEditContent: Self.measurementEditContent
            ),
            addMeasureContent: Self.addMeasureFlowContent,
            navigateAlert: .init(
                descriptionText: "inventory_navigate_description".localized(),
                confirmText: "inventory_navigate_confirm".localized(),
                cancelText: "inventory_navigate_cancel".localized()
            )
        ),
        myRecipesContent: .init(
            recipeListContent: .init(
                listTitle: "recipes_area_title".localized(),
                alertContent: Self.editCancel,
                emptyListMessage: "my_recipes_empty_message".localized(),
                addNewRecipeText: "recipe_list_add_new_recipe".localized(),
                editListText: "recipe_list_edit_list".localized()
            ),
            editDetailsContent: .init(
                recipeDetailsContent: .init(
                    applicationContent: .init(
                        invalidityText: { reason in
                            switch reason {
                            case .emptyName:
                                return "recipe_invalid_empty_name".localized()
                            }
                        },
                        byTagPrefix: "recipe_by_tag_recipe_prefix".localized(),
                        byTagEmpty: "recipe_by_tag_anything".localized()
                    ),
                    presentationContent: .init(
                        sectionTitles: Self.recipeDetailsTitles,
                        editingHeaderTitle: "editing_state_text".localized(),
                        addStepCellTitle: "recipe_add_step_cell_title".localized(),
                        unstockedMessage: "recipe_recipe_unstocked_alert".localized(),
                        unstockedResolution: "recipe_recipe_unstocked_resolution".localized(),
                        alertContent: Self.editCancel
                    )
                ),
                previewContent: Self.recipeStepPreviewContent,
                addStepContent: Self.addRecipeStepContent,
                editStepContent: Self.editStepContent
            ),
            createRecipeContent: .init(
                recipeDetailsContent: .init(
                    applicationContent: .init(
                        invalidityText: { reason in
                            switch reason {
                            case .emptyName:
                                return "recipe_invalid_empty_name".localized()
                            }
                        },
                        byTagPrefix: "recipe_by_tag_recipe_prefix".localized(),
                        byTagEmpty: "recipe_by_tag_anything".localized()
                    ),
                    presentationContent: .init(
                        sectionTitles: Self.recipeDetailsTitles,
                        editingHeaderTitle: "creating_recipe_state_text".localized(),
                        addStepCellTitle: "recipe_add_step_cell_title".localized(),
                        unstockedMessage: "recipe_recipe_unstocked_alert".localized(),
                        unstockedResolution: "recipe_recipe_unstocked_resolution".localized(),
                        alertContent: .init(
                            descriptionText: "creating_recipe_discard_message".localized(),
                            confirmText: "creating_recipe_discard_confirm_prompt".localized(),
                            cancelText: "editing_discard_cancel_prompt".localized()
                        )
                    )
                ),
                previewContent: Self.recipeStepPreviewContent,
                addStepContent: Self.addRecipeStepContent,
                editStepContent: Self.editStepContent
            )
        )
    )

    private static let addRecipeStepContent = AddRecipeStepSupervisor.Content(
        addRecipeStepTitle: "add_step_title".localized(),
        ingredientStepName: "add_step_ingredient_name".localized(),
        byTagStepName: "add_step_by_tag_name".localized(),
        instructionStepName: "add_instruction_name".localized(),
        ingredientListContent: Self.addStepIngredientListContent,
        measurementEditContent: Self.measurementEditContent,
        newMeasurementContent: Self.addRecipeStepNewIngredientContent,
        instructionEntryContent: Self.instructionEntryContent,
        tagContent: Self.ingredientTagSelector
    )

    private static let instructionEntryContent = InstructionEntrySupervisor.Content(
        instructionTitle: "instruction_header_text".localized(),
        screenTitle: "create_instruction_screen_text".localized(),
        cancelEditAlert: Self.genericCancel
    )

    private static let addRecipeStepNewIngredientContent = StorelessMeasureFlowSupervisor.Content(
        detailsContent: Self.addRecipeStepMeasureDetailsContent,
        tagSelectorContent: Self.ingredientTagSelector,
        measurementEditContent: Self.measurementEditContent
    )

    private static let measurePreviewContent = MeasurePreviewSupervisor.Content(
        applicationContent: measureDetailsApplication,
        presentationContent: measureDetailsPresentation,
        screenTitle: "ingredients_area_title".localized(),
        editSwitchAlert: myRecipesToInventorySwitchAlert
    )

    private static let editStepContent = EditRecipeStepSupervisor.Content(
        ingredientRecipeStepContent: Self.ingredientRecipeStepContent,
        byTagsRecipeStepContent: Self.tagsRecipeStepContent,
        instructionStepContent: Self.instructionRecipeStepContent,
        ingredientListContent: Self.addMeasureIngredientListContent,
        tagSelectorContent: Self.ingredientTagSelector,
        measurementContent: Self.measurementEditContent
    )

    private static let ingredientRecipeStepContent = RecipeStepDetailsSupervisor.Content(
        application: .init(
            anyMeasureDescription: "measure_any_measurement_description".localized(),
            countMeasureDescription: "measure_count_measurement_description".localized(),
            volumeMeasureDescription: "measure_volume_measurement_description".localized(),
            byIngredientName: "ingredient_name_header_text".localized(),
            byTagName: "by_tags_name_header_text".localized(),
            instructionName: "instruction_header_text".localized()
        ),
        presentation: .init(
            sectionTitles: .init(
                measurementSection: "measurement_name_header_text".localized()
            ),
            screenTitle: "edit_ingredient_step_title".localized(),
            cancelAlert: Self.genericCancel
        )
    )

    private static let tagsRecipeStepContent = RecipeStepDetailsSupervisor.Content(
        application: .init(
            anyMeasureDescription: "measure_any_measurement_description".localized(),
            countMeasureDescription: "measure_count_measurement_description".localized(),
            volumeMeasureDescription: "measure_volume_measurement_description".localized(),
            byIngredientName: "ingredient_name_header_text".localized(),
            byTagName: "by_tags_name_header_text".localized(),
            instructionName: "instruction_header_text".localized()
        ),
        presentation: .init(
            sectionTitles: .init(
                measurementSection: "measurement_name_header_text".localized()
            ),
            screenTitle: "edit_by_tags_step_title".localized(),
            cancelAlert: Self.genericCancel
        )
    )

    private static let instructionRecipeStepContent = RecipeStepDetailsSupervisor.Content(
        application: .init(
            anyMeasureDescription: "measure_any_measurement_description".localized(),
            countMeasureDescription: "measure_count_measurement_description".localized(),
            volumeMeasureDescription: "measure_volume_measurement_description".localized(),
            byIngredientName: "ingredient_name_header_text".localized(),
            byTagName: "by_tags_name_header_text".localized(),
            instructionName: "instruction_header_text".localized()
        ),
        presentation: .init(
            sectionTitles: .init(
                measurementSection: "measurement_name_header_text".localized()
            ),
            screenTitle: "edit_instruction_step_title".localized(),
            cancelAlert: Self.genericCancel
        )
    )

    private static let genericCancel = AlertContent(
        descriptionText: "generic_cancel_alert_description".localized(),
        confirmText: "generic_cancel_alert_confirm".localized(),
        cancelText: "generic_cancel_alert_cancel".localized()
    )

    private static let switchToAddIngredientAlert = AlertContent(
        descriptionText: "my_recipes_add_switch_to_inventory".localized(),
        confirmText: "my_recipes_preview_switch_confirm".localized(),
        cancelText: "my_recipes_preview_switch_cancel".localized()
    )

    private static let tagPreviewContent = TagFilteredIngredientListSupervisor.Content(
        presentationContent: .init(
            listTitle: "ingredient_by_tag_title".localized(),
            alertContent: .init(descriptionText: "", confirmText: "", cancelText: ""),
            emptyListMessage: "tag_filtered_ingredients_empty_message".localized()
        ),
        openIngredientAlert: myRecipesToInventorySwitchAlert,
        addIngredientAlert: tagPreviewCreateIngredientAlert,
        title: "ingredient_by_tag_title".localized()
    )

    private static let tagPreviewCreateIngredientAlert = AlertContent(
        descriptionText: "tag_filtered_create_ingredient_alert_description".localized(),
        confirmText: "tag_filtered_create_ingredient_alert_confirm".localized(),
        cancelText: "tag_filtered_create_ingredient_alert_cancel".localized()
    )

    private static let myRecipesToInventorySwitchAlert = AlertContent(
        descriptionText: "my_recipes_preview_switch_to_inventory".localized(),
        confirmText: "my_recipes_preview_switch_confirm".localized(),
        cancelText: "my_recipes_preview_switch_cancel".localized()
    )

    private static let ingredientDetailsTitles = IngredientPartialItemListPresentation
        .SectionTitles(
            nameLabelText: "item_list_name_header_text".localized(),
            descriptionLabelText: "item_list_description_header_text".localized(),
            tagsLabelText: "item_list_tags_header_text".localized(),
            editTagsLabelText: "item_list_edit_tags_prompt".localized(),
            requiredSectionSuffix: "item_list_required_section_suffix".localized()
        )

    private static let measureDetailsTitles = MeasureDetailsItemListPresentation.SectionTitles(
        nameLabelText: "item_list_name_header_text".localized(),
        descriptionLabelText: "item_list_description_header_text".localized(),
        tagsLabelText: "item_list_tags_header_text".localized(),
        editTagsLabelText: "item_list_edit_tags_prompt".localized(),
        measurementSectionText: "inventory_measurement_section_title".localized(),
        requiredSectionSuffix: "item_list_required_section_suffix".localized(),
        optionalSectionSuffix: "item_list_optional_section_suffix".localized()
    )

    private static let addRecipeStepMeasureDetailsTitles = MeasureDetailsItemListPresentation.SectionTitles(
        nameLabelText: "item_list_name_header_text".localized(),
        descriptionLabelText: "item_list_description_header_text".localized(),
        tagsLabelText: "item_list_tags_header_text".localized(),
        editTagsLabelText: "item_list_edit_tags_prompt".localized(),
        measurementSectionText: "recipe_add_amount_section_title".localized(),
        requiredSectionSuffix: "item_list_required_section_suffix".localized(),
        optionalSectionSuffix: "item_list_optional_section_suffix".localized()
    )

    private static let addMeasureFlowContent = AddMeasureFlowSupervisor.Content(
        ingredientListContent: addMeasureIngredientListContent,
        measureFlowSupervisorContent: addMeasureMeasureFlowContent,
        measurementEditContent: measurementEditContent
    )

    private static let addMeasureIngredientListContent = ReadOnlyUnstockedIngredientListSupervisor.Content(
        listTitle: "inventory_add_header".localized(),
        addIngredientInstruction: "inventory_add_new_ingredient".localized(),
        ingredientSectionsHeader: "inventory_ingredients_sections_header".localized()
    )

    private static let addStepIngredientListContent = ReadOnlyIngredientListSupervisor.Content(
        listTitle: "add_step_ingredient_list_title".localized(),
        addIngredientInstruction: "recipe_add_new_ingredient_cell".localized(),
        ingredientSectionsHeader: "inventory_ingredients_sections_header".localized()
    )

    private static let measurementEditContent = MeasurementEditSupervisor.Content(
        applicationContent: .init(
            anyMeasurementDescription: "measure_any_measurement_description".localized(),
            volumeMeasurementDescription: "measure_volume_measurement_description".localized(),
            countMeasurementDescription: "measure_count_measurement_description".localized(),
            validVolumeUnits: [
                .teaspoons,
                .tablespoons,
                .fluidOunces,
                .cups,
                .milliliters,
                .pints,
                .quarts,
                .liters,
                .gallons,
            ]
        ),
        presentationContent: .init(
            itemTitles: .init(
                typeTitle: "measure_type_title".localized(),
                valueTitle: "measure_value_title".localized(),
                unitTitle: "measure_unit_title".localized(),
                descriptionTitle: "measure_description_title".localized()
            ),
            screenTitle: "measure_screen_title".localized(),
            unspecifiedOptionText: "measure_any_measurement_description".localized(),
            volumeOptionText: "measure_volume_measurement_description".localized(),
            countOptionText: "measure_count_measurement_description".localized(),
            cancelAlert: .init(
                descriptionText: "add_by_measurement_cancel_alert".localized(),
                confirmText: "add_by_measurement_leave".localized(),
                cancelText: "add_by_measurement_stay".localized()
            )
        )
    )

    private static let addMeasureMeasureFlowContent = MeasureFlowSupervisor.Content(
        detailsContent: Self.addMeasureMeasureDetailsContent,
        tagSelectorContent: Self.ingredientTagSelector,
        measurementEditContent: Self.measurementEditContent
    )

    private static let addMeasureMeasureDetailsContent = MeasureDetailsSupervisor.Content(
        applicationContent: measureDetailsApplication,
        presentationContent: measureDetailsPresentation
    )

    private static let addRecipeStepMeasureDetailsContent = MeasureDetailsSupervisor.Content(
        applicationContent: measureDetailsApplication,
        presentationContent: addRecipeStepMeasureDetailsPresentation
    )

    private static let ingredientTagSelector = TagSelectorContent(barTitle: "ingredient_tag_selector_title".localized())

    private static let recipeDetailsTitles = RecipeDetailsItemListPresentation
        .SectionTitles(
            nameLabelText: "item_list_name_header_text".localized(),
            descriptionLabelText: "item_list_description_header_text".localized(),
            recipeLabelText: "item_list_recipe_header_text".localized(),
            requiredSectionSuffix: "item_list_required_section_suffix".localized()
        )

    private static let recipeStepPreviewContent = RecipeStepPreviewSupervisor.Content(
        measurePreviewContent: measurePreviewContent,
        ingredientFlowContent: editFromRecipeIngredientFlowContent,
        tagPreviewContent: tagPreviewContent,
        addStockAlert: recipesAddStockAlert
    )

    private static let editFromRecipeIngredientFlowContent = IngredientFlowSupervisor.Content(
        detailsContent: Self.editFromRecipeIngredientDetailsContent,
        tagSelectorContent: Self.ingredientTagSelector
    )

    private static let editFromRecipeIngredientDetailsContent = IngredientDetailsSupervisor.Content(
        applicationContent: ingredientDetailsApplication,
        presentationContent: ingredientDetailsPresentation
    )

    private static let editCancel = AlertContent(
        descriptionText: "editing_discard_message".localized(),
        confirmText: "editing_discard_confirm_prompt".localized(),
        cancelText: "editing_discard_cancel_prompt".localized()
    )

    private static let createIngredientCancel = AlertContent(
        descriptionText: "creating_ingredient_discard_message".localized(),
        confirmText: "creating_ingredient_discard_confirm_prompt".localized(),
        cancelText: "editing_discard_cancel_prompt".localized()
    )

    private static let createMeasurementCancel = AlertContent(
        descriptionText: "creating_measure_discard_message".localized(),
        confirmText: "creating_measure_discard_confirm_prompt".localized(),
        cancelText: "editing_discard_cancel_prompt".localized()
    )

    private static let measureDetailsApplication = MeasureDetailsApplication.Content(
        invalidityText: { reason in
            switch reason {
            case .invalidIngredient(.emptyName):
                return "ingredient_invalid_empty_name".localized()
            case .invalidMeasure:
                return ""
            }
        },
        existingNameInvalidDescription: "ingredient_name_already_exists".localized(),
        existingNameInvalidSuggestion: "ingredient_name_already_exists_suggestion".localized()
    )

    private static let ingredientDetailsApplication = IngredientDetailsApplication.Content(
        invalidityText: { reason in
            switch reason {
            case .emptyName:
                return "ingredient_invalid_empty_name".localized()
            }
        },
        existingNameInvalidDescription: "ingredient_name_already_exists".localized(),
        existingNameInvalidSuggestion: "ingredient_name_already_exists_suggestion".localized()
    )

    private static let measureDetailsPresentation = MeasureDetailsItemListPresentation.Content(
        sectionTitles: Self.measureDetailsTitles,
        headerTitle: "inventory_add_new_ingredient".localized(),
        alertContainer: Self.createMeasurementCancel,
        ingredientDetailsContent: .init(
            sectionTitles: Self.ingredientDetailsTitles,
            headerTitle: "inventory_add_header".localized(),
            editDescription: "edit_ingredient_action".localized(),
            alertContainer: Self.createMeasurementCancel
        ),
        unspecifiedMeasurementText: "measure_any_measurement_description".localized()
    )

    private static let addRecipeStepMeasureDetailsPresentation = MeasureDetailsItemListPresentation.Content(
        sectionTitles: Self.addRecipeStepMeasureDetailsTitles,
        headerTitle: "recipe_add_ingredient_screen_title".localized(),
        alertContainer: Self.createMeasurementCancel,
        ingredientDetailsContent: .init(
            sectionTitles: Self.ingredientDetailsTitles,
            headerTitle: "recipe_add_ingredient_screen_title".localized(),
            editDescription: "edit_ingredient_action".localized(),
            alertContainer: Self.createMeasurementCancel
        ),
        unspecifiedMeasurementText: "measure_any_measurement_description".localized()
    )

    private static let ingredientDetailsPartialPresentation = IngredientPartialItemListPresentation.Content(
        sectionTitles: Self.ingredientDetailsTitles,
        headerTitle: "",
        editDescription: "edit_ingredient_action".localized(),
        alertContainer: Self.createIngredientCancel
    )

    private static let ingredientDetailsPresentation = IngredientDetailsItemListPresentation.Content(
        partialContent: ingredientDetailsPartialPresentation,
        addToInventoryButtonText: "recipe_recipe_unstocked_resolution".localized()
    )

    private static let recipesAddStockAlert = AlertContent(
        descriptionText: "recipe_add_stock_alert_description".localized(),
        confirmText: "recipe_add_stock_alert_confirm".localized(),
        cancelText: "recipe_add_stock_alert_cancel".localized()
    )
}
