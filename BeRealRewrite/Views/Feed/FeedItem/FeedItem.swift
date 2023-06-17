//
//  FeedItem.swift
//  BeRealRewrite
//
//  Created by Lukas Hahn on 5/4/23.
//

import SwiftUI
import UIKit
import Foundation


struct FeedItem: View {
    let post:Post
    
    @State var comments:[Post.Comment]
    @State private var offset:CGFloat = 0.0
    @State private var isDragging = false
    @State private var isDisplayed = false
    
    let modalHeight:CGFloat = 420

    @EnvironmentObject private var model: Model
    
    enum FocusField: Hashable {
      case field
    }

    @FocusState private var focusedField: FocusField?
    @State private var isAddingComment = false
    @State private var commentText = ""
    
    @Namespace var bottomID
    
    
    init(post:Post){
        self.post = post
        
        _comments = State(initialValue: post.comment ?? [])
    }
    
    
    var body: some View {
        ZStack(alignment: .bottom){
            ZStack(alignment: .bottom){
                FeedItemImage(post:post)
                VStack{
                    HStack{
                        NavigationLink{
                            UserView(user:post.user)
                        } label: {
                            Text("@"+post.userName)
                                .font(.headline)
                        }
                        .foregroundColor(.primary)
                        
                        Spacer()
                        Menu{
                            Button{
                                print("Share")
                            } label: {
                                Label("Share", systemImage: "square.and.arrow.up")
                            }
                            if(post.user.id == model.user!.id){
                                Button{
                                    print("Delete")
                                    Task.init{
                                        do {
                                            try self.model.deletePost(post:post)
                                            try await model.fetchFriendPosts()
                                        } catch {
                                            print(error)
                                        }
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                        .foregroundColor(.red)
                                }
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .frame(width:20,height: 20,alignment: .center )
                        }
                        .foregroundColor(.primary)
                    }
                }
                .frame(width:UIScreen.main.bounds.width*0.8)
                .font(.headline)
                .padding()
                .background(.regularMaterial)
                .clipShape(Capsule(style: .continuous))
                .padding(.bottom,60)
            }
            .gesture(
                DragGesture(minimumDistance:50)
                .onChanged{value in
                    isDragging = true
                    print(value.translation.height)
                    offset = value.translation.height*0.5
                    if(isDisplayed && value.translation.height-50 < -50){
                        offset = 0
                    }
                }.onEnded{value in
                    withAnimation(.spring(response: 0.3,dampingFraction: 0.6)){
                        isDragging = false
                        if(!isDisplayed && value.translation.height < -50){
                            isDisplayed = true
                        }else if(isDisplayed && value.translation.height > 50){
                            isDisplayed = false
                            isAddingComment = false
                        }
                    }
                }
                    
            )
            .offset(y: isDisplayed ? -(modalHeight/3) : 0)
            VStack(){
                Capsule(style: .continuous)
                    .fill(.tertiary)
                    .frame(width: isDragging ? 60 : 40,height: isDragging ? 10 : 8)
                    .padding()
                ScrollViewReader { proxy in
                    ScrollView{
                        VStack(alignment: .leading){
                            if let caption = post.caption, let user = model.user{
                                FeedCommentItem(comment:  Post.Comment(id: UUID().uuidString, user: user, text: caption))
                                    .onTapGesture {
                                        withAnimation(.spring()){
                                            isAddingComment = true
                                            self.focusedField = .field
                                            commentText = "@\(user.username) "
                                        }
                                    }
                            }
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
                                            self.comments.append(Post.Comment(id: UUID().uuidString, user: self.model.user!, text: commentText))
                                            try await self.model.addComment(post:post,commentText:commentText)
                                        }
                                    }
                                }
                                .padding(.horizontal,12)
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
                                    proxy.scrollTo(bottomID)
                                }
                            }
                        } label: {
                            Text(isAddingComment ? "Cancel" : "Add Comment")
                        }
                        .buttonStyle(.bordered)
                        .foregroundColor(isAddingComment ? .red : .primary.opacity(0.9))
                        .background(.secondary)
                        .padding(.bottom,20)
                        Spacer(minLength: modalHeight-50)
                        Text("").offset(y:-100).id(bottomID)
                    }
                }
            }
            .frame(width: UIScreen.main.bounds.width,height:modalHeight,alignment: .top)
            .background(Material.regularMaterial)
            .clipShape(RoundedCorner(radius: 40,corners: [.topLeft,.topRight]))
            .offset(y: isDragging ? offset+(isDisplayed ? 0 : modalHeight-50) : isDisplayed ? 0 : modalHeight-50)
            .onDisappear{
                isDisplayed = false
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
}



extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape( RoundedCorner(radius: radius, corners: corners) )
    }
}

struct RoundedCorner: Shape {

    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}



struct FeedItem_Previews: PreviewProvider {
    
    static var previews: some View {
        // Example user
        // Example JSON data
        let jsonString = """
        {
            "id": "1",
            "userName": "lukas__with__a__k",
            "user": {
                "id": "1",
                "username": "lukas__with__a__k",
                "fullname": "Lukas Hahn"
            },
            "photoURL": "https://cdn.bereal.network/Photos/zRHCCjGLIZZ7EnliQwSMZ6zacj23/post/fbdrguR5r1OVdmNN.webp",
            "secondaryPhotoURL": "https://cdn.bereal.network/Photos/zRHCCjGLIZZ7EnliQwSMZ6zacj23/post/VCXQhGA4xcAokAs9.webp",
            "caption": "This is an example caption.",
            "retakeCounter": 0,
            "creationDate": {
                "_seconds": 1620161042,
                "_nanoseconds": 123456789
            },
            "takenAt": {
                "_seconds": 1620161142,
                "_nanoseconds": 123456789
            },
            "comment": [
                {
                    "id": "1",
                    "text": "Great post!",
                    "user": {
                        "id": "2",
                        "username": "janedoe",
                        "fullname": "Jane Doe"
                    }
                },
                {
                    "id": "2",
                    "text": "Thanks!",
                    "user": {
                        "id": "1",
                        "username": "johndoe",
                        "fullname": "John Doe"
                    }
                }
            ]
        }
        """

        // Create a JSONDecoder instance
        let decoder = JSONDecoder()

        // Attempt to decode the JSON data
        
        let post = try! decoder.decode(Post.self, from: Data(jsonString.utf8))
        return (
            GeometryReader{ geo in
                FeedItem(post: post)
            }.padding()
        )
    }
}



/**struct FeedItem: View {
 let post:Post
 let geo: GeometryProxy

 @EnvironmentObject private var model: Model
 
 var body: some View {
     VStack {
         VStack(alignment: .leading){
             VStack{
                 HStack{
                     NavigationLink{
                         UserView(user:post.user)
                     } label: {
                         Text(post.userName)
                             .font(.headline)
                     }
                     .foregroundColor(.white)
                     
                     Spacer()
                     Menu{
                         Button{
                             print("Share")
                         } label: {
                             Label("Share", systemImage: "square.and.arrow.up")
                         }
                         if(post.user.id == model.user!.id){
                             Button{
                                 print("Delete")
                                 Task.init{
                                     do {
                                         try self.model.deletePost(post:post)
                                         try await model.fetchFriendPosts()
                                     } catch {
                                         print(error)
                                     }
                                 }
                             } label: {
                                 Label("Delete", systemImage: "trash")
                                     .foregroundColor(.red)
                             }
                         }
                     } label: {
                         Image(systemName: "ellipsis")
                     }
                     .foregroundColor(.white)
                 }.padding()
                 FeedItemImage(post:post,geo:geo)
             }
             if let caption = post.caption {
                 Text(caption)
                     .padding()
             }
//                if let realmojies = post{
//                    ForEach(comments.suffix(4)){comment in
//                        FeedCommentItem(comment: comment)
//                    }
//                }
             if let comments = post.comment{
                 ForEach(comments.suffix(4)){comment in
                     FeedCommentItem(comment: comment)
                 }
             }
         }

         NavigationLink{
             FeedItemCommentView(post: post)
                 .navigationTitle(post.caption ?? "\(post.userName)'s BeReal" )
                 .navigationBarTitleDisplayMode(.inline)
         } label: {
             Text("View More")
                 .font(Font.system(size: 14, weight: .bold))
                 .foregroundColor(.white)
                 .padding(6)
         }
     }
 }
}*/
