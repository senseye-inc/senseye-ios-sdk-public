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

    var eyeColorOptions: [String] = ["Blue", "Green", "Brown", "Black"]
    var genderOptions: [String] = ["Male", "Female", "Other"]
    var ageRange: Range<Int> = (20..<100)

    var surveyIsEmpty: Bool {
        selectedAge != 0 && selectedEyeColor != "" && selectedGender != ""
    }
}
