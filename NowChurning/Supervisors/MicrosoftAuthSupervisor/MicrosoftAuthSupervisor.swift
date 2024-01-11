//
//  MicrosoftAuthSupervisor.swift
//  NowChurning
//
//  Created by Austin Dumm on 1/10/24.
//

import UIKit
import MSAL

protocol MicrosoftAuthSupervisorParent: ParentSupervisor {
    func didAuthenticate(
        token: String,
        identifier: String?
    )
}

class MicrosoftAuthSupervisor: Supervisor {
    // Microsoft scope definition for what the user is consenting the app to access
    private static let scopes = ["files.readwrite"]

    weak var parent: MicrosoftAuthSupervisorParent?

    private weak var container: UIViewController?

    init(
        container: UIViewController,
        parent: MicrosoftAuthSupervisorParent? = nil
    ) {
        self.parent = parent
        self.container = container

        self.container?.insetChild(
            AuthenticationPlaceholderViewController()
        )
    }

    func start() {
        guard
            let authority = try? MSALAuthority(
                url: URL(string: MicrosoftSecrets.authority)!
            ),
            let parent = self.parent
        else {
            return
        }

        let configuration = MSALPublicClientApplicationConfig(
            clientId: MicrosoftSecrets.clientID,
            redirectUri: MicrosoftSecrets.redirectUri,
            authority: authority
        )

        guard
            let application = try? MSALPublicClientApplication(
                configuration: configuration
            ),
            let container = container
        else {
            parent.recover(fromError: .failedMicrosoftAuthentication, on: self)
            return
        }

        let webviewParameters = MSALWebviewParameters(
            authPresentationViewController: container
        )
        let interactiveParameters = MSALInteractiveTokenParameters(
            scopes: Self.scopes,
            webviewParameters: webviewParameters
        )

        application.acquireToken(
            with: interactiveParameters
        ) { result, error in
            guard
                let authResult = result,
                error == nil
            else {
                parent.recover(fromError: .failedMicrosoftAuthentication, on: self)
                return
            }

            let accessToken = authResult.accessToken
            let accountIdentifier = authResult.account.identifier
            parent.didAuthenticate(
                token: accessToken,
                identifier: accountIdentifier
            )
        }
    }
}
