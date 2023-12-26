//
//  MeasurementEditSupervisor.swift
//  NowChurning
//
//  Created by Austin Dumm on 6/4/23.
//

import UIKit

protocol MeasurementEditSupervisorParent: ParentSupervisor {
    func updateMeasurement(to measurementType: MeasurementType)
}

class MeasurementEditSupervisor: Supervisor {
    struct Content {
        var applicationContent: MeasurementEditApplication.Content
        var presentationContent: MeasurementEditFormListPresentation.Content
    }

    weak var parent: MeasurementEditSupervisorParent?

    private let application: MeasurementEditApplication
    private let presentation: MeasurementEditFormListPresentation

    private let view: FormListViewController
    private let navBar: NavBarManager

    private let content: Content

    init(
        container: UIViewController,
        initialMeasure: MeasurementType?,
        parent: MeasurementEditSupervisorParent? = nil,
        content: Content
    ) {
        self.parent = parent
        self.content = content

        self.application = .init(
            initialMeasure: initialMeasure,
            content: content.applicationContent
        )

        self.presentation = .init(
            actionSink: self.application,
            content: content.presentationContent
        )
        self.application.displayModelSink = self.presentation

        self.view = .init(eventSink: self.presentation)
        self.presentation.viewModelSink = self.view
        container.insetChild(self.view)

        self.navBar = .init(
            navigationItem: container.navigationItem,
            alertViewDelegate: container,
            providedButtonBuilder: ProvidedBarButtonBuilder(backButton: container.navigationItem.backBarButtonItem),
            systemButtonBuilder: NavBarSystemButtonBuilder(),
            eventSink: self.presentation
        )
        self.presentation.navBarViewModelSink = self.navBar

        self.application.delegate = self
    }

    func canEnd() -> Bool {
        !self.application.hasChanges()
    }

    func requestEnd(onEnd: @escaping () -> Void) {
        self.application.attemptCancel(onEnd)
    }
}

extension MeasurementEditSupervisor: MeasurementEditDelegate {
    func didEnter(measurement: MeasurementType) {
        self.parent?.updateMeasurement(to: measurement)
        self.parent?.childDidEnd(supervisor: self)
    }

    func didCancel() {
        self.parent?.childDidEnd(supervisor: self)
    }
}
