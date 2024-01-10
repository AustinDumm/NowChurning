//
//  TestAppContent.swift
//  NowChurningTests
//
//  Created by Austin Dumm on 4/30/23.
//

import Foundation

@testable import NowChurning

class TestAppContent {
    static let testMainScreenContent = MainScreenSupervisor.Content(
        headerTitle: "Test Header",
        tilesContent: testMainTilesContent
    )

    static let testInventoryContent = InventorySupervisor.Content(
        barListContent: testBarListContent,
        measureListContent: .init(presentationContent: testMeasureListContent),
        editDetailsContent: testEditMeasureDetailsContent,
        addMeasureContent: addMeasureFlowContent,
        navigateAlert: testAlertContent
    )

    static let testMyRecipesContent = RecipesSupervisor.Content(
        recipeListContent: testRecipeListContent,
        editDetailsContent: testRecipeDetailsContent,
        createRecipeContent: testRecipeDetailsContent
    )

    static let testMainTilesContent = MainScreenApplication.Content(
        inventoryTitle: "Test My Bar",
        myRecipesTitle: "Test Recipes"
    )

    static let testAlertContent = AlertContent(
        descriptionText: "Test Description",
        confirmText: "Test Confirm",
        cancelText: "Test Cancel"
    )

    static let testBarListContent = IngredientListSupervisor.Content(
        listTitle: "Test List Title",
        alertContent: testAlertContent,
        emptyListMessage: "Test Empty"
    )

    static let testReadOnlyIngredientListContent = ReadOnlyUnstockedIngredientListSupervisor.Content(
        listTitle: "Test List Title",
        addIngredientInstruction: "Test Add Ingredient",
        ingredientSectionsHeader: "Test Suggestions"
    )

    static let testMeasureListContent = MeasureListItemListPresentation.Content(
        title: "Test Measure List",
        alertContent: testAlertContent,
        listInstruction: "Test Empty",
        editListDescription: "Test Edit List",
        addToInventoryDescription: "Test Add"
    )

    static let addMeasureFlowContent = AddMeasureFlowSupervisor.Content(
        ingredientListContent: testReadOnlyIngredientListContent,
        measureFlowSupervisorContent: testEditMeasureDetailsContent,
        measurementEditContent: testMeasurementEditContent
    )

    static let testMeasureApplicationContent = MeasureDetailsApplication.Content(
        invalidityText: { reason in
            switch reason {
            case .invalidMeasure(.negativeCount):
                return "Test Negative Count"
            case .invalidMeasure(.negativeVolume):
                return "Test Negative Volume"
            case .invalidIngredient(.emptyName):
                return "Test Emtpy Name"
            }
        },
        existingNameInvalidDescription: "Test Name Already Exists",
        existingNameInvalidSuggestion: "Test Name Already Suggestions"
    )
    static let testMeasureDetailsContent = MeasureDetailsItemListPresentation.Content(
        sectionTitles: testMeasureDetailsSectionContent,
        headerTitle: "Test Measure Details",
        alertContainer: testAlertContent,
        ingredientDetailsContent: testIngredientPartialPresentationContent,
        unspecifiedMeasurementText: "Test Measurement Unspecified"
    )

    static let testMeasureDetailsSectionContent = MeasureDetailsItemListPresentation.SectionTitles(
        nameLabelText: "Test Name",
        descriptionLabelText: "Test Description",
        tagsLabelText: "Test Tags",
        editTagsLabelText: "Test Edit",
        measurementSectionText: "Test In Stock",
        requiredSectionSuffix: "Test Required",
        optionalSectionSuffix: "Test Optional"
    )

    static let testIngredientDetailsSectionContent = IngredientPartialItemListPresentation.SectionTitles(
        nameLabelText: "Test Name",
        descriptionLabelText: "Test Description",
        tagsLabelText: "Test Tags",
        editTagsLabelText: "Test Edit",
        requiredSectionSuffix: "Test Required"
    )

    static let testIngredientDetailsApplicationContent = IngredientDetailsApplication.Content(
        invalidityText: { reason in
            switch reason {
            case .emptyName:
                return "Test Empty Name"
            }
        },
        existingNameInvalidDescription: "Test Existing Name",
        existingNameInvalidSuggestion: "Test Existing Name Suggestion"
    )

    static let testIngredientPartialPresentationContent = IngredientPartialItemListPresentation.Content(
        sectionTitles: testIngredientDetailsSectionContent,
        headerTitle: "Test Header",
        editDescription: "Test Edit Ingredient",
        alertContainer: testAlertContent
    )

    static let testIngredientDetailsPresentationContent = IngredientDetailsItemListPresentation.Content(
        partialContent: testIngredientPartialPresentationContent,
        addToInventoryButtonText: "Test Add To Inventory"
    )

    static let testIngredientDetailsContent = IngredientDetailsSupervisor.Content(
        applicationContent: testIngredientDetailsApplicationContent,
        presentationContent: testIngredientDetailsPresentationContent
    )

    static let testTagSelectorContent = TagSelectorContent(
        barTitle: "Test Tag"
    )

    static let testEditIngredientDetailsContent = IngredientFlowSupervisor.Content(
        detailsContent: testIngredientDetailsContent,
        tagSelectorContent: testTagSelectorContent
    )

    static let testEditMeasureDetailsContent = MeasureFlowSupervisor.Content(
        detailsContent: .init(
            applicationContent: testMeasureApplicationContent,
            presentationContent: testMeasureDetailsContent
        ),
        tagSelectorContent: testTagSelectorContent,
        measurementEditContent: testMeasurementEditContent
    )

    static let testMeasurementEditContent = MeasurementEditSupervisor.Content(
        applicationContent: testMeasurementEditApplication,
        presentationContent: testMeasurementEditPresentation
    )

    static let testRecipeListContent = RecipeListSupervisor.Content(
        listTitle: "Test List",
        alertContent: testAlertContent,
        emptyListMessage: "Test Empty",
        addNewRecipeText: "Test Add New",
        editListText: "Test Edit List",
        exportListText: "Test Export List",
        exportingListTitle: "Test Export Title"
    )

    static let testRecipeApplicationContent = RecipeDetailsApplication.Content(
        invalidityText: { reason in
            switch reason {
            case .emptyName:
                return "Test Empty Name"
            }
        },
        byTagPrefix: "Test Tag Prefix",
        byTagEmpty: "Test Tag Empty"
    )

    static let testRecipePresentationContent = RecipeDetailsItemListPresentation.Content(
        sectionTitles: testRecipeSectionsContent,
        editingHeaderTitle: "Test Edit",
        addStepCellTitle: "Test Add Step",
        unstockedMessage: "Test Unstocked",
        unstockedResolution: "Test Resolution",
        alertContent: testAlertContent
    )

    static let testRecipeSectionsContent = RecipeDetailsItemListPresentation.SectionTitles(
        nameLabelText: "Test Name",
        descriptionLabelText: "Test Description",
        recipeLabelText: "Test Recipe",
        requiredSectionSuffix: "Test Required"
    )

    static let testRecipeDetailsContent = RecipeFlowSupervisor.Content(
        recipeDetailsContent: .init(
            applicationContent: testRecipeApplicationContent,
            presentationContent: testRecipePresentationContent
        ),
        previewContent: .init(
            measurePreviewContent: .init(
                applicationContent: testMeasureApplicationContent,
                presentationContent: testMeasureDetailsContent,
                screenTitle: "Test Screen Title",
                editSwitchAlert: testAlertContent
            ),
            ingredientFlowContent: .init(
                detailsContent: .init(
                    applicationContent: testIngredientDetailsApplicationContent,
                    presentationContent: testIngredientDetailsPresentationContent
                ),
                tagSelectorContent: testTagSelectorContent
            ),
            tagPreviewContent: .init(
                presentationContent: .init(
                    listTitle: "Test List Title",
                    alertContent: testAlertContent,
                    emptyListMessage: "Test Empty"
                ),
                openIngredientAlert: testAlertContent,
                addIngredientAlert: testAlertContent,
                title: "Test Title"
            ),
            addStockAlert: testAlertContent
        ),
        addStepContent: .init(
            addRecipeStepTitle: "Test Add Step",
            ingredientStepName: "Test Ingredient Step",
            byTagStepName: "Test Tag Step",
            instructionStepName: "Test Instruction Step",
            ingredientListContent: testReadOnlyIngredientListContent,
            measurementEditContent: testMeasurementEditContent,
            newMeasurementContent: testStorelessMeasureFlowContent,
            instructionEntryContent: testInstructionEntryContent,
            tagContent: testTagSelectorContent
        ),
        editStepContent: .init(
            ingredientRecipeStepContent: testRecipeStepContent,
            byTagsRecipeStepContent: testRecipeStepContent,
            instructionStepContent: testRecipeStepContent,
            ingredientListContent: testReadOnlyIngredientListContent,
            tagSelectorContent: testTagSelectorContent,
            measurementContent: testMeasurementEditContent
        )
    )

    static let testRecipeStepContent = RecipeStepDetailsSupervisor.Content(
        application: .init(
            anyMeasureDescription: "Test Any Measure",
            countMeasureDescription: "Test Count Measure",
            volumeMeasureDescription: "Test Volume Measure",
            byIngredientName: "Test Ingredient",
            byTagName: "Test Tag",
            instructionName: "Test Instruction"
        ),
        presentation: .init(
            sectionTitles: .init(
                measurementSection: "Test Measurement Section"
            ),
            screenTitle: "Test Screen Title",
            cancelAlert: testAlertContent
        )
    )

    static let testInstructionEntryContent = InstructionEntrySupervisor.Content(
        instructionTitle: "Test Instruction",
        screenTitle: "Test Instruction Title",
        cancelEditAlert: testAlertContent
    )

    static let testStorelessMeasureFlowContent = StorelessMeasureFlowSupervisor.Content(
        detailsContent: .init(
            applicationContent: testMeasureApplicationContent,
            presentationContent: testMeasureDetailsContent
        ),
        tagSelectorContent: testTagSelectorContent,
        measurementEditContent: testMeasurementEditContent
    )

    static let testMainFlowContent = MainFlowSupervisor.Content(
        mainScreenContent: testMainScreenContent,
        inventoryContent: testInventoryContent,
        myRecipesContent: testMyRecipesContent
    )

    static let testMeasurementEditApplication = MeasurementEditApplication.Content(
        anyMeasurementDescription: "Test Unspecified",
        volumeMeasurementDescription: "Test By Volume",
        countMeasurementDescription: "Test By Count",
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
    )

    static let testMeasurementEditPresentation = MeasurementEditFormListPresentation.Content(
        itemTitles: .init(
            typeTitle: "Test Type",
            valueTitle: "Test Amount",
            unitTitle: "Test Units",
            descriptionTitle: "Test Description"
        ),
        screenTitle: "Test Screen Title",
        unspecifiedOptionText: "Test Unspecified",
        volumeOptionText: "Test Volume",
        countOptionText: "Test Count",
        cancelAlert: testAlertContent
    )
}
