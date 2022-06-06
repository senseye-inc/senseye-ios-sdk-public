//
//  SingleImageView.swift
//  
//
//  Created by Frank Oftring on 5/26/22.
//

import SwiftUI

@available(iOS 14.0, *)
struct SingleImageView: View {
    let imageName: String
    var body: some View {
        Image(imageName)
            .resizable()
            .scaledToFit()
            .edgesIgnoringSafeArea(.all)
    }
}
