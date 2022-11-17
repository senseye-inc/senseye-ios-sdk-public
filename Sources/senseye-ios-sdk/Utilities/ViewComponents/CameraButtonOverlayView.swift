//
//  CameraButtonOverlayView.swift
//  
//
//  Created by Frank Oftring on 6/1/22.
//

import SwiftUI

struct CameraButtonOverlayView: View {

    @Binding var callToActionText: String

    var body: some View {
        VStack {
            HStack {
                ZStack {
                    Circle()
                        .fill(Color.black)
                        .opacity(0.2)
                        .frame(width: 200, height: 200)
                    VStack {
                        Text(Strings.readyButtonTitle)
                            .font(.title)
                        Text(callToActionText)
                    }
                    .foregroundColor(.senseyeSecondary)
                }
                Spacer()
            }
        }
    }
}

