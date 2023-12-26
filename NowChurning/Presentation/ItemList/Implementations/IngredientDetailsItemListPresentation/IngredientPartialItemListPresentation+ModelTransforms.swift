//
//  IngredientPartialItemListPresentation+ModelTransforms.swift
//  NowChurning
//
//  Created by Austin Dumm on 1/1/23.
//

import Foundation

// MARK: Model Transforms
extension IngredientPartialItemListPresentation {
    static func viewModel(
        fromDisplayModel displayModel: IngredientDetailsDisplayModel,
        isEditing: Bool,
        contentContainer: Content
    ) -> ItemListViewModel {
        if isEditing {
            return self.editableViewModel(
                fromDisplayModel: displayModel,
                contentContainer: contentContainer.sectionTitles
            )
        } else {
            return self.readOnlyViewModel(
                fromDisplayModel: displayModel,
                contentContainer: contentContainer.sectionTitles
            )
        }
    }

    static func readOnlyViewModel(
        fromDisplayModel displayModel: IngredientDetailsDisplayModel,
        contentContainer: SectionTitles
    ) -> ItemListViewModel {
        .init(
            sections: [
                readOnlyNameViewModel(
                    fromDisplayModel: displayModel,
                    contentContainer: contentContainer
                ),
                readOnlyDescriptionViewModel(
                    fromDisplayModel: displayModel,
                    contentContainer: contentContainer
                ),
                readOnlyTagsViewModel(
                    fromDisplayModel: displayModel,
                    contentContainer: contentContainer
                )
            ].compactMap { $0 },
            isEditing: false
        )
    }

    private static func readOnlyNameViewModel(
        fromDisplayModel displayModel: IngredientDetailsDisplayModel,
        contentContainer: SectionTitles
    ) -> ItemListViewModel.Section {
        .init(
            title: contentContainer.nameLabelText,
            items: [
                .init(
                    id: Self.viewingId(contentContainer.nameLabelText),
                    type: .text(displayModel.name.data),
                    context: []
                )

            ]
        )
    }

    private static func readOnlyDescriptionViewModel(
        fromDisplayModel displayModel: IngredientDetailsDisplayModel,
        contentContainer: SectionTitles
    ) -> ItemListViewModel.Section? {
        if displayModel.description.isEmpty {
            return nil
        } else {
            return .init(
                title: contentContainer.descriptionLabelText,
                items: [
                    .init(
                        id: Self.viewingId(contentContainer.descriptionLabelText),
                        type: .text(displayModel.description),
                        context: []
                    )
                ]
            )
        }
    }

    private static func readOnlyTagsViewModel(
        fromDisplayModel displayModel: IngredientDetailsDisplayModel,
        contentContainer: SectionTitles
    ) -> ItemListViewModel.Section? {
        if displayModel.tagNames.count == 0 {
            return nil
        } else {
            return .init(
                title: contentContainer.tagsLabelText,
                items: displayModel
                    .tagNames
                    .map { .init(
                        type: .text($0),
                        context: [])
                    }
                )
        }
    }

    static func editableViewModel(
        fromDisplayModel displayModel: IngredientDetailsDisplayModel,
        contentContainer: SectionTitles
    ) -> ItemListViewModel {
        .init(
            sections: [
                .init(
                    title: "\(contentContainer.nameLabelText) \(contentContainer.requiredSectionSuffix)",
                    items: [
                        .init(
                            id: Self.editingId(contentContainer.nameLabelText),
                            type: .editSingleline(
                                displayModel.name.data,
                                purpose: contentContainer.nameLabelText
                            ),
                            context: []
                        )
                    ],
                    footerErrorMessage: displayModel.name.invalidityReason.map {
                        .init(
                            message: $0.error,
                            suggestion: $0.suggestion
                        ) }
                ),
                .init(
                    title: contentContainer.descriptionLabelText,
                    items: [
                        .init(
                            id: Self.editingId(contentContainer.descriptionLabelText),
                            type: .editMultiline(
                                displayModel.description,
                                purpose: contentContainer.descriptionLabelText
                            ),
                            context: []
                        )
                    ]
                ),
                .init(
                    title: contentContainer.tagsLabelText,
                    items: [
                        .init(type: .text(contentContainer.editTagsLabelText),
                              context: [.navigate, .add])
                    ] + displayModel.tagNames
                        .sorted()
                        .map {
                            .init(
                                type: .text($0),
                                indentation: 1,
                                context: []
                            )
                        }
                )
            ],
            isEditing: true
        )
    }

    static func editViewModel(
        fromDisplayModel displayModel: EditModeDisplayModel,
        forItemName name: String,
        shownAsModal: Bool,
        headerTitle: String,
        editButtonDescription: String
    ) -> NavBarViewModel {
        if displayModel.isEditing {
            return .init(
                title: headerTitle,
                leftButtons: [
                    .init(
                        type: .cancel,
                        isEnabled: true
                    )
                ],
                rightButtons: [
                    .init(
                        type: .save,
                        isEnabled: displayModel.canSave
                    )
                ]
            )
        } else {
            return .init(
                title: name,
                leftButtons: [
                    .init(
                        type: shownAsModal ? .done : .back,
                        isEnabled: true
                    )
                ],
                rightButtons: [
                    .init(
                        type: .edit,
                        displayTitle: editButtonDescription,
                        isEnabled: true
                    )
                ]
            )
        }
    }

    static func viewingId(_ id: String) -> String {
        return id + "_view"
    }

    static func editingId(_ id: String) -> String {
        return id + "_edit"
    }
}
