//
//  MeasureListApplication.swift
//  NowChurning
//
//  Created by Austin Dumm on 5/13/23.
//

import Foundation

protocol MeasureListApplicationDelegate: AnyObject {
    func navigateToDetails(forMeasure: Measure)
    func navigateToAddMeasure()
}

class MeasureListApplication {
    weak var displayModelSink: MeasureListDisplayModelSink? {
        didSet {
            self.sendDisplayModel(
                forModel: self.editModeHelper.activeModel()
            )
            self.editModeHelper
                .editModeDisplayModelSink = displayModelSink
        }
    }

    weak var storeActionSink: MeasureListStoreActionSink?
    weak var delegate: MeasureListApplicationDelegate?

    private let editModeHelper: EditModeHelper<MeasureListApplication>

    init() {
        self.editModeHelper = .init(initialModel: [])

        self.editModeHelper.delegate = self
    }

    private func sendDisplayModel(forModel measureList: [Measure]) {
        self.displayModelSink?
            .send(
                displayModel: Self.displayModel(
                    fromDomainModel: measureList
                )
            )
    }

    func scrollToMeasure(withIngredientId id: ID<Ingredient>) {
        guard
            let measure = self.editModeHelper.activeModel().first(where: { measure in
                measure.ingredient.id == id
            }),
            let (section, item) = indices(for: measure)
        else {
            return
        }

        self.displayModelSink?.scrollTo(section: section, item: item)
    }

    private func indices(
        for measure: Measure
    ) -> (section: Int, item: Int)? {
        let model = self.editModeHelper.activeModel()
        let displayModel = Self.displayModel(fromDomainModel: model)

        guard
            let sectionIndex = displayModel.sections.firstIndex(where: { section in
                section.title.lowercased() == String(measure.ingredient.name.first!).lowercased()
            }),
            let itemIndex = displayModel.sections[sectionIndex].items.firstIndex(where: { item in
                item.id == measure.ingredient.id.convert()
            })
        else {
            return nil
        }

        return (section: sectionIndex, item: itemIndex)
    }
}

// MARK: Model Transforms
extension MeasureListApplication {
    private static func displayModel(
        fromDomainModel measureList: [Measure]
    ) -> MeasureListDisplayModel {
        let groupedList = Self.groupedModel(fromDomainModel: measureList)

        return .init(
            sections: groupedList
                .map { (title, items) in
                    .init(
                        title: title,
                        items: items.map {
                            .init(
                                title: $0.ingredient.name,
                                id: $0.ingredient.id.convert()
                            )
                        }
                    )
                }
        )
    }

    private static func groupedModel(
        fromDomainModel measureList: [Measure]
    ) -> [(String, [Measure])] {
        let groupedList = Dictionary(
            grouping: measureList) { element in
                String(element.ingredient.name.first!)
            }

        return groupedList
            .map { ($0.key, $0.value.sorted()) }
            .sorted { $0.0 < $1.0 }
    }
}

extension MeasureListApplication: MeasureListDomainModelSink {
    func send(domainModel: [Measure]) {
        self.editModeHelper
            .updateStoredModel(toData: domainModel)
    }
}

extension MeasureListApplication: MeasureListActionSink {
    func send(action: MeasureListAction) {
        switch action {
        case .selectMeasure(
            atIndex: let index,
            inSection: let section
        ):
            self.selectMeasure(
                atIndex: index,
                inSection: section
            )

        case .deleteMeasure(
            atIndex: let index,
            inSection: let section
        ):
            self.deleteMeasure(
                atIndex: index,
                inSection: section
            )

        case .newMeasure:
            self.delegate?
                .navigateToAddMeasure()
        }
    }

    func send(editModeAction: EditModeAction) {
        self.editModeHelper
            .send(editModeAction: editModeAction)
    }

    private func selectMeasure(
        atIndex index: Int,
        inSection section: Int
    ) {
        guard let measure = self.measure(
            atIndex: index,
            inSection: section
        ) else {
            return
        }

        self.delegate?.navigateToDetails(forMeasure: measure)
    }

    private func deleteMeasure(
        atIndex index: Int,
        inSection section: Int
    ) {
        guard
            let measure = self.measure(atIndex: index, inSection: section),
            let domainIndex = self.editModeHelper
                .activeModel()
                .firstIndex(of: measure)
        else {
            return
        }

        self.editModeHelper.isEditing = true
        self.editModeHelper
            .updateActiveModel { model in
                model.remove(at: domainIndex)
            }
    }

    private func measure(
        atIndex index: Int,
        inSection section: Int
    ) -> Measure? {
        let groupedModel = Self.groupedModel(
            fromDomainModel: self.editModeHelper.activeModel()
        )

        guard
            let section = groupedModel[safe: section]?.1
        else {
            return nil
        }

        return section[safe: index]
    }
}

extension MeasureListApplication: EditModeHelperDelegate {
    func sendDisplayModel(
        fromDomain model: [Measure],
        isEditing _: Bool
    ) {
        self.sendDisplayModel(forModel: model)
    }

    func onEditEnd(withDoneType: EditModeAction.DoneType) {}

    func isValid(model: [Measure]) -> Bool {
        true
    }

    func save(model: [Measure]) {
        self.storeActionSink?
            .send(
                action: .save(
                    measures: model,
                    saver: self
                )
            )
    }
}
