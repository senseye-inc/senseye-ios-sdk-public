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
    
    // MARK: - login
    
    func test_login_withNewAccountAndInvalidPasswordSubmissionShowsPasswordAlert() {
        // Given
        model.isNewAccount = true
        let validSubmission = model.isValidNewPasswordSubmission()
        
        // When
        model.login()
        
        // Then
        if !validSubmission {
            XCTAssertTrue(model.isShowingPasswordAlert)
        }
    }
    
    func test_login_withExistingAccountShowsNoPasswordAlert() {
        // Given
        model.isNewAccount = false
        
        // When
        model.login()
        
        // Then
        XCTAssertTrue(model.newPassword == "")
        XCTAssertTrue(model.temporaryPassword == "")
        XCTAssertFalse(model.isShowingPasswordAlert)
    }
    
    func test_login_callsAuthenticationServiceAuthenticateSession() {
        //  When
        model.login()
        
        XCTAssertTrue(mockAuthenticationService.authenticateSessionWasCalled)
    }
    
    // MARK: - onAppear
    
    func test_onAppear_signOutCalledIfUserIsSignedIn() {
        // Given
        model.isUserSignedIn = true
        
        // When
        model.onAppear()
        
        // Then
        XCTAssertTrue(mockAuthenticationService.signOutWasCalled)
    }
}
