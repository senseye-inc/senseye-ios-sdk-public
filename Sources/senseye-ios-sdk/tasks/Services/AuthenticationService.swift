//
//  AuthenticationService.swift
//  
//
//  Created by Bobby Srisan on 2/17/22.
//

import Amplify
import SwiftUI
import Foundation
import AWSCognitoAuthPlugin
import AWSDataStorePlugin
import AWSS3StoragePlugin
import AWSPluginsCore

protocol AuthenticationServiceProtocol {
    func signOut(completeSignOut: (()->())? )
    func signIn(accountUsername: String, accountPassword: String)
    func getUsername(completion: @escaping ((String) -> Void))
    var delegate: AuthenticationServiceDelegate? { get set }
    var authError: AlertItem? { get }
    var authErrorPublished: Published<AlertItem?> { get}
    var authErrorPublisher: Published<AlertItem?>.Publisher { get }
}

protocol AuthenticationServiceDelegate: AnyObject {
    func didConfirmNewUser()
    func didSuccessfullySignIn()
    func didSuccessfullySignOut()
}

/**
 The AuthenticationService for the SDK  lets developers authenticate sessions through Senseye's backend  service.
 */
public class AuthenticationService: ObservableObject {
    
    weak var delegate: AuthenticationServiceDelegate?
    @Published var authError: AlertItem? = nil
    var authErrorPublished: Published<AlertItem?> { _authError }
    var authErrorPublisher: Published<AlertItem?>.Publisher { $authError }

    @MainActor @Published var isSignedIn: Bool = false

    private var accountUsername: String? = nil
    private var accountPassword: String? = nil
    
    var accountUserGroups: [CognitoUserGroup] = []
    private let userGroupConfig = CognitoUserGroupConfig()

    /**
     Authenticates the user session and handles subsequent all sign in flows.

     - Parameters:
     - accountUsername: User name credential
     - accountPassword: Primary name credential. In a new account flow, this is the desired new password for the user.
     */
    
    public func signIn(accountUsername: String, accountPassword: String) {
        
        self.setCredentials(
            accountUsername: accountUsername,
            accountPassword: accountPassword
        )
        
        Amplify.Auth.fetchAuthSession { result in
            switch result {
            case .success(let session):
                self.synchronizeLogin(to: session) {
                    self._signIn()
                }
            case .failure(let error):
                Log.error("Fetch session failed with error \(error)")
            }
        }
    }
    
    /**
     Sign out the currently signed in user. Calling this function on a nil current user will have no side effect unless an optional
     completion closure is provided.
     
     - Parameters:
     - completeSignOut: Optional completion action
     */
    public func signOut(completeSignOut: (()->())? = nil ) {
        guard let currentSignedInUser = Amplify.Auth.getCurrentUser()?.username else {
            completeSignOut?()
            return
        }
        
        Amplify.Auth.fetchAuthSession { result in
            switch result {
            case .success(let currentSession):
                if (currentSession.isSignedIn) {
                    Amplify.Auth.signOut { result in
                        switch result {
                        case .success():
                            DispatchQueue.main.async {
                                self.isSignedIn = currentSession.isSignedIn
                                Log.info("\(currentSignedInUser) signed out: \(self.isSignedIn)")
                                self.delegate?.didSuccessfullySignOut()
                                completeSignOut?()
                            }
                        case .failure(let error):
                            Log.warn("Amplify auth signout failed in \(#function) with error \(error)")
                        }
                    }
                }
            case .failure(let error):
                Log.error("Fetch session failed in \(#function) with error \(error)")
            }
        }
    }
    
    /**
     Convenience function.
     */
    private func setCredentials(accountUsername: String, accountPassword: String) {
        self.accountUsername = accountUsername
        self.accountPassword = accountPassword
    }
    
    /**
     Precheck routine before sign in. If a different previous username is found or any session is signed in, it will be signed out before attempting
     to sign in with assigned credentials.
     */
    private func synchronizeLogin(to currentSession: AuthSession, completion: @escaping (()->())) {
        let currentSignedInUser = Amplify.Auth.getCurrentUser()?.username
        Log.debug("current signed in user: \(String(describing: currentSignedInUser))")
        let doesUserMatchCurrentSignIn = currentSignedInUser == self.accountUsername
        
        if (currentSession.isSignedIn || !doesUserMatchCurrentSignIn) {
            DispatchQueue.main.async {
                self.signOut {
                    completion()
                }
            }
        } else {
            completion()
        }
    }
    
    /**
     Sign in with handling cases for different account states.
     */
    private func _signIn() {

        guard let username = self.accountUsername, let password = self.accountPassword else {
            Log.error("No account username or account password set")
            return
        }

        Amplify.Auth.signIn(username: username, password: password) { [self] result in
            do {
                let signinResult = try result.get()
                switch signinResult.nextStep {
                case .confirmSignInWithSMSMFACode(let deliveryDetails, let info):
                    Log.debug("SMS code send to \(deliveryDetails.destination)")
                    Log.debug("Additional info \(String(describing: info))")
                    // TODO: Prompt the user to enter the SMSMFA code they received
                    // Then invoke `confirmSignIn` api with the code
                case .confirmSignInWithCustomChallenge(let info):
                    Log.debug("Custom challenge, additional info \(String(describing: info))")
                    // TODO: Prompt the user to enter custom challenge answer
                    // Then invoke `confirmSignIn` api with the answer
                case .confirmSignInWithNewPassword(_):
                    // Continue to reuse existing password
                    // Then invoke `confirmSignIn` api with password
                    self.delegate?.didConfirmNewUser()

                    Amplify.Auth.confirmSignIn(challengeResponse: password, options: nil) { confirmSignInResult in
                        switch confirmSignInResult {
                        case .success(let confirmedResult):
                            Log.debug("Confirmed \(confirmedResult) sign in w existing password.")
                            self.delegate?.didSuccessfullySignIn()
                        case .failure(let authError):
                            Log.error("Sign in with existing password failed \(authError)")
                        }
                    }
                case .resetPassword(let info):
                    Log.debug("Reset password additional info \(String(describing: info))")
                    // Invoke `resetPassword` api to start the reset password
                    // flow, and once reset password flow completes, invoke
                    // `signIn` api to trigger signin flow again.
                case .confirmSignUp(let info):
                    Log.debug("Confirm signup additional info \(String(describing: info))")
                    // TODO: User was not confirmed during the signup process.
                    // Invoke `confirmSignUp` api to confirm the user if
                    // they have the confirmation code. If they do not have the
                    // confirmation code, invoke `resendSignUpCode` to send the
                    // code again.
                    // After the user is confirmed, invoke the `signIn` api again.
                case .done:
                    // Use has successfully signed in to the app
                    Log.debug("done")
                    self.setCurrentUserPool {
                        DispatchQueue.main.async {
                            self.isSignedIn = signinResult.isSignedIn
                        }
                        self.delegate?.didSuccessfullySignIn()
                        Log.info("Auth.signIn complete \(signinResult.isSignedIn)")
                    }
                }
            } catch(let error) {
                // TODO: Insert delegate or completion handler for failed sign in.
                Log.error("Sign in failed \(error)")
                guard let error = error as? AuthError else { return }
                DispatchQueue.main.async {
                    switch error {
                    case .notAuthorized(_, _, _):
                        self.authError = AlertContext.invalidLogin
                    case
                    .configuration(_, _, _),
                    .service(_, _, _),
                    .unknown(_, _),
                    .validation(_, _, _, _),
                    .invalidState(_, _, _),
                    .signedOut(_, _, _),
                    .sessionExpired(_, _, _):
                        Log.error("Error: \(error)", shouldLogContext: true)
                        self.authError = AlertContext.defaultAlert
                    }
                }
            }
        }
    }

    func getUsername(completion: @escaping ((String) -> Void)) {
        guard let currentSignedInUser = Amplify.Auth.getCurrentUser()?.username else {
            Log.error("Error getting signed in user")
            return
        }
        completion(currentSignedInUser)
    }
    
    private func setCurrentUserPool(completion: @escaping () -> Void) {
        Amplify.Auth.fetchAuthSession { result in
            switch result {
            case .success(let session):
                do {
                    // Get cognito user pool token
                    if let cognitoTokenProvider = session as? AuthCognitoTokensProvider {
                        print(try cognitoTokenProvider.getCognitoTokens().get().accessToken)
                        let tokens = try cognitoTokenProvider.getCognitoTokens().get()
                        print("Id token - \(tokens.idToken) ")

                        let tokenClaims = try AWSAuthService().getTokenClaims(tokenString: tokens.idToken).get()
                        print("Token Claims: \(tokenClaims)")
                        
                        if let groups = (tokenClaims["cognito:groups"] as? NSArray) as Array? {
                            var cognitoGroups: [String] = []
                            for group in groups {
                                print("Cognito group: \(group)")
                                if let groupString = group as? String {
                                    cognitoGroups.append(groupString)
                                }
                            }
                            self.accountUserGroups = cognitoGroups.compactMap({ groupId in
                                self.userGroupConfig.userGroupForGroupId(groupId: groupId)
                            })
                            print(self.accountUserGroups)
                            completion()
                        }
                    }
                } catch {
                    Log.error("Fetch user pool failed with error \(error)")
                }
            case .failure(let error):
                Log.error("Fetch session failed with error \(error)")
            }
        }
    }
}

extension AuthenticationService: AuthenticationServiceProtocol { }
