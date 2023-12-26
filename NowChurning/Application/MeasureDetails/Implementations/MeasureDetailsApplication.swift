//
//  MeasureDetailsApplication.swift
//  NowChurning
//
//  Created by Austin Dumm on 5/14/23.
//

import Foundation

protocol MeasureDetailsApplicationDelegate: AnyObject {
    func requestEditTags(forMeasure: Measure)
    func requestMeasurementEdit(forMeasure: Measure)

    func navigate(forEditDoneType: EditModeAction.DoneType)
    func exit()
    func switchEditing(toMeasureForIngredientId: ID<Ingredient>)
    func didSaveMeasure(withIngredientId id: ID<Ingredient>)
}

class MeasureDetailsApplication {
    struct Content {
        var invalidityText: (Measure.InvalidityReason) -> String
        var existingNameInvalidDescription: String
        var existingNameInvalidSuggestion: String
    }

    // MARK: Display Dependencies
    weak var displayModelSink: MeasureDetailsDisplayModelSink? {
        didSet {
            self.onSetMeasureDisplayModelSink()
            self.editModeHelper
                .editModeDisplayModelSink = displayModelSink
        }
    }


    // MARK: Persistance Dependencies
    weak var domainModelStore: MeasureStoreActionSink?


    // MARK: Local Models
    private let editModeHelper: EditModeHelper<MeasureDetailsApplication>
    private var ingredientLookup = [String: ID<Ingredient>]()
    private let content: Content

    private var hasEditedSet = Set<PartialKeyPath<Measure>>()

    weak var delegate: MeasureDetailsApplicationDelegate?

    var hasChanges: Bool {
        self.editModeHelper.hasChanges
    }

    init(
        content: Content,
        delegate: MeasureDetailsApplicationDelegate? = nil
    ) {
        self.content = content
        self.editModeHelper = .init(initialModel: .init(
            ingredient: .init(
                name: "",
                description: "",
                tags: []
            ),
            measure: .any
        ))
        self.editModeHelper.delegate = self
        self.delegate = delegate
    }

    func setTags(_ tags: [Tag<Ingredient>]) {
        if self.editModeHelper.isEditing {
            self.hasEditedSet.insert(\.ingredient.tags)
        }

        self.editModeHelper
            .updateActiveModel { model in
                model.ingredient.tags = tags
            }
    }

    func setMeasure(measure: Measure) {
        self.editModeHelper
            .updateActiveModel { model in
                model = measure
            }
    }

    func setMeasurement(measurement: MeasurementType) {
        self.editModeHelper
            .updateActiveModel { model in
                model.measure = measurement
            }
    }

    // MARK: DidSet Event Handlers
    private func onSetMeasureDisplayModelSink() {
        self.sendMeasureDisplayModel(
            model: self.editModeHelper.activeModel()
        )
    }

    // MARK: Senders
    private func sendMeasureDisplayModel(model: Measure) {
        self.displayModelSink?
            .send(measureDisplayModel: Self.displayModel(
                fromDomainModel: model,
                hasEditedSet: self.hasEditedSet,
                ingredientLookup: self.ingredientLookup,
                content: self.content
            ))
    }
}

// MARK: Model Transforms
extension MeasureDetailsApplication {
    private static func displayModel(
        fromDomainModel domainModel: Measure,
        hasEditedSet: Set<PartialKeyPath<Measure>>,
        ingredientLookup: [String: ID<Ingredient>],
        content: Content
    ) -> MeasureDetailsDisplayModel {
        let ingredient = domainModel.ingredient
        let invalidityReasons = domainModel.invalidityReasons

        let name: ValidatedData<String>
        if invalidityReasons.contains(.invalidIngredient(.emptyName)) && hasEditedSet.contains(\.ingredient.name) {
            name = .invalid(
                ingredient.name,
                .init(error: content.invalidityText(.invalidIngredient(.emptyName)))
            )
        } else if !Self.isNameUnique(
            model: domainModel,
            allIngredientLookup: ingredientLookup
        ) && hasEditedSet.contains(\.ingredient.name) {
            name = .invalid(
                ingredient.name,
                .init(
                    error: content.existingNameInvalidDescription,
                    suggestion: "\(content.existingNameInvalidSuggestion) \"\(ingredient.name)\""
                )
            )
        } else {
            name = .valid(ingredient.name)
        }

        return MeasureDetailsDisplayModel(
            name: name,
            description: ingredient.description,
            tagNames: ingredient.tags.map { $0.name },
            measurementDescription: self.measurementDescription(
                fromDomainModel: domainModel.measure
            )
        )
    }

    private static func measurementDescription(
        fromDomainModel measurement: MeasurementType
    ) -> String? {
        switch measurement {
        case .volume(let measurement):
            return MeasurementFormatter
                .volumeFormatter
                .string(from: measurement)
        case .count(let measurement, let description):
            return [
                NumberFormatter
                    .countFormatter
                    .string(from: measurement.value as NSNumber),
                description
            ].compactMap { $0 }.joined(separator: " ")
        case .any:
            return nil
        }
    }
}

extension MeasureDetailsApplication: EditModeHelperDelegate {
    func sendDisplayModel(
        fromDomain model: Measure,
        isEditing: Bool
    ) {
        let displayModel = Self.displayModel(
            fromDomainModel: model,
            hasEditedSet: self.hasEditedSet,
            ingredientLookup: self.ingredientLookup,
            content: self.content
        )

        self.displayModelSink?
            .send(
                measureDisplayModel: displayModel
            )
    }

    func onEditEnd(withDoneType doneType: EditModeAction.DoneType) {
        if doneType == .save {
            self.delegate?.didSaveMeasure(
                withIngredientId: self
                    .editModeHelper
                    .activeModel()
                    .ingredient.id
            )
        }

        self.delegate?
            .navigate(forEditDoneType: doneType)
    }

    func isValid(model: Measure) -> Bool {
        model.isValid && Self.isNameUnique(
            model: model,
            allIngredientLookup: self.ingredientLookup
        )
    }

    func save(model: Measure) {
        self.domainModelStore?
            .send(
                action: .save(measure: model)
            )
    }

    private static func isNameUnique(
        model: Measure,
        allIngredientLookup: [String: ID<Ingredient>]
    ) -> Bool {
        allIngredientLookup[model.ingredient.name.lowercased()].map {
            $0 == model.ingredient.id
        } ?? true
    }
}

extension MeasureDetailsApplication: MeasureDomainModelSink {
    func send(
        domainModel: Measure,
        ingredientNameLookup: [String: ID<Ingredient>]
    ) {
        self.editModeHelper
            .updateStoredModel(toData: domainModel)
        self.ingredientLookup = ingredientNameLookup
    }
}

extension MeasureDetailsApplication: MeasureDetailsActionSink {
    func send(
        editModeAction action: EditModeAction
    ) {
        if case .startEditing = action {
            self.hasEditedSet = []
        }

        self.editModeHelper
            .send(editModeAction: action)
    }

    func send(
        measureAction action: MeasureDetailsAction
    ) {
        switch action {
        case .edit(let edit):
            switch edit {
            case .name(let name):
                self.hasEditedSet.insert(\.ingredient.name)
                self.editModeHelper.updateActiveModel { model in
                    model.ingredient.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
                }
            case .description(let description):
                self.hasEditedSet.insert(\.ingredient.description)
                self.editModeHelper.updateActiveModel { model in
                    model.ingredient.description = description.trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
        case .action(let action):
            switch action {
            case .addTag:
                self.delegate?.requestEditTags(
                    forMeasure: self.editModeHelper.activeModel())
            case .editMeasurement:
                self.delegate?.requestMeasurementEdit(
                    forMeasure: self.editModeHelper.activeModel()
                )
            case .exit:
                self.delegate?.exit()
            case .nameFooterTap:
                self.handleNameFooterTap()
            }
        }
    }

    func cancelEditing(
        confirmAction: @escaping () -> Void
    ) {
        self.editModeHelper.cancelEditing(completion: confirmAction)
    }

    private func handleNameFooterTap() {
        guard
            let matchingId = self.ingredientLookup[self.editModeHelper
                .activeModel()
                .ingredient
                .name
                .lowercased()]
        else {
            return
        }

        self.delegate?.switchEditing(toMeasureForIngredientId: matchingId)
    }
}
