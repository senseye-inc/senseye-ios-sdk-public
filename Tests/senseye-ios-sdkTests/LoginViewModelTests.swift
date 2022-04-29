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
        } else {
            XCTAssertFalse(model.isShowingPasswordAlert)
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
    
    // MARK: - onAppear
    
    func test_onAppear_signOutCalledIfUserIsSignedInOnAppear() {
        // Given
        model.isUserSignedIn = true
        
        // When
        model.onAppear()
        
        // Then
        XCTAssertTrue(mockAuthenticationService.signOutWasCalled)
    }
}
