//
//  SurveyViewModel.swift
//
//  Created by Frank Oftring on 6/9/22.
//

import Foundation
import SwiftUI
import Combine

class SurveyViewModel: ObservableObject {

    @AppStorage(AppStorageKeys.username()) var username: String?
    @Published var isShowingDebugToggle: Bool?
    @Published var selectedAge: Int?
    @Published var selectedEyeColor: String?
    @Published var selectedGender: String?
    @Published var isDebugModeEnabled: Bool = false
    @Published var isCensorModeEnabled: Bool = false
    @Published var shouldEnableStartButton: Bool = false
    @Published var currentDownloadStatusMessage: String = ""
    @Published var currentDownloadCountString: String = ""
    @Published var isShowingAlert = false
    private var cancellables = Set<AnyCancellable>()
    
    var fileUploadService: FileUploadAndPredictionServiceProtocol
    var alertItem: AlertItem?
    let imageService: ImageService
    let authenticationService: AuthenticationService
    let userGroupConfig = CognitoUserGroupConfig()
    
    init(fileUploadService: FileUploadAndPredictionServiceProtocol, imageService: ImageService, authenticationService: AuthenticationService) {
        self.fileUploadService = fileUploadService
        self.imageService = imageService
        self.authenticationService = authenticationService
        addSubscribers()
    }

    var eyeColorOptions: [String] = [Strings.blueColor, Strings.greenColor, Strings.brownColor, Strings.hazelColor, Strings.blackColor].sorted().reversed()
    var genderOptions: [String] = [Strings.maleGender, Strings.femalGender, Strings.otherGender]
    var ageRange: Range<Int> = (18..<66)

    var surveyIsEmpty: Bool {
        selectedAge != 0 && selectedEyeColor != "" && selectedGender != ""
    }
    
    var isInternalTestingGroup: Bool {
        authenticationService.accountUserGroups.contains(where: { userGroup in
            userGroup.isDebugEligibile
        })
    }
    
    func updateDebugModeFlag() {
        fileUploadService.isDebugModeEnabled = self.isDebugModeEnabled
    }

    func updateCensorModeFlag() {
        fileUploadService.isCensorModeEnabled = self.isCensorModeEnabled
    }

    func onAppear() {
        isShowingDebugToggle = isInternalTestingGroup
        isDebugModeEnabled = false
    }
    
    func onStartButton() {
        updateDebugModeFlag()
        updateCensorModeFlag()
        createSessionJsonFile()
        resetSurveyResponses()
    }

    func onBackButton() {
        resetSurveyResponses()
    }

    private func resetSurveyResponses() {
        isCensorModeEnabled = false
        selectedAge = nil
        selectedGender = nil
        selectedEyeColor = nil
    }
    
    private func createSessionJsonFile() {
        var surveyInput : [String: String] = [:]
        surveyInput["age"] = String(selectedAge ?? -1)
        surveyInput["gender"] = selectedGender
        surveyInput["eyeColor"] = selectedEyeColor
        fileUploadService.createSessionJsonFileAndStoreCognitoUserAttributes(surveyInput: surveyInput)
    }
    
    private func addSubscribers() {
        imageService.$finishedDownloadingAllImages
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { finishedImageDownload in
                self.shouldEnableStartButton = finishedImageDownload
                self.currentDownloadStatusMessage = Strings.imageDownloadingTitle
            })
            .store(in: &cancellables)
        
        imageService.$currentDownloadCount
            .receive(on: DispatchQueue.main)
            .sink { self.currentDownloadCountString = $0 }
            .store(in: &cancellables)
        
        imageService.$imageError
            .drop(while: { $0 == nil })
            .receive(on: DispatchQueue.main)
            .sink { alertItem in
                Log.error("ImageError!")
                self.isShowingAlert = true
                self.alertItem = alertItem
            }
            .store(in: &cancellables)
    }
}
