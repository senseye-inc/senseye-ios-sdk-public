//
//  UserConfirmationView.swift
//
//  Created by Frank Oftring on 5/25/22.
//

import SwiftUI

struct UserConfirmationView: View {
    
    @EnvironmentObject var tabController: TabController
    @Environment(\.dismiss) var dismiss
    @State var isShowingAlert: Bool = false
    let yesAction: (() -> Void)
    let noAction: (() -> Void)
    
    init(yesAction: @escaping (() -> Void), noAction: @escaping (() -> Void)) {
        self.yesAction = yesAction
        self.noAction = noAction
    }
    
    var body: some View {
        ZStack {
            Color.gray
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                Spacer()
                
                Text("Was this a good recording for \(tabController.titleForCurrentTab())?")
                    .font(.title)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Spacer()
                
                HStack {
                    Button {
                        isShowingAlert = true
                    } label: {
                        SenseyeButton(text: "No", foregroundColor: .senseyePrimary, fillColor: .red)
                    }
                    Button {
                        yesAction()
                        DispatchQueue.main.async {
                            dismiss()
                        }
                    } label: {
                        SenseyeButton(text: "Yes", foregroundColor: .senseyePrimary, fillColor: .senseyeSecondary)
                    }
                }
            }
        }
        .alert("Thank You", isPresented: $isShowingAlert) {
            Button("Return") {
                dismiss()
                noAction()
            }
        } message: {
            Text("Please tap return to restart the task")
        }

    }
}
