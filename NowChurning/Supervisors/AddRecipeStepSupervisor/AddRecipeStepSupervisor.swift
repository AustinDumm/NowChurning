//
//  AddRecipeStepSupervisor.swift
//  NowChurning
//
//  Created by Austin Dumm on 7/3/23.
//

import UIKit
import Factory

protocol AddRecipeStepSupervisorParent: ParentSupervisor {
    func addIngredientStep(measure: Measure)
    func addByTagStep(
        tags: [Tag<Ingredient>],
        measurementType: MeasurementType
    )
    func addInstructionStep(instruction: String)
}

class AddRecipeStepSupervisor: NSObject, Supervisor {
    struct Content {
        let addRecipeStepTitle: String

        let ingredientStepName: String
        let byTagStepName: String
        let instructionStepName: String

        let ingredientListContent: ReadOnlyIngredientListSupervisor.Content
        let measurementEditContent: MeasurementEditSupervisor.Content
        let newMeasurementContent: StorelessMeasureFlowSupervisor.Content
        let instructionEntryContent: InstructionEntrySupervisor.Content

        let tagContent: TagSelectorContent
    }

    private enum State {
        case typeSelect(ItemListViewController, NavBarManager)

        case ingredientSelect((ReadOnlyIngredientListSupervisor, UIViewController))
        case ingredientMeasurementEdit((Ingredient, MeasurementEditSupervisor, UIViewController))
        case newIngredientEdit(StorelessMeasureFlowSupervisor)

        case tagSelect((IngredientTagSelectorSupervisor, UIViewController))
        case tagMeasurementEdit(([Tag<Ingredient>], MeasurementEditSupervisor, UIViewController))

        case editInstruction((InstructionEntrySupervisor, UIViewController))
    }

    private lazy var adapter = WeakItemListEventAdapter(eventSink: self)

    weak var parent: AddRecipeStepSupervisorParent?

    private let navigator: StackNavigation
    private let content: Content

    private var stateStack = [State]()

    init(
        navigator: StackNavigation,
        parent: AddRecipeStepSupervisorParent? = nil,
        content: Content
    ) {
        self.navigator = navigator

        self.parent = parent
        self.content = content

        super.init()

        let typeSelectController = ItemListViewController(eventSink: self.adapter)
        typeSelectController.send(viewModel: .init(
            sections: [
                .init(
                    title: "",
                    items: [
                        .init(
                            type: .text(content.ingredientStepName),
                            context: [.navigate]
                        ),
                        .init(
                            type: .text(content.byTagStepName),
                            context: [.navigate]
                        ),
                        .init(
                            type: .text(content.instructionStepName),
                            context: [.navigate]
                        )
                    ]
                )
            ],
            isEditing: false
        ))

        self.navigator.pushViewController(
            typeSelectController,
            withAssociatedNavigationDelegate: self,
            animated: true
        )

        let navBarManager = NavBarManager(
            navigationItem: typeSelectController.navigationItem,
            alertViewDelegate: typeSelectController,
            providedButtonBuilder: ProvidedBarButtonBuilder(
                backButton: typeSelectController.navigationItem.backBarButtonItem
            ),
            systemButtonBuilder: NavBarSystemButtonBuilder(),
            eventSink: self.adapter
        )
        navBarManager.send(navBarViewModel: .init(
            title: self.content.addRecipeStepTitle,
            leftButtons: [.init(type: .done, isEnabled: true)],
            rightButtons: []
        ))

        self.stateStack.append(.typeSelect(typeSelectController, navBarManager))
    }

    func canEnd() -> Bool {
        true
    }

    func requestEnd(onEnd: @escaping () -> Void) {
        onEnd()
    }

    private func endSelf() {
        self.parent?.childDidEnd(supervisor: self)
    }
}

extension AddRecipeStepSupervisor: ItemListEventSink, NavBarEventSink {
    func send(event: ItemListEvent) {
        switch event {
        case .select(itemAt: .init(item: 0, section: 0)):
            self.handleIngredientStep()
        case .select(itemAt: .init(item: 1, section: 0)):
            self.handleByTagStep()
        case .select(itemAt: .init(item: 2, section: 0)):
            self.handleInstruction()
        default:
            break
        }
    }

    func send(navBarEvent: NavBarEvent) {
        switch navBarEvent {
        case .tap(.left, index: 0):
            self.endSelf()
        default:
            break
        }
    }

    private func handleIngredientStep() {
        let container = UIViewController()

        guard
            case .typeSelect = self.stateStack.last,
            let listSupervisor = ReadOnlyIngredientListSupervisor(
                container: container,
                navigationItem: container.navigationItem,
                parent: self,
                content: self.content.ingredientListContent
            )
        else {
            return
        }

        self.stateStack.append(.ingredientSelect(
            (listSupervisor, container)
        ))
        self.navigator.pushViewController(container, animated: true)
    }

    private func handleByTagStep() {
        let container = UIViewController()

        guard
            case .typeSelect = self.stateStack.last,
            let tagSelector = IngredientTagSelectorSupervisor(
                container: container,
                navigationItem: container.navigationItem,
                initialTags: [],
                parent: self,
                content: self.content.tagContent
            )
        else {
            return
        }

        self.navigator.pushViewController(container, animated: true)
        self.stateStack.append(.tagSelect((tagSelector, container)))
    }

    private func handleInstruction() {
        let container = UIViewController()
        let supervisor = InstructionEntrySupervisor(
            parent: self,
            container: container,
            content: self.content.instructionEntryContent
        )

        self.navigator.pushViewController(container, animated: true)
        self.stateStack.append(.editInstruction((supervisor, container)))
    }
}

extension AddRecipeStepSupervisor: ParentSupervisor {
    func childDidEnd(supervisor: Supervisor) {
        switch self.stateStack.last {
        case .none, .typeSelect:
            self.endSelf()

        case .ingredientSelect((let expected, _))
            where expected === supervisor:
            self.navigator.popViewController(animated: true)
            _ = self.stateStack.popLast()

        case .ingredientMeasurementEdit((_, let expected, _))
            where expected === supervisor,
                .tagMeasurementEdit((_, let expected, _))
            where expected === supervisor:
            self.navigator.popViewController(animated: true)
            _ = self.stateStack.popLast()

        case .newIngredientEdit(let expected)
            where expected === supervisor:
            self.navigator.popViewController(animated: true)
            _ = self.stateStack.popLast()

        case .editInstruction((let expected, _))
            where expected === supervisor:
            self.navigator.popViewController(animated: true)
            _ = self.stateStack.popLast()

        default:
            self.parent?.recover(
                fromError: .addRecipeStepEndFailure,
                on: self
            )
        }
    }

    func recover(fromError error: AppError, on child: Supervisor?) {}
}

extension AddRecipeStepSupervisor: ReadOnlyIngredientListSupervisorParent {
    func navigateTo(ingredient: Ingredient) {
        guard case .ingredientSelect = self.stateStack.last else {
            return
        }

        var content = self.content.measurementEditContent
        content.presentationContent.screenTitle = ingredient.name

        let container = UIViewController()
        let supervisor = MeasurementEditSupervisor(
            container: container,
            initialMeasure: nil,
            parent: self,
            content: self.content.measurementEditContent
        )
        self.navigator.pushViewController(container, animated: true)
        self.stateStack.append(.ingredientMeasurementEdit(
            (ingredient, supervisor, container)
        ))
    }

    func navigateToAddIngredient() {
        guard
            case .ingredientSelect = self.stateStack.last
        else {
            return
        }

        let supervisor = StorelessMeasureFlowSupervisor(
            parent: self,
            navigator: self.navigator,
            measure: .newIngredient,
            content: self.content.newMeasurementContent
        )
        self.stateStack.append(.newIngredientEdit(supervisor))
    }
}

extension AddRecipeStepSupervisor: MeasurementEditSupervisorParent {
    func updateMeasurement(to measurement: MeasurementType) {
        switch self.stateStack.last {
        case let .ingredientMeasurementEdit(
            (ingredient, _, _)
        ):
            self.handleIngredientMeasurementEdit(
                measurement: measurement,
                ingredient: ingredient
            )
        case let .tagMeasurementEdit((tags, _, _)):
            self.handleTagMeasurementEdit(
                measurement: measurement,
                tags: tags
            )
        default:
            break
        }

    }

    private func handleIngredientMeasurementEdit(
        measurement: MeasurementType,
        ingredient: Ingredient
    ) {
        self.parent?.addIngredientStep(
            measure: .init(ingredient: ingredient, measure: measurement)
        )
        self.endSelf()
    }

    private func handleTagMeasurementEdit(
        measurement: MeasurementType,
        tags: [Tag<Ingredient>]
    ) {
        self.parent?.addByTagStep(
            tags: tags,
            measurementType: measurement
        )

        self.endSelf()
    }
}

extension AddRecipeStepSupervisor:
    StorelessMeasureFlowSupervisorParent {
    func didSubmit(measure: Measure) {
        guard
            case .newIngredientEdit = self.stateStack.last,
            let ingredientListStore = IngredientListCoreDataStore(
                sink: nil,
                storeUser: Container.shared.coreDataUserManager().user,
                managedObjectContext: Container.shared.managedObjectContext()
            )
        else {
            return
        }

        let newIngredientStore = NewIngredientFromListStore(
            modelSink: nil,
            storeSink: ingredientListStore
        )

        newIngredientStore.send(action: .save(ingredient: measure.ingredient))

        self.parent?.addIngredientStep(measure: measure)
    }

    func navigate(forEditDoneType doneType: EditModeAction.DoneType) {
        guard case .newIngredientEdit = self.stateStack.last else {
            return
        }

        switch doneType {
        case .save:
            self.endSelf()
        case .cancel:
            break
        }
    }

    func didSaveMeasure(withIngredientId id: ID<Ingredient>) {}

    func switchEditing(toMeasureForIngredientId id: ID<Ingredient>) {
        guard
            case .newIngredientEdit(let ingredientSupervisor) = self.stateStack.last,
            let ingredient = Container.shared.coreDataUserManager().user.ingredient(forId: id)
        else {
            return
        }

        var content = self.content.measurementEditContent
        content.presentationContent.screenTitle = ingredient.name
        let container = UIViewController()
        let newSupervisor = MeasurementEditSupervisor(
            container: container,
            initialMeasure: nil,
            parent: self,
            content: content
        )

        ingredientSupervisor.requestEnd { [weak self] in
            guard let self else { return }

            _ = self.stateStack.popLast()
            self.navigator.pushViewController(
                container, animated: true
            ) { [weak self] in
                self?.stateStack.append(.ingredientMeasurementEdit(
                    (ingredient, newSupervisor, container)
                ))
            }
        }
    }
}

extension AddRecipeStepSupervisor: TagSelectorSupervisorParent {
    func didSelect(tags: [Tag<Ingredient>]?) {
        guard let tags else {
            _ = self.stateStack.popLast()
            self.navigator.popViewController(animated: true)

            return
        }

        let container = UIViewController()
        let measurementEdit = MeasurementEditSupervisor(
            container: container,
            initialMeasure: nil,
            parent: self,
            content: self.content.measurementEditContent
        )
        self.navigator.pushViewController(container, animated: true)
        self.stateStack.append(.tagMeasurementEdit(
            (tags, measurementEdit, container)
        ))
    }
}

extension AddRecipeStepSupervisor: InstructionEntrySupervisorParent {
    func save(instruction: String) {
        self.parent?.addInstructionStep(instruction: instruction)
        self.parent?.childDidEnd(supervisor: self)
    }
}

extension AddRecipeStepSupervisor: StackNavigationDelegate {
    func didDisconnectDelegate(fromNavigationController: StackNavigation) {
        self.endSelf()
    }
    
    func navigationController(
        _ navigationController: UINavigationController,
        didShow viewController: UIViewController,
        animated: Bool
    ) {
        let expectedController: UIViewController

        switch self.stateStack.last {
        case .typeSelect, .newIngredientEdit, .none:
            return
        case .ingredientSelect((_, let container)),
                .ingredientMeasurementEdit((_, _, let container)),
                .tagSelect((_, let container)),
                .tagMeasurementEdit((_, _, let container)),
                .editInstruction((_, let container)):
            expectedController = container
        }

        if !navigationController
            .viewControllers
            .contains(expectedController) {
            _ = self.stateStack.popLast()
        }
    }
}
