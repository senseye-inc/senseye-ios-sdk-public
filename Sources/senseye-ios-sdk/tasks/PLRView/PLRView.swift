//
//  PLRView.swift
//
//  Created by Frank Oftring on 5/23/22.
//

import SwiftUI
@available(iOS 14.0, *)
struct PLRView: View {

    @StateObject var viewModel: PLRViewModel = PLRViewModel()
    @EnvironmentObject var tabController: TabController

    var body: some View {
        ZStack {
            viewModel.backgroundColor

            Image(systemName: "xmark")
                .resizable()
                .foregroundColor(viewModel.xMarkColor)
                .scaledToFit()
                .frame(width: 30, height: 25.5)
        }
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            viewModel.showPLR {
                tabController.updateTitle(with: "PLR")
                tabController.nextTab = .imageView
                tabController.open(.confirmationView)
            }
        }
    }
}


