//
//  SingleImageView.swift
//  
//
//  Created by Frank Oftring on 5/26/22.
//

import SwiftUI

@available(iOS 15.0, *)
struct SingleImageView: View {
    let imageName: URL
    var body: some View {
        AsyncImage(url: imageName) { image in
            image
                .resizable()
                .edgesIgnoringSafeArea(.all)
        } placeholder: {
            ProgressView("Downloading image sets…")
                .scaleEffect(1.5, anchor: .center)
                .progressViewStyle(.circular)
                .tint(.senseyeSecondary)
                .foregroundColor(.senseyeSecondary)
        }
    }
}
