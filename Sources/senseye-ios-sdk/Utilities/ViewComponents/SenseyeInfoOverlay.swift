//  SenseyeInfoOverlay.swift
//
//  Created by Frank Oftring on 7/15/22.
//

import SwiftUI

struct SenseyeInfoOverlay: View {

    let title: String
    let description: String
    @Binding var showingOverlay: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.senseyePrimary)
                .padding()
                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 20)
                .shadow(color: Color.black.opacity(0.7), radius: 10, x: 0, y: 5)

            VStack {
                Text(title)
                    .font(.largeTitle)
                    .foregroundColor(.white)

                Image("person_staring_image", bundle: .module)
                    .resizable()
                    .frame(width: 150, height: 150)

                Text(description)
                    .padding()
                    .font(.body)
                    .foregroundColor(.white)

                Button(action: {
                    DispatchQueue.main.async {
                        showingOverlay.toggle()
                    }
                }, label: {
                    SenseyeButton(text: Strings.continueButtonText, foregroundColor: .senseyePrimary, fillColor: .senseyeSecondary)
                })
                .foregroundColor(.white)
                .interactiveDismissDisabled()
            }
            .multilineTextAlignment(.center)
            .padding()
        }
        .frame(height: 650)
    }
}
