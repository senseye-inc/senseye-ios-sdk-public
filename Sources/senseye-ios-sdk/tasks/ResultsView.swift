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
                VStack(alignment: .trailing) {
                    Image("whiteLogo")
                    Text("Fitness for duty".uppercased())
                        .font(.title2)
                        .foregroundColor(.senseyeSecondary)
                }
                Image(systemName: "checkmark.circle.fill")
                    .resizable()
                    .frame(width: 91, height: 91)
                    .foregroundColor(.senseyeSecondary)
                    .padding()
                VStack(alignment: .leading) {
                    ResultNameAndImageStack(resultName: "General Impairment", resultPassed: true, resultDescription: nil)
                    ResultNameAndImageStack(resultName: "General Intoxication", resultPassed: false, resultDescription: nil)
                        .padding(.bottom, 35)
                    ResultNameAndImageStack(resultName: "Alcohol", resultPassed: true, resultDescription: "0.2")
                    ResultNameAndImageStack(resultName: "Fatigue", resultPassed: true, resultDescription: nil)
                    ResultNameAndImageStack(resultName: "Marijuana", resultPassed: true, resultDescription: nil)
                }
                
                Spacer()
                if resultsViewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .senseyeSecondary))
                        .scaleEffect(3)
                }
                
                Button {
                    print("Button Tapped")
                } label: {
                    Text("Home".uppercased())
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

                Spacer()
                
                Text("Status: \(resultsViewModel.predictionStatus)")
                    .foregroundColor(.senseyeTextColor)
                
                Spacer()
            }
        }
        .onAppear {
            print("Calling on appear")
            resultsViewModel.startPredictions()
        }
    }
}

@available(iOS 14.0, *)
struct SwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        ResultsView()
    }
}

@available(iOS 13.0, *)
struct ResultNameAndImageStack: View {
    
    let resultName: String
    let resultPassed: Bool
    let resultDescription: String?
    
    var body: some View {
        HStack {
            Text(resultName.uppercased())
                .foregroundColor(.senseyeTextColor)
            Image(systemName: resultPassed ? "checkmark.circle.fill" : "x.circle.fill")
                .foregroundColor(resultPassed ? .senseyeSecondary : .senseyeRed)
        }
    }
}
