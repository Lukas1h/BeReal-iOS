//
//  Login.swift
//  BeRealRewrite
//
//  Created by Lukas Hahn on 5/4/23.
//

import SwiftUI

struct Login: View {
    @EnvironmentObject private var model: Model
    @State var refreshToken = ""
    
    var body: some View {
        VStack {
            Spacer()
            Text("BeReal.")
                .font(.system(size: 40,weight: .bold,design: .rounded))
            TextField("Refresh Token",text:$refreshToken)
                .textFieldStyle(CustomTextFieldStyle())
                .padding()
            Button{
                model.authTokens.refreshToken = refreshToken
                do {
                    
                    try model.saveTokens()
                    Task.init{
                        do {
                            try await model.login()
                        }catch {
                            print("Login arror",error)
                        }
                    }
                } catch {
                    //TODO: Display the error to user
                    print("Error logging in: ",error)
                }
            } label: {
                Text("Login")
            }
            .foregroundColor(.secondary)
            .padding(.horizontal,80)
            .padding(.vertical,12)
            .background(.quaternary)
            .cornerRadius(20)
            Button{
                Task.init{
                    do {
                        try await model.login()
                    }catch {
                        print("Login arror",error)
                    }
                }

            } label: {
                Text("Retry")
            }
            .foregroundColor(.secondary)
            .padding(.horizontal,80)
            .padding(.vertical,12)
            .background(.quaternary)
            .cornerRadius(20)
            Spacer()
            Text("Your refresh token is neccesery for authenticating with your BeReal account. Login with phone will be supported soon.")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding()
            
        }
    }
}

struct Login_Previews: PreviewProvider {
    static var previews: some View {
        Login()
    }
}
