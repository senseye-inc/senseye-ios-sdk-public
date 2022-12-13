//
//  SFSafariViewWrapper.swift
//  
//
//  Created by Frank Oftring on 9/27/22.
//

import SwiftUI
import SafariServices
@available(iOS 13.0, *)
struct SFSafariViewWrapper: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: UIViewControllerRepresentableContext<Self>) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: UIViewControllerRepresentableContext<SFSafariViewWrapper>) {
        return
    }
}
