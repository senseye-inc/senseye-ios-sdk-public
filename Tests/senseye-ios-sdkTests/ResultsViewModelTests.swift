//
//  ResultsViewModelTests.swift
//  senseye-ios-sdkTests
//
//  Created by Frank Oftring on 4/22/22.
//

import XCTest
@testable import senseye_ios_sdk
@testable import Amplify
@testable import AWSS3StoragePlugin
@testable import AWSCognitoAuthPlugin

@available(iOS 15.0, *)
class ResultsViewModelTests: XCTestCase {
    
    var sut: ResultsViewModel!
    var sdk: SenseyeSDK!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        sdk = SenseyeSDK()
        sdk.initializeSDK()
        if !Amplify.isConfigured {
            let configurationURL = URL(fileURLWithPath: "/Users/frank/Library/Developer/Xcode/DerivedData/senseye-ios-sdk-bponenmhhswidiauljmdhyupwhej/Build/Products/Debug-iphonesimulator/senseye-ios-sdkTests.xctest/senseye-ios-sdk_senseye-ios-sdk.bundle/amplifyconfiguration.json")
            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            try Amplify.add(plugin: AWSS3StoragePlugin())
            try Amplify.configure(AmplifyConfiguration.init(configurationFile: configurationURL))
        }
        sut = ResultsViewModel(fileUploadService: FileUploadAndPredictionService())
    }
    
    override func tearDownWithError() throws {
        sut = nil
        try super.tearDownWithError()
    }
    
    func testAmplifyIsConfigured() {
        let configuration = Amplify.isConfigured
        XCTAssertTrue(configuration)
    }
    
    func testIsLoadingBeginsFalse() {
        XCTAssertFalse(sut.isLoading)
    }
    
    func testWhenPredictionStartIsLoadingEqualsTrue() {
        // When
        sut.startPredictions()
        
        // Then
        XCTAssertTrue(sut.isLoading)
    }
    
}
