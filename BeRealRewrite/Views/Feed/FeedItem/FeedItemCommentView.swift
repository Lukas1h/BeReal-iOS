//
//  FeedItemCommentView.swift
//  BeRealRewrite
//
//  Created by Lukas Hahn on 5/10/23.
//

import SwiftUI

struct FeedItemCommentView: View {
    
    enum FocusField: Hashable {
      case field
    }

    @EnvironmentObject private var model: Model
    @FocusState private var focusedField: FocusField?
    @State private var isAddingComment = false
    @State private var commentText = ""
    
    let post:Post
    
    var comments:[Post.Comment]
    
    init(post:Post){
        self.post = post
        self.comments = post.comment ?? []
    }
    
    var body: some View {
        GeometryReader{geo in
            ScrollView{
                FeedItemImage(post: post)
                
                VStack(alignment: .leading){
                    ForEach(comments){comment in
                        FeedCommentItem(comment: comment)
                            .onTapGesture {
                                withAnimation(.spring()){
                                    isAddingComment = true
                                    self.focusedField = .field
                                    commentText = "@\(comment.user.username) "
                                }
                            }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                
                if(isAddingComment){
                    TextField("Comment",text: $commentText)
                        .padding(6)
                        .background(Color(.secondarySystemFill).clipShape(RoundedRectangle(cornerRadius: 6)))
                        .focused($focusedField, equals: .field)
                        .onSubmit {
                            if(!commentText.isEmpty){
                                Task.init{
                                    isAddingComment = false
                                    self.focusedField = nil
                                    try await self.model.addComment(post:post,commentText:commentText)
                                    try await self.model.fetchFriendPosts()
                                }
                            }
                        }
                }
                Button{
                    print("Add comment")
                    withAnimation(.spring()){
                        if(isAddingComment){
                            isAddingComment = false
                            self.focusedField = nil
                        }else{
                            isAddingComment = true
                            self.focusedField = .field
                        }
                    }
                } label: {
                    Text(isAddingComment ? "Cancel" : "Add Comment")
                }
                .buttonStyle(.bordered)
                .foregroundColor(isAddingComment ? .red : .secondary)
                .padding(.bottom,20)
            }
        }
    }
}
