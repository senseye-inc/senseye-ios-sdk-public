//
//  ProgressView.swift
//
//  Created by Frank Oftring on 6/22/22.
//

import SwiftUI
@available(iOS 14.0, *)
struct SenseyeProgressView: View {

    @Binding var uploadProgress: Double
    private var isFinished: Bool
    
    init(isFinished: Bool, uploadProgress: Binding<Double>) {
        self.isFinished = isFinished
        self._uploadProgress = uploadProgress
    }

    var body: some View {
        ZStack {
            Color.senseyePrimary
                .edgesIgnoringSafeArea(.all)
            VStack {
                if isFinished {
                    Image(systemName: "checkmark.circle.fill")
                        .resizable()
                        .foregroundColor(.senseyeSecondary)
                        .frame(width: 100, height: 100)
                } else {
                    ProgressBar(uploadProgress: $uploadProgress).frame(height: 10)
                }
            }
            .padding()
            .animation(.easeInOut(duration: 0.25))
        }
    }
}

@available(iOS 14.0, *)
struct ProgressBar: View {
    @Binding var uploadProgress: Double

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle().frame(width: geometry.size.width , height: geometry.size.height)
                    .opacity(0.3)
                    .foregroundColor(Color(UIColor.systemTeal))

                Rectangle().frame(width: min(CGFloat(self.uploadProgress)*geometry.size.width, geometry.size.width), height: geometry.size.height)
                    .foregroundColor(.senseyeSecondary)
                    .animation(.linear)
            }.cornerRadius(45.0)
        }
    }
}
