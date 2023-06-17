//
//  BeRealRewriteApp.swift
//  BeRealRewrite
//
//  Created by Lukas Hahn on 5/3/23.
//

import SwiftUI
@main
struct BeRealRewriteApp: App {
    private var service = Service()
    private var coredataService = CoreDataService()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(Model(service: service,coreDataService: coredataService))
        }
    }
}
