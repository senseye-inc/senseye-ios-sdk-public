//
//  CameraButtonOverlayView.swift
//  
//
//  Created by Frank Oftring on 6/1/22.
//

import SwiftUI
@available(iOS 13.0.0, *)
struct CameraButtonOverlayView: View {

    var body: some View {
        VStack {
            Spacer()
            HStack {
                ZStack {
                    Circle()
                        .fill(Color.black)
                        .opacity(0.2)
                        .frame(width: 200, height: 200)
                    VStack {
                        Text("Ready?".uppercased())
                            .font(.title)
                        Text("Double tap to start")
                    }
                    .foregroundColor(.senseyeSecondary)
                }
                Spacer()
            }
        }
    }
}
