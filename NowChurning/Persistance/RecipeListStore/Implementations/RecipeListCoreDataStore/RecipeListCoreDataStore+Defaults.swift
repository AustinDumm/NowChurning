//
//  RecipeListCoreDataStore+Defaults.swift
//  NowChurning
//
//  Created by Austin Dumm on 3/7/23.
//

import Foundation

// swiftlint:disable line_length
extension RecipeListCoreDataStore {
    static let defaults: [Recipe] = {
        let tags = DefaultIngredientTagContainer.self

        let heavyCream = Ingredient(
            name: "Heavy Cream",
            description: "Also known as double cream, dairy product with 36% or more milk fat.",
            tags: [tags.dairy]
        )

        let milk = Ingredient(
            name: "Milk",
            description: "Whole (3.5% milk fat) or 2% milk fat dairy product.",
            tags: [tags.dairy]
        )

        let granulatedSugar = Ingredient(
            name: "Granulated Sugar",
            description: "Standard, white sugar.",
            tags: [tags.sweetener]
        )

        let eggYolk = Ingredient(
            name: "Egg Yolk",
            description: "Separated yolk from a chicken egg. Large or extra large.",
            tags: []
        )

        let salt = Ingredient(
            name: "Sea Salt",
            description: "Fine sea salt. Can substitute for Kosher Salt, adjusting to match weight.",
            tags: []
        )

        let vanillaBean = Ingredient(
            name: "Vanilla Bean",
            description: "Processed and dried vanilla pod. Filled with vanilla seeds and the outer pod can be steeped in dairy or soaked in a neutral alcohol to make extract.",
            tags: [tags.flavoring]
        )

        let vanillaExtract = Ingredient(
            name: "Vanilla Extract",
            description: "Vanilla bean pods soaked in a neutral alcohol.",
            tags: [tags.flavoring]
        )

        let strawberry = Ingredient(
            name: "Strawberry",
            description: "",
            tags: [tags.fruit, tags.mixin]
        )

        let freezeDriedStrawberries = Ingredient(
            name: "Freeze-Dried Strawberries",
            description: "",
            tags: [tags.flavoring, tags.fruit]
        )

        return [
            .init(
                name: "Custard Base",
                description: "Rich, creamy base recipe. Built to be augmented with flavorings and mix-ins.",
                recipeDetails: .init(
                    steps: [
                        .ingredient(.init(
                            ingredient: heavyCream,
                            measure: .volume(.init(value: 2.0, unit: .cups))
                        )),
                        .ingredient(.init(
                            ingredient: milk,
                            measure: .volume(.init(value: 1.0, unit: .cups))
                        )),
                        .ingredient(.init(
                            ingredient: granulatedSugar,
                            measure: .volume(.init(value: 0.66, unit: .cups))
                        )),
                        .ingredient(.init(
                            ingredient: salt,
                            measure: .volume(.init(value: 0.125, unit: .teaspoons))
                        )),
                        .ingredient(.init(
                            ingredient: eggYolk,
                            measure: .count(.init(value: 6, unit: .count), nil)
                        )),
                        .instruction("Bring cream, milk, sugar, and salt to a low simmer ensuring the sugar and salt are dissolved. Slowly swhisk one third of the hot dairy mixture into the yolks. Then whisky the egg/dairy mixture back into the pot."),
                        .instruction("Gently cook the mixture until it coats the back of a spoon and reaches 170 degrees."),
                        .instruction("Transfer or strain into a bowl, cover and chill."),
                        .instruction("Churn the chilled mixture in an ice cream machine and freeze."),
                    ]
                )
            ),
            .init(
                name: "No-cook base",
                description: "Simple ice cream base without eggs or the need to cook the mixture.",
                recipeDetails: .init(steps: [
                    .ingredient(.init(
                        ingredient: milk,
                        measure: .volume(.init(value: 1.0, unit: .cups))
                    )),
                    .ingredient(.init(
                        ingredient: heavyCream,
                        measure: .volume(.init(value: 1.0, unit: .cups))
                    )),
                    .ingredient(.init(
                        ingredient: granulatedSugar,
                        measure: .volume(.init(value: 0.33, unit: .cups))
                    )),
                    .instruction("Whisk the milk, heavy cream, and sugar ensuring the sugar is dissvoled. Churn immediately or chill mixture until ready to churn. Freeze after churning is complete.")
                ])
            ),
            .init(
                name: "Vanilla Ice Cream",
                description: "Simple and classic, vanilla ice cream works on its own or as a base for mixins.",
                recipeDetails: .init(steps: [
                    .instruction("Any base ice cream recipe"),
                    .ingredient(.init(
                        ingredient: vanillaBean,
                        measure: .count(.init(value: 2.0, unit: .count), "beans")
                    )),
                    .ingredient(.init(
                        ingredient: vanillaExtract,
                        measure: .volume(.init(value: 2.0, unit: .teaspoons))
                    )),
                    .instruction("Scrape the contents of the vanilla bean into the dairy used. If heating the dairy, drop the vanilla pods into the milk while warming to steep the pods. Strain the pods out before churning. Add the vanilla extract before churning just after removing the mixture from the heat.")
                ])
            ),
            .init(
                name: "Strawbery Ice Cream",
                description: "Classic fruit ice cream. Perfect for summer sundaes or neopolitan ice cream.",
                recipeDetails: .init(steps: [
                    .instruction("Any base ice cream recipe"),
                    .ingredient(.init(
                        ingredient: freezeDriedStrawberries,
                        measure: .volume(.init(value: 2.0, unit: .cups))
                    )),
                    .instruction("Blend the 2 cups of freeze-dried strawberries into a powder. Add the freeze-dried strawberries when returning the dairy mixture to the stovetop (or just before churning, if using a no-cook base)."),
                    .ingredient(.init(
                        ingredient: strawberry,
                        measure: .volume(.init(value: 0.5, unit: .cups))
                    )),
                    .instruction("Chop the fresh strawberries and serve as garnish over the fresh ice cream or mixed into the ice cream near the end of the churning for fully frozen ice cream.")
                ])
            )
        ]
    }()
}
