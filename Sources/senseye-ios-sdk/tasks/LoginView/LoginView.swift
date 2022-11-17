//
//  LoginVIew.swift
//
//  Created by Bobby Srisan on 4/3/22.
//

import SwiftUI

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
                
                Button {
                    vm.isShowingSafari.toggle()
                } label: {
                    Text(Strings.loginHelp)
                        .foregroundColor(.senseyeTextColor)
                }
                
                Button {
                    vm.login()
                } label: {
                    SenseyeButton(text: Strings.loginButtonTitle, foregroundColor: .senseyePrimary, fillColor: .senseyeSecondary)
                        .padding()
                }
                .disabled(vm.username.isEmpty || vm.password.isEmpty || vm.isFetchingAuthorization)
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
        .fullScreenCover(isPresented: $vm.isShowingSafari, content: {
            SFSafariViewWrapper(url: vm.supportURL)
        })
        .onAppear {
            vm.onAppear()
        }
        .onChange(of: vm.isUserSignedIn) { _ in
            if vm.isUserSignedIn {
                vm.password = ""
                tabController.proceedToNextTab()
            }
        }
    }
}

extension LoginView {
    init(authenticationService: AuthenticationService) {
        _vm = StateObject(wrappedValue: ViewModel(authenticationService: authenticationService))
    }
    
    var passwordField: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(Strings.passwordTitle)
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
            Text(Strings.usernameTitle)
                .foregroundColor(.senseyeTextColor)
            HStack {
                TextField("", text: $vm.username)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                if !vm.username.isEmpty {
                    Button {
                        vm.username = ""
                    } label: {
                        Image(systemName: "x.circle.fill")
                    }
                }
            }.foregroundColor(.senseyeTextColor)
            Divider()
                .background(Color.senseyeTextColor)
        }
        .padding(.horizontal, 35)
    }
    
    var headerView: some View {
        VStack {
            HeaderView()
            Image("holding_phone_icon")
            Text(Strings.loginCallToAction)
                .foregroundColor(.senseyeTextColor)
                .padding()
        }
    }
}
