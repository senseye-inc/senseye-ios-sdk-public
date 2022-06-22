//
//  AuthenticationService.swift
//  
//
//  Created by Bobby Srisan on 2/17/22.
//

import Amplify
import Foundation

protocol AuthenticationServiceProtocol {
    func signOut(completeSignOut: (()->())? )
    func authenticateSession(accountUsername: String, accountPassword: String, temporaryPassword: String?)
    func getUsername(completion: @escaping ((String) -> Void))
    var delegate: AuthenticationServiceDelegate? { get set }
}

protocol AuthenticationServiceDelegate: AnyObject {
    func didConfirmSignInWithNewPassword()
    func didSuccessfullySignIn()
    func didSuccessfullySignOut()
}

/**
 The AuthenticationService for the SDK  lets developers authenticate sessions through Senseye's backend  service.
 */
@available(iOS 13.0, *)
public class AuthenticationService: ObservableObject {
    
    weak var delegate: AuthenticationServiceDelegate?
    
    private var accountUsername: String? = nil
    private var accountPassword: String? = nil
    private var temporaryPassword: String? = nil
    
    /**
     Authenticates the user session and fetches api key to allow for uploading and processing files. Use
     didAuthenticateSession to dispatch another action if authorization is successful. This function handles all sign in flows.
     
     TODO: Add optional completion action.
     
     - Parameters:
     - accountUsername: User name credential
     - accountPassword: Primary name credential. In a new account flow, this is the desired new password for the user.
     - temporaryPassword: In a new account flow, the temporary password is initially provided to complete a new password change for the account.
     */
    
    public func authenticateSession(accountUsername: String, accountPassword: String, temporaryPassword: String?) {
        
        self.setCredentials(
            accountUsername: accountUsername,
            accountPassword: accountPassword,
            temporaryPassword: temporaryPassword
        )
        
        Amplify.Auth.fetchAuthSession { result in
            switch result {
            case .success(let session):
                self.synchronizeLogin(to: session)
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
        // User must exist to signout
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
                            Log.info("\(currentSignedInUser) signed out")
                            self.delegate?.didSuccessfullySignOut()
                            completeSignOut?()
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
    private func setCredentials(accountUsername: String, accountPassword: String, temporaryPassword: String?) {
        self.accountUsername = accountUsername
        self.accountPassword = accountPassword
        self.temporaryPassword = temporaryPassword
    }
    
    /**
     Routine to sign in with credentials. If a different previous username is found or any session is signed in, it will be signed out before attempting
     to sign in with assigned credentials.
     */
    private func synchronizeLogin(to currentSession: AuthSession) {
        guard let username = self.accountUsername, let password = self.accountPassword else {
            Log.warn("Need accountUsername or accountPassword")
            return
        }
        
        let currentSignedInUser = Amplify.Auth.getCurrentUser()?.username
        Log.debug("current signed in user: \(String(describing: currentSignedInUser))")
        let doesUserMatchCurrentSignIn = currentSignedInUser == username
        
        if (currentSession.isSignedIn || !doesUserMatchCurrentSignIn) {
            self.signOut(completeSignOut:  {
                self.signIn(username: username, password: password, temporaryPassword: self.temporaryPassword)
            })
        } else {
            self.signIn(username: username, password: password, temporaryPassword: self.temporaryPassword)
        }
    }
    
    /**
     Sign in with handling cases for different account states.
     */
    private func signIn(username: String, password: String, temporaryPassword: String?) {
        let signInPassword: String
        
        if (temporaryPassword == nil || temporaryPassword == "") {
            signInPassword = password
        } else {
            signInPassword = temporaryPassword!
        }
        
        Amplify.Auth.signIn(username: username, password: signInPassword) { result in
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
                case .confirmSignInWithNewPassword(let info):
                    // Replace temporary password user's desired password
                    // Then invoke `confirmSignIn` api with new password
                    // TODO: Do double password entries
                    Log.debug("New password additional info \(String(describing: info))")
                    Amplify.Auth.confirmSignIn(challengeResponse: password, options: nil) { confirmSignInResult in
                        switch confirmSignInResult {
                        case .success(let confirmedResult):
                            Log.debug("Confirmed \(confirmedResult) sign in w new password.")
                            self.delegate?.didConfirmSignInWithNewPassword()
                            self.delegate?.didSuccessfullySignIn()
                        case .failure(let authError):
                            Log.warn("Sign in w new password failed \(authError)")
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
                    self.delegate?.didSuccessfullySignIn()
                    Log.info("Signin complete")
                }
            } catch {
                // TODO: Insert delegate or completion handler for failed sign in.
                Log.error("Sign in failed \(error)")
            }
        }
    }

    func getUsername(completion: @escaping ((String) -> Void)) {
        guard let currentSignedInUser = Amplify.Auth.getCurrentUser()?.username else {
            print("Error getting signed in user")
            return
        }
        completion(currentSignedInUser)
    }
}

@available(iOS 13.0, *)
extension AuthenticationService: AuthenticationServiceProtocol { }
