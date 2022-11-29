//
//  SwiftUIView.swift
//  
//
//  Created by Frank Oftring on 4/6/22.
//

import SwiftUI

struct ResultsView: View {
    
    @StateObject var viewModel: ResultsViewModel
    @EnvironmentObject var tabController: TabController
    @EnvironmentObject var authenticationService: AuthenticationService

    init(fileUploadService: FileUploadAndPredictionService) {
        _viewModel = StateObject(wrappedValue: ResultsViewModel(fileUploadService: fileUploadService))
    }
    
    var body: some View {
        ZStack {
            Color.senseyePrimary
                .edgesIgnoringSafeArea(.all)
            VStack(alignment: .center, spacing: 20) {
                HeaderView()

                SenseyeProgressView(isFinished: viewModel.isFinished, uploadProgress: $viewModel.uploadProgress)

                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.senseyePrimary)
                        .padding()
                        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 20)
                        .shadow(color: Color.black.opacity(0.7), radius: 10, x: 0, y: 5)
                    
                    if viewModel.isFinished {
                        VStack {
                            Image("analyze_brain")
                                .resizable()
                                .frame(width: 91, height: 91)
                                .padding()

                            Text(Strings.resultsViewDescription)
                                .foregroundColor(.senseyeTextColor)
                                .multilineTextAlignment(.center)
                                .padding()
                            
                            Button {
                                authenticationService.signOut {
                                    Log.info("Sign out complete. Closing app")
                                    tabController.reset()
                                    viewModel.reset()
                                }
                            } label: {
                                SenseyeButton(text: Strings.completionSessionButtonTitle, foregroundColor: .senseyePrimary, fillColor: .senseyeSecondary)
                            }.padding(.top, 40)
                        }
                    } else {
                        VStack {
                            Image(systemName: "gearshape.fill")
                                .resizable()
                                .foregroundColor(.senseyeTextColor)
                                .frame(width: 91, height: 91)
                                .padding()

                            Text(viewModel.hasResultCompleteTimerElapsed ? Strings.resultsDelayed : Strings.resultsProcessing)
                                .foregroundColor(.senseyeTextColor)
                                .multilineTextAlignment(.center)
                                .padding([.leading, .trailing], 20)
                        }
                    }
                }
                .frame(width: 350, height: 450)
                .onAppear {
                    DispatchQueue.main.async {
                        viewModel.onAppear()
                    }
                }

                Spacer()
            }
        }
    }
}

struct ResultNameAndImageStack: View {
    
    let resultName: String
    let resultPassed: Bool
    let resultDescription: String?
    
    var body: some View {
        HStack {
            HStack {
                Text(resultName.uppercased())
                Text(resultDescription?.uppercased() ?? "")
            }
            .foregroundColor(.senseyeTextColor)
            Spacer()
            Image(systemName: resultPassed ? "checkmark.circle.fill" : "x.circle.fill")
                .foregroundColor(resultPassed ? .senseyeSecondary : .senseyeRed)
        }
        .frame(maxWidth: 250)
    }
}
