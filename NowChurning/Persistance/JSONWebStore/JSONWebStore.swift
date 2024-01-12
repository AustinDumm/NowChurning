//
//  JSONWebStore.swift
//  NowChurning
//
//  Created by Austin Dumm on 1/11/24.
//

import Foundation
import Alamofire

protocol JSONWebStoreDelegate: AnyObject {
    associatedtype Response: Codable
    func uploadResult(result: Result<Response, JSONWebStoreError>)
}
enum JSONWebStoreError: Swift.Error {
    case encoding(String)
    case upload(String)
}

class JSONWebStore<Delegate: JSONWebStoreDelegate> {

    struct Payload: Codable {
        var ingredientTags: [PayloadIngredientTag]
        var ingredients: [PayloadIngredient]
        var recipes: [PayloadRecipe]
    }

    struct PayloadIngredientTag: Codable {
        var name: String
    }

    struct PayloadIngredient: Codable {
        var uuid: UUID
        var name: String
        var description: String
        var tagsIndices: [Int]
    }

    struct PayloadRecipe: Codable {
        var uuid: UUID
        var name: String
        var description: String
        var recipeSteps: [PayloadRecipeStep]
    }

    enum PayloadRecipeStep: Codable {
        case ingredient(PayloadMeasure)
        case ingredientTag([Int], PayloadMeasureType)
        case instruction(String)
    }

    struct PayloadMeasure: Codable {
        var ingredientIndex: Int
        var measureType: PayloadMeasureType
    }

    enum PayloadMeasureType: Codable {
        case volume(Measurement<UnitVolume>)
        case count(Measurement<Unit>, String?)
        case any
    }

    weak var delegate: Delegate?

    private let authToken: String
    private let uploadEndpoint: String

    init(
        delegate: Delegate? = nil,
        authToken: String,
        uploadEndpoint: String
    ) {
        self.delegate = delegate
        self.authToken = authToken
        self.uploadEndpoint = uploadEndpoint
    }

    struct DomainModel {
        var tags: [Tag<Ingredient>]
        var ingredients: [Ingredient]
        var recipes: [Recipe]
    }
    func upload(model: DomainModel) {
        let payload = Self.payload(from: model)
        let jsonEncoder = JSONEncoder()

        do {
            let data = try jsonEncoder.encode(payload)
            AF.upload(
                data,
                to: self.uploadEndpoint,
                method: .put,
                headers: .init([
                    .authorization(bearerToken: self.authToken),
                    .contentType("text/plain")
                ])
            ).responseDecodable(
                of: Delegate.Response.self
            ) { [weak self] response in
                self?.delegate?.uploadResult(
                    result: response
                        .result
                        .mapError {
                            JSONWebStoreError.upload($0.localizedDescription)
                        }
                )
            }
        } catch {
            self.delegate?.uploadResult(result: .failure(.encoding(error.localizedDescription)))
            return
        }
    }

    private static func payload(
        from domainModel: DomainModel
    ) -> Payload {
        let (payloadTags, tagLookup) = Self.payloadTags(from: domainModel.tags)
        let (payloadIngredients, ingredientLookup) = Self.payloadIngredients(
            from: domainModel.ingredients,
            tagLookup: tagLookup
        )
        let payloadRecipes = Self.payloadRecipes(
            from: domainModel.recipes,
            ingredientLookup: ingredientLookup,
            tagLookup: tagLookup
        )

        return .init(
            ingredientTags: payloadTags,
            ingredients: payloadIngredients,
            recipes: payloadRecipes
        )
    }

    private static func payloadTags(
        from domainTags: [Tag<Ingredient>]
    ) -> ([PayloadIngredientTag], [Tag<Ingredient>.ID: Int]) {
        var payload = [PayloadIngredientTag]()
        var lookup = [Tag<Ingredient>.ID: Int]()

        for domainTag in domainTags {
            lookup[domainTag.id] = payload.count
            payload.append(Self.payloadTag(from: domainTag))
        }

        return (payload, lookup)
    }

    private static func payloadTag(
        from domainTag: Tag<Ingredient>
    ) -> PayloadIngredientTag {
        .init(name: domainTag.name)
    }

    private static func payloadIngredients(
        from domainIngredients: [Ingredient],
        tagLookup: [Tag<Ingredient>.ID: Int]
    ) -> ([PayloadIngredient], [Ingredient.ID: Int]) {
        var payload = [PayloadIngredient]()
        var lookup = [Ingredient.ID: Int]()

        for domainIngredient in domainIngredients {
            lookup[domainIngredient.id] = payload.count
            payload.append(Self.payloadIngredient(
                from: domainIngredient,
                tagLookup: tagLookup
            ))
        }

        return (payload, lookup)
    }

    private static func payloadIngredient(
        from domainIngredient: Ingredient,
        tagLookup: [Tag<Ingredient>.ID: Int]
    ) -> PayloadIngredient {
        .init(
            uuid: domainIngredient.id.rawId,
            name: domainIngredient.name,
            description: domainIngredient.description,
            tagsIndices: domainIngredient
                .tags
                .compactMap { tagLookup[$0.id] }
        )
    }

    private static func payloadRecipes(
        from domainRecipes: [Recipe],
        ingredientLookup: [Ingredient.ID: Int],
        tagLookup: [Tag<Ingredient>.ID: Int]
    ) -> [PayloadRecipe] {
        domainRecipes.map {
            Self.payloadRecipe(
                from: $0,
                ingredientLookup: ingredientLookup,
                tagLookup: tagLookup
            )
        }
    }

    private static func payloadRecipe(
        from domainRecipe: Recipe,
        ingredientLookup: [Ingredient.ID: Int],
        tagLookup: [Tag<Ingredient>.ID: Int]
    ) -> PayloadRecipe {
        .init(
            uuid: domainRecipe.id.rawId,
            name: domainRecipe.name,
            description: domainRecipe.description,
            recipeSteps:
                Self.payloadSteps(
                    from: domainRecipe.recipeDetails?.steps ?? [],
                    ingredientLookup: ingredientLookup,
                    tagLookup: tagLookup
                )
        )
    }

    private static func payloadSteps(
        from domainSteps: [RecipeDetails.Step],
        ingredientLookup: [Ingredient.ID: Int],
        tagLookup: [Tag<Ingredient>.ID: Int]
    ) -> [PayloadRecipeStep] {
        domainSteps.compactMap { step in
            switch step {
            case .ingredient(let measure):
                return Self.payloadIngredientStep(
                    from: measure,
                    ingredientLookup: ingredientLookup
                )

            case .ingredientTags(let tags, let measurementType):
                return Self.payloadIngredientTagStep(
                    from: tags,
                    andMeasurement: measurementType,
                    tagLookup: tagLookup
                )
            case .instruction(let instructionText):
                return .instruction(instructionText)
            }
        }
    }

    private static func payloadIngredientStep(
        from domainMeasure: Measure,
        ingredientLookup: [Ingredient.ID: Int]
    ) -> PayloadRecipeStep? {
        guard
            let ingredientIndex = ingredientLookup[domainMeasure.ingredient.id]
        else {
            return nil
        }

        return .ingredient(.init(
            ingredientIndex: ingredientIndex,
            measureType: Self.payloadMeasureType(from: domainMeasure.measure)
        ))
    }

    private static func payloadIngredientTagStep(
        from tags: [Tag<Ingredient>],
        andMeasurement measurement: MeasurementType,
        tagLookup: [Tag<Ingredient>.ID: Int]
    ) -> PayloadRecipeStep? {
        .ingredientTag(
            tags.compactMap { tagLookup[$0.id] },
            Self.payloadMeasureType(from: measurement)
        )
    }

    private static func payloadMeasureType(
        from domainMeasureType: MeasurementType
    ) -> PayloadMeasureType {
        switch domainMeasureType {
        case .volume(let measurement):
            return .volume(measurement)
        case .count(let measurement, let descriptor):
            return .count(measurement, descriptor)
        case .any:
            return .any
        }
    }
}
