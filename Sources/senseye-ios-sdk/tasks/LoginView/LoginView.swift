//
//  LoginVIew.swift
//  senseye-ios-sdk-app
//
//  Created by Bobby Srisan on 4/3/22.
//

import SwiftUI

@available(iOS 15.0.0, *)
struct LoginView: View {
    
    // ViewModel class is extension of LoginView
    @StateObject private var vm: ViewModel
    @EnvironmentObject var tabController: TabController

    var body: some View {
        Form {
            Section {
                TextField("User Name", text: $vm.username )
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                SecureField("Password", text: $vm.password )
                Toggle("New Account?", isOn: $vm.isNewAccount.animation())

                if (vm.isNewAccount) {
                    SecureField("Verify Password", text: $vm.newPassword )
                    SecureField("Temporary Password", text: $vm.temporaryPassword)
                }
            }

            Section {
                // Programmatic navigation link
                Button("Login") {
                    vm.login()
                }
                .disabled(vm.username.isEmpty || vm.password.isEmpty)
                .alert("Verify passwords match and temporary password is provided.", isPresented: $vm.isShowingPasswordAlert) {
                    Button("OK", role: .cancel) { }
                }
            }
        }
        .onAppear {
            vm.onAppear()
        }
        .onChange(of: vm.isUserSignedIn) { _ in
            tabController.open(.surveyView)
        }
    }
}

@available(iOS 15.0.0, *)
extension LoginView {
    init(authenticationService: AuthenticationService) {
        _vm = StateObject(wrappedValue: ViewModel(authenticationService: authenticationService))
    }
}

@available(iOS 15.0.0, *)
struct LoginView_Previews: PreviewProvider {
    static let authenticationService = AuthenticationService()
    static var previews: some View {
        NavigationView {
            LoginView(authenticationService: authenticationService)
        }
    }
}
