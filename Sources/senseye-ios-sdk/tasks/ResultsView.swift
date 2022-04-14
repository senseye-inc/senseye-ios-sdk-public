//
//  SwiftUIView.swift
//  
//
//  Created by Frank Oftring on 4/6/22.
//

import SwiftUI

@available(iOS 14.0, *)
struct ResultsView: View {
    
    @StateObject var resultsViewModel: ResultsViewModel = ResultsViewModel()
    
    var body: some View {
        ZStack {
            Color.senseyePrimary
                .edgesIgnoringSafeArea(.all)
            VStack(alignment: .center) {
                HeaderView()
                Image(systemName: "checkmark.circle.fill")
                    .resizable()
                    .frame(width: 91, height: 91)
                    .foregroundColor(.senseyeSecondary)
                    .padding()
                VStack(alignment: .leading, spacing: 10) {
                    ResultNameAndImageStack(resultName: "General Impairment", resultPassed: true, resultDescription: nil)
                    ResultNameAndImageStack(resultName: "General Intoxication", resultPassed: false, resultDescription: nil)
                        .padding(.bottom, 35)
                    ResultNameAndImageStack(resultName: "Alcohol", resultPassed: true, resultDescription: "bac 0.2")
                    ResultNameAndImageStack(resultName: "Fatigue", resultPassed: true, resultDescription: nil)
                    ResultNameAndImageStack(resultName: "Marijuana", resultPassed: true, resultDescription: nil)
                }
                
                Spacer()
                
                Button {
                    print("Button Tapped")
                } label: {
                    SenseyeButton(text: "Home")
                }

                Spacer()
                
                Text("Status: \(resultsViewModel.predictionStatus)")
                    .foregroundColor(.senseyeTextColor)
                
                Spacer()
            }
            
            if resultsViewModel.isLoading {
                ProcessingScreen()
            }
            
        }
        .onAppear {
            resultsViewModel.startPredictions()
        }
    }
}

@available(iOS 13.0, *)
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

@available(iOS 13.0.0, *)
struct SenseyeButton: View {
    
    let text: String

    var body: some View {
        Text(text.uppercased())
            .foregroundColor(.senseyePrimary)
            .padding()
            .frame(width: 147, height: 52)
            .background(
                RoundedRectangle(
                    cornerRadius: 34,
                    style: .continuous
                )
                .fill(Color.senseyeSecondary)
            )
    }
}
