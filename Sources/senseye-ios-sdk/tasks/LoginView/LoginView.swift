//
//  LoginVIew.swift
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
                
                Text("Having trouble logging in?")
                    .foregroundColor(.senseyeTextColor)
                
                Button(action: {
                    vm.login()
                }, label: {
                    SenseyeButton(text: "login", foregroundColor: .senseyePrimary, fillColor: .senseyeSecondary)
                        .padding()
                })
                .disabled(vm.username.isEmpty || vm.password.isEmpty)
                .alert(vm.alertItem?.title ?? "", isPresented: $vm.isShowingAlert) {
                    Button(vm.alertItem?.alertButtonText ?? "") { }
                } message: {
                    Text(vm.alertItem?.message ?? "")
                }
                
                Spacer()
                
                HStack {
                    Spacer()
                    Text(vm.versionAndBuildNumber)
                        .foregroundColor(.senseyeTextColor)
                        .padding(.trailing)
                }
            }
        }
        .onAppear {
            vm.onAppear()
        }
        .onChange(of: vm.isUserSignedIn) { _ in
            if vm.isUserSignedIn {
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
}
