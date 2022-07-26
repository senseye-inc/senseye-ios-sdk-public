//  SenseyeInfoOverlay.swift
//
//  Created by Frank Oftring on 7/15/22.
//

import SwiftUI
@available(iOS 15.0, *)
struct SenseyeInfoOverlay: View {

    @Binding var showingOverlay: Bool

    private var title: String
    private var description: String

    init(title: String, description: String, showingOverlay: Binding<Bool>) {
        self.title = title
        self.description = description
        self._showingOverlay = showingOverlay
    }

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

                Image("person_staring_image")
                    .resizable()
                    .frame(width: 150, height: 150)

                Text(description)
                    .padding()
                    .font(.body)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Button(action: {
                    DispatchQueue.main.async {
                        showingOverlay.toggle()
                    }
                }, label: {
                    SenseyeButton(text: "Continue", foregroundColor: .senseyePrimary, fillColor: .senseyeSecondary)
                })
                .foregroundColor(.white)
                .interactiveDismissDisabled()
            }
            .padding()
        }
        .frame(height: 650)
    }
}
