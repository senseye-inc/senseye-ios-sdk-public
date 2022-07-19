//
//  SurveyViewModel.swift
//
//  Created by Frank Oftring on 6/9/22.
//

import Foundation
import SwiftUI

@available(iOS 14.0, *)
class SurveyViewModel: ObservableObject {
    
    @AppStorage("selectedAge") var selectedAge: Int = 0
    @AppStorage("selectedEyeColor") var selectedEyeColor: String = ""
    @AppStorage("selectedGender") var selectedGender: String = ""
    
    var fileUploadService: FileUploadAndPredictionServiceProtocol
    
    init(fileUploadService: FileUploadAndPredictionServiceProtocol) {
        self.fileUploadService = fileUploadService
    }

    var eyeColorOptions: [String] = ["Blue", "Green", "Brown", "Black", "Hazel"]
    var genderOptions: [String] = ["Male", "Female", "Other"]
    var ageRange: Range<Int> = (20..<100)

    var surveyIsEmpty: Bool {
        selectedAge != 0 && selectedEyeColor != "" && selectedGender != ""
    }
        
    func createSessionJsonFile() {
        var surveyInput : [String: String] = [:]
        surveyInput["age"] = String(selectedAge ?? -1)
        surveyInput["gender"] = selectedEyeColor
        surveyInput["eyeColor"] = selectedGender
        fileUploadService.createSessionInputJsonFile(surveyInput: surveyInput)
    }
}
