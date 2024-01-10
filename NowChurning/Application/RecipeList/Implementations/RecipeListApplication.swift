//
//  RecipeListApplication.swift
//  NowChurning
//
//  Created by Austin Dumm on 3/3/23.
//

import Foundation

protocol RecipeListApplicationDelegate: AnyObject {
    func navigateToDetails(forRecipe: Recipe)

    func navigateToAddRecipe()

    func export(recipes: [Recipe])
}

class RecipeListApplication {
    weak var displayModelSink: RecipeListDisplayModelSink? {
        didSet {
            self.updateDisplayModelSink(
                fromModel: self.editModeHelper.activeModel()
            )
            self.editModeHelper.editModeDisplayModelSink = displayModelSink
        }
    }

    weak var storeActionSink: RecipeListStoreActionSink?
    weak var delegate: RecipeListApplicationDelegate?

    private let editModeHelper: EditModeHelper<RecipeListApplication>

    var hasChanges: Bool {
        self.editModeHelper.hasChanges
    }

    init(delegate: RecipeListApplicationDelegate? = nil) {
        self.delegate = delegate
        self.editModeHelper = .init(initialModel: [])
        self.editModeHelper.delegate = self
    }

    func scrollTo(recipe: Recipe) {
        let displayModel = Self.displayModel(fromDomainModel: self.editModeHelper.activeModel())

        guard
            let sectionIndex = displayModel.recipeSections.firstIndex(where: { section in
                section.title.lowercased() == recipe.name.first!.lowercased()
            }),
            let itemIndex = displayModel.recipeSections[sectionIndex].items.firstIndex(where: { item in
                item.id == recipe.id.convert()
            })
        else {
            return
        }

        self.displayModelSink?.scrollTo(
            section: sectionIndex, 
            item: itemIndex
        )
    }

    private func updateDisplayModelSink(
        fromModel recipeList: [Recipe]
    ) {
        self.displayModelSink?
            .send(
                displayModel: Self.displayModel(
                    fromDomainModel: recipeList
                )
            )
    }

    private func updateEditModeSink() {
        self.displayModelSink?
            .send(
                editModeDisplayModel: .init(
                    isEditing: self.editModeHelper.isEditing,
                    canSave: self.hasChanges
                )
            )
    }
}

// MARK: Model Transforms
extension RecipeListApplication {
    private static func displayModel(
        fromDomainModel domainModel: [Recipe]
    ) -> RecipeListDisplayModel {
        let grouped = self.groupModel(domainModel)
        let sections: [RecipeListDisplayModel.Section] = grouped
            .map { (initialCharacter, model) in
                .init(
                    title: initialCharacter,
                    items: model
                        .map { recipe in
                            .init(
                                id: recipe.id.convert(),
                                title: recipe.name
                            )
                        }
                )
            }

        return .init(
            recipeSections: sections
                .sorted(by: { lhs, rhs in
                    lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
                })
        )
    }

    private static func groupModel(
        _ domainModel: [Recipe]
    ) -> [(String, [Recipe])] {
        let groupedDictionary = Dictionary(
            grouping: domainModel) { recipe in
                recipe.name
                    .first?
                    .uppercased() ?? ""
            }

        return groupedDictionary
            .map { (initialCharacter, recipes) in
                (initialCharacter, recipes.sorted(by: { lhs, rhs in
                    lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
                }))
            }
            .sorted { lhs, rhs in
                lhs.0.localizedCaseInsensitiveCompare(rhs.0) == .orderedAscending
            }
    }
}

extension RecipeListApplication: RecipeListActionSink {
    func send(action: RecipeListAction) {
        switch action {
        case .selectedItem(
            inSection: let section,
            atIndex: let index
        ):
            let groupedModel = Self.groupModel(self.editModeHelper.activeModel())
            guard
                let section = groupedModel[safe: section],
                let model = section.1[safe: index]
            else {
                return
            }

            self.delegate?.navigateToDetails(forRecipe: model)

        case .deleteItem(
            inSection: let section,
            atIndex: let index
        ):
            let model = self.editModeHelper.activeModel()
            let grouped = Self.groupModel(
                model
            )
            guard
                let section = grouped[safe: section]?.1,
                let item = section[safe: index],
                let index = model.firstIndex(of: item)
            else {
                return
            }

            self.editModeHelper.isEditing = true
            self.editModeHelper
                .updateActiveModel { model in
                        model.remove(at: index)
                    }

        case .newRecipe:
            self.delegate?
                .navigateToAddRecipe()

        case .exportRecipes(let exportGroupedIndices):
            let groupedModel = Self.groupModel(self.editModeHelper.activeModel())
            let recipesToExport = exportGroupedIndices
                .compactMap { groupedModel[safe: $0.section]?.1[safe: $0.index] }

            self.delegate?.export(recipes: recipesToExport)
        }
    }

    func send(editModeAction: EditModeAction) {
        self.editModeHelper
            .send(editModeAction: editModeAction)
    }

    private func confirmEditCancel() {
        self.editModeHelper
            .cancelEditing()
    }
}

extension RecipeListApplication: RecipeListDomainModelSink {
    func send(domainModel: [Recipe]) {
        self.editModeHelper
            .updateStoredModel(toData: domainModel)
    }
}

extension RecipeListApplication: EditModeHelperDelegate {
    func sendDisplayModel(
        fromDomain recipeList: [Recipe],
        isEditing: Bool
    ) {
        self.updateDisplayModelSink(
            fromModel: recipeList
        )
    }

    func onEditEnd(withDoneType: EditModeAction.DoneType) {}

    func isValid(model: [Recipe]) -> Bool {
        true
    }

    func save(model: [Recipe]) {
        self.storeActionSink?
            .send(
                storeAction: .save(
                    recipes: model,
                    saver: self
                )
            )
    }
}
