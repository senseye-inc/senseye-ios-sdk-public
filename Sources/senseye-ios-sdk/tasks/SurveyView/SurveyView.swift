//
//  SwiftUIView.swift
//  
//
//  Created by Frank Oftring on 6/9/22.
//

import SwiftUI

struct SurveyView: View {
    @EnvironmentObject var tabController: TabController
    @StateObject var viewModel : SurveyViewModel
    @State var isPresentingSettingsView: Bool = false

    init(fileUploadAndPredictionService: FileUploadAndPredictionService, imageService: ImageService, authenticationService: AuthenticationService) {
        _viewModel = StateObject(wrappedValue: SurveyViewModel(fileUploadService: fileUploadAndPredictionService, imageService: imageService, authenticationService: authenticationService))
    }
    
    var body: some View {
        ZStack {
            Color.senseyePrimary.edgesIgnoringSafeArea(.all)
            VStack(spacing: 20) {
                HStack {
                    Spacer()
                    HeaderView()
                        .padding(.leading, 10)
                    Spacer()
                    Button(action: {
                        isPresentingSettingsView.toggle()
                    }, label: {
                        Image(systemName: "line.3.horizontal.circle.fill")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .foregroundColor(.senseyeTextColor)
                            .padding(.horizontal, 10)
                    })
                }
                VStack {
                    Text("Let's get started.")
                        .font(.title)
                        .foregroundColor(.senseyeSecondary)
                        .bold()
                    Text("Please enter your information below.")
                        .foregroundColor(.senseyeTextColor)
                        .bold()
                        .multilineTextAlignment(.center)
                }

                Spacer()
                agePicker
                genderPicker
                eyeColorPicker
                if viewModel.isShowingDebugToggle ?? false {
                    VStack {
                        Toggle(isOn: $viewModel.isDebugModeEnabled) {
                            Text("Enable Debug Mode")
                                .foregroundColor(.white)
                        }.padding()
                        Toggle(isOn: $viewModel.isCensorModeEnabled) {
                            Text("Enable Censor Mode")
                                .foregroundColor(.white)
                        }.padding()
                    }
                }
                if !viewModel.shouldEnableStartButton {
                    VStack {
                        Text(viewModel.currentDownloadStatusMessage)
                            .bold()
                        Text(viewModel.currentDownloadCountString)
                    }
                    .font(.subheadline)
                    .foregroundColor(.senseyeTextColor)
                    .multilineTextAlignment(.center)
                }
                Spacer()
                HStack(spacing: 100) {
                    Button {
                        viewModel.onBackButton()
                        tabController.proceedToPreviousTab()
                    } label: {
                        Image(systemName: "arrow.left.circle.fill")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.senseyeTextColor)
                            .padding()
                    }

                    Button {
                        viewModel.onStartButton()
                        tabController.proceedToNextTab()
                    } label: {
                        SenseyeButton(text: "start", foregroundColor: .senseyePrimary, fillColor: .senseyeSecondary)
                    }.disabled(viewModel.shouldEnableStartButton == false)
                }
            }
        }
        .onAppear {
            viewModel.onAppear()
            tabController.areInternalTestingTasksEnabled = viewModel.isInternalTestingGroup
        }
        .sheet(isPresented: self.$isPresentingSettingsView) {
            isPresentingSettingsView = false
        } content: {
            SettingsView()
        }
    }
}

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
