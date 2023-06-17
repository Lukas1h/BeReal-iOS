//
//  Feed.swift
//  BeRealRewrite
//
//  Created by Lukas Hahn on 5/4/23.
//

import SwiftUI

struct Feed: View {
    @EnvironmentObject private var model: Model
    
    func loadFeed() async{
        do{
            try await model.fetchFriendPosts()
        }catch{
            print("Error: ",error)
        }
    }
    
    
    var body: some View {
        VStack(){
            GeometryReader{ geo in
                TabView{
                    if(model.posts.isEmpty){
                        Text("No posts yet.")
                            .font(.system(.headline))
                    }else{
                        ForEach(model.posts){ post in
                            FeedItem(post: post)
                                .frame(width:UIScreen.main.bounds.width,height:UIScreen.main.bounds.height)
                        }
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .never))
                .task {await loadFeed()}
            }
        }
    }
}

struct Feed_Previews: PreviewProvider {
    static var previews: some View {
        Feed()
    }
}
