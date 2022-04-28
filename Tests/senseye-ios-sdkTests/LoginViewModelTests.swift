//
//  LoginViewModelTests.swift
//  
//
//  Created by Frank Oftring on 4/28/22.
//
import XCTest
@testable import senseye_ios_sdk

@available(iOS 15.0, *)
class LoginViewModelTests: XCTestCase {

    var model: LoginView.ViewModel!
    var mockAuthenticationService: MockAuthenticationService!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        mockAuthenticationService = MockAuthenticationService()
        model = LoginView.ViewModel(authenticationService: mockAuthenticationService)
    }
    
    override func tearDownWithError() throws {
        model = nil
        mockAuthenticationService = nil
        try super.tearDownWithError()
    }
    
    func testSetup() {

    }
    
    

    /*
     Tests Needed:
     
     viewModel
     - func login()
     - func onAppear()
     - func isMatchingPassword()
     - func isValidNewPasswordSubmission()
     - delegate methods?
     
     authenticationService
     - func authenticateSession()
     - func signOut()
     - delegate methods?
     */

}
