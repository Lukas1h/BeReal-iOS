//
//  FeedCommentItem.swift
//  BeRealRewrite
//
//  Created by Lukas Hahn on 5/9/23.
//

import SwiftUI

struct FeedCommentItem: View {
    let comment: Post.Comment
    
    
    var body: some View {
        VStack(alignment:.leading){
            Text(comment.user.username)
                .font(.headline)
            Text(comment.commentText)
        }
        .padding([.leading, .bottom, .trailing],8)
    }
}

struct FeedCommentItem_Previews: PreviewProvider {
    static var previews: some View {
        FeedCommentItem(comment: Post.Comment(id: "123", user: User(id: "123", username: "lukas__with__a__k", fullname: "Lukas Hahn"), text: "Lol. I just love this. 🤣"))
    }
}
