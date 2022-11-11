//
//  SingleImageView.swift
//  
//
//  Created by Frank Oftring on 5/26/22.
//

import SwiftUI

struct SingleImageView: View {

    @Binding var isLoading: Bool
    var image: UIImage?

    var body: some View {
        ZStack {
            if isLoading {
                ProgressView("Downloading image sets…")
                    .progressViewStyle(.circular)
                    .foregroundColor(.senseyeSecondary)
            } else if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .edgesIgnoringSafeArea(.all)
            }
        }
    }
}
