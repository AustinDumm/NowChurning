//
//  RecipeStepEditApplication.swift
//  NowChurning
//
//  Created by Austin Dumm on 7/8/23.
//

import Foundation

protocol RecipeStepEditApplicationDelegate: AnyObject {
    func didEnd()
    func edit(ingredient: Ingredient)
    func edit(tags: [Tag<Ingredient>])
    func edit(measurement: MeasurementType)
}

class RecipeStepEditApplication {
    struct Content {
        let anyMeasureDescription: String
        let countMeasureDescription: String
        let volumeMeasureDescription: String

        let byIngredientName: String
        let byTagName: String
        let instructionName: String
    }

    weak var displaySink: RecipeStepEditDisplayModelSink? {
        didSet {
            self.updateDisplayModel()
        }
    }

    weak var storeSink: RecipeStepEditStoreActionSink?
    weak var delegate: RecipeStepEditApplicationDelegate?

    private let content: Content

    private var originalStep: RecipeDetails.Step?
    private var step: RecipeDetails.Step?

    init(
        content: Content
    ) {
        self.content = content
    }

    private func updateDisplayModel() {
        guard let step else { return }

        self.displaySink?.send(
            displayModel: self.displayModel(fromStep: step)
        )
    }
}

// MARK: Model Transforms
extension RecipeStepEditApplication {
    private func displayModel(
        fromStep step: RecipeDetails.Step
    ) -> RecipeStepEditDisplayModel {
        switch step {
        case .ingredient(let measure):
            return self.displayModel(fromMeasure: measure)
        case .ingredientTags(let tags, let measurementType):
            return self.displayModel(fromTags: tags, measurement: measurementType)
        case .instruction(let instruction):
            return self.displayModel(fromInstruction: instruction)
        }
    }

    private func displayModel(
        fromMeasure measure: Measure
    ) -> RecipeStepEditDisplayModel {
        .init(
            stepTypeName: self.content.byIngredientName,
            stepName: measure.ingredient.name,
            isStepNameEditable: false,
            measurementDescription: self.measurementDescription(from: measure.measure)
        )
    }

    private func displayModel(
        fromTags tags: [Tag<Ingredient>],
        measurement: MeasurementType
    ) -> RecipeStepEditDisplayModel {
        .init(
            stepTypeName: self.content.byTagName,
            stepName: tags
                .map { $0.name }
                .joined(separator: ", "),
            isStepNameEditable: false,
            measurementDescription: self.measurementDescription(from: measurement)
        )
    }

    private func displayModel(
        fromInstruction instruction: String
    ) -> RecipeStepEditDisplayModel {
        .init(
            stepTypeName: self.content.instructionName,
            stepName: instruction,
            isStepNameEditable: true,
            measurementDescription: nil
        )
    }

    private func measurementDescription(from measureType: MeasurementType) -> String {
        switch measureType {
        case .volume(let measurement):
            return self.volumeDescription(from: measurement)
        case .count(let measurement, let description):
            return self.countDescription(
                from: measurement,
                unitDescription: description
            )
        case .any:
            return self.content.anyMeasureDescription
        }
    }

    private func volumeDescription(from volume: Measurement<UnitVolume>) -> String {
        "\(self.content.volumeMeasureDescription) - \(MeasurementFormatter.volumeFormatter.string(from: volume))"
    }

    private func countDescription(
        from count: Measurement<Unit>,
        unitDescription: String?
    ) -> String {
        ["\(self.content.countMeasureDescription) - \(MeasurementFormatter.countFormatter.string(from: count))",
         unitDescription
        ].compactMap { $0 }.joined(separator: " ")
    }
}

extension RecipeStepEditApplication: RecipeStepEditActionSink {
    func send(action: RecipeStepEditAction) {
        switch action {
        case .editMainStepData:
            self.handleEditMainStepData()

        case .mainStepTextEdit(let newText):
            self.handleMainStepTextEdit(to: newText)

        case .editMeasurement:
            self.handleEditMeasurement()

        case .cancelEdit:
            self.handleCancel()

        case .finishEdit:
            guard let step else { return }
            self.storeSink?.send(action: .saveStep(step))
            self.delegate?.didEnd()
        }
    }

    private func handleEditMainStepData() {
        switch self.step {
        case .ingredient(let measure):
            self.delegate?.edit(ingredient: measure.ingredient)
        case .ingredientTags(let tags, _):
            self.delegate?.edit(tags: tags)
        case .instruction, .none:
            break
        }
    }

    private func handleMainStepTextEdit(to newText: String) {
        switch self.step {
        case .instruction:
            self.step = .instruction(newText)
        case .ingredient, .ingredientTags, .none:
            break
        }

        self.updateDisplayModel()
    }

    private func handleEditMeasurement() {
        switch self.step {
        case .ingredient(let measure):
            self.delegate?.edit(measurement: measure.measure)
        case .ingredientTags(_, let measurement):
            self.delegate?.edit(measurement: measurement)
        case .instruction, .none:
            break
        }
    }

    private func handleCancel() {
        if self.step != originalStep {
            self.displaySink?.showCancelAlert { [weak self] in
                self?.delegate?.didEnd()
            }
        } else {
            self.delegate?.didEnd()
        }
    }
}

extension RecipeStepEditApplication: RecipeStepEditDomainModelSink {
    func send(step: RecipeDetails.Step) {
        if self.step == nil {
            self.originalStep = step
        }

        self.step = step
        self.updateDisplayModel()
    }

    func send(ingredient: Ingredient) {
        guard case .ingredient(var measure) = self.step else {
            return
        }

        measure.ingredient = ingredient
        self.step = .ingredient(measure)

        self.updateDisplayModel()
    }

    func send(tags: [Tag<Ingredient>]) {
        guard case .ingredientTags(_, let measurement) = self.step else {
            return
        }

        self.step = .ingredientTags(tags, measurement)

        self.updateDisplayModel()
    }

    func send(measurement: MeasurementType) {
        switch self.step {
        case .ingredient(var measure):
            measure.measure = measurement
            self.step = .ingredient(measure)

        case .ingredientTags(let tags, _):
            self.step = .ingredientTags(tags, measurement)

        case .instruction, .none:
            break
        }

        self.updateDisplayModel()
    }
}
