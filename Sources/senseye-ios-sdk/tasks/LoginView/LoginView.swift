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
        ZStack {
            Color.senseyePrimary
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 20) {
                headerView

                VStack {
                    usernameField

                    passwordField
                }
                .padding()

                VStack {
                    Toggle("New Account?", isOn: $vm.isNewAccount.animation())
                        .foregroundColor(.senseyeTextColor)

                    if (vm.isNewAccount) {
                        Spacer()

                        verifyPasswordView

                        temporaryPasswordView
                    }
                }
                .padding(.horizontal, 35)

                Text("Having trouble logging in?")
                    .foregroundColor(.senseyeTextColor)

                Button(action: {
                    vm.login()
                }, label: {
                    SenseyeButton(text: "login", foregroundColor: .senseyePrimary, fillColor: .senseyeSecondary)
                        .padding()
                })
                .disabled(vm.username.isEmpty || vm.password.isEmpty)
                .alert("Verify passwords match and temporary password is provided.", isPresented: $vm.isShowingPasswordAlert) {
                    Button("OK", role: .cancel) { }
                }
                Spacer()

                HStack {
                    Spacer()
                    Text("Version: " + (vm.appVersion ?? "Version Number Error"))
                        .foregroundColor(.senseyeTextColor)
                        .padding(.trailing)
                }
            }
        }
        .onAppear {
            vm.onAppear()
        }
        .onChange(of: vm.isUserSignedIn) { signedIn in
            if signedIn {
                tabController.proceedToNextTab()
            }
        }
    }
}

@available(iOS 15.0.0, *)
extension LoginView {
    init(authenticationService: AuthenticationService) {
        _vm = StateObject(wrappedValue: ViewModel(authenticationService: authenticationService))
    }

    var passwordField: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("password".uppercased())
                .foregroundColor(.senseyeTextColor)
            SecureField("", text: $vm.password)
                .foregroundColor(.senseyeTextColor)
            Divider()
                .background(Color.senseyeTextColor)
        }
        .padding(.horizontal, 35)
    }

    var usernameField: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("username".uppercased())
                .foregroundColor(.senseyeTextColor)
            TextField("", text: $vm.username)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .foregroundColor(.senseyeTextColor)
            Divider()
                .background(Color.senseyeTextColor)
        }
        .padding(.horizontal, 35)
    }

    var headerView: some View {
        VStack {
            HeaderView()
                .padding()
            Image("holding_phone_icon")
            Text("Login to get started")
                .foregroundColor(.senseyeTextColor)
                .padding()
        }
    }

    var verifyPasswordView: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Verify Password".uppercased())
                .foregroundColor(.senseyeTextColor)
            SecureField("", text: $vm.newPassword )
                .foregroundColor(.senseyeTextColor)
            Divider()
                .background(Color.senseyeTextColor)
        }
    }

    var temporaryPasswordView: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("temporary password".uppercased())
                .foregroundColor(.senseyeTextColor)
            SecureField("", text: $vm.temporaryPassword )
                .foregroundColor(.senseyeTextColor)
            Divider()
                .background(Color.senseyeTextColor)
        }
    }
}


