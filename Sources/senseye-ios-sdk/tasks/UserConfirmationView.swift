//
//  UserConfirmationView.swift
//
//  Created by Frank Oftring on 5/25/22.
//

import SwiftUI
@available(iOS 15.0, *)
struct UserConfirmationView: View {

    @EnvironmentObject var tabController: TabController
    @Environment(\.dismiss) var dismiss
    @State var isShowingAlert: Bool = false
    let taskCompleted: String?
    let yesAction: (() -> Void)
    let noAction: (() -> Void)

    init(taskCompleted: String, yesAction: @escaping (() -> Void), noAction: @escaping (() -> Void)) {
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
                        tabController.open(.cameraView)
                    } label: {
                        SenseyeButton(text: "No", foregroundColor: .senseyePrimary, fillColor: .red)
                    }
                    Button {
                        yesAction()
                    } label: {
                        SenseyeButton(text: "Yes", foregroundColor: .senseyePrimary, fillColor: .senseyeSecondary)
                    }
                }
            }
        }
        .alert(isPresented: $isShowingAlert) {
            Alert(title: Text("Thank You"), message: Text("Please tap return to restart the task"), dismissButton: .default(Text("Return"), action: {
                dismiss()
                noAction()
            }))
        }
    }
}
