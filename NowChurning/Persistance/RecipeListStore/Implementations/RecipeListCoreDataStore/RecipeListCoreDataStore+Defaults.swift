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

        let cocoaPowder = Ingredient(
            name: "Unsweetened Cocoa Powder",
            description: "",
            tags: [tags.chocolate, tags.flavoring]
        )

        let dutchCocoaPowder = Ingredient(
            name: "Dutch Process Cocoa Powder",
            description: "",
            tags: [tags.chocolate, tags.flavoring]
        )

        let basil = Ingredient(
            name: "Basil Leaves",
            description: "",
            tags: [tags.floral, tags.flavoring]
        )

        let water = Ingredient(
            name: "Water",
            description: "",
            tags: []
        )

        let butter = Ingredient(
            name: "Butter",
            description: "",
            tags: [tags.dairy]
        )

        let miniPeanutButterCups = Ingredient(
            name: "Mini Peanut Butter Cups",
            description: "",
            tags: [tags.candy, tags.mixin]
        )

        let lightCornSyrup = Ingredient(
            name: "Light Corn Syrup",
            description: "",
            tags: [tags.sweetener]
        )

        let toffeeBar = Ingredient(
            name: "Toffee Nut Candy Bar",
            description: "",
            tags: [tags.candy, tags.mixin]
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
            ),
            .init(
                name: "Chocolate Ice Cream",
                description: "Classic base extension to traditional ice cream. Perfect on its own or with mixins.",
                recipeDetails: .init(steps: [
                    .instruction("1 Recipe of the Custard Base"),
                    .ingredient(.init(
                        ingredient: cocoaPowder,
                        measure: .volume(.init(value: 0.5, unit: .cups))
                    )),
                    .instruction("Add the cocoa powder gradually to the dairy while heating before continuing with the custard base recipe.")
                ])
            ),
            .init(
                name: "Basil Ice Cream",
                description: "Italian herbal ice cream, perfect for warm days. Pair with citrus for a refreshing treat.",
                recipeDetails: .init(steps: [
                    .instruction("1 Recipe any base ice cream"),
                    .ingredient(.init(
                        ingredient: basil,
                        measure: .count(
                            .init(value: 0.5, unit: .count),
                            "Bundle"
                        ))
                    ),
                    .instruction("Blanch the basil in a pot of salited water before squeezing and draining."),
                    .instruction("Chop or blend the basil and add to the dairy while heating (or let steep in the dairy overnight for a no-cook base). Strain the dairy mix to remove pieces of the basil before continuing with base recipe.")
                ])
            ),
            .init(
                name: "Salted Candy Swirl",
                description: "Classic mixin pairings with salted caramel and peanut butter cups.",
                recipeDetails: .init(steps: [
                    .instruction("1 Custard Base Recipe"),
                    .ingredient(.init(
                        ingredient: water,
                        measure: .volume(.init(value: 0.25, unit: .cups))
                    )),
                    .ingredient(.init(
                        ingredient: granulatedSugar,
                        measure: .volume(.init(value: 1.0, unit: .cups))
                    )),
                    .ingredient(.init(
                        ingredient: heavyCream,
                        measure: .volume(.init(value: 0.5, unit: .cups))
                    )),
                    .ingredient(.init(
                        ingredient: butter,
                        measure: .volume(.init(value: 0.5, unit: .cups))
                    )),
                    .ingredient(.init(
                        ingredient: salt,
                        measure: .volume(.init(value: 1.0, unit: .teaspoons))
                    )),
                    .instruction("Dissolve the water and sugar over medium heat and boil until it forms a syrup and turns into a light amber color. Remove from heat and slowly whisk in the room temperature heavy cream then butter and sea salt."),
                    .instruction("Add the peanut butter cups to the churning base ice cream a few minutes before the churn is done."),
                    .instruction("Fold the cooled caramel sauce into the soft ice cream after taking it out of the machine, before freezing.")
                ])
            ),
            .init(
                name: "Chocolate Overload",
                description: "",
                recipeDetails: .init(steps: [
                    .instruction("1 Recipe Chocolate Ice Cream Base"),
                    .ingredient(.init(
                        ingredient: granulatedSugar,
                        measure: .volume(.init(value: 0.5, unit: .cups))
                    )),
                    .ingredient(.init(
                        ingredient: lightCornSyrup,
                        measure: .volume(.init(value: 0.33, unit: .cups))
                    )),
                    .ingredient(.init(
                        ingredient: water,
                        measure: .volume(.init(value: 0.5, unit: .cups))
                    )),
                    .ingredient(.init(
                        ingredient: dutchCocoaPowder,
                        measure: .volume(.init(value: 0.5, unit: .cups))
                    )),
                    .instruction("Add sugar, corn syrup, water, and cocoa powder into a saucier and whisk over medium heat until bubbling. Let bubble for a minute before letting cool, then refridgerate."),
                    .ingredient(.init(
                        ingredient: toffeeBar,
                        measure: .count(.init(value: 2.0, unit: .count), "Bars")
                    )),
                    .instruction("Chop the toffee candy bars and mix into the ice cream during the last few minutes of churning. Fold the fudge swirl into the ice cream after taking it out of the churn before freezing."),
                ])
            )
        ]
    }()
}
