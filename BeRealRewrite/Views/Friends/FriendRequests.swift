//
//  FriendRequests.swift
//  BeRealRewrite
//
//  Created by Lukas Hahn on 5/10/23.
//

import SwiftUI

struct FriendRequestsView: View {
    
    @EnvironmentObject private var model: Model
    @State private var sentFriendRequests:[FriendRequest] = []
    @State private var recivedFriendRequests:[FriendRequest] = []
    @State private var friends:[FriendRequest] = []
    
    func fetchFriendRequests() async {
        do {
            friends = try await self.model.getFriends()
            sentFriendRequests = try await self.model.getSentFriendRequests()
            recivedFriendRequests = try await self.model.getReceivedFriendRequests()
        } catch {
            print("Error while getting friend requests, ",error)
        }
    }
    
    var body: some View {
        NavigationView{
            List{
                Section("Friends"){
                    if(friends.count > 0){
                        ForEach(friends) { request in
                            HStack{
                                Text(request.fullname)
                                Spacer()
                                Text(request.username)
                            }
                        }
                    }else{
                        Text("No Friends")
                    }
                }
                Section("Sent Requests"){
                    if(sentFriendRequests.count > 0){
                        ForEach(sentFriendRequests) { request in
                            HStack{
                                Text(request.fullname)
                                Spacer()
                                Text(request.username)
                            }
                        }
                    }else{
                        Text("No Sent Requests")
                    }
                }
                Section("Recived Requests"){
                    if(recivedFriendRequests.count > 0){
                        ForEach(recivedFriendRequests) { request in
                            HStack{
                                Text(request.fullname)
                                Spacer()
                                Button{
                                    
                                } label: {
                                    Image(systemName:"person.badge.plus")
                                }
                            }
                        }
                    }else{
                        Text("No Recived Requests")
                    }
                }
            }
            .task {await fetchFriendRequests()}
            .refreshable {await fetchFriendRequests()}
            .navigationBarTitle("Friends")
        }
    }
}

