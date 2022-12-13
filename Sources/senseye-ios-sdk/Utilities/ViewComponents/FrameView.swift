//
//  FrameView.swift
//  
//
//  Created by Deepak Kumar on 7/28/22.
//

import SwiftUI

struct FrameView: View {
    var image: Binding<CGImage?>
    private let label = Text("Camera feed")
    var body: some View {
        if let image = image.wrappedValue {
          GeometryReader { geometry in
              Image(image, scale: 1.0, orientation: .upMirrored, label: label)
              .resizable()
              .scaledToFill()
              .frame(
                width: geometry.size.width,
                height: geometry.size.height,
                alignment: .center)
              .clipped()
          }
        } else {
          Color.black
        }
    }
}
