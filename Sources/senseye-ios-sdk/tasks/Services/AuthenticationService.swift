//
//  AuthenticationService.swift
//  
//
//  Created by Bobby Srisan on 2/17/22.
//

import Amplify
import SwiftUI
import Combine
import AWSPluginsCore

protocol AuthenticationServiceProtocol {
    func signOut()
    func signIn(accountUsername: String, accountPassword: String)
    var authError: AlertItem? { get }
    var authErrorPublisher: Published<AlertItem?>.Publisher { get }
    var isSignedIn: Bool { get }
    var isSignedInPublisher: Published<Bool>.Publisher { get }
    var userId: String { get }
}

/**
 The AuthenticationService for the SDK  lets developers authenticate sessions through Senseye's backend  service.
 */
public class AuthenticationService: ObservableObject {
    
    @Published var authError: AlertItem? = nil
    @Published var isSignedIn: Bool = false

    private var accountUsername: String? = nil
    private var accountPassword: String? = nil
    private var cancellables = Set<AnyCancellable>()
    
    var userId: String
    var accountUserGroups: [CognitoUserGroup] = []
    private let userGroupConfig = CognitoUserGroupConfig()
    
    init(userId: String) {
        self.userId = userId
    }

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
        
        Amplify.Auth.fetchAuthSession().resultPublisher
            .sink(receiveCompletion: { authError in
                if case let .failure(authError) = authError {
                    Log.error("Fetch session failed with error \(authError)")
                }
            }, receiveValue: { authSession in
                self.synchronizeLogin(to: authSession)
            })
            .store(in: &cancellables)
    }
    
    /**
     Sign out the currently signed in user. Calling this function on a nil current user will have no side effect unless an optional
     completion closure is provided.
     
     - Parameters:
     - completeSignOut: Optional completion action
     */
    public func signOut() {
        guard let currentSignedInUser = Amplify.Auth.getCurrentUser()?.username else {
            Log.info("No user to signout", shouldLogContext: true)
            return
        }
        
        Amplify.Auth.signOut().resultPublisher
            .sink { authError in
                if case let .failure(authError) = authError {
                    Log.warn("Amplify auth signout failed in \(#function) with error \(authError)")
                }
            } receiveValue: { _ in
                Log.info("Signed out currentSignedInUser \(currentSignedInUser)")
                DispatchQueue.main.async {
                    self.isSignedIn = false
                }
            }
            .store(in: &cancellables)
    }
    
    /**
     Convenience function.
     */
    private func setCredentials(accountUsername: String, accountPassword: String) {
        self.userId = accountUsername
        self.accountUsername = accountUsername
        self.accountPassword = accountPassword
    }
    
    /**
     Precheck routine before sign in. If a different previous username is found or any session is signed in, it will be signed out before attempting
     to sign in with assigned credentials.
     */
    private func synchronizeLogin(to currentSession: AuthSession) {
        let currentSignedInUser = Amplify.Auth.getCurrentUser()?.username
        
        if (currentSession.isSignedIn || currentSignedInUser != nil) {
            self.signOut()
        } else {
            self._signIn()
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
        
        Amplify.Auth.signIn(username: username, password: password).resultPublisher
            .sink(receiveCompletion: { authError in
                if case let .failure(error) = authError {
                    Log.error("Sign in failed \(error)")
                    DispatchQueue.main.async {
                        switch error {
                        case .notAuthorized(_, _, _), .service(_, _, _):
                            self.authError = AlertContext.invalidLogin
                        default:
                            Log.error("Error: \(error)", shouldLogContext: true)
                            self.authError = AlertContext.defaultAlert
                        }
                    }
                }
            }, receiveValue: { signInResult in
                switch signInResult.nextStep {
                case .confirmSignInWithNewPassword(_):
                    // Continue to reuse existing password
                    // Then invoke `confirmSignIn` api with password
                    Log.info("Calling confirmSignInWithNewPassword!!")

                    Amplify.Auth.confirmSignIn(challengeResponse: password, options: nil) { confirmSignInResult in
                        switch confirmSignInResult {
                        case .success(let confirmedResult):
                            Log.debug("Confirmed \(confirmedResult) sign in w existing password.")
                            self.isSignedIn = confirmedResult.isSignedIn
                        case .failure(let authError):
                            Log.error("Sign in with existing password failed \(authError)")
                        }
                    }
                case .done:
                    // Use has successfully signed in to the app
                    Log.debug("done")
                    self.setCurrentUserPool(signinResult: signInResult)
                default:
                    Log.info("Triggering default case. Auth flow not accounted for")
                    self.authError = AlertContext.authFlowError
                }
            })
            .store(in: &cancellables)
    }
    
    private func setCurrentUserPool(signinResult: AuthSignInResult) {
        
        Amplify.Auth.fetchAuthSession().resultPublisher
            .sink { authError in
                if case let .failure(authError) = authError {
                    Log.error("Fetch user pool failed with error \(authError)")
                }
            } receiveValue: { authSession in
                do {
                    if let cognitoTokenProvider = authSession as? AuthCognitoTokensProvider {
                        let tokens = try cognitoTokenProvider.getCognitoTokens().get()

                        let tokenClaims = try AWSAuthService().getTokenClaims(tokenString: tokens.idToken).get()
                        
                        if let groups = (tokenClaims["cognito:groups"] as? NSArray) as Array? {
                            let cognitoGroups: [String] = groups.compactMap({ "\($0)" })
                            self.accountUserGroups = cognitoGroups.compactMap({ groupId in
                                self.userGroupConfig.userGroupForGroupId(groupId: groupId)
                            })
                            DispatchQueue.main.async {
                                self.isSignedIn = signinResult.isSignedIn
                                Log.info("Auth.signIn complete \(signinResult.isSignedIn)")
                            }
                        }
                    }
                } catch {
                    Log.error("Fetch user pool failed with error \(error)")
                }
            }
            .store(in: &cancellables)
    }
    
    func reset() {
        cancellables.removeAll()
        userId = ""
    }
}

extension AuthenticationService: AuthenticationServiceProtocol {
    var authErrorPublisher: Published<AlertItem?>.Publisher { $authError }
    var isSignedInPublisher: Published<Bool>.Publisher { $isSignedIn }
}
