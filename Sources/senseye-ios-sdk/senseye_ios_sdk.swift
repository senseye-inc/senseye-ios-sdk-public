import Foundation
import SwiftUI
#if !os(macOS)
import UIKit
import Amplify
import AWSS3StoragePlugin
import AWSCognitoAuthPlugin
import Firebase
import SwiftUI

protocol SenseyeTaskCompletionDelegate: AnyObject {
    func didCompleteTasksAndReturnResult(result: String)
}


public class SenseyeSDK {
    
    public enum TaskId: String, CaseIterable {
        case hrCalibration
        case firstCalibration
        case affectiveImageSets
        case finalCalibration
        case attentionBiasTest
    }
    
    weak var delegate: SenseyeTaskCompletionDelegate?
    private var initializedTaskIdList: [TaskId] = []
    private var userId: String
    private var shouldCollectSurveyInfo: Bool
    private var requiresAuth: Bool

    public init(userId: String = "default_user_id", taskIds: [TaskId] = TaskId.allCases, shouldCollectSurveyInfo: Bool = false, requiresAuth: Bool = false) {
        Log.enable()
        Log.debug("SDK Object created!", shouldLogContext: false)
        self.userId = userId
        self.initializedTaskIdList = taskIds
        self.shouldCollectSurveyInfo = shouldCollectSurveyInfo
        self.requiresAuth = requiresAuth
        initializeSDK()
    }
    
    private func initializeSDK() {
        do {
            guard let configurationURL = Bundle.module.url(forResource: "amplifyconfiguration", withExtension: "json") else {
                Log.error("Unable to load amplifyconfiguration.")
                return
            }
            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            try Amplify.add(plugin: AWSS3StoragePlugin())
            try Amplify.configure(AmplifyConfiguration.init(configurationFile: configurationURL))
            
            Log.info("Amplify configured with storage plugin")
        } catch {
            Log.error("Failed to initialize Amplify with \(error)")
        }

        // Use the Firebase library to configure APIs.
        FirebaseApp.configure()
    }

    @MainActor public func senseyeTabView() -> some View {
        let authenticationService = AuthenticationService()
        let bluetoothService = BluetoothService()
        let fileUploadService = FileUploadAndPredictionService(authenticationService: authenticationService)
        let cameraService = CameraService(authenticationService: authenticationService, fileUploadService: fileUploadService)
        let imageService = ImageService(authenticationService: authenticationService)
        return SenseyeTabView(taskIds: initializedTaskIdList, shouldCollectSurveyInfo: shouldCollectSurveyInfo, requiresAuth: requiresAuth)
            .environmentObject(authenticationService)
            .environmentObject(fileUploadService)
            .environmentObject(imageService)
            .environmentObject(cameraService)
            .environmentObject(bluetoothService)
    }
    
}
#endif
