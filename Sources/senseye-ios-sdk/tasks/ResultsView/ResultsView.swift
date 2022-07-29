//
//  SwiftUIView.swift
//  
//
//  Created by Frank Oftring on 4/6/22.
//

import SwiftUI

@available(iOS 14.0, *)
struct ResultsView: View {
    
    @StateObject var resultsViewModel: ResultsViewModel
    @EnvironmentObject var tabController: TabController

    init(fileUploadService: FileUploadAndPredictionService) {
        _resultsViewModel = StateObject(wrappedValue: ResultsViewModel(fileUploadService: fileUploadService))
    }
    
    var body: some View {
        ZStack {
            Color.senseyePrimary
                .edgesIgnoringSafeArea(.all)
            VStack(alignment: .center, spacing: 50) {
                HeaderView()
                    .padding()

                SenseyeProgressView(currentProgress: $resultsViewModel.uploadProgress)

                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.senseyePrimary)
                        .padding()
                        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 20)
                        .shadow(color: Color.black.opacity(0.7), radius: 10, x: 0, y: 5)

                    VStack {
                        Image("analyze_brain")
                            .resizable()
                            .frame(width: 91, height: 91)
                            .padding()

                        Text("You have completed the diagnostic, please speak with your health care provider for further information.")
                            .foregroundColor(.senseyeTextColor)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                    .padding()
                }
                .frame(width: 350, height: 350)

                Spacer()
            }
        }.onAppear {
            resultsViewModel.uploadJsonSessionFile()
        }
    }
}

@available(iOS 14.0, *)
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
