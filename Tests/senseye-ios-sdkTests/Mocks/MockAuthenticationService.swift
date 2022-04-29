//
//  File.swift
//  
//
//  Created by Frank Oftring on 4/28/22.
//

import Foundation
@testable import senseye_ios_sdk
import XCTest

class SpyAuthenticationServiceDelegate: AuthenticationServiceDelegate {
    
    var didSuccessfullySignInResult: Bool?
    var didSuccessfullySignOutResult: Bool?
    var asyncExpectation: XCTestExpectation?
    
    func didConfirmSignInWithNewPassword() { }
    
    func didSuccessfullySignIn() {
        guard let expectation = asyncExpectation else {
            XCTFail("SpyDelegate was not setup correctly. Missing XCTExpectation reference")
            return
        }
        
        didSuccessfullySignInResult = true
        expectation.fulfill()
    }
    
    func didSuccessfullySignOut() {
        guard let expectation = asyncExpectation else {
            XCTFail("SpyDelegate was not setup correctly. Missing XCTExpectation reference")
            return
        }
        didSuccessfullySignOutResult = true
        expectation.fulfill()
    }
    
    
}

class MockAuthenticationService {
    
    var signOutWasCalled: Bool = false
    var authenticateSessionWasCalled: Bool = false
    
    weak var delegate: AuthenticationServiceDelegate?
    
    var accountUsername: String? = nil
    var accountPassword: String? = nil
    var temporaryPassword: String? = nil
}

extension MockAuthenticationService: AuthenticationServiceProtocol {
    
    func signOut(completeSignOut: (() -> ())?) {
        signOutWasCalled = true
    }
    
    public func authenticateSession(accountUsername: String, accountPassword: String, temporaryPassword: String?) {
        authenticateSessionWasCalled = true
    }
}

extension MockAuthenticationService: AuthenticationServiceDelegate {
    func didConfirmSignInWithNewPassword() { }
    
    func didSuccessfullySignIn() { }
    
    func didSuccessfullySignOut() { }
    
    
}
