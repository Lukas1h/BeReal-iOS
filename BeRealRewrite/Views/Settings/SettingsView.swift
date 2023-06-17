//
//  SettingsView.swift
//  BeRealRewrite
//
//  Created by Lukas Hahn on 5/18/23.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var model:Model
    
    var body: some View {
        NavigationView {
            List {
                Section("General") {
                    NavigationLink(destination: Text("General")) {
                        Label("General", systemImage: "gear")
                    }
                    
                    NavigationLink(destination: UserView(user: model.user!)) {
                        Label("Profile", systemImage: "person")
                    }
                }
                
                Section("Notifications") {
                    NavigationLink(destination: Text("Notifications")) {
                        Label("Notifications", systemImage: "bell")
                    }
                }
                Button("Log Out", role: .destructive){
                    do{
                        try
                        self.model.logOut()
                    } catch {
                        print("Error logging out")
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
