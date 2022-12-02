//
//  File.swift
//  
//
//  Created by Frank Oftring on 11/15/22.
//

import Foundation

struct Strings {
    
    // MARK: - LoginView
    static let loginHelp = NSLocalizedString("loginHelp", value: "Having trouble logging in?", comment: "")
    static let loginButtonTitle = NSLocalizedString("loginButtonTitle", value: "LOGIN", comment: "")
    static let loginCallToAction = NSLocalizedString("loginCallToAction", value: "Login to get started", comment: "")
    static let passwordTitle = NSLocalizedString("passwordTitle", value: "PASSWORD", comment: "")
    static let usernameTitle = NSLocalizedString("usernameTitle", value: "USERNAME", comment: "")
    static let tokenCallToAction = NSLocalizedString("tokenCallToAction", value: "Use one-time token", comment: "")
    static let tokenTitle = NSLocalizedString("tokenTitle", value: "ONE-TIME TOKEN", comment: "")

    // MARK: - SurveyView
    static let blueColor = NSLocalizedString("blueColor", value: "Blue", comment: "")
    static let greenColor = NSLocalizedString("greenColor", value: "Green", comment: "")
    static let brownColor = NSLocalizedString("brownColor", value: "Brown", comment: "")
    static let blackColor = NSLocalizedString("blackColor", value: "Black", comment: "")
    static let hazelColor = NSLocalizedString("hazelColor", value: "Hazel", comment: "")
    
    static let maleGender = NSLocalizedString("maleGender", value: "Male", comment: "")
    static let femalGender = NSLocalizedString("femaleGender", value: "Female", comment: "")
    static let otherGender = NSLocalizedString("otherGender", value: "Other", comment: "")
    
    static let genderTitle = NSLocalizedString("genderTitle", value: "GENDER", comment: "")
    static let eyeColorTitle = NSLocalizedString("eyeColorTitle", value: "EYE COLOR", comment: "")
    static let ageTitle = NSLocalizedString("ageTitle", value: "AGE", comment: "")
    
    static let continueButtonText = NSLocalizedString("continueButtonText", value: "CONTINUE", comment: "")
    static let surveyViewCallToActionText = NSLocalizedString("surveyViewCallToActionText", value: "Let's get started.", comment: "")
    static let surveyViewInstructions = NSLocalizedString("surveyViewInstructions", value: "Please enter your information below.", comment: "")
    static let debugModeDescription = NSLocalizedString("debugModeDescription", value: "Enable Debug Mode", comment: "")
    static let startButtonTitle = NSLocalizedString("startButtonTitle", value: "START", comment: "")
    static let imageDownloadingTitle = NSLocalizedString("imageDownloadingTitle", value: "Downloading the Image Set, please give it a few minutes..", comment: "")
    
    // MARK: - SettingsView
    static let bluetoothTitle = NSLocalizedString("bluetoothTitle", value: "Bluetooth", comment: "")
    static let connectedTitle = NSLocalizedString("connectedTitle", value: "Connected", comment: "")
    static let notConnectedTitle = NSLocalizedString("notConnectedTitle", value: "Not Connected", comment: "")
    static let searchingForDevices = NSLocalizedString("searchingForDevices", value: "Searching for devices…", comment: "")
    static let bluetoothConnectedDescription = NSLocalizedString("bluetoothConnectedDescription", value: "Connected", comment: "")
    static let bluetoothSearchingText = NSLocalizedString("bluetoothSearchingText", value: "Searching for devices…", comment: "")
    static let language = NSLocalizedString("langauge", value: "Language", comment: "")
    
    // MARK: - TabController
    static let affectiveImageTaskDescription = NSLocalizedString(
        "affectiveImageTaskDescription",
        value: "8 different images will come across the screen. \n Note: Some of the images may be disturbing.",
        comment: "")
    static let calibrationTaskName = NSLocalizedString("calibrationTaskName", value: "Calibration", comment: "")
    static let heartRateCalibrationTaskName = NSLocalizedString("heartRateCalibrationTaskName", value: "Heart Rate Calibration", comment: "")
    
    static let heartRateTaskInstructions = NSLocalizedString("heartRateTaskInstructions", value: "Relax and sit still for 3 minutes while we measure your baseline heart rate!", comment: "")
    static let plrTaskInstructions = NSLocalizedString("plrTaskInstructions", value: "Stare at the cross for the duration of the task.", comment: "")
    static let calibrationTaskInstructions = NSLocalizedString("calibrationTaskInstructions", value: "When a ball appears look at it as quickly as possible, and remain staring at it until it disappears.", comment: "")
    static let attentionBiasFaceInstructions = NSLocalizedString("attentionBiasFaceInstructions", value: "Fixate on the white cross or dot when it appears on the screen. There will be various emotional faces displayed on the screen. Freely view the images on the screen", comment: "")
    static let attentionBiasFaceTaskName = NSLocalizedString("attentionBiasFaceTaskName", value: "Attention Bias Face", comment: "")
    
    // MARK: - PLR View
    static let plrTaskDescription = NSLocalizedString("plrTaskDescription", value: "PLR", comment: "")
    
    // MARK: - CameraView

    static let readyButtonTitle = NSLocalizedString("readyButtonTitle", value: "READY?", comment: "")
    static let cameraTapToStartInstructions = NSLocalizedString("cameraTapToStartInstructions", value: "Double tap to start", comment: "")
    static let cameraPermissionsDescripton = NSLocalizedString("cameraPermissionsDescripton", value: "Change camera permissions in your settings.", comment: "")
    static let gotoSettingsButtonTitle = NSLocalizedString("gotoSettingsButtonTitle", value: "Go to settings", comment: "")
    static let needCameraAccess = NSLocalizedString("needCameraAccess", value: "Need Camera Access", comment: "")
    
    // MARK: - UserConfirmationView
    static let yesButtonTitle = NSLocalizedString("yesButtonTitle", value: "YES", comment: "")
    static let noButtonTitle = NSLocalizedString("noButtonTitle", value: "NO", comment: "")
    static let thankYouAlert = NSLocalizedString("thankYouAlert", value: "Thank You", comment: "")
    static let returnButton = NSLocalizedString("returnButton", value: "Return", comment: "")
    static let restartTask = NSLocalizedString("restartTask", value: "Please tap return to restart the task", comment: "")
    
    // MARK: - ResultsView
    static let resultsProcessing = NSLocalizedString("resultsProcessing", value: "Please wait. Results processing.", comment: "")
    static let resultsDelayed = NSLocalizedString("resultsDelayed", value: "Sorry, this is taking longer than expected. Please allow the session to complete by staying on this screen. This may take up to 30 minutes.", comment: "")
    static let resultsViewDescription = NSLocalizedString("resultsViewdescription", value: "You have completed the diagnostic, please speak with your health care provider for further information.", comment: "")
    static let completionSessionButtonTitle = NSLocalizedString("completionSessionButtonTitle", value: "COMPLETE SESSION", comment: "")
    
}
