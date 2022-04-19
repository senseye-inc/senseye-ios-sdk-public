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
                //TODO: Factor out destination and create a DestinationView factory that takes in that var
                //programmatically push new view onto NavigationView using NavigationLink's isActive,
                //meaning that we can trigger the navigation when isSignedIn becomes true rather than
                //when user tapped a button or list row.
                
                ZStack {
                    // Programmatic navigation link
                    NavigationLink(
                        destination: NextView(),
                        isActive: $vm.isUserSignedIn
                    ) { EmptyView() }
                        .opacity(0) // hides disclosure indicator arrow
                        .disabled(!vm.isUserSignedIn) // need this modifier because Form is messing with isActive state variable
                    Button("Login") {
                        vm.login()
                    }
                    .disabled(vm.username.isEmpty || vm.password.isEmpty)
                    .alert("Verify passwords match and temporary password is provided.", isPresented: $vm.isShowingPasswordAlert) {
                        Button("OK", role: .cancel) { }
                    }
                }
            }
        }
        .onAppear {
            vm.onAppear()
        }
    }
        
    
}

@available(iOS 15.0.0, *)
extension LoginView {
    struct NextView: View {
        var body: some View {
            SurveyView()
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
