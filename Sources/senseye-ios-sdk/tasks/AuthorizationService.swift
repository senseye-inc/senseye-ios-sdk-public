//
//  AuthorizationService.swift
//  
//
//  Created by Bobby Srisan on 2/17/22.
//

import Amplify
import Foundation

protocol AuthorizationServiceDelegate: AnyObject {
    func didConfirmSignInWithNewPassword()
    func didSuccessfullySignIn()
    func didAuthorizeSession()
}

class AuthorizationService {
    weak var delegate: AuthorizationServiceDelegate?
    
    var apiUrl: String? { self.hostApiUrl }
    var apiKey: String? { self.hostApiKey }
    var bucketUrl: String? { self.hostBucketUrl }

    private var accountUsername: String? = nil
    private var accountPassword: String? = nil
    private var temporaryPassword: String? = nil
        
    // TODO: feature flag?
    private let hostApiUrl: String? =  "https://api.senseye.co"
    private var hostApiKey: String? = nil
    // TODO: put in build env or fetchable AWS env
    private let hostBucketUrl: String? = "s3://senseyeiossdk98d50aa77c5143cc84a829482001110f111246-dev/public/"

    // TODO: make a better mapping function
    func setGroupIdAndUniqueId(groupId: String, uniqueId: String, temporaryPassword: String) {
        self.accountUsername = groupId
        self.accountPassword = uniqueId
        self.temporaryPassword = temporaryPassword
    }

    func authorizeSession() {
        Amplify.Auth.fetchAuthSession { result in
            switch result {
            case .success(let session):
                self.synchronize(currentSession: session)
                self.setUserApiKey()
                self.delegate?.didAuthorizeSession()
            case .failure(let error):
                print("Fetch session failed with error \(error)")
            }
        }
    }
    
    
    /**
     Signs into session with user credentials, or ensures current signed in session matches user entry at login.

     - Parameters:
        - currentSession: Current session that may be signed in
     */
    private func synchronize(currentSession: AuthSession) {
        guard let username = self.accountUsername, let password = self.accountPassword else {
            print("Need accountUsername or accountPassword")
            return
        }
        
        let doesUserMatchCurrentSignIn = Amplify.Auth.getCurrentUser()?.username == username

        if (!currentSession.isSignedIn || !doesUserMatchCurrentSignIn) {
            Amplify.Auth.signOut { result in
                switch result {
                case .success():
                    self.signIn(username: username, password: password, temporaryPassword: self.temporaryPassword)
                case .failure(let error):
                    print("Synchronize session failed at Amplify auth signout \(error)")
                }
            }
        }
    }
    
    private func setUserApiKey() {
        if (self.hostApiKey == nil) {
            Amplify.Auth.fetchUserAttributes() { result in
                switch result {
                case .success(let attributes):
                    if let attribute = attributes.first(where: { $0.key == AuthUserAttributeKey.custom("senseye_api_token") }) {
                        self.hostApiKey = attribute.value
                    }
                    print("Host api key: \(self.hostApiKey)")
                case .failure(let authError):
                    print("Fetching user attributes failed: \(authError)")
                }
            }
        }
    }
    
    private func signIn(username: String, password: String, temporaryPassword: String?) {
        let signInPassword: String
        
        if (temporaryPassword != nil || temporaryPassword != "") {
            signInPassword = temporaryPassword!
        } else {
            signInPassword = password
        }

        Amplify.Auth.signIn(username: username, password: signInPassword) { result in
            do {
                let signinResult = try result.get()
                switch signinResult.nextStep {
                case .confirmSignInWithSMSMFACode(let deliveryDetails, let info):
                    print("SMS code send to \(deliveryDetails.destination)")
                    print("Additional info \(info)")
                    // TODO: Prompt the user to enter the SMSMFA code they received
                    // Then invoke `confirmSignIn` api with the code
                case .confirmSignInWithCustomChallenge(let info):
                    print("Custom challenge, additional info \(info)")
                    // TODO: Prompt the user to enter custom challenge answer
                    // Then invoke `confirmSignIn` api with the answer
                case .confirmSignInWithNewPassword(let info):
                    // Replace temporary password user's desired password
                    // Then invoke `confirmSignIn` api with new password
                    // TODO: Do double password entries
                    print("New password additional info \(info)")
                    Amplify.Auth.confirmSignIn(challengeResponse: password, options: nil) { confirmSignInResult in
                        switch confirmSignInResult {
                        case .success(let confirmedResult):
                            print("Confirmed sign in w new password.")
                            self.delegate?.didConfirmSignInWithNewPassword()
                            self.delegate?.didSuccessfullySignIn()
                        case .failure(let authError):
                            print("Sign in w new password failed \(authError)")
                        }
                    }
                case .resetPassword(let info):
                    print("Reset password additional info \(info)")
                    // TODO: User needs to reset their password.
                    // Invoke `resetPassword` api to start the reset password
                    // flow, and once reset password flow completes, invoke
                    // `signIn` api to trigger signin flow again.
                case .confirmSignUp(let info):
                    print("Confirm signup additional info \(info)")
                    // TODO: User was not confirmed during the signup process.
                    // Invoke `confirmSignUp` api to confirm the user if
                    // they have the confirmation code. If they do not have the
                    // confirmation code, invoke `resendSignUpCode` to send the
                    // code again.
                    // After the user is confirmed, invoke the `signIn` api again.
                case .done:
                    // Use has successfully signed in to the app
                    self.delegate?.didSuccessfullySignIn()
                    print("Signin complete")
                }
            } catch {
                print ("Sign in failed \(error)")
            }
        }
    }
}
