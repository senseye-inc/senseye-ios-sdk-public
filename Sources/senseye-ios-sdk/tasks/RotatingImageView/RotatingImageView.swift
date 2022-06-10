//
//  ImageView.swift
//
//  Created by Frank Oftring on 5/19/22.
//

import SwiftUI

@available(iOS 15.0, *)
struct RotatingImageView: View {

    @StateObject var viewModel: RotatingImageViewModel = RotatingImageViewModel()
    @EnvironmentObject var tabController: TabController

    var body: some View {
        ZStack {
            Color.black
                .edgesIgnoringSafeArea(.all)

            GeometryReader { geometry in
                HStack(spacing: 0) {
                    SingleImageView(imageName: viewModel.currentImageName)
                }
                .frame(width: geometry.size.width, height: geometry.size.height, alignment: .leading)
                .onAppear {
                    viewModel.showImages {
                        if viewModel.finishedAllTasks {
                            tabController.nextTab = .resultsView
                        } else {
                            tabController.nextTab = .plrView
                        }
                        tabController.updateTitle(with: "PTSD \(viewModel.numberOfImagesShown)/\(viewModel.totalNumberOfImagesToBeShown)")
                        tabController.open(.confirmationView)
                    }
                }
            }
        }
    }
}
