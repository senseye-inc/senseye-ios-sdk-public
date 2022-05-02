//
//  File.swift
//  
//
//  Created by Frank Oftring on 4/28/22.
//

import Foundation
@testable import senseye_ios_sdk
import XCTest

class MockAuthenticationService {
    
    var signOutWasCalled: Bool = false
    var authenticateSessionWasCalled: Bool = false
    
    weak var delegate: AuthenticationServiceDelegate?
}

extension MockAuthenticationService: AuthenticationServiceProtocol {
    
    func signOut(completeSignOut: (() -> ())?) {
        signOutWasCalled = true
    }
    
    func authenticateSession(accountUsername: String, accountPassword: String, temporaryPassword: String?) {
        authenticateSessionWasCalled = true
    }
}

extension MockAuthenticationService: AuthenticationServiceDelegate {
    func didConfirmSignInWithNewPassword() { }
    
    func didSuccessfullySignIn() { }
    
    func didSuccessfullySignOut() { }
}
