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
    @StateObject var viewModel : SurveyViewModel
    let authenticationService: AuthenticationService

    init(authenticationService: AuthenticationService, fileUploadAndPredictionService: FileUploadAndPredictionService) {
        self.authenticationService = authenticationService
        _viewModel = StateObject(wrappedValue: SurveyViewModel(fileUploadService: fileUploadAndPredictionService))
    }
    
    var body: some View {
        ZStack {
            Color.senseyePrimary
                .edgesIgnoringSafeArea(.all)
            VStack {
                Spacer()

                VStack {
                    Text("Let's get started.")
                        .font(.title)
                        .foregroundColor(.senseyeSecondary)
                        .bold()
                    Text("First, please take a moment to log your recent activity.")
                        .foregroundColor(.senseyeTextColor)
                        .bold()
                        .multilineTextAlignment(.center)
                }

                Spacer()

                agePicker

                genderPicker

                eyeColorPicker

                Spacer()
                Spacer()

                HStack(spacing: 100) {
                    Button {
                        authenticationService.signOut {
                            tabController.proceedToPreviousTab()
                        }
                    } label: {
                        Image(systemName: "arrow.left.circle.fill")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.senseyeTextColor)
                            .padding()
                    }

                    Button {
                        tabController.proceedToNextTab()
                        viewModel.createSessionJsonFile()
                    } label: {
                        SenseyeButton(text: "start", foregroundColor: .senseyePrimary, fillColor: .senseyeSecondary)
                    }
                }
            }
        }
    }
}

@available(iOS 15.0, *)
extension SurveyView {

    var agePicker: some View {
        Menu {
            Picker("", selection: $viewModel.selectedAge) {
                ForEach(viewModel.ageRange, id: \.self) { age in
                    Text("\(age)")
                        .tag(Optional(age))
                }
            }
        } label: {
            SenseyePicker(title: "age", currentValue: viewModel.selectedAge?.description)
        }
    }

    var genderPicker: some View {
        Menu {
            Picker("", selection: $viewModel.selectedGender) {
                ForEach(viewModel.genderOptions, id: \.self) { gender in
                    Text("\(gender)")
                        .tag(Optional(gender))
                }
            }
        } label: {
            SenseyePicker(title: "gender", currentValue: viewModel.selectedGender)
        }
    }

    var eyeColorPicker: some View {
        Menu {
            Picker("", selection: $viewModel.selectedEyeColor) {
                ForEach(viewModel.eyeColorOptions, id: \.self) { eyeColor in
                    Text("\(eyeColor)")
                        .tag(Optional(eyeColor))
                }
            }
        } label: {
            SenseyePicker(title: "eye color", currentValue: viewModel.selectedEyeColor)
        }
    }
}
