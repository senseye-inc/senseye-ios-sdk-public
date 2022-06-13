//
//  UserConfirmationView.swift
//
//  Created by Frank Oftring on 5/25/22.
//

import SwiftUI
@available(iOS 15.0, *)
struct UserConfirmationView: View {

    @EnvironmentObject var tabController: TabController
    @Environment(\.presentationMode) var presentationMode
    @State var isShowingAlert: Bool = false
    let taskCompleted: String?
    let yesAction: (() -> Void)?
    let noAction: (() -> Void)?

    init(taskCompleted: String? = nil, yesAction: (() -> Void)? = nil, noAction: (() -> Void)? = nil) {
        self.taskCompleted = taskCompleted
        self.yesAction = yesAction
        self.noAction = noAction
    }

    var body: some View {
        ZStack {
            Color.gray
                .edgesIgnoringSafeArea(.all)

            VStack {
                Spacer()

                Text("Was this a good recording for \(taskCompleted ?? "n/a")?")
                    .font(.title)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Spacer()

                HStack {
                    Button {
                        isShowingAlert = true
                        if let noAction = noAction {
                            noAction()
                        }
                    } label: {
                        SenseyeButton(text: "No", foregroundColor: .senseyePrimary, fillColor: .red)
                    }
                    Button {
                        if let yesAction = yesAction {
                            yesAction()
                        }
                    } label: {
                        SenseyeButton(text: "Yes", foregroundColor: .senseyePrimary, fillColor: .senseyeSecondary)
                    }
                }
            }
        }
        .alert("Thank you, please tap return to restart the task", isPresented: $isShowingAlert) {
            Button("Return") {
                presentationMode.wrappedValue.dismiss()
                isShowingAlert = false
                tabController.open(.cameraView)
            }
        }
    }
}
