//
//  UserView.swift
//  BeRealRewrite
//
//  Created by Lukas Hahn on 5/9/23.
//

import SwiftUI

struct UserView: View {
    let user: User
    
    var body: some View {
        Text(user.username)
            .font(.title)
    }
}

