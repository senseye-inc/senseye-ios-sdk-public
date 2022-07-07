//
//  LoginView-ViewModel.swift
//  senseye-ios-sdk-app
//
//  Created by Bobby Srisan on 4/3/22.
//

import Foundation
import Amplify
import UIKit
import SwiftUI

@available(iOS 15.0.0, *)
extension LoginView {
    class ViewModel: ObservableObject {
        @AppStorage("username") var username: String = ""
        @Published var password: String = ""
        @Published var newPassword: String = ""
        @Published var temporaryPassword: String = ""
        @Published var isNewAccount = false
        @Published var isUserSignedIn = false
        @Published var isShowingPasswordAlert = false

        private var authenticationService: AuthenticationServiceProtocol

        init(authenticationService: AuthenticationServiceProtocol) {
            self.authenticationService = authenticationService
        }
        
        func login() {
            if (self.isNewAccount && !self.isValidNewPasswordSubmission()) {
                isShowingPasswordAlert = true
                return
            } else {
                self.newPassword = ""
                self.temporaryPassword = ""
            }
            
            self.authenticationService.authenticateSession(
                accountUsername: self.username,
                accountPassword: self.password,
                temporaryPassword: self.temporaryPassword
            )
        }

        /**
         On any  view load, any current user is signed out.
         */
        func onAppear() {
            authenticationService.delegate = self
            if (self.isUserSignedIn) {
                self.authenticationService.signOut(completeSignOut: nil)
            }
            Log.debug("Login view appears! isSignedIn is \(self.isUserSignedIn)")
        }
        
        func isMatchingNewPassword() -> Bool { self.password == self.newPassword }
                
        func isValidNewPasswordSubmission() -> Bool {
            isMatchingNewPassword() && !temporaryPassword.isEmpty
        }
    }


}
@available(iOS 15.0.0, *)
extension LoginView.ViewModel: AuthenticationServiceDelegate {
    func didConfirmSignInWithNewPassword() {
        Log.info("New account password set.")
    }
    
    func didSuccessfullySignIn() {
        Log.info("Successful sign in")
        DispatchQueue.main.async {
            self.isUserSignedIn = true
        }
    }
 
    func didSuccessfullySignOut() {
        Log.info("Successful signed out")
        DispatchQueue.main.async {
            self.isUserSignedIn = false
        }
    }
}
