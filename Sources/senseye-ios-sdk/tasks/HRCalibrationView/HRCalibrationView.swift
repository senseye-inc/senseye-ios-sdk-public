//
//  HRCalibrationView.swift
//  
//
//  Created by Deepak Kumar on 9/30/22.
//

import SwiftUI

@available(iOS 15.0, *)
struct HRCalibrationView: View {
    
    @StateObject var viewModel: HRCalibrationViewModel
    @EnvironmentObject var tabController: TabController
    
    init(fileUploadService: FileUploadAndPredictionService) {
        _viewModel = StateObject(wrappedValue: HRCalibrationViewModel(fileUploadService: fileUploadService))
    }
    
    var body: some View {
        ZStack {
            viewModel.backgroundColor
            Text(tabController.descriptionForCurrentTab())
                .font(.title2)
                .padding(10)
        }
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            DispatchQueue.main.async {
                viewModel.startHRCalibration()
            }
        }
        .fullScreenCover(isPresented: $viewModel.shouldShowConfirmationView) {
            UserConfirmationView(yesAction: {
                viewModel.shouldShowConfirmationView.toggle()
                viewModel.addTaskInfoToJson()
                tabController.proceedToNextTab()
            }, noAction: {
                tabController.refreshSameTab()
            })
        }
    }
}
