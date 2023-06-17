//
//  ContentView.swift
//  BeRealRewrite
//
//  Created by Lukas Hahn on 5/3/23.


import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var model: Model
    @State private var loginPresented = true;
    @State private var isLoading = true;
    
    var body: some View {
        Group{
            if(isLoading){
                ProgressView("Logging In... ")
                    .controlSize(.large)
            }else{
                if(model.isLoggedIn){
                    Home()
                        .sheet(isPresented: $model.isModalPresented){
                            model.modalView
                                .background(.regularMaterial)
                            
                        }
                }else{
                    Text("Logging In... ")
                        .sheet(isPresented: $loginPresented){
                            Login()
                                .interactiveDismissDisabled()
                        }
                }
            }
        }.task {
            do{
                try await model.login()
            } catch {
                isLoading = false;
            }
            isLoading = false;
            loginPresented = !model.isLoggedIn;
        }.onChange(of: model.isLoggedIn){newIsLoggedIn in
            if(newIsLoggedIn == false){
                print("Just got logged out!")
                isLoading = false
                loginPresented = true
            }
        }
        .onOpenURL { url in
            self.model.onDeepLink(url: url)
            print("Received deep link: \(url)")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static private var service = Service()
    static private var coredataService = CoreDataService()
    
    static var previews: some View {
        ContentView()
            .environmentObject(Model(service: service,coreDataService: coredataService))
    }
}
