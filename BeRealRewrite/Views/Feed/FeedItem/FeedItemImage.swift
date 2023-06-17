//
//  FeedItemImage.swift
//  BeRealRewrite
//
//  Created by Lukas Hahn on 5/5/23.
//

import SwiftUI

struct FeedItemImage: View {
    let post:Post
    
    @State private var isPrimaryActive = true;
    @State private var isPrimarySelected = false;
    @State private var isSecondarySelected = false;
    
    let smallWidth = UIScreen.main.bounds.width*0.4
    let smallHeight = UIScreen.main.bounds.height*0.4
    
    let bigWidth = UIScreen.main.bounds.width
    let bigHeight = UIScreen.main.bounds.height*0.9
    
    
    var body: some View {
        ZStack{
            ZStack(alignment: .topLeading){
                AsyncImage(url: URL(string: post.photoURL)) { image in
                    image
                        .resizable()
                    //                    .aspectRatio(contentMode: .fit)
                        .scaledToFill()
                        .frame(width: isPrimaryActive ? bigWidth : smallWidth,height: isPrimaryActive ? bigHeight : smallHeight)
                        .contextMenu {
                            Button {
                                UIImageWriteToSavedPhotosAlbum(image.asUIImage(), nil,nil, nil)
                            } label: {
                                Label("Save to Photos", systemImage: "square.and.arrow.down")
                            }
                            ShareLink(item:post.photoURL) {
                                Label("Share", systemImage:  "square.and.arrow.up")
                            }
                        }
                } placeholder: {
                    ProgressView()
                        .frame(width: isPrimaryActive ? bigWidth : smallWidth,height:  isPrimaryActive ? bigHeight : smallHeight)
                }
                .clipShape(RoundedRectangle(cornerRadius: 25))
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(isPrimaryActive ? .black.opacity(0) : .black, lineWidth: 3)
                )
                .opacity(isSecondarySelected ? 0 : 100)
                .shadow(radius: 4)
                .zIndex(isPrimaryActive ? 0 : 100)
                .padding(isPrimaryActive ? 0 : 10)
                .onTapGesture {
                    withAnimation(.spring(blendDuration: 0.1)){
                        if(isPrimarySelected){
                            isPrimarySelected = false;
                            
                        }else{
                            if isPrimaryActive == false {
                                isPrimaryActive = true
                            }
                        }
                    }
                }
                
                
                AsyncImage(url: URL(string: post.secondaryPhotoURL)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                    //                    .aspectRatio(contentMode: .fit)
                        .frame(width: isPrimaryActive ? smallWidth : bigWidth,height:  isPrimaryActive ? smallHeight : bigHeight)
                        .contextMenu {
                            Button {
                                UIImageWriteToSavedPhotosAlbum(image.asUIImage(), nil,nil, nil)
                            } label: {
                                Label("Save to Photos", systemImage: "square.and.arrow.down")
                            }
                            ShareLink(item:post.photoURL) {
                                Label("Share", systemImage:  "square.and.arrow.up")
                            }
                        }
                } placeholder: {
                    ProgressView()
                        .frame(width: smallWidth,height: isPrimaryActive ? smallHeight : bigHeight)
                }
                .clipShape(RoundedRectangle(cornerRadius: 25))
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(isPrimaryActive ? .black : .black.opacity(0), lineWidth: 3)
                )
                .opacity(isPrimarySelected ? 0 : 100)
                .shadow(radius: 4)
                .zIndex(isPrimaryActive ? 100 : 0)
                .padding(isPrimaryActive ? 10 : 0)
                .onTapGesture {
                    withAnimation(.spring(blendDuration: 0.1)){
                        if(isSecondarySelected){
                            isSecondarySelected = false;
                            
                        }else{
                            if isPrimaryActive == true {
                                isPrimaryActive = false
                            }
                        }
                    }
                }
            }
        }
        .frame(width:UIScreen.main.bounds.height, height:UIScreen.main.bounds.height)
    }
}



struct FeedItemImage_Previews: PreviewProvider {
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
            "photoURL": "https://cdn.bereal.network/Photos/zRHCCjGLIZZ7EnliQwSMZ6zacj23/post/SQHPxIPQTDnaXybC.webp",
            "secondaryPhotoURL": "https://cdn.bereal.network/Photos/zRHCCjGLIZZ7EnliQwSMZ6zacj23/post/uYrolrkua36g68lG.webp",
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
        GeometryReader{geo in
            
            FeedItemImage(post: post)
        }
        )
        

        
    }
}


extension View {
// This function changes our View to UIView, then calls another function
// to convert the newly-made UIView to a UIImage.
    public func asUIImage() -> UIImage {
        let controller = UIHostingController(rootView: self)
        
 // Set the background to be transparent incase the image is a PNG, WebP or (Static) GIF
        controller.view.backgroundColor = .clear
        
        controller.view.frame = CGRect(x: 0, y: CGFloat(Int.max), width: 1, height: 1)
        UIApplication.shared.windows.first!.rootViewController?.view.addSubview(controller.view)
        
        let size = controller.sizeThatFits(in: UIScreen.main.bounds.size)
        controller.view.bounds = CGRect(origin: .zero, size: size)
        controller.view.sizeToFit()
        
// here is the call to the function that converts UIView to UIImage: `.asUIImage()`
        let image = controller.view.asUIImage()
        controller.view.removeFromSuperview()
        return image
    }
}

extension UIView {
// This is the function to convert UIView to UIImage
    public func asUIImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { rendererContext in
            layer.render(in: rendererContext.cgContext)
        }
    }
}
