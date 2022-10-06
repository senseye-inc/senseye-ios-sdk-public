//
//  SurveyViewModel.swift
//
//  Created by Frank Oftring on 6/9/22.
//

import Foundation
import SwiftUI
import Combine

@available(iOS 14.0, *)
class SurveyViewModel: ObservableObject {
    
    @AppStorage("isShowingDebugToggle") var isShowingDebugToggle: Bool?
    @AppStorage("selectedAge") var selectedAge: Int?
    @AppStorage("selectedEyeColor") var selectedEyeColor: String?
    @AppStorage("selectedGender") var selectedGender: String?
    @Published var debugModeEnabled: Bool = false
    @Published var shouldEnableStartButton: Bool = false
    @Published var currentDownloadStatusMessage: String = ""
    private var cancellables = Set<AnyCancellable>()
    
    var fileUploadService: FileUploadAndPredictionServiceProtocol
    let imageService: ImageService
    
    init(fileUploadService: FileUploadAndPredictionServiceProtocol, imageService: ImageService) {
        self.fileUploadService = fileUploadService
        self.imageService = imageService
        addSubscribers()
    }

    var eyeColorOptions: [String] = ["Blue", "Green", "Brown", "Black", "Hazel"].sorted().reversed()
    var genderOptions: [String] = ["Male", "Female", "Other"]
    var ageRange: Range<Int> = (18..<66)

    var surveyIsEmpty: Bool {
        selectedAge != 0 && selectedEyeColor != "" && selectedGender != ""
    }
    
    func updateDebugModeFlag() {
        fileUploadService.isDebugModeEnabled = self.debugModeEnabled
    }
    
    func reset() {
        debugModeEnabled = false
        fileUploadService.isDebugModeEnabled = false
        isShowingDebugToggle = false
        selectedAge = nil
        selectedGender = nil
        selectedEyeColor = nil
    }
    
    func createSessionJsonFile() {
        var surveyInput : [String: String] = [:]
        surveyInput["age"] = String(selectedAge ?? -1)
        surveyInput["gender"] = selectedGender
        surveyInput["eyeColor"] = selectedEyeColor
        fileUploadService.createSessionJsonFileAndStoreCognitoUserAttributes(surveyInput: surveyInput)
    }
    
    func addSubscribers() {
        imageService.$finishedDownloadingAllImages
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { finishedImageDownload in
                self.shouldEnableStartButton = finishedImageDownload
                self.currentDownloadStatusMessage = "Downloading the Image Set, please give it a few minutes.. \(self.imageService.currentDownloadCount)"
            })
            .store(in: &cancellables)
    }
}
