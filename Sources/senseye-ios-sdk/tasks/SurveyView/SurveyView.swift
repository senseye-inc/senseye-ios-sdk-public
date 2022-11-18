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
                    Text(Strings.surveyViewCallToActionText)
                        .font(.title)
                        .foregroundColor(.senseyeSecondary)
                        .bold()
                    Text(Strings.surveyViewInstructions)
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
                            Text(Strings.debugModeDescription)
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
                        SenseyeButton(text: Strings.startButtonTitle, foregroundColor: .senseyePrimary, fillColor: .senseyeSecondary)
                    }.disabled(viewModel.shouldEnableStartButton == false)
                }
            }
        }
        .alert(viewModel.alertItem?.title ?? "", isPresented: $viewModel.isShowingAlert) {
            Button(viewModel.alertItem?.alertButtonText ?? "") { }
        } message: {
            Text(viewModel.alertItem?.message ?? "")
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
            SenseyePicker(title: Strings.ageTitle, currentValue: viewModel.selectedAge?.description)
        }
    }

    var genderPicker: some View {
        Menu {
            Picker("", selection: $viewModel.selectedGender) {
                ForEach(viewModel.genderOptions, id: \.self) { gender in
                    Text(gender.localizedStringKey)
                        .tag(Optional(gender.localizedString))
                }
            }
        } label: {
            SenseyePicker(title: Strings.ageTitle, currentValue: "\(viewModel.selectedGender ?? "N/A")")
        }
    }

    var eyeColorPicker: some View {
        Menu {
            Picker("", selection: $viewModel.selectedEyeColor) {
                ForEach(viewModel.eyeColorOptions, id: \.self) { eyeColor in
                    Text(eyeColor.localizedStringKey)
                        .tag(Optional(eyeColor.localizedString))
                }
            }
        } label: {
            SenseyePicker(title: Strings.eyeColorTitle, currentValue: "\(viewModel.selectedEyeColor ?? "N/A")")
        }
    }
}
