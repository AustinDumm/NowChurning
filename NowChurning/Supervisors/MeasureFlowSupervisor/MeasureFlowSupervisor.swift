//
//  MeasureFlowSupervisor.swift
//  NowChurning
//
//  Created by Austin Dumm on 5/14/23.
//

import UIKit
import CoreData
import Factory

protocol MeasureFlowSupervisorParent: ParentSupervisor {
    func didSaveMeasure(withIngredientId id: ID<Ingredient>)
    func navigate(forEditDoneType: EditModeAction.DoneType)
    func switchEditing(toMeasureForIngredientId: ID<Ingredient>)
}

class MeasureFlowSupervisor: NSObject, Supervisor {
    struct Content {
        let detailsContent: MeasureDetailsSupervisor.Content
        let tagSelectorContent: TagSelectorContent
        let measurementEditContent: MeasurementEditSupervisor.Content
    }

    typealias InitialMeasureType = MeasureDetailsSupervisor.InitialMeasureType

    private enum State {
        case measureDetails(
            (MeasureDetailsSupervisor, UIViewController)
        )
        case tagSelector(
            (MeasureDetailsSupervisor, UIViewController),
            IngredientTagSelectorSupervisor
        )
        case measurementEdit(
            (MeasureDetailsSupervisor, UIViewController),
            MeasurementEditSupervisor
        )
    }
    weak var parent: MeasureFlowSupervisorParent?
    private let navigator: StackNavigation

    private var state: State?
    private let content: Content

    private var detailsViewController: UIViewController? {
        switch self.state {
        case .measureDetails((_, let viewController)),
                .tagSelector((_, let viewController), _),
                .measurementEdit((_, let viewController), _):
            return viewController
        case .none:
            return nil
        }
    }

    init(
        parent: MeasureFlowSupervisorParent? = nil,
        navigator: StackNavigation,
        measure: InitialMeasureType,
        measureStore: StockedMeasureListCoreDataStore,
        content: Content,
        completion: (() -> Void)? = nil
    ) {
        self.parent = parent
        self.navigator = navigator
        self.content = content

        super.init()

        let container = UIViewController()
        let supervisor = MeasureDetailsSupervisor(
            container: container,
            navigationItem: container.navigationItem,
            measure: measure,
            listStore: measureStore,
            parent: self,
            content: content.detailsContent
        )

        self.state = .measureDetails(
            (supervisor, container)
        )

        self.navigator
            .pushViewController(
                container,
                withAssociatedNavigationDelegate: self,
                animated: true,
                completion: completion
            )
    }

    func canEnd() -> Bool {
        switch self.state {
        case .measureDetails((let supervisor, _)):
            return supervisor.canEnd()
        case .tagSelector(_, let supervisor):
            return supervisor.canEnd()
        case .measurementEdit(_, let supervisor):
            return supervisor.canEnd()
        case .none:
            return true
        }
    }

    func requestEnd(
        onEnd: @escaping () -> Void
    ) {
        switch self.state {
        case .tagSelector(
            let (supervisor, container),
            _
        ):
            self.navigator.dismiss(animated: true)
            self.state = .measureDetails((supervisor, container))

            fallthrough
        case .measureDetails(let (supervisor, _)):
            supervisor.requestEnd(onEnd: onEnd)
        case .measurementEdit(_, let supervisor):
            return supervisor.requestEnd(onEnd: onEnd)
        case .none:
            break
        }
    }

    private func endSelf() {
        self.parent?
            .childDidEnd(supervisor: self)
    }
}

extension MeasureFlowSupervisor: ParentSupervisor {
    func childDidEnd(supervisor child: Supervisor) {
        switch self.state {
        case .measureDetails(
            (let expected, _)
        ) where expected === child:
            self.endSelf()

        case .tagSelector(
            let measureDetails,
            let expected
        ) where expected === child:
            self.navigator.dismiss(animated: true)
            self.state = .measureDetails(measureDetails)

        case .measurementEdit(
            let measureDetails,
            let expected
        ) where expected === child:
            self.navigator.dismiss(animated: true)
            self.state = .measureDetails(measureDetails)

        default:
            self.handle(
                error: .measureEndStateFailure
            )
        }
    }

    func recover(
        fromError error: AppError,
        on child: Supervisor?
    ) {
        self.handle(error: error)
    }

    private func handle(error: AppError) {
        switch self.state {
        case .measureDetails(let (measureDetails, detailsContainer)),
                .tagSelector(let (measureDetails, detailsContainer), _):
            _ = self.navigator
                .popToViewController(
                    detailsContainer,
                    animated: true
                )
            error.showAsAlert(on: self.navigator)
            self.state = .measureDetails(
                (measureDetails, detailsContainer)
            )
        default:
            self.parent?
                .recover(
                    fromError: error,
                    on: self
                )
        }
    }
}

extension MeasureFlowSupervisor: MeasureDetailsSupervisorParent {
    func requestEditTags(forMeasure measure: Measure) {
        let container = UIViewController()
        let modalNavigation = UINavigationController(rootViewController: container)

        guard
            case .measureDetails(
                let measureDetails
            ) = self.state,
            let supervisor = IngredientTagSelectorSupervisor(
                container: container,
                navigationItem: container.navigationItem,
                initialTags: measure.ingredient.tags,
                parent: self,
                content: self.content.tagSelectorContent
            )
        else {
            self.handle(
                error: .measureTagSelPushStateFailure
            )

            return
        }

        self.state = .tagSelector(
            measureDetails,
            supervisor
        )

        modalNavigation
            .presentationController?
            .delegate = self
        self.navigator
            .present(
                modalNavigation,
                animated: true
            )
    }

    func requestMeasurementEdit(forMeasure measure: Measure) {
        guard case let .measureDetails(detailsPair) = self.state else {
            self.handle(error: .measureMeasurementEditPushStateFailure)
            return
        }

        let container = UIViewController()
        let modalNavigation = UINavigationController(rootViewController: container)
        let editSupervisor = MeasurementEditSupervisor(
            container: container,
            initialMeasure: measure.measure,
            parent: self,
            content: self.content.measurementEditContent
        )

        self.state = .measurementEdit(
            detailsPair,
            editSupervisor
        )

        modalNavigation
            .presentationController?
            .delegate = self
        self.navigator
            .present(
                modalNavigation,
                animated: true
            )
    }

    func navigate(forDoneType doneType: EditModeAction.DoneType) {
        self.parent?.navigate(forEditDoneType: doneType)
    }

    func didSaveMeasure(withIngredientId id: ID<Ingredient>) {
        self.parent?.didSaveMeasure(withIngredientId: id)
    }

    func switchEditing(
        toMeasureForIngredientId ingredientId: ID<Ingredient>
    ) {
        self.parent?.switchEditing(toMeasureForIngredientId: ingredientId)
    }
}

extension MeasureFlowSupervisor: TagSelectorSupervisorParent {
    func didSelect(tags: [Tag<Ingredient>]?) {
        switch self.state {
        case .tagSelector(let (measureDetails, container), _),
                .measureDetails(let (measureDetails, container)):
            self.handleTagUpdate(
                to: tags,
                for: measureDetails,
                in: container
            )
        default:
            self.handle(
                error: .measureTagSelectionStateFailure
            )
        }
    }

    private func handleTagUpdate(
        to tags: [Tag<Ingredient>]?,
        for detailsSupervisor: MeasureDetailsSupervisor,
        in container: UIViewController
    ) {
        if let tags {
            detailsSupervisor
                .setTags(to: tags)
        }

        self.navigator
            .dismiss(animated: true)
        self.state = .measureDetails(
            (detailsSupervisor, container)
        )
    }
}

extension MeasureFlowSupervisor: StackNavigationDelegate {
    func didDisconnectDelegate(fromNavigationController: StackNavigation) {
        self.endSelf()
    }
}

extension MeasureFlowSupervisor: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(
        _ presentationController: UIPresentationController
    ) {
        switch self.state {
        case .tagSelector(let details, _),
                .measurementEdit(let details, _):
            self.state = .measureDetails(details)
        default:
            return
        }
    }
}

extension MeasureFlowSupervisor: MeasurementEditSupervisorParent {
    func updateMeasurement(to measurementType: MeasurementType) {
        switch self.state {
        case .measureDetails((let supervisor, _)),
                .measurementEdit((let supervisor, _), _),
                .tagSelector((let supervisor, _), _):
            supervisor.setMeasurement(to: measurementType)
        case .none:
            break
        }
    }
}
