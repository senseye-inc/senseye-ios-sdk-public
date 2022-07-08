//
//  SwiftUIView.swift
//  
//
//  Created by Frank Oftring on 6/9/22.
//

import SwiftUI

@available(iOS 15.0, *)
struct SurveyView: View {
    @EnvironmentObject var tabController: TabController
    @StateObject var viewModel = SurveyViewModel()
    
    var body: some View {
        Form {
            Picker("Age", selection: $viewModel.selectedAge) {
                ForEach(viewModel.ageRange, id: \.self) { age in
                    Text("\(age)")
                        .tag(Optional(age))
                }
            }
            Picker("Gender", selection: $viewModel.selectedGender) {
                ForEach(viewModel.genderOptions, id: \.self) { gender in
                    Text(gender)
                        .tag(Optional(gender))
                }
            }
            Picker("Eye Color", selection: $viewModel.selectedEyeColor) {
                ForEach(viewModel.eyeColorOptions, id: \.self) { eyeColor in
                    Text(eyeColor)
                        .tag(Optional(eyeColor))
                }
            }
            Section {
                Button {
                    tabController.proceedToNextTab()
                    //tabController.open(.cameraView)
                } label: {
                    Text("Continue")
                }
            }
            .disabled(!viewModel.surveyIsEmpty)
        }
    }
}
