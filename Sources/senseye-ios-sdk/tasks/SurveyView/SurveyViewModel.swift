//
//  SurveyViewModel.swift
//
//  Created by Frank Oftring on 6/9/22.
//

import Foundation
import SwiftUI

@available(iOS 14.0, *)
class SurveyViewModel: ObservableObject {
    
    @AppStorage("selectedAge") var selectedAge: Int?
    @AppStorage("selectedEyeColor") var selectedEyeColor: String?
    @AppStorage("selectedGender") var selectedGender: String?
    @Published var enableDebugMode: Bool = false
    
    var fileUploadService: FileUploadAndPredictionServiceProtocol
    
    init(fileUploadService: FileUploadAndPredictionServiceProtocol) {
        self.fileUploadService = fileUploadService
    }

    var eyeColorOptions: [String] = ["Blue", "Green", "Brown", "Black", "Hazel"].sorted().reversed()
    var genderOptions: [String] = ["Male", "Female", "Other"]
    var ageRange: Range<Int> = (18..<66)

    var surveyIsEmpty: Bool {
        selectedAge != 0 && selectedEyeColor != "" && selectedGender != ""
    }
    
    func updateDebugModeFlag() {
        fileUploadService.enableDebugMode = self.enableDebugMode
    }
    
    func createSessionJsonFile() {
        var surveyInput : [String: String] = [:]
        surveyInput["age"] = String(selectedAge ?? -1)
        surveyInput["gender"] = selectedGender
        surveyInput["eyeColor"] = selectedEyeColor
        fileUploadService.createSessionJsonFileAndStoreCognitoUserAttributes(surveyInput: surveyInput)
    }
}
