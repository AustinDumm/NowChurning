//
//  ExportSupervisor.swift
//  NowChurning
//
//  Created by Austin Dumm on 1/10/24.
//

import UIKit

class ExportSupervisor: NSObject, Supervisor {
    weak var parent: ParentSupervisor?

    private enum State {
        case authentication(MicrosoftAuthSupervisor)
        case upload(JSONWebStore<ExportSupervisor>, UploadProgressViewController)
    }

    private var state: State

    private let navigation: SegmentedNavigationController
    private let recipesToExport: [Recipe]

    init(
        recipesToExport: [Recipe],
        navigation: SegmentedNavigationController,
        parent: ParentSupervisor? = nil
    ) {
        self.recipesToExport = recipesToExport
        self.navigation = navigation
        self.parent = parent

        let container = UIViewController()
        let authentication = MicrosoftAuthSupervisor(container: container)
        self.state = .authentication(authentication)

        super.init()

        authentication.parent = self
        self.navigation.pushViewController(
            container,
            startingNewSegmentWithDelegate: self,
            animated: true,
            completion: {
                authentication.start()
            }
        )
    }
}

extension ExportSupervisor: ParentSupervisor {
    func childDidEnd(
        supervisor: Supervisor
    ) {
        switch self.state {
        case .authentication(let child)
            where child === supervisor:
            self.navigation.dismiss(animated: true)
            self.parent?.childDidEnd(supervisor: self)

        default:
            self.parent?.recover(fromError: .invalidExportChildEndState, on: self)
        }
    }

    func recover(
        fromError error: AppError,
        on child: Supervisor?
    ) {
        self.navigation.dismiss(animated: true)
        self.parent?.recover(fromError: error, on: child)
    }
}

extension ExportSupervisor: MicrosoftAuthSupervisorParent {
    private static let uploadDomain = "https://graph.microsoft.com/v1.0"
    private static let uploadPath = "/me/drive/root:/NowChurning/exported.json:/content"
    func didAuthenticate(
        token: String,
        identifier: String?
    ) {
        let uploadViewController = UploadProgressViewController()
        uploadViewController.setState(.uploading)
        uploadViewController.confirmCallback = { [weak self, parent] in
            guard
                let self
            else {
                parent?.recover(
                    fromError: .invalidExportChildEndState,
                    on: nil
                )
                return
            }

            self.parent?.childDidEnd(supervisor: self)
        }

        self.navigation.setViewControllers(
            [uploadViewController],
            animated: true
        )

        let store = JSONWebStore(
            delegate: self,
            authToken: token,
            uploadEndpoint: "\(Self.uploadDomain)\(Self.uploadPath)"
        )
        store.delegate = self
        store.upload(model: self.collectUploadModel())
        self.state = .upload(store, uploadViewController)
    }

    private func collectUploadModel() -> JSONWebStore<ExportSupervisor>.DomainModel {
        var tagSet = Set<Tag<Ingredient>>()
        var ingredientSet = [Ingredient.ID: Ingredient]()

        for recipesToExport in self.recipesToExport {
            for step in recipesToExport.recipeDetails?.steps ?? [] {
                switch step {
                case .ingredient(let measure):
                    ingredientSet[measure.ingredient.id] = measure.ingredient
                    for tag in measure.ingredient.tags {
                        tagSet.insert(tag)
                    }

                case .ingredientTags(let tags, _):
                    for tag in tags {
                        tagSet.insert(tag)
                    }

                case .instruction:
                    break
                }
            }
        }

        return .init(
            tags: Array(tagSet),
            ingredients: Array(ingredientSet.values),
            recipes: self.recipesToExport
        )
    }
}

extension ExportSupervisor: JSONWebStoreDelegate {
    struct MicrosoftResponse: Codable {
        var id: String
        var name: String
        var size: Int
    }
    typealias Response = MicrosoftResponse

    func uploadResult(
        result: Result<MicrosoftResponse, JSONWebStoreError>
    ) {
        guard case let .upload(_, progressViewController) = self.state else {
            self.parent?.childDidEnd(supervisor: self)
            return
        }

        switch result {
        case .success:
            progressViewController.setState(.done)
        case .failure:
            progressViewController.setState(.failed)
        }
    }
}

extension ExportSupervisor: SegmentedNavigationControllerDelegate {
    func didDisconnectDelegate(
        fromNavigationController: SegmentedNavigationController
    ) {
        self.parent?.childDidEnd(supervisor: self)
    }
}
