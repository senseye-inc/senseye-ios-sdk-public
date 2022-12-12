//
//  LoginVIew.swift
//
//  Created by Bobby Srisan on 4/3/22.
//

import SwiftUI

struct LoginView: View {
    
    enum FocusedField {
        case username, password, tokenField
    }
    
    // ViewModel class is extension of LoginView
    @StateObject private var vm: ViewModel
    @EnvironmentObject var tabController: TabController
    @FocusState private var focusField: FocusedField?
    
    var body: some View {
        ZStack {
            Color.senseyePrimary
                .edgesIgnoringSafeArea(.all)
                .onTapGesture { hideKeyboard() }
            
            VStack(spacing: focusField == nil ? 20 : 0) {
                headerView
                
                loginOptionsView

                Button {
                    vm.isShowingSafari.toggle()
                } label: {
                    Text(Strings.loginHelp)
                        .underline()
                        .foregroundColor(.senseyeTextColor)
                }

                Button {
                    vm.login()
                    hideKeyboard()
                } label: {
                    SenseyeButton(text: Strings.loginButtonTitle, foregroundColor: .senseyePrimary, fillColor: .senseyeSecondary)
                        .padding()
                }
                .disabled(((vm.username.isEmpty || vm.password.isEmpty) && vm.token.isEmpty) || vm.isFetchingAuthorization)
                .alert(vm.alertItem?.title ?? "", isPresented: $vm.isShowingAlert) {
                    Button(vm.alertItem?.alertButtonText ?? "") { }
                } message: {
                    Text(vm.alertItem?.message ?? "")
                }

                HStack {
                    Spacer()
                    Text(vm.versionAndBuildNumber)
                        .foregroundColor(.senseyeTextColor)
                        .padding(.trailing)
                }
            }
            .keyboardAdaptive()
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

    var loginOptionsView: some View {
        VStack {
            if !vm.isUsingToken {
                VStack {
                    usernameField

                    passwordField
                }
                .padding()
            } else {
                VStack {
                    tokenField
                }
                .padding()
            }

            Spacer()

            tokenToggle
                .padding()
        }
    }

    var usernameField: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(Strings.usernameTitle)
                .foregroundColor(.senseyeTextColor)
            HStack {
                TextField("", text: $vm.username, onEditingChanged: { isEditingUsernameField in
                    vm.token = ""
                })
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .keyboardType(.emailAddress)
                    .submitLabel(.continue)
                    .focused($focusField, equals: .username)
                    .onSubmit { focusField = .password }
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

    var passwordField: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(Strings.passwordTitle)
                .foregroundColor(.senseyeTextColor)
            SecureField("", text: $vm.password)
                .foregroundColor(.senseyeTextColor)
                .submitLabel(.go)
                .focused($focusField, equals: .password)
                .onSubmit {
                    vm.login()
                    hideKeyboard()
                }
            Divider()
                .background(Color.senseyeTextColor)
        }
        .padding(.horizontal, 35)
    }

    var tokenField: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(Strings.tokenTitle)
                .foregroundColor(.senseyeTextColor)
            TextField("", text: $vm.token, onEditingChanged: { isEditingTokenField in
                if isEditingTokenField {
                    vm.username = ""
                    vm.password = ""
                }
            })
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .submitLabel(.go)
                .focused($focusField, equals: .tokenField)
            Divider()
                .background(Color.senseyeTextColor)
        }
        .padding(.horizontal, 35)
    }

    var tokenToggle: some View {
        VStack(alignment: .leading, spacing: 5) {
            Toggle(Strings.tokenCallToAction, isOn: $vm.isUsingToken.animation())
                .foregroundColor(.senseyeTextColor)
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
