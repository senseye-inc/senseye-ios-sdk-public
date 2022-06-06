//
//  UserConfirmationView.swift
//
//  Created by Frank Oftring on 5/25/22.
//

import SwiftUI
@available(iOS 14.0, *)
struct UserConfirmationView: View {

    @EnvironmentObject var tabController: TabController
    let taskCompleted: String

    var body: some View {
        ZStack {
            Color.gray
                .edgesIgnoringSafeArea(.all)

            VStack {
                Spacer()

                Text("Was this a good recording for \(taskCompleted)?")
                    .font(.title)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Spacer()

                HStack {
                    Button {
                        print("No Pressed")
                    } label: {
                        SenseyeButton(text: "No", foregroundColor: .senseyePrimary, fillColor: .red)
                    }

                    Button {
                        print("Active Tab: \(tabController.activeTab)")
                        if let nextTab = tabController.nextTab {
                            print("Next Tab: \(tabController.nextTab)")
                            tabController.open(nextTab)
                        }
                    } label: {
                        SenseyeButton(text: "Yes", foregroundColor: .senseyePrimary, fillColor: .senseyeSecondary)
                    }
                }
            }
        }
    }
}
