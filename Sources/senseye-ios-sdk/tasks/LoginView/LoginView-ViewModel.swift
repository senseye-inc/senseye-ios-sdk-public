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
        @Published var isUserSignedIn = false

        private var authenticationService: AuthenticationServiceProtocol

        init(authenticationService: AuthenticationServiceProtocol) {
            self.authenticationService = authenticationService
        }
        
        func login() {
            self.authenticationService.signIn(
                accountUsername: self.username,
                accountPassword: self.password
            )
        }

        var versionAndBuildNumber: String {
            let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
            let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
            return "\(version ?? "Error getting version") (\(build ?? "Error getting build"))"
        }

        /**
         On any view load, any current user is signed out
         # TODO: handle signout at a previous load state or make signout dependent on last account activity idle time
         */
        func onAppear() {
            authenticationService.delegate = self
            if (self.isUserSignedIn) {
                self.authenticationService.signOut(completeSignOut: nil)
            }
            Log.debug("isSignedIn is \(self.isUserSignedIn)")
        }
        
    }


}
@available(iOS 15.0.0, *)
extension LoginView.ViewModel: AuthenticationServiceDelegate {
    func didConfirmNewUser() {
        Log.info("Attempted sign in for new user")
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
